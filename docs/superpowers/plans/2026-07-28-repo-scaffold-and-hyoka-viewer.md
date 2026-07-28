# Repo-Grundstruktur & Hyōka-Viewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the rf-dojos repo scaffold (dojo content, submission template) and the GitHub-Pages-hosted Hyōka viewer that loads open PRs and displays submissions thematically per `config.yaml` rounds.

**Architecture:** Static content-only repo (`dojos/...`) plus a single-file vanilla JS/HTML/CSS app (`viewer/index.html`) that talks directly to the GitHub REST API from the browser, using a user-supplied Personal Access Token stored in `localStorage`.

**Tech Stack:** Vanilla HTML/CSS/JS, `js-yaml` (CDN) for parsing `config.yaml`, `highlight.js` (CDN) for syntax highlighting. No npm, no bundler, no framework.

## Global Constraints

- Viewer is reines HTML/CSS/JS in einer einzigen Datei `viewer/index.html` — keine Build-Pipeline, kein npm, kein Framework.
- Externe Abhängigkeiten nur via CDN (`js-yaml`, `highlight.js`).
- Läuft auf GitHub Pages — keine eigene Server-Infrastruktur, alles client-side.
- Alle GitHub-API-Calls sind read-only und brauchen keine Org-Rechte.
- GitHub-Token wird **nicht** im Repo gespeichert — Eingabe per Textfeld beim ersten Öffnen, Ablage ausschließlich in `localStorage` des Browsers.
- PR-Titel-Konvention: `[<dojo-id>] <github-username>` (z.B. `[dojo-01-web-testing] alice`).
- Tastatursteuerung: `←`/`→` wechselt Teilnehmer, `↑`/`↓` wechselt Runden.
- Keine automatisierte Test-Suite/Build-Tooling einführen. Verifikation erfolgt manuell im Browser. Für isolierte, reine Funktionen ohne DOM/Netzwerk-Abhängigkeit (z.B. Tree-Aufbau, Glob-Matching) wird zusätzlich ein Node-Scratch-Skript zur Verifikation genutzt (nicht Teil des Shipped-Codes, nur Entwicklungs-Hilfsmittel).

---

### Task 1: Repo-Grundgerüst (README, Dojo #1 Inhalt, Submission-Template)

**Files:**
- Create: `README.md`
- Create: `dojos/dojo-01-web-testing/README.md`
- Create: `dojos/dojo-01-web-testing/config.yaml`
- Create: `dojos/dojo-01-web-testing/submissions/_template/tests/.gitkeep`
- Create: `dojos/dojo-01-web-testing/submissions/_template/resources/.gitkeep`

**Interfaces:**
- Produces: das `config.yaml`-Schema (`dojo.id`, `dojo.title`, `dojo.date`, `dojo.target_app`, `rounds[].{id,title,description,show,filename_pattern,highlight}`), das Task 5 (Runden-Navigation) und Task 7 (Datei-Anzeige) parsen.
- Produces: die PR-Titel-Konvention `[<dojo-id>] <github-username>`, die Task 4 (PR-Filterung) nutzt.

- [ ] **Step 1: `README.md` schreiben**

```markdown
# 🥋 rf-dojos – Robot Framework User Group München

Dojo-Abende der RFUGM: jeder Teilnehmer löst dieselbe Robot-Framework-Aufgabe
individuell, die Lösungen werden anschließend live thematisch verglichen.

- [`manual.md`](manual.md) – Konzept & Moderationsleitfaden
- [`dojos/`](dojos/) – Aufgaben & Teilnehmer-Submissions je Dojo-Abend
- [`viewer/`](viewer/) – Browserbasiertes Vergleichs-Tool für den Hyōka

## Mitmachen

Siehe `dojos/<dojo-id>/README.md` für die jeweilige Aufgabenstellung und
den Submission-Workflow.
```

- [ ] **Step 2: `dojos/dojo-01-web-testing/README.md` schreiben (Aufgabenstellung)**

