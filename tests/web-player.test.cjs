const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('index.html', 'utf8');
const start = source.indexOf('function playtestWebEntry(');
const end = source.indexOf('function setPlaytestFocus(', start);
assert.ok(start >= 0, 'showroom Web player functions exist');
const context = vm.createContext({playtestWebExports: [], URL, document: {baseURI: 'https://queenrain9.github.io/danbi-game-office/'}});
vm.runInContext(source.slice(start, end), context);
const commit = 'a'.repeat(40);
const row = {status:'ready', project_path:'builds/clockwork-pet-dentist', final_commit:commit};
const entry = {project_path:row.project_path, source_commit:commit, status:'exported', url:`play/clockwork-pet-dentist/${commit}/index.html`};
test('maps canonical path plus exact source commit, independent of fixture slug', () => {
  context.playtestWebExports = [entry];
  assert.equal(context.playtestWebEntry({...row, slug:'clockwork-pet-dentist-showroom-test'}), entry);
  assert.equal(context.playtestWebUrl(row), 'https://queenrain9.github.io/danbi-game-office/'+entry.url);
});
test('rejects stale source, failed exports, foreign repositories and unsafe URLs', () => {
  context.playtestWebExports = [entry];
  assert.equal(context.playtestWebEntry({...row,final_commit:'b'.repeat(40)}), null);
  assert.equal(context.playtestWebEntry({...row,repo_full_name:'other/repo'}), null);
  context.playtestWebExports = [{...entry,status:'failed'}];
  assert.equal(context.playtestWebUrl(row), '');
  for (const url of ['https://other.example/game', 'javascript:alert(1)', '../index.html']) {
    context.playtestWebExports = [{...entry,url}];
    assert.equal(context.playtestWebUrl(row), '');
  }
});
