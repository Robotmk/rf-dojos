# Keiko Buddy & Timer Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `viewer/keiko.html`, a single-file companion tool for the Keiko phase that lets the organizer run a shared countdown with automatic milestone broadcasts, and routes participant help requests to their assigned buddy before escalating to the organizer.

**Architecture:** Static single-file vanilla JS/HTML/CSS app, realtime-synced across all open browser tabs via an Ably Realtime channel (one channel per dojo, direct client-side publish/subscribe with a restricted API key — no custom backend). Buddy pairing and timer milestones come from an extension to the dojo's existing `config.yaml`.

**Tech Stack:** Vanilla HTML/CSS/JS, `js-yaml` (CDN) for config parsing, `ably.js` (CDN) for realtime pub/sub, Web Audio API (`AudioContext`) for notification tones — no npm, no bundler, no framework.

**Depends on:** `docs/superpowers/plans/2026-07-28-repo-scaffold-and-hyoka-viewer.md` Task 1 (creates `dojos/dojo-01-web-testing/config.yaml`, extended here) — should be executed first or in parallel, since Task 1 of this plan edits the same file.

## Global Constraints

- Neue Seite `viewer/keiko.html` — reines HTML/CSS/JS, keine Build-Pipeline, kein npm, kein Framework, wie der bestehende Viewer.
- Externe Abhängigkeiten nur via CDN (`js-yaml`, `ably.js`).
- Realtime-Transport: Ably, direkt aus dem Browser mit einem eingeschränkten API-Key (nur `publish`+`subscribe`), kein eigener Auth-Server.
- Ably-Key wird **nicht** im Repo gespeichert — Eingabe per Textfeld, Ablage nur in `localStorage` (analog zum GitHub-Token-Muster in `viewer/index.html`).
- Ein Ably-Channel pro Dojo: `dojo-{dojoId}-keiko`.
- Buddy-Paare und Timer-Meilensteine kommen aus `config.yaml` (`buddies:`, `timer:`), nicht hartcodiert im Tool.
- Kein persistenter Chat-Verlauf nach Abend-Ende — reine Live-Signalisierung.
- Kein Ersatz für Video-/Audio-Kommunikation — nur Timer/Signalisierung.
- Kein klassisches Unit-Testing (UI + externer Realtime-Dienst). Reine, DOM-freie Funktionen (Buddy-Auflösung, Countdown-Berechnung) werden per Node-Scratch-Skript verifiziert; alles andere manuell im Browser mit mehreren Tabs.

---

### Task 1: config.yaml-Schema-Erweiterung + keiko.html Grundgerüst (Rollen-/Namenswahl)

**Files:**
- Modify: `dojos/dojo-01-web-testing/config.yaml`
- Create: `viewer/keiko.html`

**Interfaces:**
- Produces: `buddies:` (Liste `{a, b}`) und `timer: {duration_minutes, buddy_timeout_minutes, milestones: [{at_minute, message}]}` im `config.yaml`-Schema, das alle folgenden Tasks konsumieren.
- Produces: `getUrlParam(name)`, `ROLE_KEY`/`NAME_KEY`-localStorage-Konstanten, `getRole()`/`setRole()`, `getMyName()`/`setMyName()`, globales `state`-Objekt `{dojoId, config, role, myName, myBuddy}`, `render()`.

- [ ] **Step 1: `config.yaml` um `buddies` und `timer` erweitern**

Ergänze in `dojos/dojo-01-web-testing/config.yaml` (nach dem bestehenden `rounds:`-Abschnitt):

```yaml
buddies:
  - a: alice
    b: bob
  - a: charlie
    b: diana

timer:
  duration_minutes: 60
  buddy_timeout_minutes: 2
  milestones:
    - at_minute: 45
      message: "Noch 15 Minuten!"
    - at_minute: 58
      message: "Zeit ist um – bitte aufräumen für die Präsentation."
```

- [ ] **Step 2: YAML-Syntax verifizieren**

Run: `python3 -c "import yaml; yaml.safe_load(open('dojos/dojo-01-web-testing/config.yaml'))" && echo VALID`
Expected: `VALID`

- [ ] **Step 3: `viewer/keiko.html` Grundgerüst mit Rollen-/Namenswahl schreiben**