```markdown
# Dojo #1 – Web Testing

**Ziel-Applikation:** https://www.saucedemo.com
**Datum:** 2026-07-30

## Die Aufgabe

Implementiere einen Robot-Framework-Test, der folgenden Ablauf testet:

1. Login mit gültigen Credentials
2. Einen Artikel in den Warenkorb legen
3. Checkout durchführen (Formular ausfüllen, Bestellung abschicken)
4. Verifizieren, dass die Bestätigungsseite korrekt erscheint

## Eingebaute Challenges

| Challenge | Warum spannend |
|---|---|
| Login-Daten nicht hardcoden | Zeigt Umgang mit Variables, Resource Files oder Secrets |
| Wait-Handling | Wie wartet man sauber auf dynamische Elemente? |
| Screenshot bei Fehler | Bewusster Umgang mit Teardown und Fehlerbehandlung |
| Mindestens 1 Custom Keyword | Wie strukturiert jemand seinen Code? |

## Für Fortgeschrittene (optional)

- Page Object Model umsetzen
- Resource File Struktur anlegen
- Test in mehrere Test Cases aufsplitten
- Browser Library statt SeleniumLibrary – oder beide vergleichen

## Workflow

1. Repo forken: `github.com/[owner]/rf-dojos`
2. Branch anlegen: `git checkout -b dojo-01/[github-username]`
3. Template kopieren:
   `cp -r dojos/dojo-01-web-testing/submissions/_template dojos/dojo-01-web-testing/submissions/[github-username]`
4. Test implementieren in `submissions/[github-username]/`
5. Committen, pushen, PR öffnen gegen `main` des Original-Repos
   - PR-Titel: `[dojo-01-web-testing] [github-username]`
```

- [ ] **Step 3: `dojos/dojo-01-web-testing/config.yaml` schreiben**

```yaml
dojo:
  id: dojo-01-web-testing
  title: "Web Testing Dojo #1"
  date: "2026-07-30"
  target_app: "https://www.saucedemo.com"

rounds:
  - id: structure
    title: "Verzeichnisstruktur"
    description: "Wie ist das Projekt aufgebaut?"
    show: tree

  - id: test_structure
    title: "Test-Struktur"
    description: "Aufbau der .robot-Datei: Settings, Variables, Keywords, Test Cases"
    show: file
    filename_pattern: "*.robot"

  - id: locators
    title: "Locator-Strategie"
    description: "Wie werden Elemente gefunden? CSS, XPath, ID, Playwright-native?"
    show: file
    filename_pattern: "*.robot"
    highlight: "locator|css|xpath|id="

  - id: wait_handling
    title: "Wait-Handling"
    description: "Wie wird auf dynamische Elemente gewartet?"
    show: file
    filename_pattern: "*.robot"
    highlight: "Wait|sleep|timeout"

  - id: keywords
    title: "Custom Keywords"
    description: "Was wurde abstrahiert – und was nicht?"
    show: file
    filename_pattern: "*.robot|*keywords*.robot|*resources*"

  - id: teardown
    title: "Teardown & Fehlerbehandlung"
    description: "Screenshot-Strategie, Cleanup, Suite Teardown"
    show: file
    filename_pattern: "*.robot"
    highlight: "Teardown|Screenshot|Run Keyword If Test Failed"
```

- [ ] **Step 4: Submission-Template-Verzeichnisse anlegen**

```bash
mkdir -p dojos/dojo-01-web-testing/submissions/_template/tests
mkdir -p dojos/dojo-01-web-testing/submissions/_template/resources
touch dojos/dojo-01-web-testing/submissions/_template/tests/.gitkeep
touch dojos/dojo-01-web-testing/submissions/_template/resources/.gitkeep
```

- [ ] **Step 5: YAML-Syntax verifizieren**

Run: `python3 -c "import yaml; yaml.safe_load(open('dojos/dojo-01-web-testing/config.yaml'))" && echo VALID`
Expected: `VALID` (kein Traceback)

- [ ] **Step 6: Struktur verifizieren**

Run: `find dojos -type f | sort`
Expected:
```
dojos/dojo-01-web-testing/README.md
dojos/dojo-01-web-testing/config.yaml
dojos/dojo-01-web-testing/submissions/_template/resources/.gitkeep
dojos/dojo-01-web-testing/submissions/_template/tests/.gitkeep
```

- [ ] **Step 7: Commit**

```bash
git add README.md dojos/
git commit -m "Add repo scaffold and Dojo #1 content"
```

---

### Task 2: Viewer-Shell (Layout, Token-Onboarding, URL-Parameter)

**Files:**
- Create: `viewer/index.html`

