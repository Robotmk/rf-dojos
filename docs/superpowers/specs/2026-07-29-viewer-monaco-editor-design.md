# Viewer: Monaco-Editor mit RF-Highlighting statt starrem Datei-Pattern – Design

## Kontext

`viewer/index.html` zeigt Dateiinhalte aktuell in einem `<pre><code>`
(`renderFileView`), ohne echtes Syntax-Highlighting – nur ganze Zeilen werden
per Regex (`round.highlight`) gelb hinterlegt. Welche Dateien überhaupt
angezeigt werden, bestimmt `round.filename_pattern` (ein einzelner Glob-String
wie `"*.robot"`).

Das Problem: `filename_pattern` ist reines Dateinamen-Matching, kein
inhaltliches Verständnis. Beim Hyōka vergleichen sich Lösungen verschiedener
Teilnehmer thematisch – wenn jemand für eine Runde wie "Locator-Strategie"
seine Daten z.B. aus einer `.yaml`-Datei lädt statt direkt im `.robot`-File,
blendet der aktuelle Mechanismus diese Datei komplett aus. Der Moderator sieht
die abweichende Lösung nicht, obwohl sie für den Vergleich relevant wäre.

Dieses Design ersetzt den Datei-Anzeige-Teil des Viewers durch:

1. Einen Monaco-Editor (read-only) mit eigenem, schlankem RF-Syntax-Tokenizer,
   im hellen Theme.
2. Eine immer volle Datei-Explorer-Ansicht (mit optionalem
   Blacklist/Whitelist-Filter) statt einer strikten Whitelist über
   `filename_pattern`.
3. Ein `search`-Feld pro Runde, das Treffer **im gesamten Dateibaum** der
   Submission markiert (nicht nur in "erwarteten" Dateitypen) und im Explorer
   sichtbar macht.

## Nicht-Ziele

- Keine Änderung an der GitHub-API-Anbindung (PRs laden, Dateiinhalt laden) –
  nur an der Anzeige der geladenen Inhalte.
- Kein Language Server/RobotCode/robotframework-lsp – keine semantische
  Analyse, keine Keyword-/Library-Auflösung, keine Diagnostics. Nur
  lexikalisches Syntax-Highlighting.
- Kein `show: diff`-Modus in diesem Design (bleibt möglich als spätere
  Erweiterung dank Monacos eingebautem Diff-Editor, ist aber nicht Teil
  dieses Scopes).
- Kein Build-Schritt/npm für den Viewer – bleibt Single-File-HTML mit
  vendorten/CDN-artigen `<script>`-Einbindungen wie bisher.

## 1. Editor-Technologie: Monaco, vendored, eigener Monarch-Tokenizer

Monaco wird **nicht per Live-CDN**, sondern als vendorte Kopie unter
`viewer/vendor/monaco/` im Repo eingebunden (AMD-Loader-Pattern, wie in
Monacos offiziellen Standalone-Beispielen beschrieben). Grund: an einem
Dojo-Abend darf der Viewer nicht vom Venue-WLAN abhängen; ein einmaliger
Git-Bloat von wenigen MB ist der sicherere Trade gegenüber einem
CDN-Ausfallrisiko live vor Publikum.

Für Robot-Framework-Highlighting wird ein **eigener Monarch-Tokenizer**
geschrieben (Monacos eingebaute Tokenizer-DSL, kein TextMate-Grammar, kein
Oniguruma-WASM). Er deckt ab:

- Section-Header (`*** Settings ***`, `*** Variables ***`, `*** Test Cases ***`,
  `*** Keywords ***`)
- Variablen-Syntax (`${var}`, `@{list}`, `&{dict}`)
- Settings-Keywords (`Library`, `Resource`, `Variables`, `Suite Setup`,
  `Suite Teardown`, `Test Setup`, `Test Teardown`, `Documentation`, …)
- Kommentare (`#`)
- Spalten-Trennung (mehrere Leerzeichen / Pipe-Syntax)

Es findet **keine Library- oder Keyword-Auflösung** statt – der Tokenizer
tokenisiert rein lexikalisch. Damit entfällt das Problem "Library nicht
gefunden" grundsätzlich: es gibt keinen Schritt, der versucht, Libraries
aufzulösen. RobotCode/robotframework-lsp sind VS-Code-Extensions mit
Python-Language-Server-Prozess im Hintergrund – das ist für eine statische
GitHub-Pages-Seite ohne Backend nicht einsetzbar und für reines Highlighting
auch nicht nötig.

