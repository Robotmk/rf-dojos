# Viewer: Inline Round Descriptions & Dojo-List Landing Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show each round's description inline (smaller text under the title) instead of as a hover tooltip, and make `viewer/index.html` show a browsable list of all dojos in the repo when opened without a `?dojo=` parameter.

**Architecture:** Both changes are additions/modifications to the existing single-file `viewer/index.html` — no new files, no build pipeline. The round-description change touches `renderRoundsNav()` and CSS only. The dojo-list change adds two new functions (`loadDojoList()`, `renderDojoList()`) and branches `init()` on whether `state.dojoId` is set.

**Tech Stack:** Vanilla HTML/CSS/JS (already established in this file), `js-yaml` (already loaded via CDN), GitHub Contents API (already used elsewhere in this file via `githubFetch`).

## Global Constraints

- `viewer/index.html` bleibt eine einzige Datei, kein Build-Pipeline, kein npm, kein Framework.
- Alle dynamischen/repo-abgeleiteten Strings werden über `textContent` (nicht `innerHTML`-Template-Interpolation) eingefügt — dieses Repo hat die gegenteilige Bug-Klasse (HTML-Injection über `innerHTML`) bereits vier Mal gefunden und gefixt.
- Kein zusätzlicher GitHub-API-Call-Typ jenseits der bereits genutzten Contents-API.
- Kein automatisiertes Test-Framework. Verifikation über `node --check` (Syntax) und, wo isolierbar, Node-Scratch-Skripte für reine Logikanteile; interaktive Browser-Prüfung wird als manueller Schritt dokumentiert, da diese Umgebung keinen echten Browser/GitHub-Zugriff hat.

---

### Task 1: Rundenbeschreibung inline statt Tooltip

**Files:**
- Modify: `viewer/index.html:14-26` (CSS-Block)
- Modify: `viewer/index.html:91-102` (`renderRoundsNav`)

**Interfaces:**
- Consumes: `state.config.rounds[].{title,description}`, `state.currentRoundIndex`, `selectRound(index)` (bestehend, unverändert).
- Produces: keine neuen Funktionen — nur geänderter Rendering-Output von `renderRoundsNav()`.

- [ ] **Step 1: CSS-Regel für die Beschreibung ergänzen**

Füge im bestehenden `<style>`-Block (nach der Zeile `#rounds-nav li.active { ... }`, aktuell `viewer/index.html:17`) folgende Regel hinzu:

```css
#rounds-nav li .round-title { display: block; }
#rounds-nav li .round-description { display: block; font-size: 0.75rem; color: #57606a; margin-top: 0.15rem; }
#rounds-nav li.active .round-description { color: #d0d7de; }
```

(Die letzte Regel sorgt dafür, dass die Beschreibung auf dem farbig hervorgehobenen aktiven Eintrag lesbar bleibt, da `--accent` ein dunkles Blau ist.)

- [ ] **Step 2: `renderRoundsNav()` um die Beschreibung erweitern**

Ersetze die komplette Funktion (aktuell `viewer/index.html:91-102`):

```javascript
function renderRoundsNav() {
  const list = document.getElementById('rounds-list');
  list.innerHTML = '';
  (state.config?.rounds || []).forEach((round, index) => {
    const li = document.createElement('li');
    li.className = index === state.currentRoundIndex ? 'active' : '';

    const titleEl = document.createElement('span');
    titleEl.className = 'round-title';
    titleEl.textContent = round.title;
    li.appendChild(titleEl);

    if (round.description) {
      const descEl = document.createElement('small');
      descEl.className = 'round-description';
      descEl.textContent = round.description;
      li.appendChild(descEl);
    }

    li.addEventListener('click', () => selectRound(index));
    list.appendChild(li);
  });
}
```

Beachte: `li.title = round.description` (Tooltip) entfällt ersatzlos — die
Beschreibung ist jetzt permanent sichtbar statt nur per Hover.

- [ ] **Step 3: Verifizieren**

Extrahiere das `<script>`-Element und prüfe die Syntax:

Run: `node --check <(sed -n '/^<script>$/,/^<\/script>$/p' viewer/index.html | sed '1d;$d')`

(Falls dein System kein Prozess-Substitution-`<()` unterstützt, schreibe den
extrahierten Bereich zuerst in eine temporäre `.js`-Datei und rufe
`node --check tmp.js` darauf auf.)

Expected: keine Ausgabe (kein Syntaxfehler).

Lies den erzeugten HTML-Output einmal durch (z.B. via kurzem Node-Skript,
das `renderRoundsNav` mit einem Fake-`document`/Fake-`state` aufruft, falls
gewünscht — nicht zwingend, da die Logik trivial ist) und bestätige, dass
für eine Runde ohne `description` (z.B. falls `config.yaml` das Feld
weglässt) kein leeres `<small>`-Element erzeugt wird (siehe `if (round.description)`-Guard oben).

Live-Browser-Verifikation (sieht die Beschreibung unter dem Titel gut aus,
ist sie auf dem aktiven Eintrag lesbar) ist manuell nachzuholen, sobald ein
echter Browser/Repo verfügbar ist — hier nicht automatisierbar.

- [ ] **Step 4: Commit**

```bash
git add viewer/index.html
git commit -m "Show round description inline instead of as tooltip"
```

---

### Task 2: Dojo-Übersicht als Startseite

**Files:**
- Modify: `viewer/index.html:357-372` (`init`)
- Modify: `viewer/index.html` (neue Funktionen `loadDojoList`, `renderDojoList`, `buildDojoLink` — direkt vor `init()` einfügen, z.B. nach `clearError()` bei Zeile 355)

