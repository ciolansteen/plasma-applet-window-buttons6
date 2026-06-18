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

// --- PlasmaTasksModel.qml contract ---

const focusExpr = boolProperty(tasksQml, 'focusOutsideTaskModel');
assert.match(
  focusExpr,
  /!targetTaskItem/,
  'cross-screen focus must not count as outside/unusable while this screen still has a local action target'
);

// --- main.qml contract ---

const blocksExpr = boolProperty(mainQml, 'blocksInactiveWindowActions');
assert.doesNotMatch(
  blocksExpr,
  /existsMaximizedWindow/,
  'blocking must be based on local target availability, not a broad maximized-window shortcut'
);

const dimsExpr = boolProperty(mainQml, 'dimsInactiveWindowActions');
assert.doesNotMatch(
  dimsExpr,
  /activeFloatingWithoutMaximizedTarget/,
  'a same-screen active floating target should not self-dim; dim only when another local active window obscures the tracked target'
);

// isActive expressions must guard the inactive-gray path with perScreenLocalContext
const isActiveMatches = mainQml.match(/isActive:\s*\{[^}]*perScreenLocalContext[^}]*\}/g);
assert.ok(isActiveMatches && isActiveMatches.length >= 2,
  'both button delegates (pluginButton + auroraeButton) must guard isActive with perScreenLocalContext');
assert.match(
  mainQml,
  /var perScreenLocalContext = root\.perScreenActive && root\.existsWindowShown/,
  'perScreenLocalContext must be perScreenActive && existsWindowShown'
);

// --- State model ---

function desiredState({ inactiveStateEnabled, perScreenActive, hasTrackedWindow, hasActiveTask, hasTargetTaskItem, existsWindowShown, targetObscuredByTrackedWindow }) {
  const focusOutsideTaskModel = hasTrackedWindow && !hasActiveTask && !hasTargetTaskItem;
  const blocksInactiveWindowActions = inactiveStateEnabled && focusOutsideTaskModel;
  const dimsInactiveWindowActions = inactiveStateEnabled && targetObscuredByTrackedWindow;
  const perScreenLocalContext = perScreenActive && existsWindowShown;
  const isLastActiveWindowActive = hasActiveTask;
  const buttonIsGray = blocksInactiveWindowActions ||
    (!perScreenLocalContext && inactiveStateEnabled && existsWindowShown && !isLastActiveWindowActive && !dimsInactiveWindowActions);
  return {
    focusOutsideTaskModel,
    blocksInactiveWindowActions,
    dimsInactiveWindowActions,
    buttonIsGray,
  };
}

// Per-screen: maximized local target stays bright when focus moves to another screen
assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  perScreenActive: true,
  hasTrackedWindow: true,
  hasActiveTask: false,
  hasTargetTaskItem: true,
  existsWindowShown: true,
  targetObscuredByTrackedWindow: false,
}), {
  focusOutsideTaskModel: false,
  blocksInactiveWindowActions: false,
  dimsInactiveWindowActions: false,
  buttonIsGray: false,
}, 'per-screen: local target stays bright under cross-screen focus');

// Same-screen: floating-over-target dims without blocking
assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  perScreenActive: true,
  hasTrackedWindow: true,
  hasActiveTask: true,
  hasTargetTaskItem: true,
  existsWindowShown: true,
  targetObscuredByTrackedWindow: true,
}), {
  focusOutsideTaskModel: false,
  blocksInactiveWindowActions: false,
  dimsInactiveWindowActions: true,
  buttonIsGray: false,
}, 'same-screen floating-over-target dims without blocking');

// No local target: remains blocked/gray
assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  perScreenActive: true,
  hasTrackedWindow: true,
  hasActiveTask: false,
  hasTargetTaskItem: false,
  existsWindowShown: false,
  targetObscuredByTrackedWindow: false,
}), {
  focusOutsideTaskModel: true,
  blocksInactiveWindowActions: true,
  dimsInactiveWindowActions: false,
  buttonIsGray: true,
}, 'no local target remains blocked');

// perScreenActive off: standard inactive gray behavior preserved
assert.deepEqual(desiredState({
  inactiveStateEnabled: true,
  perScreenActive: false,
  hasTrackedWindow: true,
  hasActiveTask: false,
  hasTargetTaskItem: true,
  existsWindowShown: true,
  targetObscuredByTrackedWindow: false,
}), {
  focusOutsideTaskModel: false,
  blocksInactiveWindowActions: false,
  dimsInactiveWindowActions: false,
  buttonIsGray: true,
}, 'perScreenActive off: standard inactive gray behavior preserved');

console.log('windowbuttons state contract ok');
