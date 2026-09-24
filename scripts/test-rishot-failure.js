#!/usr/bin/env node
// Run with Node: node scripts/test-rishot-failure.js
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {spawnSync} = require('node:child_process');

const source = fs.readFileSync(path.join(__dirname, '../dotfiles/.config/quickshell/rishot/src/shell.qml'), 'utf8');
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'rishot-failure-test-'));
const bin = path.join(tmp, 'bin');
fs.mkdirSync(bin);

function stub(name, body) {
    const file = path.join(bin, name);
    fs.writeFileSync(file, '#!/bin/sh\n' + body + '\n', {mode: 0o755});
}
stub('wl-copy', 'cat >/dev/null\n[ "$WL_COPY_FAIL" != 1 ]');
stub('cliphist', 'cat >/dev/null');
stub('magick', 'exit 0');
stub('curl', '[ "$CURL_FAIL" != 1 ] || exit 22\nprintf %s "${CURL_REPLY:-https://example.org/shot.png}"');
stub('notify-send', 'printf "%s\\n" "$*" > "$NOTIFY_LOG"');

function section(id) {
    return source.slice(source.indexOf('        id: ' + id));
}

function command(id, variables) {
    const match = section(id).match(/command = ([\s\S]*?);\n\s*running = true;/);
    assert.ok(match, 'Missing command for ' + id);
    return Function(...Object.keys(variables), 'return ' + match[1])(...Object.values(variables));
}

function handler(id, code, variables) {
    const text = section(id);
    const start = text.indexOf('onExited: (code) =>');
    const arrow = text.slice(start + 'onExited: '.length, text.indexOf('\n    }', start));
    return Function(...Object.keys(variables), 'return ' + arrow)(...Object.values(variables))(code);
}

function shell(command, env = {}) {
    const args = command[0] === 'setsid' ? command.slice(2) : command;
    const result = spawnSync(args[0], args.slice(1), {
        env: {...process.env, PATH: bin + ':' + process.env.PATH,
            NOTIFY_LOG: path.join(tmp, 'notification'), ...env},
        encoding: 'utf8', timeout: 5000
    });
    if (result.status === null) assert.ifError(result.error);
    return result.status;
}

try {
    const image = path.join(tmp, 'capture with spaces.png');
    const root = {uploadEndpoint: 'https://example.org/upload', iconPath: '/icon',
        savedAuto: image, pretty: p => p,
        finishes: [], after: [],
        finish(...args) { this.finishes.push(args); },
        afterSave(p) { this.after.push(p); }};
    const notification = path.join(tmp, 'notification');
    const copy = keep => command('copyProc', {f: image, keep});
    const upload = () => command('uploadProc', {file: image, root});
    const saveCopy = () => command('saveCopyProc', {path: image});

    fs.writeFileSync(image, 'capture');
    assert.equal(shell(copy(false), {WL_COPY_FAIL: '1'}), 1);
    assert.ok(fs.existsSync(image), 'Failed clipboard copy deleted the capture');
    handler('copyProc', 1, {root, file: image, keep: false, console});
    assert.deepEqual(root.finishes.pop(), ['Copy failed', image, true, image]);
    assert.equal(shell(copy(false)), 0);
    assert.ok(!fs.existsSync(image), 'Successful temporary copy was not cleaned up');

    fs.writeFileSync(image, 'capture');
    assert.equal(shell(saveCopy(), {WL_COPY_FAIL: '1'}), 1);
    assert.ok(fs.existsSync(image), 'Failed copy-on-save deleted the saved file');
    handler('saveCopyProc', 1, {root, p: image});
    assert.deepEqual(root.finishes.pop(), ['Saved, clipboard copy failed', image, true, image]);
    handler('copyFileProc', 1, {root, dst: path.join(tmp, 'destination.png')});
    assert.equal(root.after.length, 0, 'Failed cp was reported as a save');
    assert.deepEqual(root.finishes.pop(), ['Save failed', image, true, image]);
    assert.ok(fs.existsSync(image), 'Failed save lost the original capture');

    assert.equal(shell(upload(), {CURL_FAIL: '1'}), 0);
    assert.ok(fs.existsSync(image), 'Failed upload deleted the capture');
    assert.match(fs.readFileSync(notification, 'utf8'), /Upload failed.*Capture kept at/);
    assert.equal(shell(upload(), {WL_COPY_FAIL: '1'}), 0);
    assert.ok(fs.existsSync(image), 'Failed link copy deleted the capture');
    assert.match(fs.readFileSync(notification, 'utf8'), /Link copy failed.*capture kept at/i);
    assert.equal(shell(upload(), {CURL_REPLY: 'unexpected response'}), 0);
    assert.ok(fs.existsSync(image), 'Invalid upload response deleted the capture');
    assert.equal(shell(upload()), 0);
    assert.ok(!fs.existsSync(image), 'Successful upload did not clean up its capture');
    assert.match(fs.readFileSync(notification, 'utf8'), /Link copied/);

    console.log('Rishot failure checks passed');
} finally {
    fs.rmSync(tmp, {recursive: true, force: true});
}
