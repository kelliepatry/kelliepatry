// Run from the repository root: node --test tests/doorbell.test.cjs
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const yaml = fs.readFileSync(path.join(__dirname, '../examples/first-staff-member/doorbell.yml'), 'utf8');
const script = yaml.split('          script: |\n')[1].split('\n').map(line => line.slice(12)).join('\n');
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
const runScript = new AsyncFunction('require', 'context', 'github', 'core', script);

function fixture(overrides = {}) {
  const packet = '# Packet\nA literal value: `$(not-a-command)`\n';
  return {packet, meta: {changed: true, run_id: '101', run_attempt: '1',
    source_commit: 'a'.repeat(40), packet_revision: 'b'.repeat(40),
    packet_sha256: crypto.createHash('sha256').update(packet).digest('hex'), ...overrides}};
}
async function ring(data, issues = [], options = {}) {
  let created = 0;
  const fakeRequire = name => name === 'node:fs' ? {
    readFileSync(file) {
      if (options.missing) throw new Error('artifact missing');
      return file.endsWith('packet.json') ? JSON.stringify(data.meta) : data.packet;
    }
  } : require(name);
  const github = {paginate: async () => issues, rest: {issues: {
    listForRepo() {},
    async create(issue) {
      created++;
      issues.push({...issue, state: 'open'});
      if (options.lostResponse) throw new Error('response lost after save');
    }
  }}};
  await runScript(fakeRequire, {
    repo: {owner: 'example', repo: 'tutorial'},
    payload: {workflow_run: {id: 101, run_attempt: 1}}
  }, github, {info() {}});
  return {created, issues};
}

test('creates one issue with the exact artifact and source run', async () => {
  const data = fixture();
  const result = await ring(data);
  assert.equal(result.created, 1);
  assert.ok(result.issues[0].body.endsWith(data.packet));
  assert.match(result.issues[0].body, /actions\/runs\/101/);
});
test('unchanged packet creates no issue', async () => {
  assert.equal((await ring(fixture({changed: false}))).created, 0);
});
test('replay finds an existing closed issue', async () => {
  const data = fixture();
  const first = await ring(data);
  first.issues[0].state = 'closed';
  assert.equal((await ring(data, first.issues)).created, 0);
});
test('lost response after creation does not create another issue on retry', async () => {
  const data = fixture(), issues = [];
  await assert.rejects(ring(data, issues, {lostResponse: true}));
  assert.equal(issues.length, 1);
  assert.equal((await ring(data, issues)).created, 0);
});
test('wrong run, attempt, hash, type and revision fail before creation', async () => {
  for (const override of [{run_id: '102'}, {run_attempt: '2'},
    {packet_sha256: 'bad'}, {changed: 'true'}, {packet_revision: 'not-a-sha'}]) {
    const issues = [];
    await assert.rejects(ring(fixture(override), issues), /Invalid or mismatched/);
    assert.equal(issues.length, 0);
  }
});
test('missing artifact fails visibly', async () => {
  await assert.rejects(ring(fixture(), [], {missing: true}), /artifact missing/);
});
test('overtaking run cannot substitute its newer packet', async () => {
  const old = fixture();
  const issues = [{body: '<!-- punch-list-revision:' + 'c'.repeat(40) + ' -->\nNewer snapshot'}];
  const result = await ring(old, issues);
  assert.equal(result.created, 1);
  assert.ok(result.issues[1].body.endsWith(old.packet));
  assert.match(result.issues[1].body, /Check for newer work before acting/);
});
test('marker embedded in another issue or a PR is not a delivery receipt', async () => {
  const marker = '<!-- punch-list-revision:' + 'b'.repeat(40) + ' -->\n';
  const issues = [{body: 'quoted ' + marker}, {body: marker, pull_request: {}}];
  assert.equal((await ring(fixture(), issues)).created, 1);
});
test('workflow restricts upstream events, reads the exact run, and serializes delivery', () => {
  for (const fragment of ["conclusion == 'success'", "head_branch == 'main'",
    "head_repository.full_name == github.repository", "workflow_run.event == 'push'",
    "workflow_run.event == 'schedule'", "workflow_run.event == 'workflow_dispatch'",
    "run-id: ${{ github.event.workflow_run.id }}", "github.event.workflow_run.run_attempt",
    "group: punch-list-doorbell", "cancel-in-progress: false", "actions: read"]) {
    assert.ok(yaml.includes(fragment), fragment);
  }
  assert.ok(!yaml.includes('actions/checkout'));
});