**Interfaces:**
- Produces: `getUrlParam(name)`, `getToken()`, `setToken(value)` (localStorage key `rf_dojos_github_token`), globales `state` Objekt `{dojoId, token, config, prs, currentRoundIndex, currentParticipantIndex}`, `render()` als zentrale Re-Render-Funktion.
- Consumes: nichts (erste Task des Viewers).

- [ ] **Step 1: Grundgerüst mit 3-Spalten-Layout und Token-Modal schreiben**

```html
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>🥋 RFUGM Dojo Viewer</title>
<script src="https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js"></script>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/styles/github.min.css">
<script src="https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/lib/highlight.min.js"></script>
<style>
  :root { --border: #d0d7de; --bg-nav: #f6f8fa; --accent: #0969da; }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, Segoe UI, sans-serif; color: #1f2328; }
  header { display: flex; align-items: center; gap: 1rem; padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); }
  header h1 { font-size: 1.1rem; margin: 0; }
  #layout { display: grid; grid-template-columns: 240px 1fr; height: calc(100vh - 52px); }
  #rounds-nav { border-right: 1px solid var(--border); background: var(--bg-nav); overflow-y: auto; padding: 0.5rem; }
  #rounds-nav ul { list-style: none; margin: 0; padding: 0; }
  #rounds-nav li { padding: 0.5rem 0.75rem; border-radius: 6px; cursor: pointer; }
  #rounds-nav li.active { background: var(--accent); color: white; }
  #main { display: flex; flex-direction: column; overflow: hidden; }
  #participant-tabs { display: flex; gap: 0.25rem; padding: 0.5rem 1rem; border-bottom: 1px solid var(--border); overflow-x: auto; }
  #participant-tabs button { border: 1px solid var(--border); background: white; border-radius: 6px; padding: 0.35rem 0.75rem; cursor: pointer; }
  #participant-tabs button.active { background: var(--accent); color: white; border-color: var(--accent); }
  #content { flex: 1; overflow: auto; padding: 1rem; }
  #status-bar { padding: 0.25rem 1rem; font-size: 0.85rem; color: #57606a; border-top: 1px solid var(--border); }
  dialog#token-dialog { border: 1px solid var(--border); border-radius: 8px; padding: 1.5rem; }
  dialog#token-dialog input { width: 320px; padding: 0.4rem; }
  .highlight-line { background: #fff8c5; }
</style>
</head>
<body>
<header>
  <h1>🥋 RFUGM Dojo Viewer</h1>
  <span id="dojo-title"></span>
</header>
<div id="layout">
  <nav id="rounds-nav"><ul id="rounds-list"></ul></nav>
  <div id="main">
    <div id="participant-tabs"></div>
    <div id="content"></div>
    <div id="status-bar"></div>
  </div>
</div>
<dialog id="token-dialog">
  <form method="dialog" id="token-form">
    <p>GitHub Personal Access Token eingeben (Scope <code>public_repo</code>).<br>
    Wird nur lokal in diesem Browser gespeichert, nie im Repo.</p>
    <input type="password" id="token-input" placeholder="ghp_...">
    <button type="submit">Speichern</button>
  </form>
</dialog>
<script>
const TOKEN_KEY = 'rf_dojos_github_token';

function getUrlParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

function getToken() {
  return localStorage.getItem(TOKEN_KEY) || '';
}

function setToken(value) {
  localStorage.setItem(TOKEN_KEY, value);
}

const state = {
  dojoId: getUrlParam('dojo'),
  token: getToken(),
  config: null,
  prs: [],
  currentRoundIndex: 0,
  currentParticipantIndex: 0,
};

function render() {
  document.getElementById('dojo-title').textContent = state.config ? state.config.dojo.title : '';
}

function ensureToken() {
  return new Promise((resolve) => {
    if (state.token) return resolve(state.token);
    const dialog = document.getElementById('token-dialog');
    dialog.showModal();
    document.getElementById('token-form').addEventListener('submit', () => {
      const value = document.getElementById('token-input').value.trim();
      setToken(value);
      state.token = value;
      resolve(value);
    }, { once: true });
  });
}

async function init() {
  await ensureToken();
  render();
}

init();
</script>
</body>
</html>
```

- [ ] **Step 2: Im Browser manuell verifizieren**