```html
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="UTF-8">
<title>🥋 RFUGM Keiko Timer & Buddy</title>
<script src="https://cdn.jsdelivr.net/npm/js-yaml@4.1.0/dist/js-yaml.min.js"></script>
<style>
  * { box-sizing: border-box; }
  body { margin: 0; font-family: -apple-system, Segoe UI, sans-serif; color: #1f2328; }
  header { padding: 0.75rem 1rem; border-bottom: 1px solid #d0d7de; }
  #onboarding, #app { padding: 1rem; }
  #app { display: none; }
  #countdown { font-size: 4rem; font-variant-numeric: tabular-nums; text-align: center; }
  #broadcast-banner { display: none; background: #fff8c5; padding: 0.75rem 1rem; border-radius: 6px; margin: 0.5rem 0; }
  #help-status { padding: 0.5rem; }
  .help-entry { padding: 0.5rem; border: 1px solid #d0d7de; border-radius: 6px; margin: 0.25rem 0; }
  .help-entry.escalated { border-color: #cf222e; background: #ffebe9; }
  button { cursor: pointer; }
</style>
</head>
<body>
<header><h1>🥋 Keiko Timer &amp; Buddy</h1></header>

<div id="onboarding">
  <div id="role-choice">
    <p>Deine Rolle:</p>
    <button id="role-organizer-btn">Organizer</button>
    <button id="role-participant-btn">Teilnehmer</button>
  </div>
  <div id="name-choice" style="display:none;">
    <p>Dein Name:</p>
    <select id="name-select"></select>
    <button id="name-confirm-btn">Bestätigen</button>
  </div>
</div>

<div id="app">
  <div id="broadcast-banner"></div>
  <div id="countdown">--:--</div>
  <div id="organizer-panel" style="display:none;"></div>
  <div id="participant-panel" style="display:none;">
    <p id="buddy-info"></p>
    <button id="help-btn">Ich brauche Hilfe</button>
    <div id="help-status"></div>
  </div>
</div>

<script>
const ROLE_KEY = 'rf_dojos_keiko_role';
const NAME_KEY = 'rf_dojos_keiko_name';

function getUrlParam(name) {
  return new URLSearchParams(window.location.search).get(name);
}

function getRepoOwner() {
  const host = window.location.hostname;
  return host.endsWith('.github.io') ? host.replace('.github.io', '') : getUrlParam('owner');
}

function getRole() { return localStorage.getItem(ROLE_KEY) || ''; }
function setRole(value) { localStorage.setItem(ROLE_KEY, value); }
function getMyName() { return localStorage.getItem(NAME_KEY) || ''; }
function setMyName(value) { localStorage.setItem(NAME_KEY, value); }

const state = {
  dojoId: getUrlParam('dojo'),
  config: null,
  role: getRole(),
  myName: getMyName(),
  myBuddy: null,
};

function render() {
  document.getElementById('onboarding').style.display =
    (state.role && (state.role === 'organizer' || state.myName)) ? 'none' : 'block';
  document.getElementById('app').style.display =
    (state.role && (state.role === 'organizer' || state.myName)) ? 'block' : 'none';
  document.getElementById('organizer-panel').style.display = state.role === 'organizer' ? 'block' : 'none';
  document.getElementById('participant-panel').style.display = state.role === 'participant' ? 'block' : 'none';
}

async function loadDojoConfig(dojoId) {
  const owner = getRepoOwner();
  const url = `https://raw.githubusercontent.com/${owner}/rf-dojos/main/dojos/${dojoId}/config.yaml`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`config.yaml nicht gefunden (${res.status})`);
  return jsyaml.load(await res.text());
}

function wireOnboarding() {
  document.getElementById('role-organizer-btn').addEventListener('click', () => {
    state.role = 'organizer';
    setRole('organizer');
    render();
  });
  document.getElementById('role-participant-btn').addEventListener('click', () => {
    document.getElementById('role-choice').style.display = 'none';
    document.getElementById('name-choice').style.display = 'block';
    const select = document.getElementById('name-select');
    const names = (state.config.buddies || []).flatMap((pair) => [pair.a, pair.b]);
    select.innerHTML = names.map((n) => `<option value="${n}">${n}</option>`).join('');
  });
  document.getElementById('name-confirm-btn').addEventListener('click', () => {
    state.role = 'participant';
    state.myName = document.getElementById('name-select').value;
    setRole('participant');
    setMyName(state.myName);
    render();
  });
}

async function init() {
  state.config = await loadDojoConfig(state.dojoId);
  wireOnboarding();
  render();
}

init();
</script>
</body>
</html>
```

- [ ] **Step 4: Manuell verifizieren**

Run: `python3 -m http.server 8000 --directory viewer` und
`http://localhost:8000/keiko.html?dojo=dojo-01-web-testing&owner=<dein-github-username>`
öffnen.
Expected: Rollenauswahl erscheint. Klick auf "Teilnehmer" zeigt eine
Namensauswahl mit `alice`, `bob`, `charlie`, `diana` (aus `config.yaml`).
Nach Bestätigung erscheint der `#app`-Bereich, Onboarding verschwindet.
Klick auf "Organizer" (in einem zweiten Tab/Inkognito-Fenster) zeigt
direkt den `#app`-Bereich mit sichtbarem Organizer-Panel.

- [ ] **Step 5: Commit**

```bash
git add dojos/dojo-01-web-testing/config.yaml viewer/keiko.html
git commit -m "Add buddy/timer config schema and keiko.html onboarding shell"
```

