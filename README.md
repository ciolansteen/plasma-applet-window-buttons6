# Window Buttons Applet

This fork is maintained at <https://git.ciolan.net/iAdrian/plasma-applet-window-buttons6>.
It is based on <https://git.ciolan.net/github-mirrors/applet-window-buttons6>,
which mirrors <https://github.com/moodyhunter/applet-window-buttons6>.

## What differs from upstream

This fork keeps the same Plasma applet id (`org.kde.windowbuttons`) so it can
replace the upstream package without rebuilding existing panels, but changes the
window selection semantics to fit global-menu/top-panel setups where maximized
windows are borderless and the panel acts as their titlebar.

## Fixed problem

Upstream ties both visibility and button actions to the active/last-active
window. That is fine for a normal decorated-window workflow, but it breaks a
top-panel workflow:

1. A maximized, borderless window is visually represented by the top panel.
2. A small floating window, dialog, picker, or helper gets focus above it.
3. The panel still looks like the maximized window's titlebar.
4. Pressing the panel close/maximize/minimize buttons unexpectedly affects the
   focused floating window instead of the maximized window behind it.

This fork makes the panel buttons target the maximized window on the current
screen, because that is the window the panel visually represents. Focus is only
used as a fallback when no maximized window exists.

Changes:

- Window button actions prefer the maximized window on the current screen. If a
  floating dialog or helper window is focused above a maximized window, the
  panel buttons still operate on the maximized window they visually represent.
- If no maximized window exists on that screen, actions fall back to the active
  window, preserving the useful upstream behavior for normal/floating sessions.
- The old "Active window is maximized" behavior is treated as a compatibility
  alias for the maximized-window behavior, because tying panel titlebar
  visibility to focus is misleading when floating windows overlap maximized
  windows.
- A real `MaximizedWindowExists` visibility mode is added and exposed in the
  Behavior settings as "Maximized window is shown".
- Maximized-window detection uses Plasma's `TaskManager.TasksModel` after its
  existing screen, virtual desktop, and activity filters. With "Show only for
  windows in current screen" enabled, visibility and actions are screen-local.
- "Draw buttons inactive state when needed" is evaluated against the window represented
  by the panel buttons, not whichever floating window currently has focus. If
  the maximized target window is inactive, the panel buttons use inactive
  decoration colors; when that target window is active, they use active colors.
- Button release and hover events are forwarded to KDecoration with corrected
  coordinates, avoiding stale pointer state caused by mismatched event geometry.

The goal is not to make a generic fork with every possible policy knob. It is to
provide predictable defaults for a Plasma setup where maximized windows are
borderless and the top panel owns their window controls.

This is a Plasma 5 applet that shows window buttons in your panels. This plasmoid is coming from [Latte land](https://phabricator.kde.org/source/latte-dock/repository/master/) but it can also support Plasma panels.

<p align="center">
<img src="https://i.imgur.com/4FItfte.gif" width="580"><br/>
<i>slide in/out animation</i>
</p>

<p align="center">
<img src="https://i.imgur.com/70qeMME.png" width="580"><br/>
<i>Breeze decoration</i>
</p>

<p align="center">
<img src="https://i.imgur.com/uEen6P0.png" width="580"><br/>
<i>BreezeEnhanced decoration</i>
</p>

<p align="center">
<img src="https://i.imgur.com/Zz20RXC.png" width="580"><br/>
<i>Settings window</i>
</p>

# Requires

- Qt >= 5.9
- KF5 >= 5.38
- Plasma >= 5.23.2
- KDecoration2 >= 5.23

**Qt elements**: Gui Qml Quick

**KF5 elements**: CoreAddons Declarative Plasma PlasmaQuick extra-cmake-modules


# Install

You can execute `sh install.sh` in the root directory as long as you have installed the previous mentioned development packages. For more details please read [INSTALLATION.md](/INSTALLATION.md)