Run: `python3 -m http.server 8000 --directory viewer` und öffne
`http://localhost:8000/?dojo=dojo-01-web-testing`.
Expected: Token-Dialog erscheint; nach Eingabe eines beliebigen Strings
schließt sich der Dialog, Layout (Header/Nav/Tabs/Content) ist sichtbar,
kein Fehler in der Browser-Konsole.

- [ ] **Step 3: Commit**

```bash
git add viewer/index.html
git commit -m "Add viewer shell with layout and token onboarding"
```

---

### Task 3: GitHub-API-Client & config.yaml laden

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `state.token`, `state.dojoId`, `render()` aus Task 2.
- Produces: `githubFetch(path)` (async, wirft `Error` mit `.status` bei Nicht-2xx), `getRepoOwner()`, `loadConfig(dojoId)` (async, setzt `state.config` und ruft `render()`).

- [ ] **Step 1: `githubFetch` und `loadConfig` implementieren**

Ergänze im `<script>`-Block von `viewer/index.html`, vor `init()`:

```javascript
function getRepoOwner() {
  // Wird aus dem Hostnamen der GitHub-Pages-URL abgeleitet: <owner>.github.io
  const host = window.location.hostname;
  return host.endsWith('.github.io') ? host.replace('.github.io', '') : getUrlParam('owner');
}

const REPO_NAME = 'rf-dojos';

async function githubFetch(path) {
  const res = await fetch(`https://api.github.com${path}`, {
    headers: state.token ? { Authorization: `Bearer ${state.token}` } : {},
  });
  if (!res.ok) {
    const err = new Error(`GitHub API ${res.status} für ${path}`);
    err.status = res.status;
    err.remaining = res.headers.get('X-RateLimit-Remaining');
    throw err;
  }
  return res.json();
}

async function loadConfig(dojoId) {
  const owner = getRepoOwner();
  const data = await githubFetch(`/repos/${owner}/${REPO_NAME}/contents/dojos/${dojoId}/config.yaml`);
  const yamlText = atob(data.content);
  state.config = jsyaml.load(yamlText);
  render();
}
```

- [ ] **Step 2: `init()` erweitern, um `loadConfig` aufzurufen**

```javascript
async function init() {
  await ensureToken();
  await loadConfig(state.dojoId);
}
```

- [ ] **Step 3: Manuell verifizieren**

Run: lokalen Server starten (wie Task 2, Step 2), Browser-Devtools öffnen,
`http://localhost:8000/?dojo=dojo-01-web-testing&owner=<dein-github-username>`
aufrufen, gültigen Token eingeben.
Expected: Header zeigt "Web Testing Dojo #1" (aus `config.yaml` geladen),
kein Fehler in der Konsole. Bei ungültigem Token: Fehler mit Status 401/404
wird geworfen und in der Konsole sichtbar (noch keine UI-Fehlerbehandlung –
folgt in Task 9).

- [ ] **Step 4: Commit**

```bash
git add viewer/index.html
git commit -m "Load dojo config.yaml via GitHub API"
```

---

### Task 4: Offene PRs laden & Teilnehmer-Tabs rendern

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `githubFetch`, `getRepoOwner`, `state.dojoId`, `state.currentParticipantIndex` aus Task 2/3.
- Produces: `loadOpenPRs(dojoId)` (setzt `state.prs = [{username, branch, number}]`, sortiert nach `username`), `renderParticipantTabs()`, `selectParticipant(index)`.

- [ ] **Step 1: `loadOpenPRs` implementieren**

```javascript
async function loadOpenPRs(dojoId) {
  const owner = getRepoOwner();
  const allOpen = await githubFetch(`/repos/${owner}/${REPO_NAME}/pulls?state=open&per_page=100`);
  const titlePrefix = `[${dojoId}]`;
  state.prs = allOpen
    .filter((pr) => pr.title.startsWith(titlePrefix))
    .map((pr) => ({
      username: pr.title.slice(titlePrefix.length).trim(),
      branch: pr.head.ref,
      number: pr.number,
    }))
    .sort((a, b) => a.username.localeCompare(b.username));
  render();
}
```

- [ ] **Step 2: `renderParticipantTabs` und `selectParticipant` implementieren, `render()` erweitern**