---

### Task 2: Ably-Onboarding & Channel-Verbindung

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `state.dojoId`, `render()` aus Task 1.
- Produces: `ABLY_KEY_STORAGE`, `getAblyKey()`/`setAblyKey()`, `ensureAblyKey()`, `state.ably`, `state.channel`, `getChannelName(dojoId)`.

- [ ] **Step 1: Ably-CDN-Script und Key-Dialog ergänzen**

Füge im `<head>` hinzu:

```html
<script src="https://cdn.ably.io/lib/ably.min.js"></script>
```

Füge im `<body>` nach dem Onboarding-Div ein:

```html
<dialog id="ably-key-dialog">
  <form method="dialog" id="ably-key-form">
    <p>Ably API-Key eingeben (Capability: publish + subscribe).<br>
    Wird nur lokal in diesem Browser gespeichert.</p>
    <input type="password" id="ably-key-input" placeholder="xxxx.yyyy:zzzz">
    <button type="submit">Speichern</button>
  </form>
</dialog>
```

- [ ] **Step 2: `ensureAblyKey`, `getChannelName` und Verbindungsaufbau implementieren**

```javascript
const ABLY_KEY_STORAGE = 'rf_dojos_ably_key';

function getAblyKey() { return localStorage.getItem(ABLY_KEY_STORAGE) || ''; }
function setAblyKey(value) { localStorage.setItem(ABLY_KEY_STORAGE, value); }

function ensureAblyKey() {
  return new Promise((resolve) => {
    const existing = getAblyKey();
    if (existing) return resolve(existing);
    const dialog = document.getElementById('ably-key-dialog');
    dialog.showModal();
    document.getElementById('ably-key-form').addEventListener('submit', () => {
      const value = document.getElementById('ably-key-input').value.trim();
      setAblyKey(value);
      resolve(value);
    }, { once: true });
  });
}

function getChannelName(dojoId) {
  return `dojo-${dojoId}-keiko`;
}

async function connectAbly() {
  const key = await ensureAblyKey();
  state.ably = new Ably.Realtime({ key });
  state.channel = state.ably.channels.get(getChannelName(state.dojoId));
  state.channel.subscribe((message) => handleIncomingEvent(message));
}

function handleIncomingEvent(message) {
  // Wird in Task 3+ pro Event-Typ erweitert.
  console.log('Empfangen:', message.name, message.data);
}
```

- [ ] **Step 3: `init()` erweitern**

```javascript
async function init() {
  state.config = await loadDojoConfig(state.dojoId);
  wireOnboarding();
  render();
  await connectAbly();
}
```

- [ ] **Step 4: Manuell verifizieren**

Voraussetzung: kostenloser Ably-Account, App angelegt, API-Key mit
Capability `publish`+`subscribe` kopiert.
Run: Seite wie in Task 1 öffnen.
Expected: Ably-Key-Dialog erscheint, nach Eingabe schließt er sich.
Öffne die Browser-Konsole zweier Tabs (z.B. einmal als "Organizer",
einmal als "Teilnehmer"), führe in einem Tab
`state.channel.publish('test', {foo: 'bar'})` in der Konsole aus.
Expected: Der andere Tab loggt `Empfangen: test {foo: 'bar'}`.

- [ ] **Step 5: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add Ably onboarding and channel connection"
```

---

### Task 3: Timer starten & Countdown-Anzeige

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `state.channel`, `state.config.timer.duration_minutes`, `handleIncomingEvent`.
- Produces: `computeMsRemaining(startedAt, durationMinutes, now)` (reine Funktion), `formatCountdown(msRemaining)` (reine Funktion), `startTimer()`, `state.timerStartedAt`, `state.tickerInterval`, `renderCountdown()`.

- [ ] **Step 1: Reine Funktionen `computeMsRemaining` und `formatCountdown` schreiben**

```javascript
function computeMsRemaining(startedAt, durationMinutes, now) {
  const endsAt = startedAt + durationMinutes * 60 * 1000;
  return Math.max(0, endsAt - now);
}

