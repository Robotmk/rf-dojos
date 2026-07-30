# Viewer Light/Dark-Theme-Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 🌙/☀️ toggle button to the viewer header that switches the entire viewer UI (not just the Monaco editor) between a light and a dark theme, with the choice persisted in `localStorage`.

**Architecture:** Task 1 introduces the CSS-variable-based light/dark theming (extending the existing `:root` variable pattern), the header toggle button, and the toggle/persistence JS — the whole page (except the Monaco editor's internal theme) switches correctly and is independently testable. Task 2 adds a second Monaco theme (`rf-dark`) and wires the toggle to also call `monaco.editor.setTheme(...)`, so the editor switches in sync with the rest of the page.

**Tech Stack:** Vanilla HTML/CSS/JS (existing pattern), `localStorage` (existing pattern, see `TOKEN_KEY`), Monaco Editor's `defineTheme`/`setTheme` API (already in use for `rf-light`).

## Global Constraints

- No build pipeline, no npm — `viewer/index.html`/`viewer/robotframework-language.js` stay plain files with `<script>`/inline JS, consistent with the rest of this project.
- Default theme (no stored preference yet) is always light — no `prefers-color-scheme` auto-detection (explicitly out of scope per the design).
- The theme choice persists across reloads via `localStorage`, analogous to the existing `TOKEN_KEY` pattern (`viewer/index.html`).
- The WHOLE viewer UI switches themes (header, rounds nav, participant tabs, explorer, tab bar, token dialog, error banner) — not only the Monaco editor pane.
- No automated test framework; verification is `node --check` for syntax and manual browser verification, consistent with the rest of this viewer's codebase.

Reference spec: `docs/superpowers/specs/2026-07-30-viewer-light-dark-toggle-design.md`

---

### Task 1: CSS theming, toggle button, and page-wide theme switching

**Files:**
- Modify: `viewer/index.html` (CSS: extend `:root`, add `[data-theme="dark"]` block, convert a few hardcoded colors to variables; HTML: add the anti-flash inline script and the toggle button; JS: add theme get/set/toggle logic)

**Interfaces:**
- Consumes: existing CSS variables `--border`/`--bg-nav`/`--accent` (unchanged in the light block), the existing `monacoEditor` top-level variable (referenced but not yet used by this task).
- Produces: `getTheme()` (returns `'light'` or `'dark'`), `setTheme(theme)` (applies + persists + updates button icon), `toggleTheme()`. Task 2 modifies `setTheme(theme)` to add a Monaco call.

- [ ] **Step 1: Extend the CSS variables with a dark theme, and convert hardcoded colors to variables**

Replace the current:

```css
  :root { --border: #d0d7de; --bg-nav: #f6f8fa; --accent: #0969da; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, Segoe UI, sans-serif; color: #1f2328; }
```

with:

```css
  :root {
    --border: #d0d7de; --bg-nav: #f6f8fa; --accent: #0969da;
    --bg-page: #ffffff; --text: #1f2328; --search-hit-bg: #fff8c5;
    --error-bg: #ffebe9; --error-text: #82071e; --error-border: #ffc1c1;
  }
  :root[data-theme="dark"] {
    --border: #30363d; --bg-nav: #161b22; --accent: #58a6ff;
    --bg-page: #0d1117; --text: #c9d1d9; --search-hit-bg: #4d3800;
    --error-bg: #3d1a1a; --error-text: #ffb3ab; --error-border: #6e2c2c;
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, Segoe UI, sans-serif; background: var(--bg-page); color: var(--text); }
```

Then update these existing rules to use the new variables instead of hardcoded colors:

```css
  #participant-tabs button { border: 1px solid var(--border); background: var(--bg-page); border-radius: 6px; padding: 0.35rem 0.75rem; cursor: pointer; color: var(--text); }
```

(was `background: white;`, no `color` before — add `color: var(--text);` too, since a hardcoded-white button would otherwise stay unreadable-light in dark mode)

```css
  #tab-bar .tab { display: flex; align-items: center; gap: 0.35rem; border: 1px solid var(--border); border-radius: 6px; padding: 0.2rem 0.5rem; background: var(--bg-page); cursor: pointer; font-size: 0.85rem; color: var(--text); }
```

(same change: was `background: white;`, add `color: var(--text);`)

```css
  .search-hit { background: var(--search-hit-bg); }
```

(was `background: #fff8c5;`)

```css
  dialog#token-dialog { border: 1px solid var(--border); border-radius: 8px; padding: 1.5rem; background: var(--bg-page); color: var(--text); }
```

(was missing `background`/`color` entirely — relied on the browser default, which is always light)

Add a new rule for the error banner (its colors currently live as an inline `style` attribute on the element — remove them from there in Step 2 and let this rule take over):

```css
  #error-banner { background: var(--error-bg); color: var(--error-text); padding: 0.5rem 1rem; border-bottom: 1px solid var(--error-border); }
```

Add this rule anywhere in the `<style>` block (e.g. right after the `dialog#token-dialog input` rule).

- [ ] **Step 2: Simplify the error banner's inline style to just `display:none`**

Replace:

```html
<div id="error-banner" style="display:none; background:#ffebe9; color:#82071e; padding:0.5rem 1rem; border-bottom:1px solid #ffc1c1;"></div>
```

with:

```html
<div id="error-banner" style="display:none;"></div>
```

(The colors/padding/border now come from the `#error-banner` CSS rule added in Step 1; the JS `showError`/`clearError` functions already only ever touch `banner.style.display`, so no JS change is needed here.)

- [ ] **Step 3: Add the anti-flash inline script**

Add this `<script>` block immediately after the closing `</style>` tag (still inside `<head>`, before `</head>`):

```html
<script>
  document.documentElement.dataset.theme = localStorage.getItem('rf_dojos_theme') || 'light';
</script>
```

This must run before `<body>` is parsed, so the correct theme's CSS variables are already active at first paint — without it, a stored dark preference would flash light for a moment on every reload.

- [ ] **Step 4: Add the toggle button to the header**

Replace:

```html
  <select id="dojo-select">
    <option value="">Dojo wählen…</option>
  </select>
  <a href="../">Zur Startseite</a>
```

with:

```html
  <select id="dojo-select">
    <option value="">Dojo wählen…</option>
  </select>
  <button id="theme-toggle-btn" type="button" title="Theme wechseln">🌙</button>
  <a href="../">Zur Startseite</a>
```

- [ ] **Step 5: Add the theme get/set/toggle JS and wire up the button**

Add this near the top of the main `<script>` block, right after the existing `setToken(value)` function definition (both are small `localStorage`-backed helpers, a natural place to group them):

```javascript
const THEME_KEY = 'rf_dojos_theme';

function getTheme() {
  return localStorage.getItem(THEME_KEY) || 'light';
}

function setTheme(theme) {
  localStorage.setItem(THEME_KEY, theme);
  document.documentElement.dataset.theme = theme;
  document.getElementById('theme-toggle-btn').textContent = theme === 'dark' ? '☀️' : '🌙';
}

function toggleTheme() {
  setTheme(getTheme() === 'dark' ? 'light' : 'dark');
}
```

Then, near the bottom of the script (alongside the existing `document.getElementById('change-token-btn').addEventListener('click', changeToken);` line), add:

```javascript
document.getElementById('theme-toggle-btn').addEventListener('click', toggleTheme);
setTheme(getTheme());
```

The `setTheme(getTheme())` call syncs the button's icon with whatever theme the Step 3 anti-flash script already applied to `<html>` before the button existed (that script can't set the button's icon, since the button isn't in the DOM yet when it runs).