```javascript
function selectParticipant(index) {
  state.currentParticipantIndex = index;
  render();
}

function renderParticipantTabs() {
  const container = document.getElementById('participant-tabs');
  container.innerHTML = '';
  state.prs.forEach((pr, index) => {
    const btn = document.createElement('button');
    btn.textContent = pr.username;
    btn.className = index === state.currentParticipantIndex ? 'active' : '';
    btn.addEventListener('click', () => selectParticipant(index));
    container.appendChild(btn);
  });
}

function render() {
  document.getElementById('dojo-title').textContent = state.config ? state.config.dojo.title : '';
  renderParticipantTabs();
  document.getElementById('status-bar').textContent =
    `Teilnehmer: ${state.prs.length} PRs`;
}
```

- [ ] **Step 3: `init()` erweitern**

```javascript
async function init() {
  await ensureToken();
  await loadConfig(state.dojoId);
  await loadOpenPRs(state.dojoId);
}
```

- [ ] **Step 4: Manuell verifizieren**

Voraussetzung: mindestens ein offener PR im Test-Repo mit Titel
`[dojo-01-web-testing] <username>`.
Run: Viewer wie in Task 3 öffnen.
Expected: Tab-Leiste zeigt den/die Teilnehmer-Namen, Klick auf einen Tab
markiert ihn als aktiv (Statusleiste zeigt korrekte Anzahl PRs).

- [ ] **Step 5: Commit**

```bash
git add viewer/index.html
git commit -m "Load open PRs and render participant tabs"
```

---

### Task 5: Runden-Navigation aus config.yaml rendern

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `state.config.rounds`, `state.currentRoundIndex`, `render()`.
- Produces: `renderRoundsNav()`, `selectRound(index)`.

- [ ] **Step 1: `renderRoundsNav` und `selectRound` implementieren**

```javascript
function selectRound(index) {
  state.currentRoundIndex = index;
  render();
}

function renderRoundsNav() {
  const list = document.getElementById('rounds-list');
  list.innerHTML = '';
  (state.config.rounds || []).forEach((round, index) => {
    const li = document.createElement('li');
    li.textContent = round.title;
    li.className = index === state.currentRoundIndex ? 'active' : '';
    li.title = round.description;
    li.addEventListener('click', () => selectRound(index));
    list.appendChild(li);
  });
}
```

- [ ] **Step 2: `render()` erweitern**

```javascript
function render() {
  document.getElementById('dojo-title').textContent = state.config ? state.config.dojo.title : '';
  renderRoundsNav();
  renderParticipantTabs();
  document.getElementById('status-bar').textContent =
    `Teilnehmer: ${state.prs.length} PRs`;
}
```

- [ ] **Step 3: Manuell verifizieren**

Run: Viewer öffnen wie zuvor.
Expected: Linke Navigation zeigt alle 6 Runden aus `config.yaml`
("Verzeichnisstruktur", "Test-Struktur", …), erste Runde ist aktiv
markiert, Klick wechselt die aktive Markierung.

- [ ] **Step 4: Commit**

```bash
git add viewer/index.html
git commit -m "Render rounds navigation from config.yaml"
```

---

### Task 6: Dateibaum-Ansicht (Modus `tree`)

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `githubFetch`, `getRepoOwner`, `state.prs`, `state.currentParticipantIndex`, `state.config.rounds`, `state.currentRoundIndex`.
- Produces: `loadFileTree(branch)` (async, gibt flaches Array von Pfaden zurück), `buildTreeFromPaths(paths)` (reine Funktion, gibt verschachteltes Objekt zurück), `renderTreeView(container, paths)`.

- [ ] **Step 1: `buildTreeFromPaths` als reine Funktion schreiben**

```javascript
function buildTreeFromPaths(paths) {
  const root = {};
  for (const path of paths) {
    const parts = path.split('/');
    let node = root;
    parts.forEach((part, i) => {
      if (!node[part]) node[part] = i === parts.length - 1 ? null : {};
      if (node[part] !== null) node = node[part];
    });
  }
  return root;
}
```

- [ ] **Step 2: Reine Funktion isoliert per Node-Scratch-Skript verifizieren**

Run:
```bash
node -e "
$(sed -n '/^function buildTreeFromPaths/,/^}/p' viewer/index.html)
const result = buildTreeFromPaths(['tests/login.robot', 'resources/keywords.resource']);
console.assert(JSON.stringify(result) === JSON.stringify({tests: {'login.robot': null}, resources: {'keywords.resource': null}}), 'FAIL', result);
console.log('OK');
"
```
Expected: `OK` ohne vorherige `FAIL`-Zeile.