function formatCountdown(msRemaining) {
  const totalSeconds = Math.floor(msRemaining / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}
```

- [ ] **Step 2: Per Node-Scratch-Skript verifizieren**

Run:
```bash
node -e "
$(sed -n '/^function computeMsRemaining/,/^}/p' viewer/keiko.html)
$(sed -n '/^function formatCountdown/,/^}/p' viewer/keiko.html)
console.assert(computeMsRemaining(1000, 60, 1000) === 3600000, 'FAIL 1');
console.assert(computeMsRemaining(0, 1, 61000) === 0, 'FAIL 2 (darf nicht negativ werden)');
console.assert(formatCountdown(3600000) === '60:00', 'FAIL 3');
console.assert(formatCountdown(65000) === '01:05', 'FAIL 4');
console.log('OK');
"
```
Expected: `OK` ohne vorherige `FAIL`-Zeile.

- [ ] **Step 3: Organizer-Panel um Start-Button erweitern, `startTimer`/`renderCountdown` implementieren**

Ersetze den Inhalt von `<div id="organizer-panel">` im HTML:

```html
<div id="organizer-panel" style="display:none;">
  <button id="start-timer-btn">Keiko starten (60 Min)</button>
</div>
```

Ergänze im Script:

```javascript
function renderCountdown() {
  const el = document.getElementById('countdown');
  if (!state.timerStartedAt) { el.textContent = '--:--'; return; }
  const remaining = computeMsRemaining(state.timerStartedAt, state.config.timer.duration_minutes, Date.now());
  el.textContent = formatCountdown(remaining);
}

function startTimer() {
  const startedAt = Date.now();
  state.channel.publish('timer:start', { startedAt });
}

function onTimerStart(startedAt) {
  state.timerStartedAt = startedAt;
  if (state.tickerInterval) clearInterval(state.tickerInterval);
  state.tickerInterval = setInterval(renderCountdown, 1000);
  renderCountdown();
}

function handleIncomingEvent(message) {
  if (message.name === 'timer:start') {
    onTimerStart(message.data.startedAt);
  } else {
    console.log('Empfangen:', message.name, message.data);
  }
}
```

Ergänze am Ende von `wireOnboarding()` (oder in einer neuen `wireApp()`-Funktion,
die aus `init()` nach `render()` aufgerufen wird):

```javascript
function wireApp() {
  const startBtn = document.getElementById('start-timer-btn');
  if (startBtn) startBtn.addEventListener('click', startTimer);
}
```

Rufe `wireApp();` in `init()` direkt nach `render();` auf.

- [ ] **Step 4: Manuell verifizieren**

Run: zwei Tabs öffnen (einer als Organizer, einer als Teilnehmer).
Klicke im Organizer-Tab auf "Keiko starten".
Expected: Countdown startet in **beiden** Tabs synchron bei `60:00` und
zählt sekündlich runter.

- [ ] **Step 5: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add synchronized Keiko countdown timer"
```

---

### Task 4: Automatische Meilenstein-Broadcasts

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `state.config.timer.milestones`, `state.timerStartedAt`, `state.role`, `sendBroadcast` (wird in dieser Task erstmals implementiert, von Task 5 weiterverwendet).
- Produces: `sendBroadcast(text)`, `checkMilestones(elapsedMinutes)`, `state.firedMilestones`.

- [ ] **Step 1: `sendBroadcast` und `checkMilestones` implementieren**

```javascript
function sendBroadcast(text) {
  state.channel.publish('broadcast', { text });
}

function checkMilestones(elapsedMinutes) {
  if (state.role !== 'organizer') return;
  for (const milestone of (state.config.timer.milestones || [])) {
    if (elapsedMinutes >= milestone.at_minute && !state.firedMilestones.has(milestone.at_minute)) {
      state.firedMilestones.add(milestone.at_minute);
      sendBroadcast(milestone.message);
    }
  }
}
```

- [ ] **Step 2: `onTimerStart` erweitern, `state.firedMilestones` initialisieren**

```javascript
function onTimerStart(startedAt) {
  state.timerStartedAt = startedAt;
  state.firedMilestones = new Set();
  if (state.tickerInterval) clearInterval(state.tickerInterval);
  state.tickerInterval = setInterval(() => {
    renderCountdown();
    const elapsedMinutes = (Date.now() - state.timerStartedAt) / 60000;
    checkMilestones(elapsedMinutes);
  }, 1000);
  renderCountdown();
}
```

- [ ] **Step 3: Manuell verifizieren**

Setze testweise in der Browser-Konsole des Organizer-Tabs
`state.config.timer.milestones = [{at_minute: 0.05, message: "Test-Meilenstein"}]`
**bevor** der Timer gestartet wird (0.05 Min ≈ 3 Sekunden).
Klicke "Keiko starten".
Expected: Nach ca. 3 Sekunden wird in der Konsole eines zweiten Tabs
`Empfangen: broadcast {text: "Test-Meilenstein"}` geloggt (Banner-Anzeige
folgt in Task 5), und der Meilenstein feuert nicht ein zweites Mal.

- [ ] **Step 4: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add automatic milestone broadcasts from config.yaml"
```

---

### Task 5: Broadcast-Banner mit Ton (Teilnehmer & Organizer) + manueller Broadcast

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `sendBroadcast`, `handleIncomingEvent`.
- Produces: `playTone(frequency, durationMs)`, `showBroadcastBanner(text)`, Broadcast-Composer-UI im Organizer-Panel.

- [ ] **Step 1: `playTone` implementieren (Web Audio, kein Audio-Asset nötig)**

```javascript
let audioCtx;

function playTone(frequency, durationMs) {
  audioCtx = audioCtx || new (window.AudioContext || window.webkitAudioContext)();
  const oscillator = audioCtx.createOscillator();
  const gain = audioCtx.createGain();
  oscillator.frequency.value = frequency;
  oscillator.connect(gain);
  gain.connect(audioCtx.destination);
  oscillator.start();
  gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + durationMs / 1000);
  oscillator.stop(audioCtx.currentTime + durationMs / 1000);
}
```

- [ ] **Step 2: `showBroadcastBanner` implementieren und in `handleIncomingEvent` einhängen**

```javascript
function showBroadcastBanner(text) {
  const banner = document.getElementById('broadcast-banner');
  banner.textContent = text;
  banner.style.display = 'block';
  playTone(660, 300);
  setTimeout(() => { banner.style.display = 'none'; }, 10000);
}

