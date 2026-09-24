#!/usr/bin/env node
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

const source = fs.readFileSync(path.join(__dirname,
    '../dotfiles/.config/quickshell/widgets/singletons/system/Config.qml'), 'utf8');
const scriptMatch = source.match(/let script =\n([\s\S]*?)\n\n        saveProc\.writingPatch/);
const exitMatch = source.match(/onExited: \(code\) => \{([\s\S]*?)^        \}/m);
assert(scriptMatch && exitMatch);
const script = Function('return ' + scriptMatch[1])();

const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'widget-settings-'));
try {
    const target = path.join(dir, 'settings.json');
    fs.writeFileSync(target, '{"network":{"screenFraction":0.62}}\n');
    const before = fs.statSync(target).ino;
    const patch = {wallpaperDir: '/walls'};
    const args = ['-c', script, '_', target, JSON.stringify(patch), '{}'];
    let result = spawnSync('bash', args, {encoding: 'utf8'});
    assert.equal(result.status, 0, result.stderr);
    assert.notEqual(fs.statSync(target).ino, before, 'save must atomically replace the file');
    assert.deepEqual(JSON.parse(fs.readFileSync(target, 'utf8')),
        {network: {screenFraction: 0.62}, wallpaperDir: '/walls'});

    const fakeBin = path.join(dir, 'bin');
    fs.mkdirSync(fakeBin);
    fs.writeFileSync(path.join(fakeBin, 'jq'), '#!/bin/sh\nexit 1\n', {mode: 0o755});
    const persisted = fs.readFileSync(target, 'utf8');
    result = spawnSync('bash', args, {encoding: 'utf8',
        env: {...process.env, PATH: fakeBin + ':' + process.env.PATH}});
    assert.equal(result.status, 1);
    assert.equal(fs.readFileSync(target, 'utf8'), persisted, 'failed save changed the file');

    const handler = Function('code', 'config', 'writingPatch', 'saveTimer', exitMatch[1]);
    const config = {pendingUpdates: {wallpaperDir: '/walls'}};
    const timer = {interval: 0, restart() { this.restarted = true; }};
    handler(1, config, patch, timer);
    assert.deepEqual(config.pendingUpdates, patch, 'failed save lost pending changes');
    assert.equal(timer.interval, 5000);
    config.pendingUpdates.wallpaperDir = '/newer';
    handler(0, config, patch, timer);
    assert.equal(config.pendingUpdates.wallpaperDir, '/newer', 'newer update was discarded');
} finally {
    fs.rmSync(dir, {recursive: true, force: true});
}
console.log('widget settings save checks passed');