- [ ] **Step 3: `loadFileTree` und `renderTreeView` implementieren**

```javascript
async function loadFileTree(branch) {
  const owner = getRepoOwner();
  const data = await githubFetch(`/repos/${owner}/${REPO_NAME}/git/trees/${branch}?recursive=1`);
  return data.tree.filter((entry) => entry.type === 'blob').map((entry) => entry.path);
}

function renderTreeNode(name, subtree) {
  if (subtree === null) return `<li>${name}</li>`;
  const children = Object.entries(subtree).map(([k, v]) => renderTreeNode(k, v)).join('');
  return `<li>${name}/<ul>${children}</ul></li>`;
}

function renderTreeView(container, paths) {
  const tree = buildTreeFromPaths(paths);
  const html = Object.entries(tree).map(([k, v]) => renderTreeNode(k, v)).join('');
  container.innerHTML = `<ul class="file-tree">${html}</ul>`;
}
```

- [ ] **Step 4: In `render()` einhängen (Modus `tree` nur für aktuelle Runde/Teilnehmer)**

```javascript
async function renderContent() {
  const round = (state.config.rounds || [])[state.currentRoundIndex];
  const pr = state.prs[state.currentParticipantIndex];
  const content = document.getElementById('content');
  if (!round || !pr) { content.innerHTML = ''; return; }
  if (round.show === 'tree') {
    const paths = await loadFileTree(pr.branch);
    renderTreeView(content, paths.filter((p) => p.startsWith(`dojos/${state.dojoId}/submissions/${pr.username}/`)));
  }
}
```

Rufe `renderContent()` am Ende von `render()` auf (fire-and-forget, da `render()`
synchron bleibt): `renderContent();` als letzte Zeile in `render()` hinzufügen.

- [ ] **Step 5: Manuell verifizieren**

Run: Viewer öffnen, Runde "Verzeichnisstruktur" auswählen (ist bereits per
Default aktiv).
Expected: Rechter Bereich zeigt eingerückten Dateibaum der Submission des
aktiven Teilnehmers, kein Fehler in der Konsole.

- [ ] **Step 6: Commit**

```bash
git add viewer/index.html
git commit -m "Add tree view mode for file structure round"
```

---

### Task 7: Datei-Anzeige mit Syntax-Highlighting & Regex-Highlight (Modus `file`)

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `githubFetch`, `getRepoOwner`, `renderContent()` aus Task 6.
- Produces: `globToRegex(pattern)` (reine Funktion), `matchFilenamePattern(path, pattern)` (reine Funktion), `loadFileContent(path, branch)`, `renderFileView(container, files, highlightPattern)`.

- [ ] **Step 1: `globToRegex` und `matchFilenamePattern` als reine Funktionen schreiben**

```javascript
function globToRegex(glob) {
  const escaped = glob.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*');
  return new RegExp(`^${escaped}$`);
}

function matchFilenamePattern(path, pattern) {
  const filename = path.split('/').pop();
  return pattern.split('|').some((glob) => globToRegex(glob).test(filename));
}
```

- [ ] **Step 2: Per Node-Scratch-Skript verifizieren**

Run:
```bash
node -e "
$(sed -n '/^function globToRegex/,/^}/p' viewer/index.html)
$(sed -n '/^function matchFilenamePattern/,/^}/p' viewer/index.html)
console.assert(matchFilenamePattern('tests/login.robot', '*.robot') === true, 'FAIL 1');
console.assert(matchFilenamePattern('resources/shared_resources.resource', '*.robot|*keywords*.robot|*resources*') === true, 'FAIL 2');
console.assert(matchFilenamePattern('README.md', '*.robot') === false, 'FAIL 3');
console.log('OK');
"
```
Expected: `OK` ohne vorherige `FAIL`-Zeile.

- [ ] **Step 3: `loadFileContent` und `renderFileView` implementieren**

