# Viewer: Monaco-Editor mit RF-Highlighting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current `<pre>`-based file display in `viewer/index.html` (driven by a rigid `filename_pattern` glob) with a read-only Monaco editor (RF syntax highlighting, light theme) fed by an always-full file explorer that is only filtered by explicit blacklist/whitelist config, plus a cross-file `search` that badges files containing a match — so divergent participant solutions (e.g. locators loaded from a `.yaml` instead of a `.robot`) stay visible instead of silently disappearing.

**Architecture:** Monaco is vendored as static AMD-loader assets under `viewer/vendor/monaco/` (no CDN dependency at event time, no build step). A new file `viewer/robotframework-language.js` defines a Monarch tokenizer + light theme for Robot Framework syntax (purely lexical — no library/keyword resolution, no language server). `viewer/index.html` gains: a two-pane file view (explorer tree + tab bar + single reused Monaco editor instance) that replaces the old single `<pre>` block for `show: file` rounds; pure filtering/matching functions for the new `explorer`/`default_open`/`search` config fields; and a small in-memory cache for fetched file content (used both for opened tabs and for cross-file search-badge computation). The existing `show: tree` round mode, GitHub API layer, token handling, and keyboard navigation are untouched.

**Tech Stack:** Vanilla HTML/CSS/JS (existing pattern), `js-yaml` (existing, CDN), Monaco Editor (vendored, AMD loader — `viewer/vendor/monaco/min/vs/loader.js`), GitHub Contents/Trees API (existing, via `githubFetch`).

## Global Constraints