function handleIncomingEvent(message) {
  if (message.name === 'timer:start') {
    onTimerStart(message.data.startedAt);
  } else if (message.name === 'broadcast') {
    showBroadcastBanner(message.data.text);
  } else {
    console.log('Empfangen:', message.name, message.data);
  }
}
```

- [ ] **Step 3: Broadcast-Composer im Organizer-Panel ergänzen**

```html
<div id="organizer-panel" style="display:none;">
  <button id="start-timer-btn">Keiko starten (60 Min)</button>
  <div>
    <input type="text" id="broadcast-input" placeholder="Nachricht an alle...">
    <button id="broadcast-send-btn">Senden</button>
  </div>
</div>
```

```javascript
function wireApp() {
  const startBtn = document.getElementById('start-timer-btn');
  if (startBtn) startBtn.addEventListener('click', startTimer);
  const sendBtn = document.getElementById('broadcast-send-btn');
  if (sendBtn) sendBtn.addEventListener('click', () => {
    const input = document.getElementById('broadcast-input');
    if (input.value.trim()) {
      sendBroadcast(input.value.trim());
      input.value = '';
    }
  });
}
```

- [ ] **Step 4: Manuell verifizieren**

Run: Organizer-Tab, Text in das Broadcast-Feld eingeben, "Senden" klicken.
Expected: In **allen** offenen Tabs (inkl. Organizer selbst, da Ably
standardmäßig `echoMessages: true` verwendet) erscheint das gelbe Banner
mit dem Text und ein hörbarer Ton, Banner verschwindet nach 10 Sekunden
automatisch.

- [ ] **Step 5: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add broadcast banner with sound and manual broadcast composer"
```

---

### Task 6: Buddy-Auflösung & Hilfe-Anfrage

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `state.config.buddies`, `state.myName`, `state.channel`.
- Produces: `resolveBuddy(name, buddyPairs)` (reine Funktion), `state.myBuddy`, `respondResolved(from)`, `respondEscalate(from, originalBuddy)`, `requestHelp()`, `state.pendingHelpTimeout`, `renderMyHelpStatus(status)`.

- [ ] **Step 1: `resolveBuddy` als reine Funktion schreiben**

```javascript
function resolveBuddy(name, buddyPairs) {
  for (const pair of buddyPairs) {
    if (pair.a === name) return pair.b;
    if (pair.b === name) return pair.a;
  }
  return null;
}
```

- [ ] **Step 2: Per Node-Scratch-Skript verifizieren**

Run:
```bash
node -e "
$(sed -n '/^function resolveBuddy/,/^}/p' viewer/keiko.html)
const pairs = [{a: 'alice', b: 'bob'}, {a: 'charlie', b: 'diana'}];
console.assert(resolveBuddy('alice', pairs) === 'bob', 'FAIL 1');
console.assert(resolveBuddy('diana', pairs) === 'charlie', 'FAIL 2');
console.assert(resolveBuddy('unknown', pairs) === null, 'FAIL 3');
console.log('OK');
"
```
Expected: `OK` ohne vorherige `FAIL`-Zeile.

- [ ] **Step 3: `state.myBuddy` beim Namens-Bestätigen setzen, Teilnehmer-Panel anzeigen**

Erweitere den `name-confirm-btn`-Click-Handler in `wireOnboarding()`:

```javascript
document.getElementById('name-confirm-btn').addEventListener('click', () => {
  state.role = 'participant';
  state.myName = document.getElementById('name-select').value;
  state.myBuddy = resolveBuddy(state.myName, state.config.buddies);
  setRole('participant');
  setMyName(state.myName);
  render();
});
```

Ergänze in `render()`:

```javascript
if (state.role === 'participant') {
  document.getElementById('buddy-info').textContent = `Dein Buddy: ${state.myBuddy}`;
}
```

Falls die Seite mit bereits gespeicherter Rolle/Name neu geladen wird, muss
`state.myBuddy` auch dort gesetzt werden — ergänze in `init()` direkt nach
`state.config = await loadDojoConfig(state.dojoId);`:

```javascript
if (state.role === 'participant' && state.myName) {
  state.myBuddy = resolveBuddy(state.myName, state.config.buddies);
}
```

