# Viewer: Light/Dark-Theme-Toggle – Design

## Kontext

`viewer/index.html` ist aktuell fest auf ein helles Theme ausgelegt: die
CSS-Variablen im `:root`-Block (`--border`, `--bg-nav`, `--accent`) sowie
hart codierte Werte (`body { color: #1f2328; }`, impliziter weißer
Hintergrund, `.search-hit { background: #fff8c5; }`) gehen von einem
hellen Raum/Bildschirm aus. Der Monaco-Editor läuft mit dem eigenen
`rf-light`-Theme (`viewer/robotframework-language.js`).

Bei einer Live-Session in einem abgedunkelten Raum (Beamer/Projektor) ist
ein durchgängiges Dark-Theme angenehmer. Dieses Design ergänzt einen
Toggle-Button, der die komplette Viewer-Oberfläche (nicht nur den Editor)
zwischen hell und dunkel umschaltet.

## Nicht-Ziele

- Kein automatisches Folgen der Betriebssystem-Präferenz
  (`prefers-color-scheme`) – der Nutzer schaltet manuell um, Default ist
  immer hell.
- Keine weiteren Theme-Varianten (nur hell/dunkel, kein High-Contrast o.ä.).
- Keine Änderung an der RF-Tokenizer-Logik selbst (Sections, Variablen,
  Settings-Keywords etc.) – nur an den Farbwerten des neuen Dark-Themes.

## 1. CSS-Variablen: hell (bestehend) + dunkel (neu)

Erweiterung des bestehenden `:root`-Blocks um zwei neue Variablen
(`--bg-page`, `--text`), die die aktuell hart codierten Werte ablösen,
plus einen `:root[data-theme="dark"]`-Override-Block:

```css
:root {
  --border: #d0d7de; --bg-nav: #f6f8fa; --accent: #0969da;
  --bg-page: #ffffff; --text: #1f2328; --search-hit-bg: #fff8c5;
}
:root[data-theme="dark"] {
  --border: #30363d; --bg-nav: #161b22; --accent: #58a6ff;
  --bg-page: #0d1117; --text: #c9d1d9; --search-hit-bg: #4d3800;
}
body { background: var(--bg-page); color: var(--text); }
.search-hit { background: var(--search-hit-bg); }
```

Alle bestehenden Regeln, die `var(--border)`/`var(--accent)`/`var(--bg-nav)`
bereits nutzen (Header, `#rounds-nav`, `#participant-tabs`,
`#tab-bar`, `#explorer`), passen sich automatisch an, ohne selbst
geändert werden zu müssen – das ist der Grund, warum die bestehende
CSS-Variablen-Struktur beibehalten und nur erweitert wird. Elemente mit
hart codierten Hintergrundfarben (`background: white` bei
`#participant-tabs button`, `#tab-bar .tab`) bekommen `background:
var(--bg-page)` statt `white`.

Zwei weitere Stellen mit bisher hart codierten Farben, die für eine
wirklich durchgängige Umschaltung ebenfalls auf die neuen Variablen
umgestellt werden:

- `dialog#token-dialog` hat aktuell keine explizite Hintergrund-/Textfarbe
  (nutzt den Browser-Default, i.d.R. weiß) – bekommt
  `background: var(--bg-page); color: var(--text);` ergänzt, sonst leuchtet
  im Dark-Mode ein heller Dialog auf.
- Der Error-Banner (`#error-banner`) hat seine Farben aktuell inline im
  HTML (`style="...background:#ffebe9; color:#82071e;..."`), nicht im
  `<style>`-Block. Diese werden in eine CSS-Regel `#error-banner { ... }`
  überführt (mit einer eigenen dunklen Variante der Rot-Töne im
  `[data-theme="dark"]`-Block), damit auch Fehlermeldungen im Dark-Mode
  nicht unpassend hell aufblitzen.

## 2. Theme-Anwendung ohne Flackern

Ein kleines Inline-`<script>` direkt nach dem `<style>`-Block im `<head>`
(vor dem Rendern von `<body>`) liest den gespeicherten Wert und setzt das
`data-theme`-Attribut auf `<html>` sofort:

```html
<script>
  document.documentElement.dataset.theme = localStorage.getItem('rf_dojos_theme') || 'light';
</script>
```

Das verhindert ein kurzes Aufblitzen im hellen Theme beim Laden, falls
Dark-Mode gespeichert ist – die CSS-Regeln greifen dadurch schon beim
ersten Paint.

## 3. Toggle-Button im Header

Ein neuer Button `#theme-toggle-btn` im Header, positioniert vor „Zur
Startseite" (rechts vom `#dojo-select`-Dropdown):

```html
<button id="theme-toggle-btn" type="button" title="Theme wechseln">🌙</button>
```

Klick-Handler liest das aktuelle `data-theme`, schaltet um, aktualisiert
`localStorage`, das Button-Icon (🌙 im hellen Theme = „zu dunkel
wechseln", ☀️ im dunklen Theme = „zu hell wechseln") und ruft
`monaco.editor.setTheme(...)` auf (siehe Abschnitt 4). Falls der Toggle
geklickt wird, bevor Monaco geladen ist (Race mit dem AMD-Bootstrap), wird
der `monaco.editor.setTheme(...)`-Aufruf übersprungen – die CSS-Variablen
(Seiten-Theme) sind davon unabhängig und schalten in jedem Fall korrekt
um; sobald Monaco fertig geladen ist, übernimmt `ensureEditorInstance()`
ohnehin das zu diesem Zeitpunkt aktuell gespeicherte Theme beim Erzeugen
des Editors (`theme: currentMonacoTheme()`).

## 4. Zweites Monaco-Theme `rf-dark`

In `viewer/robotframework-language.js` wird neben `rf-light` ein
`rf-dark`-Theme definiert (Basis `vs-dark`, gleiche Token-Regeln wie
`rf-light`, angepasste Farben für dunklen Hintergrund):

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

`ensureEditorInstance()` erzeugt den Editor mit dem zum Ladezeitpunkt
aktuell gewählten Theme (`rf-light` oder `rf-dark`, abgeleitet aus
`document.documentElement.dataset.theme`), nicht mehr hart codiert mit
`theme: 'rf-light'`.

## 5. Persistenz

`localStorage`-Key `rf_dojos_theme` (Werte `'light'`/`'dark'`), analog zum
bestehenden `rf_dojos_github_token`-Pattern. Fehlt der Key (erster
Besuch), ist der Default `'light'`.

## Testing

Wie beim Rest des Viewers: kein automatisiertes Test-Framework.
Verifikation über `node --check` (Syntax) und manuelle Browser-Prüfung:
Toggle mehrfach klicken (Seite + Editor wechseln gemeinsam, kein
Flackern beim Reload nach dem Umschalten), Suche-Highlight im Dark-Mode
lesbar, bestehende Funktionen (Explorer, Tabs, Runden-/Teilnehmer-Wechsel)
unverändert in beiden Themes.

## Offene Entscheidungen

Keine – Umfang (ganze Oberfläche statt nur Editor), Persistenz
(localStorage, Default hell) und Icon/Position wurden mit dem Nutzer
geklärt.
