#!/usr/bin/env python3
"""Build a public-safe GitHub mirror commit from a Gitea checkout.

This script is intentionally kept under .gitea so it never enters the public
mirror. It copies only tracked source files, removes Gitea-only workflow files,
normalizes the two known public URLs, rejects private markers, and commits the
result on top of the current GitHub master without rewriting history.
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

PRIVATE_PREFIXES = (".gitea/",)
REPLACEMENTS = {
    b"https://git.ciolan.net/iAdrian/plasma-applet-window-buttons6": b"https://github.com/ciolansteen/plasma-applet-window-buttons6",
    b"https://git.ciolan.net/github-mirrors/applet-window-buttons6": b"https://github.com/moodyhunter/applet-window-buttons6",
}
FORBIDDEN_MARKERS = (
    "git.ciolan.net",
    "ciolan.go.ro",
    "archRepo",
    "CI_TOKEN",
    "/home/iadrian",
)


def run(*args: str, cwd: Path | None = None, check: bool = True) -> str:
    result = subprocess.run(
        args,
        cwd=cwd,
        check=False,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if check and result.returncode:
        raise RuntimeError(
            f"command failed ({result.returncode}): {' '.join(args)}\n"
            f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
        )
    return result.stdout


def tracked_files(repo: Path) -> list[Path]:
    raw = subprocess.check_output(["git", "-C", str(repo), "ls-files", "-z"])
    paths = [Path(item.decode("utf-8")) for item in raw.split(b"\0") if item]
    return [path for path in paths if not any(str(path).startswith(prefix) for prefix in PRIVATE_PREFIXES)]


def clear_tracked_tree(target: Path) -> None:
    names = run("git", "-C", str(target), "ls-files", "-z").encode()
    for item in names.split(b"\0"):
        if not item:
            continue
        path = target / item.decode("utf-8")
        if path.is_dir() and not path.is_symlink():
            shutil.rmtree(path)
        else:
            path.unlink(missing_ok=True)


def copy_tree(source: Path, target: Path) -> None:
    for relative in tracked_files(source):
        source_path = source / relative
        target_path = target / relative
        target_path.parent.mkdir(parents=True, exist_ok=True)
        if source_path.is_symlink():
            target_path.unlink(missing_ok=True)
            target_path.symlink_to(os.readlink(source_path))
        else:
            shutil.copy2(source_path, target_path)


def normalize_text_files(target: Path) -> None:
    for relative in tracked_files(target):
        path = target / relative
        if path.is_symlink() or not path.is_file():
            continue
        data = path.read_bytes()
        if b"\0" in data:
            continue
        updated = data
        for old, new in REPLACEMENTS.items():
            updated = updated.replace(old, new)
        if updated != data:
            path.write_bytes(updated)


def assert_public_safe(target: Path) -> None:
    paths = run("git", "-C", str(target), "ls-files").splitlines()
    forbidden_paths = [path for path in paths if any(path.startswith(prefix) for prefix in PRIVATE_PREFIXES)]
    if forbidden_paths:
        raise RuntimeError(f"private paths staged for publication: {forbidden_paths}")

    for marker in FORBIDDEN_MARKERS:
        result = subprocess.run(
            ["git", "-C", str(target), "grep", "-n", "-I", "--cached", "-F", marker],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        if result.returncode == 0:
            raise RuntimeError(f"private marker {marker!r} staged for publication:\n{result.stdout}")
        if result.returncode != 1:
            raise RuntimeError(result.stderr)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--source-sha", required=True)
    args = parser.parse_args()

    source = args.source.resolve()
    target = args.target.resolve()
    if not (source / ".git").exists() or not (target / ".git").exists():
        raise RuntimeError("source and target must be Git working trees")

    original_target_head = run("git", "-C", str(target), "rev-parse", "HEAD").strip()
    clear_tracked_tree(target)
    copy_tree(source, target)
    normalize_text_files(target)

    run("git", "-C", str(target), "add", "-A")
    run("git", "-C", str(target), "diff", "--cached", "--check")
    assert_public_safe(target)

    changed = subprocess.run(["git", "-C", str(target), "diff", "--cached", "--quiet"]).returncode != 0
    if not changed:
        print(f"No public mirror change for Gitea source {args.source_sha}.")
        return 0

    run(
        "git",
        "-C",
        str(target),
        "-c",
        "user.name=Gitea public mirror",
        "-c",
        "user.email=mirror@ciolan.net",
        "commit",
        "-m",
        f"Mirror Gitea source {args.source_sha}",
    )

    run("git", "-C", str(target), "fetch", "origin", "master")
    remote_head = run("git", "-C", str(target), "rev-parse", "origin/master").strip()
    if remote_head != original_target_head:
        raise RuntimeError(
            "GitHub master changed while the mirror was being built; refusing to overwrite it."
        )

    run("git", "-C", str(target), "push", "origin", "HEAD:refs/heads/master")
    print(f"Published sanitized mirror of Gitea source {args.source_sha}.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"mirror failed: {error}", file=sys.stderr)
        raise SystemExit(1)