Theme: Monacos eingebautes `vs`-Light-Theme als Basis, mit
`monaco.editor.defineTheme(...)`-Anpassung der Token-Farben, damit sie zum
bestehenden hellen UI (`--accent: #0969da` etc.) passen.

Editor-Instanz-Pattern: **eine** Monaco-Editor-Instanz wird einmal erzeugt;
beim Wechsel von Teilnehmer/Runde/Tab wird nur `editor.setModel(...)` mit dem
passenden (ggf. neu erzeugten) `ITextModel` aufgerufen, statt den Editor neu
zu instanzieren. Das hält Teilnehmer-/Runden-Wechsel spürbar schnell.

## 2. Config-Schema: `explorer` + `search` statt `filename_pattern`

```yaml
# Optionaler Dojo-weiter Default (gilt für alle Runden, sofern nicht
# pro Runde überschrieben):
dojo:
  id: dojo-01-web-testing
  title: "Web Testing Dojo #1"
  date: "2026-07-30"
  target_app: "https://sampleapp.tricentis.com/101/"
  explorer_blacklist: ["*_template*", "*.png", "*.pyc", "__pycache__/*"]

rounds:
  - id: locators
    title: "Locator-Strategie"
    description: "Wie werden Elemente gefunden? CSS, XPath, ID, Playwright-native?"
    show: file
    explorer:
      blacklist: []      # optional, wird zu dojo.explorer_blacklist hinzugefügt (Union, kein Override)
      whitelist: []       # optional; wenn nicht-leer: NUR diese Muster im Explorer zeigen
    default_open: ["tests/*.robot"]      # Datei(en), die beim Runden-/Teilnehmerwechsel automatisch als Tab öffnen
    search: "locator|css|xpath|id="       # regex; markiert Treffer im offenen Editor + Badge im Explorer
```

Feld-Semantik:

- `explorer.blacklist` / `explorer.whitelist`: Listen von Glob-Patterns
  (gematcht wie das bisherige `filename_pattern`, per `|`-Split intern zu
  Regexes kompiliert). Effektive Blacklist einer Runde = `dojo.explorer_blacklist`
  ∪ `round.explorer.blacklist` (Union, kein Override). Blacklist blendet
  Treffer aus dem Baum aus. Ist `round.explorer.whitelist` nicht-leer, wird
  sie **zusätzlich** angewendet (nur Treffer aus der Whitelist werden
  gezeigt, davon wiederum Blacklist-Treffer entfernt). Beide sind optional;
  ohne beide zeigt der Explorer den vollen Baum.
- `default_open`: Liste von Glob-Patterns; alle im Dateibaum matchenden
  Pfade werden beim Runden-/Teilnehmerwechsel automatisch als Editor-Tabs
  geöffnet (siehe Abschnitt 3 zu Tab-Verhalten).
- `search`: Regex (wie bisheriges `highlight`), aber mit erweiterter
  Wirkung: (a) markiert Treffer-Zeilen im aktuell offenen Editor-Tab
  (Monaco-Decorations statt HTML-`<span>`), (b) wird zusätzlich gegen **alle**
  Dateien der Submission geprüft (nach Anwendung von blacklist/whitelist),
  und jede Datei mit mindestens einem Treffer bekommt ein Badge/Icon im
  Explorer-Baum – unabhängig davon, ob sie in `default_open` gelistet ist.

`filename_pattern` und `highlight` (alte Feldnamen) entfallen ersatzlos aus
dem Schema; bestehende `config.yaml`-Dateien (aktuell nur
`dojos/dojo-01-web-testing/config.yaml`) werden im Zuge der Implementierung
auf das neue Schema migriert.

## 3. Layout & Interaktion

