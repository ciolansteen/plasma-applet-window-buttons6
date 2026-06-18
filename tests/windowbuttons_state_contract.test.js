#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const repoRoot = path.resolve(__dirname, '..');
const mainQml = fs.readFileSync(path.join(repoRoot, 'package/contents/ui/main.qml'), 'utf8');
const tasksQml = fs.readFileSync(path.join(repoRoot, 'package/contents/ui/PlasmaTasksModel.qml'), 'utf8');

function boolProperty(source, name) {
  const match = source.match(new RegExp(`readonly property bool ${name}:\\s*([^\\n]+)`));
  assert.ok(match, `missing readonly property bool ${name}`);
  return match[1].trim();
}

const focusExpr = boolProperty(tasksQml, 'focusOutsideTaskModel');
const blocksExpr = boolProperty(mainQml, 'blocksInactiveWindowActions');
const dimsExpr = boolProperty(mainQml, 'dimsInactiveWindowActions');

assert.match(
  focusExpr,
  /!targetTaskItem/,
  'cross-screen focus must not count as outside/unusable while this screen still has a local action target'
);

assert.doesNotMatch(
  blocksExpr,
  /existsMaximizedWindow/,
  'blocking must be based on local target availability, not a broad maximized-window shortcut'
);

assert.doesNotMatch(
  dimsExpr,
  /activeFloatingWithoutMaximizedTarget/,
  'a same-screen active floating target should not self-dim; dim only when another local active window obscures the tracked target'
);

function desiredState({ inactiveStateEnabled, hasTrackedWindow, hasActiveTask, hasTargetTaskItem, targetObscuredByTrackedWindow }) {
  const focusOutsideTaskModel = hasTrackedWindow && !hasActiveTask && !hasTargetTaskItem;
  return {
    focusOutsideTaskModel,
    blocksInactiveWindowActions: inactiveStateEnabled && focusOutsideTaskModel,
    dimsInactiveWindowActions: inactiveStateEnabled && targetObscuredByTrackedWindow,
  };
}

assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  hasTrackedWindow: true,
  hasActiveTask: false,
  hasTargetTaskItem: true,
  targetObscuredByTrackedWindow: false,
}), {
  focusOutsideTaskModel: false,
  blocksInactiveWindowActions: false,
  dimsInactiveWindowActions: false,
}, 'local target remains actionable when global focus moves to another screen');

assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  hasTrackedWindow: true,
  hasActiveTask: true,
  hasTargetTaskItem: true,
  targetObscuredByTrackedWindow: true,
}), {
  focusOutsideTaskModel: false,
  blocksInactiveWindowActions: false,
  dimsInactiveWindowActions: true,
}, 'same-screen floating-over-target still dims without blocking');

assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  hasTrackedWindow: true,
  hasActiveTask: false,
  hasTargetTaskItem: false,
  targetObscuredByTrackedWindow: false,
}), {
  focusOutsideTaskModel: true,
  blocksInactiveWindowActions: true,
  dimsInactiveWindowActions: false,
}, 'no local action target remains blocked');

console.log('windowbuttons state contract ok');