- `viewer/index.html` gets no build pipeline, no npm, no bundler. Monaco is vendored as static files and loaded via the classic AMD `require`/`loader.js` pattern (Monaco's own documented standalone-usage approach), exactly like `js-yaml` today is loaded via a plain `<script>` tag.
- All dynamic/repo-derived strings continue to go through `textContent` (never `innerHTML` string interpolation) — this repo has fixed HTML-injection-via-`innerHTML` bugs multiple times already. Monaco itself renders file content safely inside its own canvas/DOM (not via `innerHTML`), so this constraint is automatically satisfied for file content; it still applies to any label/path text we render ourselves (explorer tree labels, tab labels).
- No new GitHub API call *types* beyond the Contents API (`/repos/.../contents/...`) and Git Trees API (`/repos/.../git/trees/...`) already used elsewhere in this file via the existing `githubFetch`/`loadFileContent`/`loadFileTree` functions.
- No language server, no semantic keyword/library resolution (RobotCode/robotframework-lsp are out of scope — see spec). Only lexical Monarch tokenization.
- No automated test framework. Verification is: `node --check` for syntax, isolated `node -e` scripts for pure logic functions (matching/filtering — these have no DOM/Monaco dependency and are fully testable this way), and documented manual browser verification for anything that needs a live DOM/Monaco/GitHub session (consistent with how this repo's prior viewer plans verified UI behavior).
- Old config fields `filename_pattern` and `highlight` are removed entirely (not kept for backward compatibility) and replaced by `explorer` (`blacklist`/`whitelist`), `default_open`, and `search`, per the approved spec.
- The `show: tree` round mode (ASCII directory tree) is unchanged by this plan — only `show: file` rounds are affected.
- Effective blacklist for a round = `dojo.explorer_blacklist` ∪ `round.explorer.blacklist` (union, never override). `round.explorer.whitelist`, when non-empty, is applied on top (intersect), then blacklist removes from what remains.
- `default_open` and cross-file `search` are matched against **all** files of the submission (not the blacklist/whitelist-filtered subset) for `default_open`, and against the blacklist/whitelist-filtered subset for `search` badges (badges only make sense on files that are actually visible in the explorer).
- Glob patterns (`explorer.blacklist`, `explorer.whitelist`, `default_open`) are matched against the file path **relative to the submission root** (e.g. `tests/login.robot`, not the full GitHub path `dojos/dojo-01-web-testing/submissions/alice/tests/login.robot`), so that both bare patterns (`*.robot`) and directory-qualified patterns (`tests/*.robot`) work as expected.

Reference spec: `docs/superpowers/specs/2026-07-29-viewer-monaco-editor-design.md`

---

### Task 1: Vendor Monaco Editor assets

**Files:**
- Create: `viewer/vendor/monaco/min/vs/**` (vendored, not hand-written)

**Interfaces:**
- Consumes: nothing (no code dependency on other tasks).
- Produces: `viewer/vendor/monaco/min/vs/loader.js` — the AMD loader entry point that Task 2 will `<script src>` and `require(['vs/editor/editor.main'], ...)` from.

- [ ] **Step 1: Download and extract the monaco-editor npm package's standalone AMD build**

Run (from repo root, using a scratch directory so no `node_modules`/tarball ever lands in the repo):

```bash
mkdir -p /tmp/monaco-vendor && cd /tmp/monaco-vendor
VERSION=$(npm view monaco-editor version)
echo "Vendoring monaco-editor@$VERSION"
npm pack "monaco-editor@$VERSION" --silent
tar -xzf monaco-editor-*.tgz
```

- [ ] **Step 2: Copy only the AMD `min/vs` build into the repo**

```bash
mkdir -p viewer/vendor/monaco
cp -r /tmp/monaco-vendor/package/min viewer/vendor/monaco/
rm -rf /tmp/monaco-vendor
```

Do **not** copy `min-maps` or `package/esm`/`package/dev` — only `min/vs` is needed for the AMD loader pattern used in Task 2, keeping the vendored footprint small.

- [ ] **Step 3: Verify the vendored files are intact**

```bash
ls viewer/vendor/monaco/min/vs/loader.js
node --check viewer/vendor/monaco/min/vs/loader.js
du -sh viewer/vendor/monaco
```

Expected: `loader.js` exists, `node --check` produces no output (valid JS — this also catches a corrupted/truncated download or an HTML error page saved instead of the tarball), and the total size is on the order of a few MB (sanity check against a botched partial download).

- [ ] **Step 4: Commit**

```bash
git add viewer/vendor/monaco
git commit -m "Vendor Monaco editor (AMD standalone build) for the viewer"
```

---

### Task 2: RobotFramework Monarch tokenizer, light theme, and Monaco bootstrap

**Files:**
- Create: `viewer/robotframework-language.js`
- Modify: `viewer/index.html` (add `<script>` includes and the `require`-based bootstrap, right before the existing `<script>` block that currently starts with `const TOKEN_KEY = ...`)

**Interfaces:**
- Consumes: `viewer/vendor/monaco/min/vs/loader.js` (Task 1).
- Produces: `window.registerRobotFrameworkLanguage(monaco)` — called once Monaco has finished loading; registers the `'robotframework'` language id and the `'rf-light'` theme. Later tasks reference the language id `'robotframework'` and theme id `'rf-light'` when creating models/editors.

- [ ] **Step 1: Write the Monarch tokenizer + theme**

Create `viewer/robotframework-language.js`:

```javascript
function registerRobotFrameworkLanguage(monaco) {
  monaco.languages.register({ id: 'robotframework' });

  monaco.languages.setMonarchTokensProvider('robotframework', {
    tokenizer: {
      root: [
        // *** Settings ***, *** Test Cases ***, *** Keywords ***, *** Variables ***, *** Tasks ***, *** Comments ***
        [/^\*{3}\s*(Settings|Variables|Test Cases|Tasks|Keywords|Comments)\s*\*{3}.*$/, 'keyword.section'],
        // Full-line comments
        [/^#.*$/, 'comment'],
        // Variable syntax: ${scalar}, @{list}, &{dict}
        [/[$@&]\{[^}]*\}/, 'variable'],
        // Settings-section keywords (Library, Resource, Suite Setup, ...)
        [/^(Library|Resource|Variables|Documentation|Metadata|Suite Setup|Suite Teardown|Test Setup|Test Teardown|Test Template|Test Timeout|Force Tags|Default Tags|Test Tags)(?=\s|$)/, 'keyword.setting'],
        // A name starting at column 0 (test case / keyword definition header)
        [/^\S.*?(?=(\s{2,}|\t|$))/, 'entity.name.testcase'],
        // Column separators (2+ spaces or a tab, Robot Framework's plain-text format)
        [/\s{2,}|\t/, 'white'],
        [/.*$/, 'text'],
      ],
    },
  });

  monaco.editor.defineTheme('rf-light', {
    base: 'vs',
    inherit: true,
    rules: [
      { token: 'keyword.section', foreground: '0969da', fontStyle: 'bold' },
      { token: 'keyword.setting', foreground: '8250df' },
      { token: 'variable', foreground: '116329' },
      { token: 'comment', foreground: '6e7781', fontStyle: 'italic' },
      { token: 'entity.name.testcase', foreground: '953800', fontStyle: 'bold' },
    ],
    colors: {},
  });
}
```

Note: this tokenizer is intentionally simple and purely lexical (no library/keyword resolution — see Global Constraints). Fine-tuning the exact token boundaries against real submission files happens in the manual verification step below and can be refined later without touching any other task.

- [ ] **Step 2: Wire the `<script>` includes and Monaco bootstrap into `viewer/index.html`**

In `viewer/index.html`, immediately after the existing line:

```html
<script src="https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js"></script>
```

add:

```html
<script src="vendor/monaco/min/vs/loader.js"></script>
<script src="robotframework-language.js"></script>
```

Then, at the very end of the existing `<script>` block (after the line `init();`, i.e. after the current last line of script content), add the Monaco bootstrap. Since `init()` currently runs immediately and unconditionally, wrap the existing `init();` call so it only runs once Monaco (and our language) is ready:

Replace the last line of the script block:

```javascript
init();
```

with:

```javascript
require.config({ paths: { vs: 'vendor/monaco/min/vs' } });
require(['vs/editor/editor.main'], function () {
  registerRobotFrameworkLanguage(monaco);
  init();
});
```

- [ ] **Step 3: Verify the script syntax**

Extract the inline `<script>` content (the second one, containing `TOKEN_KEY`) and check it:

```bash
node --check viewer/robotframework-language.js
```

Expected: no output (valid JS).

For `viewer/index.html`'s inline script, extract it to a temp file first (its content now references the global `require`/`monaco`, which don't exist in Node — `node --check` only validates syntax, it does not execute, so this is safe and expected to pass):

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

Expected: no output.

- [ ] **Step 4: Manual browser verification**

Serve `viewer/` locally (e.g. `python3 -m http.server` from the `viewer/` directory) and open it with `?dojo=dojo-01-web-testing&owner=<your-github-username>` in a browser. Confirm via the browser console:

- No 404s for `vendor/monaco/min/vs/loader.js` or `robotframework-language.js`.
- `typeof monaco !== 'undefined'` evaluates to `true` in the console once the page has loaded.
- The existing viewer UI (rounds nav, participant tabs, token dialog) still works exactly as before — this task only adds a loading chain, no visible behavior changes yet since nothing calls `registerRobotFrameworkLanguage`'s registered language/theme in the UI yet (that starts in Task 3).
- If the console shows a warning like "Could not create web worker(s), falling back...": this is expected and harmless for our use case — we only use Monarch tokenization (main-thread), no language feature (autocomplete/diagnostics) that requires a worker.

- [ ] **Step 5: Commit**

```bash
git add viewer/robotframework-language.js viewer/index.html
git commit -m "Add Robot Framework Monarch tokenizer, light theme, and Monaco bootstrap"
```

---

### Task 3: Single reused Monaco editor instance, opening one file read-only

**Files:**
- Modify: `viewer/index.html` (CSS: add `#file-view`/`#explorer`/`#editor-pane` rules; HTML: restructure `#content`; JS: replace `renderFileView` usage with a new editor-pane mechanism)

**Interfaces:**
- Consumes: `'robotframework'` language id and `'rf-light'` theme id (Task 2), existing `loadFileContent(path, branch)` (unchanged).
- Produces: `ensureEditorInstance()` (returns the single reused `monaco.editor.IStandaloneCodeEditor`, creating it on first call), `openFileInEditor(relPath, absolutePath, branch)` (async — fetches content, creates/reuses a model, calls `setModel`). Later tasks (5, 6, 7) call `openFileInEditor` and build on top of `ensureEditorInstance()`.

- [ ] **Step 1: Restructure the `#content` container to hold both view modes**

Replace the current:

```html
<div id="content"></div>
```

with:

```html
<div id="content">
  <p id="content-message" style="display:none;"></p>
  <div id="tree-view"></div>
  <div id="file-view" style="display:none;">
    <div id="explorer"></div>
    <div id="editor-pane"></div>
  </div>
</div>
```

(`#explorer` stays empty until Task 5; `#editor-pane` is the persistent host element Monaco attaches to — it must never be recreated or have its `innerHTML` cleared, otherwise the editor instance would need to be destroyed and recreated on every render. `#content-message` is a dedicated slot for the guard-clause messages that `renderContent()` currently renders via `content.innerHTML = '<p>...</p>'` — those calls must stop targeting `#content` directly from Step 4 onward, precisely because that would wipe out `#file-view`/`#editor-pane` along with it.)

- [ ] **Step 2: Add CSS for the two-pane file view**

In the existing `<style>` block, add:

```css
#file-view { display: flex; height: 100%; }
#explorer { width: 220px; border-right: 1px solid var(--border); overflow-y: auto; padding: 0.5rem; flex-shrink: 0; }
#editor-pane { flex: 1; min-width: 0; }
```

- [ ] **Step 3: Add the single-editor-instance and file-opening mechanism**

Add this near the top of the script, after the `decodeBase64Utf8` function definition:

```javascript
let monacoEditor = null;
const modelCache = new Map(); // key: `${branch}::${relPath}` -> monaco.editor.ITextModel

function ensureEditorInstance() {
  if (monacoEditor) return monacoEditor;
  monacoEditor = monaco.editor.create(document.getElementById('editor-pane'), {
    readOnly: true,
    theme: 'rf-light',
    automaticLayout: true,
    minimap: { enabled: false },
  });
  return monacoEditor;
}

async function openFileInEditor(relPath, absolutePath, branch) {
  const key = `${branch}::${relPath}`;
  let model = modelCache.get(key);
  if (!model) {
    const content = await loadFileContent(absolutePath, branch);
    model = monaco.editor.createModel(content, 'robotframework');
    modelCache.set(key, model);
  }
  ensureEditorInstance().setModel(model);
}

function showContentMessage(text) {
  const messageEl = document.getElementById('content-message');
  messageEl.textContent = text;
  messageEl.style.display = text ? '' : 'none';
  document.getElementById('tree-view').style.display = 'none';
  document.getElementById('file-view').style.display = 'none';
}
```

- [ ] **Step 4: Wire `renderContent()` to use the new file view for `show: file` rounds, without clobbering the persistent editor DOM**

Replace the entire `renderContent()` function:

```javascript
async function renderContent() {
  const seq = ++renderSeq;
  const round = (state.config?.rounds || [])[state.currentRoundIndex];
  const pr = state.prs[state.currentParticipantIndex];
  if (!state.prs.length) {
    showContentMessage('Noch keine offenen PRs für dieses Dojo gefunden.');
    return;
  }
  if (!round || !pr) { showContentMessage(''); return; }
  try {
    const prefix = `dojos/${state.dojoId}/submissions/${pr.username}/`;
    const paths = (await loadFileTree(pr.branch)).filter((p) => p.startsWith(prefix));
    if (seq !== renderSeq) return; // a newer render superseded this one; abandon silently
    if (!paths.length) {
      showContentMessage(`Keine Dateien unter ${prefix} gefunden.`);
      clearError();
      return;
    }
    showContentMessage('');
    document.getElementById('tree-view').style.display = round.show === 'tree' ? '' : 'none';
    document.getElementById('file-view').style.display = round.show === 'file' ? 'flex' : 'none';
    if (round.show === 'tree') {
      renderTreeView(document.getElementById('tree-view'), paths);
    } else if (round.show === 'file') {
      const prefixLen = prefix.length;
      const relPaths = paths.map((p) => p.slice(prefixLen));
      if (relPaths.length) {
        await openFileInEditor(relPaths[0], paths[0], pr.branch);
      }
    }
    if (seq !== renderSeq) return;
    clearError();
  } catch (err) {
    if (seq !== renderSeq) return; // a newer render already superseded this one
    showError(`Fehler beim Laden der Dateien für ${pr.username}: ${err.message}`);
  }
}
```

Note what changed relative to the current version: the guard-clause messages ("keine PRs", "kein Round/PR", "keine Dateien") now go through `showContentMessage()` (which uses `textContent` on the dedicated `#content-message` element) instead of `content.innerHTML = '<p>...</p>'` — the old version would have wiped out `#file-view`/`#editor-pane` the next time any guard clause fired after the editor already existed. This also drops the now-unnecessary `escapeHtml(prefix)` call, since `textContent` is injection-safe by construction.

(`relPaths`/full-explorer-tree rendering and multi-file/tab support land in Tasks 5–6; this step only proves the editor mechanism works end-to-end by opening the first matching file — full config-driven filtering replaces the "first file" placeholder behavior in Task 5.)

Remove the now-unused `renderFileView` and `highlightLines` functions entirely (their behavior is fully superseded).

- [ ] **Step 5: Verify syntax**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

Expected: no output.

- [ ] **Step 6: Manual browser verification**

Serve `viewer/` locally as in Task 2 and open a dojo with at least one open PR. Select a `show: file` round (e.g. "Test-Struktur"). Confirm:

- The first matching file now renders in a real Monaco editor (line numbers, RF section headers in blue/bold, variables in green, comments in italic gray) instead of a plain `<pre>` block.
- Switching between participants (arrow keys) swaps the editor content without visibly recreating the editor (no flicker/resize jump).
- The editor is read-only (typing does nothing).
- Selecting a `show: tree` round still shows the ASCII tree exactly as before.

- [ ] **Step 7: Commit**

```bash
git add viewer/index.html
git commit -m "Show file content in a read-only Monaco editor with RF highlighting"
```

---

### Task 4: Config schema migration + pure matching/filtering functions

**Files:**
- Modify: `dojos/dojo-01-web-testing/config.yaml`
- Modify: `viewer/index.html` (replace `matchFilenamePattern`; add new pure functions, placed right after the existing `globToRegex` function)

**Interfaces:**
- Consumes: `globToRegex(glob)` (existing, unchanged).
- Produces: `matchesAnyGlob(relPath, globs)`, `resolveExplorerFilter(dojoConfig, round)` (returns `{blacklist: string[], whitelist: string[]}`), `filterExplorerPaths(relPaths, filter)`, `resolveDefaultOpenPaths(relPaths, round)`, `contentMatchesSearch(content, searchPattern)`. Task 5 consumes `resolveExplorerFilter`/`filterExplorerPaths`; Task 6 consumes `resolveDefaultOpenPaths`; Task 7 consumes `contentMatchesSearch`.

- [ ] **Step 1: Migrate `dojos/dojo-01-web-testing/config.yaml` to the new schema**

Replace the file's `rounds:` section (keep the `dojo:` block as-is except for the addition of `explorer_blacklist`):

```yaml
dojo:
  id: dojo-01-web-testing
  title: "Web Testing Dojo #1"
  date: "2026-07-30"
  target_app: "https://sampleapp.tricentis.com/101/"
  explorer_blacklist: ["*_template*", "*.png", "*.pyc", "__pycache__/*"]

rounds:
  - id: structure
    title: "Verzeichnisstruktur"
    description: "Wie ist das Projekt aufgebaut?"
    show: tree

  - id: test_structure
    title: "Test-Struktur"
    description: "Aufbau der .robot-Datei: Settings, Variables, Keywords, Test Cases"
    show: file
    default_open: ["tests/*.robot"]

  - id: locators
    title: "Locator-Strategie"
    description: "Wie werden Elemente gefunden? CSS, XPath, ID, Playwright-native?"
    show: file
    default_open: ["tests/*.robot"]
    search: "locator|css|xpath|id="

  - id: wait_handling
    title: "Wait-Handling"
    description: "Wie wird auf dynamische Elemente gewartet?"
    show: file
    default_open: ["tests/*.robot"]
    search: "Wait|sleep|timeout"

  - id: keywords
    title: "Custom Keywords"
    description: "Was wurde abstrahiert – und was nicht?"
    show: file
    default_open: ["tests/*.robot", "resources/*.resource"]

  - id: teardown
    title: "Teardown & Fehlerbehandlung"
    description: "Screenshot-Strategie, Cleanup, Suite Teardown"
    show: file
    default_open: ["tests/*.robot"]
    search: "Teardown|Screenshot|Run Keyword If Test Failed"
```

- [ ] **Step 2: Replace `matchFilenamePattern` with the new pure functions**

Remove the existing function:

```javascript
function matchFilenamePattern(path, pattern) {
  const filename = path.split('/').pop();
  return pattern.split('|').some((glob) => globToRegex(glob).test(filename));
}
```

Add in its place:

```javascript
function matchesAnyGlob(relPath, globs) {
  if (!globs || !globs.length) return false;
  return globs.some((glob) => globToRegex(glob).test(relPath));
}

function resolveExplorerFilter(dojoConfig, round) {
  const blacklist = [
    ...(dojoConfig?.explorer_blacklist || []),
    ...(round.explorer?.blacklist || []),
  ];
  const whitelist = round.explorer?.whitelist || [];
  return { blacklist, whitelist };
}

function filterExplorerPaths(relPaths, filter) {
  return relPaths.filter((relPath) => {
    if (filter.whitelist.length && !matchesAnyGlob(relPath, filter.whitelist)) return false;
    if (matchesAnyGlob(relPath, filter.blacklist)) return false;
    return true;
  });
}

function resolveDefaultOpenPaths(relPaths, round) {
  return relPaths.filter((relPath) => matchesAnyGlob(relPath, round.default_open || []));
}

function contentMatchesSearch(content, searchPattern) {
  if (!searchPattern) return false;
  return new RegExp(searchPattern, 'i').test(content);
}
```

- [ ] **Step 3: Verify the pure functions in isolation with Node**

These functions have no DOM/Monaco dependency, so they can be extracted and tested directly:

```bash
sed -n '/^function globToRegex/,/^}/p; /^function matchesAnyGlob/,/^}/p; /^function resolveExplorerFilter/,/^}/p; /^function filterExplorerPaths/,/^}/p; /^function resolveDefaultOpenPaths/,/^}/p; /^function contentMatchesSearch/,/^}/p' viewer/index.html > /tmp/matching.js
cat >> /tmp/matching.js << 'EOF'

console.assert(matchesAnyGlob('tests/login.robot', ['*.robot']) === true, 'FAIL 1: bare glob should match nested file');
console.assert(matchesAnyGlob('tests/login.robot', ['tests/*.robot']) === true, 'FAIL 2: directory-qualified glob should match');
console.assert(matchesAnyGlob('resources/data.yaml', ['tests/*.robot']) === false, 'FAIL 3: non-matching path should not match');
console.assert(matchesAnyGlob('a.robot', []) === false, 'FAIL 4: empty glob list should never match');

const filter = resolveExplorerFilter(
  { explorer_blacklist: ['*_template*'] },
  { explorer: { blacklist: ['*.png'] } }
);
console.assert(JSON.stringify(filter.blacklist) === JSON.stringify(['*_template*', '*.png']), 'FAIL 5: blacklist should be dojo ∪ round union');
console.assert(filter.whitelist.length === 0, 'FAIL 6: whitelist should default to empty');

const paths = ['tests/login.robot', 'data/elements.yaml', 'logo_template.png'];
const filtered = filterExplorerPaths(paths, { blacklist: ['*_template*'], whitelist: [] });
console.assert(JSON.stringify(filtered) === JSON.stringify(['tests/login.robot', 'data/elements.yaml']), 'FAIL 7: blacklist should remove matching files, keep the rest incl. the yaml');

const whitelisted = filterExplorerPaths(paths, { blacklist: [], whitelist: ['*.robot'] });
console.assert(JSON.stringify(whitelisted) === JSON.stringify(['tests/login.robot']), 'FAIL 8: whitelist should keep only matches');

const opens = resolveDefaultOpenPaths(paths, { default_open: ['tests/*.robot'] });
console.assert(JSON.stringify(opens) === JSON.stringify(['tests/login.robot']), 'FAIL 9: default_open should resolve against all paths');

console.assert(contentMatchesSearch('Click   id=submit', 'id=') === true, 'FAIL 10: search should match on content');
console.assert(contentMatchesSearch('nothing relevant here', 'id=') === false, 'FAIL 11: search should not match unrelated content');
console.assert(contentMatchesSearch('anything', '') === false, 'FAIL 12: empty search pattern should never match');

console.log('OK');
EOF
node /tmp/matching.js
rm /tmp/matching.js
```

Expected: `OK` printed with no preceding `Assertion failed` output (Node's `console.assert` prints `Assertion failed: <message>` to stderr when an assertion is false, but does not throw/stop execution — so check the full output, not just the exit code).

- [ ] **Step 4: Confirm no remaining references to the removed config fields**

```bash
grep -n "filename_pattern\|matchFilenamePattern\|round.highlight" viewer/index.html dojos/dojo-01-web-testing/config.yaml
```

Expected: no matches (empty output). If `round.highlight`/`highlightLines` still appear, they were meant to be removed in Task 3 already — double check Task 3, Step 4 was applied.

- [ ] **Step 5: Commit**

```bash
git add dojos/dojo-01-web-testing/config.yaml viewer/index.html
git commit -m "Replace filename_pattern/highlight config fields with explorer/default_open/search"
```

---

### Task 5: Explorer tree (always-full, blacklist/whitelist-filtered) wired to the editor

**Files:**
- Modify: `viewer/index.html` (CSS: explorer tree list styling; JS: new `renderExplorerTree`, wire into `renderContent()`)

**Interfaces:**
- Consumes: `filterExplorerPaths`, `resolveExplorerFilter` (Task 4), `openFileInEditor` (Task 3), existing `escapeHtml`.
- Produces: `renderExplorerTree(container, relPaths, branch, absolutePathsByRelPath, onSelect)` — later reused by Task 6 (adds badges) and Task 7 (tabs) by passing a different `onSelect` callback.

- [ ] **Step 1: Add explorer tree CSS**

```css
#explorer ul { list-style: none; margin: 0; padding-left: 1rem; }
#explorer > ul { padding-left: 0; }
#explorer li.file { cursor: pointer; padding: 0.1rem 0; }
#explorer li.file:hover { text-decoration: underline; }
#explorer li.file.active { font-weight: 600; color: var(--accent); }
```

- [ ] **Step 2: Implement `renderExplorerTree`**

Add this function right after `buildTreeFromPaths` (reusing it to build the nested structure):

```javascript
function renderExplorerNode(name, subtree, fullRelPath, activeRelPath, onSelect) {
  const escapedName = escapeHtml(name);
  if (subtree === null) {
    const li = document.createElement('li');
    li.className = 'file' + (fullRelPath === activeRelPath ? ' active' : '');
    li.textContent = name;
    li.addEventListener('click', () => onSelect(fullRelPath));
    return li;
  }
  const li = document.createElement('li');
  li.textContent = name + '/';
  const ul = document.createElement('ul');
  Object.entries(subtree).forEach(([childName, childSubtree]) => {
    const childPath = fullRelPath ? `${fullRelPath}/${childName}` : childName;
    ul.appendChild(renderExplorerNode(childName, childSubtree, childPath, activeRelPath, onSelect));
  });
  li.appendChild(ul);
  return li;
}

function renderExplorerTree(container, relPaths, activeRelPath, onSelect) {
  const tree = buildTreeFromPaths(relPaths);
  container.innerHTML = '';
  const ul = document.createElement('ul');
  Object.entries(tree).forEach(([name, subtree]) => {
    ul.appendChild(renderExplorerNode(name, subtree, name, activeRelPath, onSelect));
  });
  container.appendChild(ul);
}
```

- [ ] **Step 3: Wire the explorer into `renderContent()`**

Replace the `show === 'file'` branch from Task 3 (currently opening only the first matching file) with:

```javascript
    } else if (round.show === 'file') {
      const prefixLen = prefix.length;
      const relPaths = paths.map((p) => p.slice(prefixLen));
      const absoluteByRel = new Map(paths.map((p) => [p.slice(prefixLen), p]));
      const filter = resolveExplorerFilter(state.config.dojo, round);
      const visibleRelPaths = filterExplorerPaths(relPaths, filter);
      const activeRelPath = state.activeTabPath && visibleRelPaths.includes(state.activeTabPath)
        ? state.activeTabPath
        : visibleRelPaths[0];
      renderExplorerTree(document.getElementById('explorer'), visibleRelPaths, activeRelPath, (relPath) => {
        state.activeTabPath = relPath;
        openFileInEditor(relPath, absoluteByRel.get(relPath), pr.branch);
        renderContent();
      });
      if (activeRelPath) {
        state.activeTabPath = activeRelPath;
        await openFileInEditor(activeRelPath, absoluteByRel.get(activeRelPath), pr.branch);
      }
    }
```

Add `activeTabPath: null` to the `state` object's initial definition (alongside `currentRoundIndex`/`currentParticipantIndex`).

(This still opens only a single file — full `default_open` multi-file resolution and the tab bar UI land in Task 6. This task's deliverable is: the full, correctly-filtered file tree is visible and clicking any node opens it.)

- [ ] **Step 4: Verify syntax**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

Expected: no output.

- [ ] **Step 5: Manual browser verification**

Serve `viewer/` locally and open a `show: file` round. Confirm:

- The explorer shows the full submission file tree (not just `.robot` files) minus anything matched by `explorer_blacklist` (e.g. a `_template`-named file, if present in a submission, is hidden).
- Clicking any file in the explorer (including a non-`.robot` file, e.g. a `.yaml` if a submission has one) opens it in the Monaco editor.
- The clicked file gets the `active` highlight style in the tree.
- Switching participants re-renders the tree for the new participant's files and re-opens the first visible file.

- [ ] **Step 6: Commit**

```bash
git add viewer/index.html
git commit -m "Add always-full, blacklist/whitelist-filtered file explorer wired to the editor"
```

---

### Task 6: Tab bar with `default_open` resolution and reset-on-change behavior

**Files:**
- Modify: `viewer/index.html` (HTML: add `#tab-bar` container; CSS: tab styling; JS: tab state management)

**Interfaces:**
- Consumes: `resolveDefaultOpenPaths` (Task 4), `renderExplorerTree`/`openFileInEditor` (Tasks 3, 5).
- Produces: `state.openTabs` (array of relative paths, in order), `renderTabBar()`, `switchToTab(relPath)`, `closeTab(relPath)`. Task 7 (search badges) reads `state.openTabs`/`state.activeTabPath` to know which model to apply decorations to.

- [ ] **Step 1: Add the tab bar container**

Update the `#file-view` block from Task 3:

```html
  <div id="file-view" style="display:none;">
    <div id="explorer"></div>
    <div id="file-view-main">
      <div id="tab-bar"></div>
      <div id="editor-pane"></div>
    </div>
  </div>
```

- [ ] **Step 2: Add tab bar CSS**

```css
#file-view-main { display: flex; flex-direction: column; flex: 1; min-width: 0; }
#tab-bar { display: flex; gap: 0.25rem; padding: 0.25rem 0.5rem; border-bottom: 1px solid var(--border); overflow-x: auto; flex-shrink: 0; }
#tab-bar .tab { display: flex; align-items: center; gap: 0.35rem; border: 1px solid var(--border); border-radius: 6px; padding: 0.2rem 0.5rem; background: white; cursor: pointer; font-size: 0.85rem; }
#tab-bar .tab.active { background: var(--accent); color: white; border-color: var(--accent); }
#tab-bar .tab .close { opacity: 0.7; }
#tab-bar .tab .close:hover { opacity: 1; }
#editor-pane { flex: 1; min-width: 0; }
```

Remove the `#editor-pane { flex: 1; min-width: 0; }` rule added in Task 3 — it is superseded by the `#editor-pane { flex: 1; min-width: 0; }` rule in the block above, which now lives inside `#file-view-main` instead of directly inside `#file-view`.

- [ ] **Step 3: Implement tab state management**

Add `openTabs: []` to the `state` object's initial definition, alongside `activeTabPath`.

Add these functions after `openFileInEditor`:

```javascript
function renderTabBar() {
  const bar = document.getElementById('tab-bar');
  bar.innerHTML = '';
  state.openTabs.forEach((relPath) => {
    const tab = document.createElement('div');
    tab.className = 'tab' + (relPath === state.activeTabPath ? ' active' : '');
    const label = document.createElement('span');
    label.textContent = relPath.split('/').pop();
    label.title = relPath;
    tab.appendChild(label);
    const close = document.createElement('span');
    close.className = 'close';
    close.textContent = '✕';
    close.addEventListener('click', (event) => {
      event.stopPropagation();
      closeTab(relPath);
    });
    tab.appendChild(close);
    tab.addEventListener('click', () => switchToTab(relPath));
    bar.appendChild(tab);
  });
}

async function switchToTab(relPath) {
  state.activeTabPath = relPath;
  renderTabBar();
  renderContent();
}

function closeTab(relPath) {
  state.openTabs = state.openTabs.filter((p) => p !== relPath);
  if (state.activeTabPath === relPath) {
    state.activeTabPath = state.openTabs[state.openTabs.length - 1] || null;
  }
  renderTabBar();
  renderContent();
}

function openTab(relPath) {
  if (!state.openTabs.includes(relPath)) state.openTabs.push(relPath);
  state.activeTabPath = relPath;
}
```

- [ ] **Step 4: Reset tabs to `default_open` on round/participant change, wire explorer clicks to open tabs**

In `selectParticipant` and `selectRound` (both currently just set an index and call `render()`), reset the tab state before rendering:

```javascript
function selectParticipant(index) {
  state.currentParticipantIndex = index;
  state.openTabs = [];
  state.activeTabPath = null;
  render();
}

function selectRound(index) {
  state.currentRoundIndex = index;
  state.openTabs = [];
  state.activeTabPath = null;
  render();
}
```

Replace the `show === 'file'` branch in `renderContent()` (from Task 5) with the `default_open`-aware version:

```javascript
    } else if (round.show === 'file') {
      const prefixLen = prefix.length;
      const relPaths = paths.map((p) => p.slice(prefixLen));
      const absoluteByRel = new Map(paths.map((p) => [p.slice(prefixLen), p]));
      const filter = resolveExplorerFilter(state.config.dojo, round);
      const visibleRelPaths = filterExplorerPaths(relPaths, filter);

      if (!state.openTabs.length) {
        const defaultPaths = resolveDefaultOpenPaths(relPaths, round);
        defaultPaths.forEach((relPath) => openTab(relPath));
        if (!state.openTabs.length && visibleRelPaths.length) openTab(visibleRelPaths[0]);
      }
      renderTabBar();

      renderExplorerTree(document.getElementById('explorer'), visibleRelPaths, state.activeTabPath, (relPath) => {
        openTab(relPath);
        renderTabBar();
        renderContent();
      });

      if (state.activeTabPath) {
        await openFileInEditor(state.activeTabPath, absoluteByRel.get(state.activeTabPath), pr.branch);
      }
    }
```

- [ ] **Step 5: Verify syntax**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

Expected: no output.

- [ ] **Step 6: Manual browser verification**

Serve `viewer/` locally. Confirm:

- Entering a `show: file` round auto-opens the tab(s) matching that round's `default_open` patterns (e.g. the "Custom Keywords" round opens both a `.robot` and a `.resource` tab if the submission has matching files).
- Clicking a file in the explorer that isn't in `default_open` adds a new tab, which becomes active.
- Closing a tab via the ✕ switches the active tab to another open one (or clears the editor if none remain).
- Switching participant or round resets the tab bar to that round's `default_open` set (no tabs carried over from the previous participant/round).

- [ ] **Step 7: Commit**

```bash
git add viewer/index.html
git commit -m "Add tab bar with default_open resolution and reset-on-change behavior"
```

---

### Task 7: Cross-file search badges and in-editor highlight

**Files:**
- Modify: `viewer/index.html` (JS: content cache + badge computation; CSS: badge + in-editor highlight styling)

**Interfaces:**
- Consumes: `contentMatchesSearch` (Task 4), `loadFileContent` (existing), `renderExplorerTree` (Task 5, extended here to accept a badge set).
- Produces: `loadFileContentCached(path, branch)`, `computeSearchMatchingPaths(visibleRelPaths, absoluteByRel, branch, searchPattern)`, `applySearchDecorations(searchPattern)`.

- [ ] **Step 1: Add a content cache to avoid refetching on every round/participant flip**

Add near `modelCache` (Task 3):

```javascript
const fileContentCache = new Map(); // key: `${branch}::${path}` -> Promise<string>

function loadFileContentCached(path, branch) {
  const key = `${branch}::${path}`;
  if (!fileContentCache.has(key)) {
    fileContentCache.set(key, loadFileContent(path, branch));
  }
  return fileContentCache.get(key);
}
```

Update `openFileInEditor` (Task 3) to use the cache instead of calling `loadFileContent` directly:

```javascript
async function openFileInEditor(relPath, absolutePath, branch) {
  const key = `${branch}::${relPath}`;
  let model = modelCache.get(key);
  if (!model) {
    const content = await loadFileContentCached(absolutePath, branch);
    model = monaco.editor.createModel(content, 'robotframework');
    modelCache.set(key, model);
  }
  ensureEditorInstance().setModel(model);
}
```

- [ ] **Step 2: Compute which visible files match the round's `search` pattern**

Add after `loadFileContentCached`:

```javascript
async function computeSearchMatchingPaths(visibleRelPaths, absoluteByRel, branch, searchPattern) {
  if (!searchPattern) return new Set();
  const results = await Promise.all(visibleRelPaths.map(async (relPath) => {
    const content = await loadFileContentCached(absoluteByRel.get(relPath), branch);
    return contentMatchesSearch(content, searchPattern) ? relPath : null;
  }));
  return new Set(results.filter(Boolean));
}
```

- [ ] **Step 3: Extend `renderExplorerTree` to show a badge for matching files**

Update `renderExplorerNode`/`renderExplorerTree` (Task 5) to accept and use a `matchingRelPaths` set:

```javascript
function renderExplorerNode(name, subtree, fullRelPath, activeRelPath, matchingRelPaths, onSelect) {
  const escapedName = escapeHtml(name);
  if (subtree === null) {
    const li = document.createElement('li');
    li.className = 'file' + (fullRelPath === activeRelPath ? ' active' : '');
    li.textContent = matchingRelPaths.has(fullRelPath) ? `🔶 ${name}` : name;
    li.addEventListener('click', () => onSelect(fullRelPath));
    return li;
  }
  const li = document.createElement('li');
  li.textContent = name + '/';
  const ul = document.createElement('ul');
  Object.entries(subtree).forEach(([childName, childSubtree]) => {
    const childPath = fullRelPath ? `${fullRelPath}/${childName}` : childName;
    ul.appendChild(renderExplorerNode(childName, childSubtree, childPath, activeRelPath, matchingRelPaths, onSelect));
  });
  li.appendChild(ul);
  return li;
}

function renderExplorerTree(container, relPaths, activeRelPath, matchingRelPaths, onSelect) {
  const tree = buildTreeFromPaths(relPaths);
  container.innerHTML = '';
  const ul = document.createElement('ul');
  Object.entries(tree).forEach(([name, subtree]) => {
    ul.appendChild(renderExplorerNode(name, subtree, name, activeRelPath, matchingRelPaths, onSelect));
  });
  container.appendChild(ul);
}
```

- [ ] **Step 4: Apply in-editor decorations for the active tab's search matches**

Add after `ensureEditorInstance`:

```javascript
let searchDecorationIds = [];

function applySearchDecorations(searchPattern) {
  const editor = ensureEditorInstance();
  const model = editor.getModel();
  if (!searchPattern || !model) {
    searchDecorationIds = editor.deltaDecorations(searchDecorationIds, []);
    return;
  }
  const matches = model.findMatches(searchPattern, false, true, false, null, false);
  searchDecorationIds = editor.deltaDecorations(searchDecorationIds, matches.map((m) => ({
    range: m.range,
    options: { inlineClassName: 'search-hit' },
  })));
  if (matches.length) editor.revealRangeInCenter(matches[0].range);
}
```

Add CSS:

```css
.search-hit { background: #fff8c5; }
```

- [ ] **Step 5: Wire badge computation and decoration application into `renderContent()`**

Update the `show === 'file'` branch (from Task 6) — insert the badge computation and pass it to `renderExplorerTree`, and call `applySearchDecorations` after opening the active tab:

```javascript
    } else if (round.show === 'file') {
      const prefixLen = prefix.length;
      const relPaths = paths.map((p) => p.slice(prefixLen));
      const absoluteByRel = new Map(paths.map((p) => [p.slice(prefixLen), p]));
      const filter = resolveExplorerFilter(state.config.dojo, round);
      const visibleRelPaths = filterExplorerPaths(relPaths, filter);

      if (!state.openTabs.length) {
        const defaultPaths = resolveDefaultOpenPaths(relPaths, round);
        defaultPaths.forEach((relPath) => openTab(relPath));
        if (!state.openTabs.length && visibleRelPaths.length) openTab(visibleRelPaths[0]);
      }
      renderTabBar();

      const matchingRelPaths = await computeSearchMatchingPaths(visibleRelPaths, absoluteByRel, pr.branch, round.search);
      if (seq !== renderSeq) return;
      renderExplorerTree(document.getElementById('explorer'), visibleRelPaths, state.activeTabPath, matchingRelPaths, (relPath) => {
        openTab(relPath);
        renderTabBar();
        renderContent();
      });

      if (state.activeTabPath) {
        await openFileInEditor(state.activeTabPath, absoluteByRel.get(state.activeTabPath), pr.branch);
        applySearchDecorations(round.search);
      }
    }
```

- [ ] **Step 6: Verify syntax**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

Expected: no output.

- [ ] **Step 7: Manual browser verification**

Prepare a test submission where the relevant content is deliberately in an unexpected file (e.g. copy `dojos/dojo-01-web-testing/submissions/_template/` to a scratch participant folder, and put a line matching the "locators" round's `search` pattern — e.g. `id=submit` — into a `.yaml` file that is not part of `default_open`, then open a PR for it). Confirm:

- That `.yaml` file shows the 🔶 badge in the explorer even though it's not auto-opened.
- Opening it manually shows the matching text highlighted (yellow) in the editor, and the view scrolls to the first match.
- A round without a `search` pattern shows no badges and no decorations.
- Flipping between rounds/participants repeatedly does not cause a growing number of GitHub API requests for the same file (check the Network tab — repeated opens of the same `branch`+`path` should hit the cache, not fire a new request).

- [ ] **Step 8: Commit**

```bash
git add viewer/index.html
git commit -m "Add cross-file search badges and in-editor search highlight"
```

---

### Task 8: Cleanup, final CSS polish, and operational documentation

**Files:**
- Modify: `viewer/index.html` (remove now-fully-obsolete leftovers, final CSS pass)
- Modify: `SETUP.md` (add the Monaco warmload note)

**Interfaces:**
- Consumes: everything from Tasks 1–7.
- Produces: nothing new — this task only removes dead code and documents an operational step.

- [ ] **Step 1: Confirm no dead code remains**

```bash
grep -n "renderFileView\|highlightLines\|matchFilenamePattern" viewer/index.html
```

Expected: no matches. (These were removed incrementally in Tasks 3 and 4; this step is a final safety net in case any reference was missed.)

- [ ] **Step 2: Confirm the old single flat `.highlight-line` CSS rule is gone if unused**

```bash
grep -n "highlight-line" viewer/index.html
```

If it still appears and nothing references the class anymore (superseded by `.search-hit` from Task 7), remove the CSS rule:

```css
.highlight-line { background: #fff8c5; }
```

- [ ] **Step 3: Add the Monaco warmload operational note**

Read `SETUP.md` first to find the appropriate existing checklist section, then add a bullet point (in the section covering pre-event preparation) along these lines:

```markdown
- Viewer einmal vor dem Abend im Zielbrowser öffnen (mit echtem `?dojo=`-Parameter), damit die vendorten Monaco-Editor-Assets (~mehrere MB, `viewer/vendor/monaco/`) bereits im Browser-Cache liegen. Verhindert, dass der erste Request am Abend selbst vom Venue-WLAN abhängt.
```

- [ ] **Step 4: Full-file syntax verification**

```bash
sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d' > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
node --check viewer/robotframework-language.js
rm /tmp/viewer-inline.js
```

Expected: no output from either check.

- [ ] **Step 5: Full manual regression pass**

Serve `viewer/` locally, open a dojo with several open PRs, and walk through every round type (`tree` and `file`) for at least two different participants, using both mouse and arrow-key navigation. Confirm no console errors, no visual layout breakage (explorer/tab-bar/editor sizing), and that the token dialog / error banner / status bar (all untouched by this plan) still behave as before.

- [ ] **Step 6: Commit**

```bash
git add viewer/index.html SETUP.md
git commit -m "Clean up obsolete file-view code, document Monaco warmload step"
```