**Interfaces:**
- Consumes: `githubFetch(path)`, `getRepoOwner()`, `REPO_NAME`, `decodeBase64Utf8(b64)` (alle bereits vorhanden und unverändert), `state.dojoId`.
- Produces: `loadDojoList()` (async, lädt Liste und ruft `renderDojoList` auf), `renderDojoList(dojos)` (rendert `{id, title}[]` in `#content`), `buildDojoLink(dojoId)` (reine Funktion bis auf den `window.location.search`-Zugriff — gibt einen relativen Query-String zurück, der `dojo` setzt und alle übrigen bestehenden Query-Parameter, z.B. `owner`, erhält).

- [ ] **Step 1: `buildDojoLink`, `loadDojoList`, `renderDojoList` implementieren**

Füge direkt vor `async function init() {` (aktuell `viewer/index.html:357`) ein:

```javascript
function buildDojoLink(dojoId) {
  const params = new URLSearchParams(window.location.search);
  params.set('dojo', dojoId);
  return `?${params.toString()}`;
}

async function loadDojoList() {
  const owner = getRepoOwner();
  const entries = await githubFetch(`/repos/${owner}/${REPO_NAME}/contents/dojos`);
  const dirs = entries.filter((entry) => entry.type === 'dir');
  const dojos = [];
  for (const dir of dirs) {
    let title = dir.name;
    try {
      const data = await githubFetch(`/repos/${owner}/${REPO_NAME}/contents/dojos/${dir.name}/config.yaml`);
      const config = jsyaml.load(decodeBase64Utf8(data.content));
      if (config?.dojo?.title) title = config.dojo.title;
    } catch (err) {
      console.warn(`Konnte config.yaml für ${dir.name} nicht laden:`, err);
    }
    dojos.push({ id: dir.name, title });
  }
  dojos.sort((a, b) => a.id.localeCompare(b.id));
  renderDojoList(dojos);
}

function renderDojoList(dojos) {
  document.getElementById('dojo-title').textContent = 'Dojos auswählen';
  const content = document.getElementById('content');
  content.innerHTML = '';
  if (!dojos.length) {
    content.textContent = 'Keine Dojos gefunden.';
    return;
  }
  const ul = document.createElement('ul');
  dojos.forEach((dojo) => {
    const li = document.createElement('li');
    const a = document.createElement('a');
    a.href = buildDojoLink(dojo.id);
    a.textContent = dojo.title;
    li.appendChild(a);
    ul.appendChild(li);
  });
  content.appendChild(ul);
}
```

- [ ] **Step 2: `init()` um die Verzweigung erweitern**

Ersetze die komplette Funktion (aktuell `viewer/index.html:357-372`):

```javascript
async function init() {
  try {
    await ensureToken();
    if (!state.dojoId) {
      await loadDojoList();
      clearError();
      return;
    }
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

(Einzige Änderung: der neue `if (!state.dojoId) { ... return; }`-Block direkt
nach `ensureToken()`. Der bestehende catch-Block bleibt unverändert und
fängt jetzt auch Fehler aus `loadDojoList()` — z.B. Rate Limit beim Scannen
von `dojos/` — auf dieselbe Art ab wie bisher.)

- [ ] **Step 3: Reine Teilfunktion isoliert verifizieren**

`buildDojoLink` ist bis auf den `window.location.search`-Zugriff einfach
genug, um per kurzer Simulation zu prüfen, dass bestehende Query-Parameter
erhalten bleiben. Da `window` in Node nicht existiert, prüfe stattdessen die
Kernlogik direkt mit `URLSearchParams`:

Run:
```bash
node -e "
const params = new URLSearchParams('owner=testowner&foo=bar');
params.set('dojo', 'dojo-02-api-testing');
const result = '?' + params.toString();
console.assert(result.includes('dojo=dojo-02-api-testing'), 'FAIL 1: dojo param missing');
console.assert(result.includes('owner=testowner'), 'FAIL 2: existing owner param dropped');
console.assert(result.includes('foo=bar'), 'FAIL 3: existing unrelated param dropped');
console.log('OK');
"
```
Expected: `OK` ohne vorherige `FAIL`-Zeile.

- [ ] **Step 4: Weitere Verifikation**

Extrahiere das `<script>`-Element erneut und prüfe die Syntax:

Run: `node --check` auf den extrahierten Script-Inhalt (wie in Task 1, Step 3).
Expected: keine Ausgabe (kein Syntaxfehler).

Lies `loadDojoList()`/`renderDojoList()` durch und bestätige:
- Ein einzelnes Dojo mit kaputter/fehlender `config.yaml` bricht die
  Gesamtliste nicht ab (eigenes `try/catch` pro Dojo, Fallback auf
  `dir.name` als Titel).
- Sortierung erfolgt über `localeCompare` auf `dojo.id` (Ordner-Name),
  nicht auf `title`.
- Kein `innerHTML`-Aufruf mit interpoliertem, dynamischem Text — Titel und
  Link-Text werden über `textContent`, die URL über `.href`
  (Property-Zuweisung, kein HTML-Injection-Vektor) gesetzt.

Live-Browser-/Live-Repo-Verifikation (öffnet `viewer/index.html` ohne
`?dojo=`, zeigt die echte Liste, Klick führt zum richtigen Dojo) ist manuell
nachzuholen, sobald ein echter Browser/Repo verfügbar ist.

- [ ] **Step 5: Commit**

```bash
git add viewer/index.html
git commit -m "Add dojo-list landing page when no ?dojo= parameter is given"
```
