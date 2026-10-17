const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const logic = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,
    '../dotfiles/.config/quickshell/lib/workspaces.js'), 'utf8'), logic);

assert.equal(logic.workspaceIndex({ id: -1337, name: '0' }), 0);
assert.equal(logic.workspaceIndex({ id: 10, name: '10' }), 10);
assert.equal(logic.workspaceIndex({ id: 11, name: '11' }), 11);
assert.equal(logic.workspaceIndex({ id: 21, name: '21' }), 21);
assert.equal(logic.workspaceIndex({ id: -99, name: 'special:0' }), -1);
assert.equal(logic.workspaceIndex(null), -1);
const client = { mapped: true, hidden: false, workspace: { id: 2, name: '2' }, at: [5, 5], size: [600, 700] };
assert.equal(logic.containsWindow(client, 2), true);
assert.equal(logic.containsWindow(client, 1), false);
assert.equal(logic.containsWindow({ ...client, hidden: true }, 2), false);
assert.equal(logic.containsWindow({ ...client, mapped: false }, 2), false);
assert.equal(logic.containsWindow({ ...client, size: [0, 700] }, 2), false);

const occupiedClients = [1, 2, 9].map(id => ({ ...client, workspace: { id, name: String(id) } }));
const occupied = clients => Array.from(logic.occupiedWorkspaces(clients));
assert.deepEqual(occupied(occupiedClients), [1, 2, 9]);
assert.deepEqual(occupied([occupiedClients[2], client, client, occupiedClients[0]]), [1, 2, 9]);
assert.deepEqual(occupied([client]), [2]);
assert.deepEqual(occupied([]), []);
const zeroClient = { ...client, workspace: { id: -1337, name: '0' } };
assert.deepEqual(occupied([...occupiedClients, zeroClient]), [0, 1, 2, 9]);
assert.deepEqual(occupied([...occupiedClients, { ...zeroClient, hidden: true },
    { ...zeroClient, mapped: false }, { ...client, workspace: { id: 11, name: '11' } },
    { ...client, workspace: { id: -99, name: 'special:0' } }]), [1, 2, 9, 11]);
assert.deepEqual(occupied([...occupiedClients,
    { ...client, monitor: 0, workspace: { id: 11, name: '11' } },
    { ...client, monitor: 2, workspace: { id: 21, name: '21' } }]), [1, 2, 9, 11, 21]);

assert.equal(logic.move(10, 1, 4, 11), 0);
assert.equal(logic.move(0, -1, 4, 11), 10);
assert.equal(logic.move(2, 4, 4, 11), 6);
assert.equal(logic.move(10, 4, 4, 11), 2);
assert.equal(logic.move(3, -4, 4, 11), 7);
assert.equal(logic.move(7, 4, 4, 11), 3);
for (let count = 1; count <= 16; count++) {
    const columns = Math.min(4, count);
    for (let index = 0; index < count; index++) {
        for (const step of [1, -1, columns, -columns]) {
            const next = logic.move(index, step, columns, count);
            assert.ok(next >= 0 && next < count);
            assert.equal(logic.move(next, -step, columns, count), index);
        }
    }
}
const monitor = { x: 1280, y: -100, width: 1920, height: 1080, scale: 1.5 };
assert.equal(JSON.stringify(logic.monitorGeometry(monitor)),
    JSON.stringify({ x: 1280, y: -100, width: 1280, height: 720 }));
assert.equal(JSON.stringify(logic.monitorGeometry({ ...monitor, transform: 1 })),
    JSON.stringify({ x: 1280, y: -100, width: 720, height: 1280 }));
assert.equal(logic.focusRequest(0), 'hl.dsp.focus({ workspace = "name:0" })');
assert.equal(logic.focusRequest(10), 'hl.dsp.focus({ workspace = 10 })');
assert.equal(logic.focusRequest(21), 'hl.dsp.focus({ workspace = 21 })');
console.log('Workspace navigation, filtering, scaled geometry and dispatch checks passed.');