- [ ] **Step 6: Verify syntax**

There are now two `<script>...</script>` blocks in `viewer/index.html`: the small anti-flash one added in Step 3 (inside `<head>`, encountered first in the file) and the existing large main one (before `</body>`, encountered second). Extract each by its position among script blocks — bounded to the content strictly between a `<script>` line and its matching `</script>` line, robust regardless of exact line numbers, since both tags sit alone on their own line throughout this file (verified against the current file before writing this step):

```bash
awk '/<script>/{c++; if(c==1) f=1; next} /<\/script>/{f=0; next} f' viewer/index.html > /tmp/viewer-antiflash.js
awk '/<script>/{c++; if(c==2) f=1; next} /<\/script>/{f=0; next} f' viewer/index.html > /tmp/viewer-inline.js
node --check /tmp/viewer-antiflash.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-antiflash.js /tmp/viewer-inline.js
```

Expected: no output from either `node --check` call.

- [ ] **Step 7: Manual browser verification**

Serve `viewer/` locally (e.g. `python3 -m http.server` from the `viewer/` directory) and open it with a real `?dojo=...&owner=...`. Confirm:

- The 🌙 button appears in the header, between the dojo dropdown and "Zur Startseite".
- Clicking it switches the ENTIRE page to a dark background/text (header, rounds nav, participant tabs, explorer, tab bar, token dialog if you trigger it, error banner if you trigger an error) — the icon changes to ☀️.
- Clicking again switches back to light, icon back to 🌙.
- Reload the page after switching to dark — it should load already dark, with no visible flash of the light theme first.
- The Monaco editor's own content pane is NOT expected to change theme yet at this point (that's Task 2) — it's fine/expected that it stays in its light `rf-light` colors while the rest of the page goes dark.

- [ ] **Step 8: Commit**

```bash
git add viewer/index.html
git commit -m "Add page-wide light/dark theme toggle to the viewer"
```

---

### Task 2: Dark Monaco theme, synced with the page toggle

**Files:**
- Modify: `viewer/robotframework-language.js` (add the `rf-dark` theme definition)
- Modify: `viewer/index.html` (`ensureEditorInstance()`: pick the theme dynamically instead of hardcoding `'rf-light'`; `setTheme(theme)`: also call `monaco.editor.setTheme(...)` when the editor exists)

