const assert = require('node:assert/strict');
const { create } = require('../dotfiles/.config/quickshell/rishot/src/lib/AnnotationModel.js');

const stroke = { type: 'pen', color: '#fff', width: 4, points: [{ x: 1, y: 2 }, { x: 3, y: 4 }] };
const model = create();
assert.equal(model.undo(), false);
assert.equal(model.redo(), false);
model.add(stroke);
const original = structuredClone(model.items);
stroke.points[0].x = 999;
assert.deepEqual(model.items, original, 'Later draft changes must not change stored annotations');

// Moving must replace the annotation, keeping shared history untouched.
for (const point of model.items[0].points) Object.freeze(point);
Object.freeze(model.items[0].points);
Object.freeze(model.items[0]);
assert.equal(model.move(0, 10, -5), true);
assert.deepEqual(model.items[0].points, [{ x: 11, y: -3 }, { x: 13, y: -1 }]);
const moved = structuredClone(model.items);
assert.equal(model.undo(), true);
assert.deepEqual(model.items, original);
assert.equal(model.redo(), true);
assert.deepEqual(model.items, moved);
assert.equal(model.remove(0), true);
assert.deepEqual(model.items, []);
assert.equal(model.undo(), true);
assert.deepEqual(model.items, moved);
assert.equal(model.undo(), true);
assert.deepEqual(model.items, original);
model.add({ type: 'text', text: 'hello', size: 18, points: [{ x: 0, y: 0 }] });
assert.equal(model.canRedo(), false, 'An edit after undo discards the redo branch');
assert.equal(model.move(-1, 1, 1), false);
assert.equal(model.remove(model.items.length), false);

const history = create();
for (let i = 0; i < 105; i++) history.add(stroke);
for (let i = 0; i < 100; i++) assert.equal(history.undo(), true);
assert.equal(history.items.length, 5);
assert.equal(history.undo(), false);
for (let i = 0; i < 100; i++) assert.equal(history.redo(), true);
assert.equal(history.items.length, 105);
assert.equal(history.redo(), false);
console.log('Rishot draft isolation, move, undo/redo, removal and history limit checks passed.');
