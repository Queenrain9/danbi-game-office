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
test('available player shows controls without instructional text', () => {
  context.playtestWebExports=[entry];
  context.esc=s=>String(s??'');
  const html=context.playtestPlayerCard(row);
  assert.ok(!html.includes('playtestPlayerStatus'));
  assert.ok(!html.includes('플레이를 누르면'));
  assert.ok(html.includes('웹에서 플레이'));
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

const galleryStart = source.indexOf('function playtestGalleryRows(');
const galleryEnd = source.indexOf('function directedCard(', galleryStart);
test('gallery is compact, searchable and retains games after decisions', () => {
  assert.ok(galleryStart >= 0, 'gallery functions exist');
  const rows = Array.from({length:30}, (_,i)=>({...row, id:'showcase-'+i, build_job_id:'build-'+i, title:'Game '+i, art_options:[]}));
  const gallery = vm.createContext({
    playtestRows:()=>rows, playtestDecisionFor:id=>id==='showcase-0'?{decision:'KEEP'}:null,
    playtestGalleryFilter:'all', playtestGallerySearch:'', playtestGalleryPage:1,
    playtestOptions:()=>[], playtestArtUrl:()=>'', playtestWebUrl:()=>'',
    esc:s=>String(s??'').replaceAll('"','&quot;'), verdictLabel:s=>s,
    genericHeader:()=>'', playtestGalleryLabel:undefined,
  });
  vm.runInContext(source.slice(galleryStart,galleryEnd),gallery);
  assert.equal(gallery.playtestGalleryRows().length,30);
  const html=gallery.reviewPage();
  assert.equal((html.match(/class="pt-library-card"/g)||[]).length,24);
  assert.ok(!html.includes('<iframe'));
  assert.ok(!html.includes('Repository'));
  assert.ok(!html.includes('Visual Direction'));
  gallery.playtestGalleryFilter='pending';
  assert.equal(gallery.playtestGalleryRows().length,29);
  gallery.playtestGalleryFilter='KEEP';
  assert.equal(gallery.playtestGalleryRows().length,1);
  gallery.playtestGalleryFilter='all';
  gallery.playtestGallerySearch='game 29';
  assert.equal(gallery.playtestGalleryRows()[0].title,'Game 29');
});