**Interfaces:**
- Consumes: `setTheme(theme)`/`getTheme()` (Task 1), `monacoEditor` (existing top-level variable), `ensureEditorInstance()` (existing function).
- Produces: nothing new for later tasks — this is the last task of this plan.

- [ ] **Step 1: Add the `rf-dark` Monaco theme**

In `viewer/robotframework-language.js`, add this right after the existing `monaco.editor.defineTheme('rf-light', {...});` call (still inside `registerRobotFrameworkLanguage`, before the closing `}`):

```javascript
  monaco.editor.defineTheme('rf-dark', {
    base: 'vs-dark',
    inherit: true,
    rules: [
      { token: 'keyword.section', foreground: '58a6ff', fontStyle: 'bold' },
      { token: 'keyword.setting', foreground: 'd2a8ff' },
      { token: 'variable', foreground: '7ee787' },
      { token: 'comment', foreground: '8b949e', fontStyle: 'italic' },
      { token: 'entity.name.testcase', foreground: 'ffa657', fontStyle: 'bold' },
    ],
    colors: {},
  });
```

- [ ] **Step 2: Make `ensureEditorInstance()` pick the theme dynamically**

Replace the current:

```javascript
function ensureEditorInstance() {
  if (monacoEditor) return monacoEditor;
  monacoEditor = monaco.editor.create(document.getElementById('editor-pane'), {
    readOnly: true,
    theme: 'rf-light',
    automaticLayout: true,
    minimap: { enabled: false },
  });
```

with:

```javascript
function ensureEditorInstance() {
  if (monacoEditor) return monacoEditor;
  monacoEditor = monaco.editor.create(document.getElementById('editor-pane'), {
    readOnly: true,
    theme: getTheme() === 'dark' ? 'rf-dark' : 'rf-light',
    automaticLayout: true,
    minimap: { enabled: false },
  });
```

(Everything after this line in `ensureEditorInstance` — the `addCommand` calls, the `return monacoEditor;` — stays exactly as-is; only the `theme:` value changes.)

- [ ] **Step 3: Make `setTheme(theme)` also switch the Monaco editor's theme**

Replace the Task 1 version:

```javascript
function setTheme(theme) {
  localStorage.setItem(THEME_KEY, theme);
  document.documentElement.dataset.theme = theme;
  document.getElementById('theme-toggle-btn').textContent = theme === 'dark' ? '☀️' : '🌙';
}
```

with:

```javascript
function setTheme(theme) {
  localStorage.setItem(THEME_KEY, theme);
  document.documentElement.dataset.theme = theme;
  document.getElementById('theme-toggle-btn').textContent = theme === 'dark' ? '☀️' : '🌙';
  if (typeof monaco !== 'undefined' && monacoEditor) {
    monaco.editor.setTheme(theme === 'dark' ? 'rf-dark' : 'rf-light');
  }
}
```

The `typeof monaco !== 'undefined' && monacoEditor` guard covers two cases where the editor isn't ready yet: the very first `setTheme(getTheme())` call at page load runs before Monaco's AMD bootstrap has finished (`monaco` global doesn't exist yet), and even after Monaco has loaded, `monacoEditor` stays `null` until a `show: file` round is actually opened (`ensureEditorInstance()` is lazy). In both cases, skipping the `monaco.editor.setTheme(...)` call is correct — Step 2's dynamic `theme:` pick in `ensureEditorInstance()` already makes sure the editor is created with the right theme once it does get created for the first time.

- [ ] **Step 4: Verify syntax**

```bash
node --check viewer/robotframework-language.js
awk '/<script>/{c++; if(c==2) f=1; next} /<\/script>/{f=0; next} f' viewer/index.html > /tmp/viewer-inline.js
node --check /tmp/viewer-inline.js
rm /tmp/viewer-inline.js
```

(This extracts the main script block — the second `<script>...</script>` pair in the file, after the Task 1 anti-flash block — the same extraction approach used in Task 1, Step 6.)

Expected: no output from either check.

- [ ] **Step 5: Manual browser verification**

Serve `viewer/` locally, open a `show: file` round so the Monaco editor is created, then:

- Click the theme toggle — confirm the Monaco editor's background/text colors switch to the dark palette IN SYNC with the rest of the page (same click, same moment), not just the surrounding UI.
- Confirm RF syntax highlighting is still legible in dark mode: section headers, settings keywords, variables, comments, and test-case/keyword names should all have visibly distinct, readable colors against the dark background (not all washed out to one color).
- Switch back to light — confirm the editor returns to the original `rf-light` colors.
- Reload the page while dark is active, WITHOUT having opened a file yet this time, then open a `show: file` round for the first time this session — confirm the editor is created already in dark mode (exercises Step 2's dynamic pick at creation time, not just Step 3's live-switch path).

- [ ] **Step 6: Commit**

```bash
git add viewer/index.html viewer/robotframework-language.js
git commit -m "Add dark Monaco theme, synced with the page-wide toggle"
```