```javascript
async function loadFileContent(path, branch) {
  const owner = getRepoOwner();
  const data = await githubFetch(`/repos/${owner}/${REPO_NAME}/contents/${path}?ref=${branch}`);
  return atob(data.content);
}

function highlightLines(codeHtml, pattern) {
  if (!pattern) return codeHtml;
  const regex = new RegExp(pattern, 'i');
  return codeHtml.split('\n').map((line) => {
    const plain = line.replace(/<[^>]*>/g, '');
    return regex.test(plain) ? `<span class="highlight-line">${line}</span>` : line;
  }).join('\n');
}

async function renderFileView(container, paths, branch, filenamePattern, highlightPattern) {
  const matching = paths.filter((p) => matchFilenamePattern(p, filenamePattern));
  container.innerHTML = '';
  for (const path of matching) {
    const raw = await loadFileContent(path, branch);
    const highlighted = hljs.highlight(raw, { language: 'plaintext' }).value;
    const pre = document.createElement('pre');
    pre.innerHTML = `<code>${highlightLines(highlighted, highlightPattern)}</code>`;
    const heading = document.createElement('h4');
    heading.textContent = path;
    container.appendChild(heading);
    container.appendChild(pre);
  }
}
```

- [ ] **Step 4: `renderContent()` um Modus `file` erweitern**

```javascript
async function renderContent() {
  const round = (state.config.rounds || [])[state.currentRoundIndex];
  const pr = state.prs[state.currentParticipantIndex];
  const content = document.getElementById('content');
  if (!round || !pr) { content.innerHTML = ''; return; }
  const paths = (await loadFileTree(pr.branch))
    .filter((p) => p.startsWith(`dojos/${state.dojoId}/submissions/${pr.username}/`));
  if (round.show === 'tree') {
    renderTreeView(content, paths);
  } else if (round.show === 'file') {
    await renderFileView(content, paths, pr.branch, round.filename_pattern, round.highlight);
  }
}
```

- [ ] **Step 5: Manuell verifizieren**

Run: Viewer öffnen, Runde "Locator-Strategie" auswählen (hat `highlight`-Pattern).
Expected: `.robot`-Dateien der Submission werden mit Syntax-Highlighting
angezeigt, Zeilen die `locator|css|xpath|id=` matchen sind gelb hinterlegt.

- [ ] **Step 6: Commit**

```bash
git add viewer/index.html
git commit -m "Add file view mode with syntax and regex highlighting"
```

---

### Task 8: Tastatursteuerung

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `selectParticipant`, `selectRound`, `state.prs`, `state.config.rounds`, `state.currentParticipantIndex`, `state.currentRoundIndex`.
- Produces: `handleKeydown(event)`.

- [ ] **Step 1: `handleKeydown` implementieren und registrieren**

```javascript
function handleKeydown(event) {
  const roundCount = (state.config.rounds || []).length;
  const participantCount = state.prs.length;
  if (event.key === 'ArrowRight' && participantCount) {
    selectParticipant((state.currentParticipantIndex + 1) % participantCount);
  } else if (event.key === 'ArrowLeft' && participantCount) {
    selectParticipant((state.currentParticipantIndex - 1 + participantCount) % participantCount);
  } else if (event.key === 'ArrowDown' && roundCount) {
    selectRound((state.currentRoundIndex + 1) % roundCount);
  } else if (event.key === 'ArrowUp' && roundCount) {
    selectRound((state.currentRoundIndex - 1 + roundCount) % roundCount);
  }
}

document.addEventListener('keydown', handleKeydown);
```

- [ ] **Step 2: Manuell verifizieren**

Run: Viewer öffnen mit mindestens 2 offenen PRs.
Expected: `←`/`→` wechselt zwischen Teilnehmer-Tabs (mit Wrap-Around),
`↑`/`↓` wechselt zwischen Runden (mit Wrap-Around), Inhalt aktualisiert
sich jeweils.

- [ ] **Step 3: Commit**

```bash
git add viewer/index.html
git commit -m "Add keyboard navigation for rounds and participants"
```

---

### Task 9: Fehlerbehandlung & Ladezustände

**Files:**
- Modify: `viewer/index.html`

**Interfaces:**
- Consumes: `githubFetch` (liest `.status`/`.remaining` vom geworfenen Error), `render()`.
- Produces: `showError(message)`, `clearError()`, try/catch-Wrapping in `init()` und `renderContent()`.

- [ ] **Step 1: `showError`/`clearError` und Fehlerbanner-Element ergänzen**

Füge im `<body>` direkt nach `<header>` ein:

```html
<div id="error-banner" style="display:none; background:#ffebe9; color:#82071e; padding:0.5rem 1rem; border-bottom:1px solid #ffc1c1;"></div>
```

