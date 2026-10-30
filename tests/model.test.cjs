const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const Model = require('../Model.js');

assert.equal(Model.fileUrl('/home/a/my #1 bg?.png'), 'file:///home/a/my%20%231%20bg%3F.png');
assert.equal(Model.fileUrl('relative.png'), '');
assert.equal(Model.fileUrl(null), '');
assert.equal(Model.displayName('fast_is-what__you'), 'fast is what you');
assert(Model.validStatus({intros: [{still: '/a.png', intro: '/intros/a.mp4'}]}));
assert(!Model.validStatus({intros: [{still: 'a.png', intro: '/intros/a.mp4'}]}));
assert(!Model.validStatus({intros: 'nope'}));
assert(!Model.validStatus(null));

// Every shared tooltip sink passes through our helper. Markup from any source
// must never reach the shell's AutoText widgets, including file names.
const attack = '<img src="https://example.invalid/tracker"> & <b>unsafe</b>';
assert(!/[<>&]/.test(Model.sharedText(attack)));
for (const filename of fs.readdirSync(path.resolve(__dirname, '..')).filter(f => f.endsWith('.qml'))) {
  const qml = fs.readFileSync(path.resolve(__dirname, '..', filename), 'utf8');
  for (const sink of qml.matchAll(/tooltipText:\s*([^\n]+)/g)) {
    assert(sink[1].startsWith('Model.sharedText('), `${filename}: unguarded shared tooltip`);
  }
  // File names are untrusted: no bare Text elements that could fall back to AutoText.
  assert(!/^\s*Text\s*\{/m.test(qml) || filename === 'PlainText.qml', `${filename}: use PlainText`);
}
const text = fs.readFileSync(path.resolve(__dirname, '../PlainText.qml'), 'utf8');
assert(text.includes('textFormat: Text.PlainText'));
console.log('Model helpers, markup handling, and shared tooltip sinks passed');