```text
┌────────────────────────────────────────────────────────────────────────┐
│  RFUGM Dojo Viewer     Web Testing Dojo #1                       ⚙️    │
├───────────┬────────────────────────────────────────────────────────────┤
│ RUNDEN    │  alice   bob   charlie   diana  …        (Teilnehmer-Tabs)  │
│ ───────   ├───────────┬────────────────────────────────────────────────┤
│ ✓ Struktur│ EXPLORER  │  locators.robot ✕   elements.yaml ✕            │
│ → Locators│ ▾ tests/  │ ┌────────────────────────────────────────────┐ │
│   Wait    │   login.. │ │ 1  *** Settings ***                        │ │
│   Keywords│ ▾ resourc.│ │ 2  Library    Browser                      │ │
│   Teardown│   locators│ │ 3  Resource   ../resources/locators.resource│ │
│           │ ▾ data/   │ │ ...                                        │ │
│           │  🔶elements│ │  (Monaco, RF-Highlighting, read-only,     │ │
│           │   .yaml   │ │   Treffer aus "search" gelb markiert)      │ │
│ ────────  │           │ └────────────────────────────────────────────┘ │
│ 8/8 PRs   │           │                                                │
└───────────┴───────────┴────────────────────────────────────────────────┘
```

- **Explorer (links, innerhalb des Content-Bereichs):** immer der volle
  Baum der Submission (Quelle: bestehender `loadFileTree`-Aufruf), gefiltert
  nur nach `explorer.blacklist`/`explorer.whitelist` der aktuellen Runde
  (bzw. Dojo-Default). Dateien mit `search`-Treffer erhalten ein
  Badge-Icon.
- **Tabs im Editor-Bereich:** Beim Runden- oder Teilnehmerwechsel werden die
  Tabs auf die `default_open`-Treffer der aktuellen Runde **zurückgesetzt**
  (kein Anhäufen über Personen/Runden hinweg). Innerhalb einer
  Person/Runde darf der Moderator beliebig zusätzliche Dateien aus dem
  Explorer anklicken; diese bleiben offen, bis er sie schließt oder
  Teilnehmer/Runde wechselt.
- **Theme:** Monaco `vs`-Light (siehe Abschnitt 1).
- **Tastatursteuerung:** unverändert (←/→ Teilnehmer, ↑/↓ Runden); zusätzlich
  steht Monacos eingebaute In-Editor-Suche (Strg+F) im aktiven Tab zur
  Verfügung.
- Der bisherige `show: tree`-Modus (reine ASCII-Baum-Ansicht ohne Editor,
  z.B. für die "Verzeichnisstruktur"-Runde) bleibt unverändert bestehen –
  dieses Design betrifft nur `show: file`.

## 4. Performance & Hosting

- RF-Submission-Dateien sind klein (üblicherweise deutlich unter 500
  Zeilen); Monacos virtualisiertes Rendering macht das trivial – keine
  Performance-Bedenken beim reinen Anzeigen.
- Die eigentliche Latenz bleibt wie bisher die GitHub-API (Dateien laden
  pro Klick) – daran ändert der Editor-Wechsel nichts.
- Monaco-Assets (~3–5 MB) werden einmalig beim ersten Laden der
  Viewer-Seite aus `viewer/vendor/monaco/` geladen und vom Browser
  gecacht; danach kein weiterer Ladevorgang nötig, solange die Seite nicht
  neu geladen wird. **Operativer Hinweis (kein Code-Punkt):** Der
  Moderator sollte die Viewer-Seite vor dem Abend einmal warmladen, damit
  der erste Request nicht am Abend selbst vom Venue-WLAN abhängt. Gehört
  in die bestehende Setup-Checkliste (`SETUP.md`/`ORGANISATOR.md`).

## Testing

Wie beim Rest des Viewers: kein automatisiertes Test-Framework. Verifikation
über `node --check` (Syntax) sowie manuelle Prüfung im Browser: Monarch-
Tokenizer gegen reale Submission-Dateien (Sections, Variablen, Settings
korrekt eingefärbt), Explorer-Filterung (blacklist/whitelist-Kombinationen),
Search-Badges auf Dateien außerhalb `default_open`, Tab-Reset beim
Teilnehmer-/Rundenwechsel.

## Offene Entscheidungen

Keine – Editor-Technologie (Monaco, vendored, eigener Monarch-Tokenizer),
Explorer-Verhalten (immer voll, blacklist/whitelist-Filter), Config-Schema
(`explorer`/`default_open`/`search`) und Tab-Verhalten (Reset pro
Teilnehmer/Runde) wurden mit dem Nutzer geklärt.