- [ ] **Step 4: `respondResolved`/`respondEscalate` und `requestHelp` implementieren, Button verdrahten**

`respondResolved`/`respondEscalate` sind schmale Publish-Wrapper, die sowohl
der Requester-Timeout (unten) als auch die Buddy-Buttons (Task 7) aufrufen —
deshalb hier zentral definiert:

```javascript
function respondResolved(from) {
  state.channel.publish('help:resolved', { from });
}

function respondEscalate(from, originalBuddy) {
  state.channel.publish('help:escalate', { from, originalBuddy });
}

function renderMyHelpStatus(status) {
  const el = document.getElementById('help-status');
  const labels = {
    idle: '',
    'waiting-for-buddy': `Anfrage an ${state.myBuddy} gesendet – wartet auf Reaktion...`,
    escalated: 'Keine Reaktion vom Buddy – an den Organizer eskaliert.',
  };
  el.textContent = labels[status] || '';
}

function requestHelp() {
  const timeoutMinutes = state.config.timer.buddy_timeout_minutes || 2;
  state.channel.publish('help:request', { from: state.myName, to: state.myBuddy });
  renderMyHelpStatus('waiting-for-buddy');
  state.pendingHelpTimeout = setTimeout(() => {
    respondEscalate(state.myName, state.myBuddy);
  }, timeoutMinutes * 60 * 1000);
}
```

Füge in `wireApp()` hinzu:

```javascript
const helpBtn = document.getElementById('help-btn');
if (helpBtn) helpBtn.addEventListener('click', requestHelp);
```

- [ ] **Step 5: Manuell verifizieren (nur Publish-Seite, Empfang folgt in Task 7)**

Run: als Teilnehmer "alice" einloggen, "Ich brauche Hilfe" klicken.
Expected: Statustext "Anfrage an bob gesendet – wartet auf Reaktion..."
erscheint; in einem anderen Tab (Konsole) wird
`Empfangen: help:request {from: "alice", to: "bob"}` geloggt.

- [ ] **Step 6: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add buddy resolution and help request publishing"
```

---

### Task 7: Buddy-Ansicht & Reaktionen (Erledigt / Eskalieren)

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `handleIncomingEvent`, `playTone`, `state.myName`, `state.channel`, `respondResolved(from)` und `respondEscalate(from, originalBuddy)` (beide bereits in Task 6 implementiert).
- Produces: `showBuddyHelpAlert(from)`, Buddy-Hilferuf-UI im Teilnehmer-Panel.

- [ ] **Step 1: Buddy-Hilferuf-UI und `showBuddyHelpAlert` ergänzen**

Füge im Teilnehmer-Panel-HTML hinzu:

```html
<div id="participant-panel" style="display:none;">
  <p id="buddy-info"></p>
  <button id="help-btn">Ich brauche Hilfe</button>
  <div id="help-status"></div>
  <div id="incoming-help-alert" style="display:none;"></div>
</div>
```

```javascript
function showBuddyHelpAlert(from) {
  const el = document.getElementById('incoming-help-alert');
  el.innerHTML = `
    <p>${from} braucht Hilfe!</p>
    <button id="resolve-btn-${from}">Erledigt</button>
    <button id="escalate-btn-${from}">Eskalieren</button>
  `;
  el.style.display = 'block';
  playTone(880, 500);
  document.getElementById(`resolve-btn-${from}`).addEventListener('click', () => {
    respondResolved(from);
    el.style.display = 'none';
  });
  document.getElementById(`escalate-btn-${from}`).addEventListener('click', () => {
    respondEscalate(from, state.myName);
    el.style.display = 'none';
  });
}
```

- [ ] **Step 2: `handleIncomingEvent` um `help:request` und `help:resolved` (eigene Auflösung) erweitern**

```javascript
function handleIncomingEvent(message) {
  const data = message.data;
  if (message.name === 'timer:start') {
    onTimerStart(data.startedAt);
  } else if (message.name === 'broadcast') {
    showBroadcastBanner(data.text);
  } else if (message.name === 'help:request') {
    if (state.role === 'participant' && data.to === state.myName) {
      showBuddyHelpAlert(data.from);
    }
    if (state.role === 'organizer') {
      addOrUpdateHelpEntry(data.from, data.to, 'buddy');
    }
  } else if (message.name === 'help:resolved') {
    if (data.from === state.myName && state.pendingHelpTimeout) {
      clearTimeout(state.pendingHelpTimeout);
      renderMyHelpStatus('idle');
    }
    if (state.role === 'organizer') {
      removeHelpEntry(data.from);
    }
  } else if (message.name === 'help:escalate') {
    if (data.from === state.myName) {
      renderMyHelpStatus('escalated');
    }
    if (state.role === 'organizer') {
      addOrUpdateHelpEntry(data.from, data.originalBuddy, 'escalated');
    }
  }
}
```

`addOrUpdateHelpEntry`/`removeHelpEntry` werden in Task 8 implementiert
(Organizer-Liste) — bis dahin dürfen sie als No-Op-Stubs existieren, damit
diese Task für sich lauffähig bleibt:

```javascript
function addOrUpdateHelpEntry(from, to, status) { /* siehe Task 8 */ }
function removeHelpEntry(from) { /* siehe Task 8 */ }
```

- [ ] **Step 3: Manuell verifizieren**

Run: Tab A als "alice", Tab B als "bob" (bobs Buddy ist alice).
In Tab A: "Ich brauche Hilfe" klicken.
Expected: In Tab B erscheint sofort ein Alert "alice braucht Hilfe!" mit
Ton und den Buttons "Erledigt"/"Eskalieren". Klick auf "Erledigt" in Tab B
lässt den Statustext in Tab A auf leer zurückspringen (Timeout wird
serverseitig via `clearTimeout` in Tab A gelöscht). Klick auf "Eskalieren"
lässt Tab A "Keine Reaktion vom Buddy – an den Organizer eskaliert."
anzeigen.

- [ ] **Step 4: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add buddy help alert with resolve/escalate actions"
```