```javascript
function showError(message) {
  const banner = document.getElementById('error-banner');
  banner.textContent = message;
  banner.style.display = 'block';
}

function clearError() {
  document.getElementById('error-banner').style.display = 'none';
}
```

- [ ] **Step 2: `init()` und `renderContent()` mit try/catch absichern**

```javascript
async function init() {
  try {
    await ensureToken();
    await loadConfig(state.dojoId);
    await loadOpenPRs(state.dojoId);
    clearError();
  } catch (err) {
    if (err.status === 403 && err.remaining === '0') {
      showError('GitHub Rate Limit erreicht. Bitte kurz warten oder Token prüfen.');
    } else if (err.status === 404) {
      showError(`Nicht gefunden: ${err.message}. Existiert das Dojo/die config.yaml?`);
    } else {
      showError(`Fehler beim Laden: ${err.message}`);
    }
  }
}
```

```javascript
async function renderContent() {
  const round = (state.config.rounds || [])[state.currentRoundIndex];
  const pr = state.prs[state.currentParticipantIndex];
  const content = document.getElementById('content');
  if (!state.prs.length) {
    content.innerHTML = '<p>Noch keine offenen PRs für dieses Dojo gefunden.</p>';
    return;
  }
  if (!round || !pr) { content.innerHTML = ''; return; }
  try {
    const paths = (await loadFileTree(pr.branch))
      .filter((p) => p.startsWith(`dojos/${state.dojoId}/submissions/${pr.username}/`));
    if (round.show === 'tree') {
      renderTreeView(content, paths);
    } else if (round.show === 'file') {
      await renderFileView(content, paths, pr.branch, round.filename_pattern, round.highlight);
    }
    clearError();
  } catch (err) {
    showError(`Fehler beim Laden der Dateien für ${pr.username}: ${err.message}`);
  }
}
```

- [ ] **Step 3: Manuell verifizieren**

Run: Viewer mit ungültigem Token öffnen (z.B. `xxx` eingeben).
Expected: Rotes Fehlerbanner mit verständlicher Meldung erscheint, Seite
bleibt sonst bedienbar (kein weißer Bildschirm / kein unbehandelter
Konsolenfehler).

Run: Viewer für ein Dojo ohne offene PRs öffnen.
Expected: Content-Bereich zeigt "Noch keine offenen PRs..." statt leer/leerer Fehler.

- [ ] **Step 4: Commit**

```bash
git add viewer/index.html
git commit -m "Add error handling and empty-state messaging"
```

---

### Task 10: GitHub Pages aktivieren & End-to-End-Smoketest

**Files:**
- Create: `viewer/README.md`

**Interfaces:**
- Consumes: alle vorherigen Tasks (kompletter Viewer).
- Produces: Bedienungsanleitung für den Organisator (kein Code-Interface).

- [ ] **Step 1: `viewer/README.md` schreiben**

```markdown
# Viewer – Bedienungsanleitung

1. Repo-Settings → Pages → Branch `main`, Ordner `/viewer`.
2. URL bookmarken: `https://<owner>.github.io/rf-dojos/viewer/?dojo=<dojo-id>`
3. Beim ersten Öffnen: GitHub Personal Access Token (Scope `public_repo`)
   eintragen. Wird nur lokal im Browser gespeichert.
4. Tastatursteuerung: `←`/`→` = Teilnehmer wechseln, `↑`/`↓` = Runde wechseln.
```

- [ ] **Step 2: GitHub Pages in den Repo-Settings aktivieren**

Manuell in den GitHub-Repo-Settings: Pages → Source: Branch `main`,
Folder `/viewer`.

- [ ] **Step 3: End-to-End-Smoketest gegen echtes Repo**

Voraussetzung: mindestens ein echter Test-PR mit korrektem Titel und
Submission-Dateien im Repo.
Run: `https://<owner>.github.io/rf-dojos/viewer/?dojo=dojo-01-web-testing`
im Browser öffnen.
Expected: Alle 6 Runden durchklickbar, Teilnehmer-Tab des Test-PRs
erscheint, Tree- und File-Modus zeigen echte Dateien aus dem PR-Branch,
Tastatursteuerung funktioniert, kein Fehlerbanner.

- [ ] **Step 4: Commit**

```bash
git add viewer/README.md
git commit -m "Add viewer usage instructions"
```