---

### Task 8: Organizer-Live-Liste & automatische Timeout-Eskalation

**Files:**
- Modify: `viewer/keiko.html`

**Interfaces:**
- Consumes: `addOrUpdateHelpEntry`/`removeHelpEntry`-Aufrufe aus Task 7, `state.role`.
- Produces: `state.helpEntries` (Objekt `{[name]: {to, status}}`), `renderHelpList()`, Organizer-Panel-Erweiterung.

- [ ] **Step 1: `state.helpEntries` initialisieren und Liste im Organizer-Panel ergänzen**

Füge im HTML des Organizer-Panels hinzu:

```html
<div id="organizer-panel" style="display:none;">
  <button id="start-timer-btn">Keiko starten (60 Min)</button>
  <div>
    <input type="text" id="broadcast-input" placeholder="Nachricht an alle...">
    <button id="broadcast-send-btn">Senden</button>
  </div>
  <h3>Offene Hilferufe</h3>
  <div id="help-list"></div>
</div>
```

Ergänze `state.helpEntries = {};` direkt bei der Definition des globalen
`state`-Objekts.

- [ ] **Step 2: `addOrUpdateHelpEntry`, `removeHelpEntry`, `renderHelpList` implementieren (ersetzt die Stubs aus Task 7)**

```javascript
function addOrUpdateHelpEntry(from, to, status) {
  state.helpEntries[from] = { to, status };
  renderHelpList();
}

function removeHelpEntry(from) {
  delete state.helpEntries[from];
  renderHelpList();
}

function renderHelpList() {
  const container = document.getElementById('help-list');
  if (!container) return;
  const entries = Object.entries(state.helpEntries);
  container.innerHTML = '';
  if (!entries.length) { container.textContent = 'Keine offenen Hilferufe.'; return; }
  entries
    .sort(([, a], [, b]) => (b.status === 'escalated') - (a.status === 'escalated'))
    .forEach(([from, entry]) => {
      const div = document.createElement('div');
      div.className = entry.status === 'escalated' ? 'help-entry escalated' : 'help-entry';
      const strong = document.createElement('strong');
      strong.textContent = from;
      div.appendChild(strong);
      div.appendChild(document.createTextNode(
        ` → Buddy: ${entry.to} (${entry.status === 'escalated' ? 'ESKALIERT' : 'läuft mit Buddy'})`
      ));
      container.appendChild(div);
    });
}
```

Hinweis: `entry.to`/`from` werden hier per `textContent`/`createTextNode` statt `innerHTML`-Konkatenation eingefügt — gleiches Muster wie die XSS-Fixes in Task 1, Task 6 (Viewer-Plan) und Task 7 dieses Plans, von vornherein korrekt statt erst per Review nachgezogen.

- [ ] **Step 3: Ton bei Eskalation für Organizer ergänzen**

Erweitere den `help:escalate`-Zweig in `handleIncomingEvent`:

```javascript
} else if (message.name === 'help:escalate') {
  if (data.from === state.myName) {
    renderMyHelpStatus('escalated');
  }
  if (state.role === 'organizer') {
    addOrUpdateHelpEntry(data.from, data.originalBuddy, 'escalated');
    playTone(220, 700);
  }
}
```

- [ ] **Step 4: Manuell verifizieren**

Run: 3 Tabs — Organizer, "alice" (Teilnehmer), "bob" (Teilnehmer, alices
Buddy). In Tab "alice": "Ich brauche Hilfe" klicken.
Expected: Organizer-Tab zeigt sofort einen Eintrag "alice → Buddy: bob
(läuft mit Buddy)". Klickt "bob" auf "Eskalieren", ändert sich der
Organizer-Eintrag zu "ESKALIERT" (rot hinterlegt) mit hörbarem
Alarm-Ton. Klickt "bob" stattdessen auf "Erledigt", verschwindet der
Eintrag aus der Organizer-Liste komplett.

Run: Timeout-Test — `state.config.timer.buddy_timeout_minutes` in der
Konsole von Tab "alice" vor dem Klick auf `0.05` setzen (≈ 3 Sekunden),
dann "Ich brauche Hilfe" klicken und **nicht** auf "bob" reagieren.
Expected: Nach ca. 3 Sekunden eskaliert Tab "alice" automatisch (Statustext
wechselt auf "Keine Reaktion vom Buddy...", Organizer-Eintrag wird rot).

- [ ] **Step 5: Commit**

```bash
git add viewer/keiko.html
git commit -m "Add organizer live help-request list with auto-escalation"
```

---

### Task 9: Verbindungsfehler-Behandlung & manueller Multi-Tab-Testplan

**Files:**
- Modify: `viewer/keiko.html`
- Create: `viewer/keiko-testplan.md`

**Interfaces:**
- Consumes: `state.ably`.
- Produces: `showConnectionBanner(text)`/`hideConnectionBanner()`, Ably-Connection-State-Listener (kein neues Code-Interface für Folge-Tasks, letzte Task des Plans).

- [ ] **Step 1: Connection-Banner-Element und Handler ergänzen**

Füge im `<body>` direkt nach `<header>` ein:

```html
<div id="connection-banner" style="display:none; background:#ffebe9; color:#82071e; padding:0.5rem 1rem;"></div>
```

```javascript
function showConnectionBanner(text) {
  const el = document.getElementById('connection-banner');
  el.textContent = text;
  el.style.display = 'block';
}

function hideConnectionBanner() {
  document.getElementById('connection-banner').style.display = 'none';
}
```

- [ ] **Step 2: Ably-Connection-State-Listener in `connectAbly` ergänzen**

```javascript
async function connectAbly() {
  const key = await ensureAblyKey();
  state.ably = new Ably.Realtime({ key });
  state.channel = state.ably.channels.get(getChannelName(state.dojoId));
  state.channel.subscribe((message) => handleIncomingEvent(message));
  state.ably.connection.on('disconnected', () => showConnectionBanner('Verbindung getrennt, verbinde neu…'));
  state.ably.connection.on('suspended', () => showConnectionBanner('Verbindung unterbrochen, verbinde neu…'));
  state.ably.connection.on('connected', hideConnectionBanner);
}
```

- [ ] **Step 3: Manuell verifizieren**

Run: Seite öffnen, verbunden abwarten, dann WLAN/Netzwerk kurz trennen.
Expected: Rotes Banner "Verbindung getrennt, verbinde neu…" erscheint.
Nach Wiederherstellung der Verbindung verschwindet das Banner automatisch
(Ably reconnected selbstständig).

- [ ] **Step 4: `viewer/keiko-testplan.md` schreiben (Generalprobe vor dem echten Abend)**

```markdown
# Keiko-Tool – Testplan vor dem Dojo-Abend

Vorbereitung: `config.yaml` des Test-Dojos mit mind. 2 Buddy-Paaren,
Ably-Key griffbereit. 3 Browser-Fenster (1 normal + 2 Inkognito) öffnen.

- [ ] Fenster 1: Rolle "Organizer" wählen
- [ ] Fenster 2: Rolle "Teilnehmer", Name = erste Person eines Buddy-Paares
- [ ] Fenster 3: Rolle "Teilnehmer", Name = zweite Person desselben Paares
- [ ] Organizer startet Timer → Countdown läuft in allen 3 Fenstern synchron
- [ ] Organizer sendet manuellen Broadcast → Banner + Ton in allen 3 Fenstern
- [ ] Teilnehmer 1 klickt "Ich brauche Hilfe" → Alert + Ton bei Teilnehmer 2,
      Eintrag "läuft mit Buddy" beim Organizer
- [ ] Teilnehmer 2 klickt "Erledigt" → Status bei Teilnehmer 1 zurückgesetzt,
      Eintrag beim Organizer verschwindet
- [ ] Wiederholen, diesmal Teilnehmer 2 klickt "Eskalieren" → Organizer-
      Eintrag wird rot/"ESKALIERT" mit Alarm-Ton
- [ ] Wiederholen, diesmal Teilnehmer 2 reagiert gar nicht → nach
      `buddy_timeout_minutes` eskaliert Teilnehmer 1 automatisch
- [ ] Einen Tab kurz offline schalten (Flugmodus/WLAN aus) → Verbindungs-
      Banner erscheint, verschwindet nach Wiederverbindung
```

- [ ] **Step 5: Commit**

```bash
git add viewer/keiko.html viewer/keiko-testplan.md
git commit -m "Add connection error handling and pre-event test plan"
```
