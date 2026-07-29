# rf-dojos – Technisches Konzept & Implementierungsbriefing

## Kontext

Die Robot Framework User Group München (RFUGM) führt regelmäßige "Dojo"-Abende durch.
Jeder Teilnehmer löst dieselbe Aufgabe individuell. In der Reviewphase (Hyōka) werden
die Lösungen **thematisch** verglichen – nicht monolithisch ("jetzt zeigt Person 1 alles,
dann Person 2 alles"), sondern Aspekt für Aspekt: erst alle Verzeichnisstrukturen,
dann alle Locator-Strategien, dann alle Custom Keywords usw.

Dieses Repo enthält:
- Die Aufgaben und Submissions aller Dojos
- Ein browserbasiertes Viewer-Tool (GitHub Pages) zum Live-Vergleich am Abend

---

## Repo-Struktur

```
rf-dojos/                          ← GitHub Repo (öffentlich)
│
├── README.md                      ← Beschreibung des Projekts
│
├── dojos/
│   ├── dojo-01-web-testing/
│   │   ├── config.yaml            ← Konfiguration dieses Dojos
│   │   ├── README.md              ← Aufgabenstellung für Teilnehmer
│   │   └── submissions/
│   │       └── _template/         ← Vorlage die jeder kopiert
│   │           ├── tests/
│   │           └── resources/
│   └── dojo-02-api-testing/       ← spätere Dojos gleiche Struktur
│       └── ...
│
└── viewer/
    ├── index.html                 ← GitHub Pages Tool (Single File)
    └── README.md                  ← Bedienungsanleitung
```

---

## config.yaml – Schema

Jedes Dojo hat eine eigene `config.yaml`. Sie ist die einzige Datei,
die für ein neues Dojo angepasst werden muss.

```yaml
# dojos/dojo-01-web-testing/config.yaml

dojo:
  id: dojo-01-web-testing
  title: "Web Testing Dojo #1"
  date: "2026-07-30"
  target_app: "https://www.saucedemo.com"

# Themen-Runden für den Hyōka
# Jede Runde fokussiert auf einen Aspekt aller Lösungen
rounds:
  - id: structure
    title: "Verzeichnisstruktur"
    description: "Wie ist das Projekt aufgebaut?"
    show: tree          # Anzeigemodus: tree | file | diff

  - id: test_structure
    title: "Test-Struktur"
    description: "Aufbau der .robot-Datei: Settings, Variables, Keywords, Test Cases"
    show: file
    filename_pattern: "*.robot"   # welche Datei(en) anzeigen

  - id: locators
    title: "Locator-Strategie"
    description: "Wie werden Elemente gefunden? CSS, XPath, ID, Playwright-native?"
    show: file
    filename_pattern: "*.robot"
    highlight: "locator|css|xpath|id="   # regex zum Highlighten relevanter Zeilen

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

---

## Submission-Workflow für Teilnehmer

### Vorbereitung (vor dem Abend, per E-Mail kommuniziert)

1. Repo forken: `github.com/[simon]/rf-dojos`
2. Branch anlegen: `git checkout -b dojo-01/[github-username]`
3. Submissions-Template kopieren:
   `cp -r dojos/dojo-01-web-testing/submissions/_template dojos/dojo-01-web-testing/submissions/[github-username]`
4. Aufgabe in `dojos/dojo-01-web-testing/README.md` lesen

### Am Abend

1. Test implementieren in `submissions/[github-username]/`
2. Committen und pushen
3. Pull Request öffnen gegen `main` des Original-Repos
   - PR-Titel: `[dojo-01] [github-username]`
   - Kein weiterer Text nötig

### Was der Viewer dann tut

- Liest alle offenen PRs des Repos
- Filtert nach PR-Titel-Pattern `[dojo-01]`
- Lädt die Dateien aus jedem PR-Branch via GitHub API
- Zeigt sie thematisch nach `config.yaml` rounds an

---

## Viewer – Technische Spezifikation

### Stack

- **Reines HTML/CSS/JS** – eine einzige Datei `viewer/index.html`
- Keine Build-Pipeline, kein npm, kein Framework
- Läuft auf **GitHub Pages** (kostenlos, automatisch aus dem Repo)
- Externe Abhängigkeiten nur via CDN:
  - [highlight.js](https://highlightjs.org/) für Syntax-Highlighting (Robot Framework)
  - Kein CSS-Framework – eigenes minimales Styling

### GitHub API Nutzung

**Alle Calls sind read-only und brauchen keine Org-Rechte.**

| Aktion | API Endpoint |
|---|---|
| PRs laden | `GET /repos/{owner}/rf-dojos/pulls?state=open` |
| Dateiliste eines PR | `GET /repos/{owner}/rf-dojos/git/trees/{sha}?recursive=1` |
| Dateiinhalt laden | `GET /repos/{owner}/rf-dojos/contents/{path}?ref={branch}` |
| config.yaml laden | `GET /repos/{owner}/rf-dojos/contents/dojos/{id}/config.yaml` |

**Rate Limit:**
- Ohne Token: 60 Requests/Stunde (zu knapp für einen Abend)
- Mit Personal Access Token (PAT): 5.000 Requests/Stunde (problemlos)

**Token-Handling:**
- Token wird **nicht** im Repo gespeichert (Sicherheit)
- Beim ersten Öffnen des Viewers: einmalige Eingabe in ein Textfeld
- Token wird in `localStorage` des Browsers gespeichert
- Bleibt lokal auf dem Präsentationsrechner, taucht nie in GitHub auf

### URL-Schema

Der Viewer wird mit URL-Parametern gesteuert – kein manuelles Eintippen am Abend:

```
https://[simon].github.io/rf-dojos/viewer/?dojo=dojo-01-web-testing
```

Du bookmarkst die URL vor dem Abend. Beim Öffnen lädt der Viewer
automatisch die passende `config.yaml` und alle PRs.

### UI-Struktur

```
┌─────────────────────────────────────────────────────────┐
│  RFUGM Dojo Viewer     │  Web Testing Dojo #1  │  ⚙️   │
├──────────────────┬──────────────────────────────────────┤
│  RUNDEN          │                                       │
│  ─────────────   │   [Teilnehmer-Tabs]                   │
│  ✓ Struktur      │   alice  bob  charlie  diana  …       │
│  → Locators      │  ─────────────────────────────────── │
│    Wait          │                                       │
│    Keywords      │   [Code-Anzeige mit Highlighting]     │
│    Teardown      │                                       │
│                  │   Relevante Zeilen werden             │
│  ─────────────   │   automatisch hervorgehoben           │
│  Teilnehmer:     │                                       │
│  8 / 8 PRs       │                                       │
└──────────────────┴──────────────────────────────────────┘
```

**Linke Spalte:** Themen-Runden aus `config.yaml` – du klickst eine Runde an

**Rechte Spalte oben:** Tabs für jeden Teilnehmer – du klickst durch

**Rechte Spalte unten:** Dateiinhalt mit Syntax-Highlighting, relevante Zeilen
(aus `highlight`-Pattern in config) werden farblich hervorgehoben

**Tastatursteuerung** (wichtig für flüssige Moderation):
- `←` / `→` – zwischen Teilnehmern wechseln
- `↑` / `↓` – zwischen Runden wechseln

### Anzeigemodi (aus config.yaml `show:`)

| Modus | Verhalten |
|---|---|
| `tree` | Zeigt Verzeichnisstruktur als ASCII-Tree |
| `file` | Zeigt Dateiinhalt, gefiltert nach `filename_pattern` |
| `diff` | Zeigt zwei Submissions nebeneinander (optional, später) |

---

## Wiederverwendbarkeit – neues Dojo anlegen

Für jedes neue Dojo:

1. Neuen Ordner anlegen: `dojos/dojo-02-api-testing/`
2. `config.yaml` kopieren und anpassen (Titel, Datum, Runden)
3. `README.md` mit neuer Aufgabe schreiben
4. `submissions/_template/` für das neue Thema anpassen
5. Viewer-URL bookmarken: `…/viewer/?dojo=dojo-02-api-testing`

Der Viewer selbst (`viewer/index.html`) wird **nicht** angefasst.

---

## Implementierungsreihenfolge

Empfohlene Reihenfolge für die Umsetzung in Claude Code:

### Schritt 1 – Repo-Grundstruktur
- `README.md` (Projekt-Beschreibung)
- `dojos/dojo-01-web-testing/README.md` (Aufgabenstellung)
- `dojos/dojo-01-web-testing/config.yaml` (nach obigem Schema)
- `dojos/dojo-01-web-testing/submissions/_template/` (leere RF-Struktur)

### Schritt 2 – Viewer Grundgerüst
- `viewer/index.html` als Single-File-App
- Token-Eingabe beim ersten Start, localStorage-Persistenz
- GitHub API: PRs laden, nach Dojo-ID filtern
- Linke Navigation: Runden aus config.yaml
- Rechte Spalte: Teilnehmer-Tabs

### Schritt 3 – Datei-Anzeige
- Dateibaum-Ansicht (Modus `tree`)
- Dateiinhalt-Ansicht (Modus `file`) mit highlight.js
- Regex-Highlighting für konfigurierte Patterns

### Schritt 4 – Tastatursteuerung & UX
- Pfeiltasten-Navigation
- Ladezustand anzeigen (API-Calls dauern kurz)
- Fehlerbehandlung: PR fehlt, Datei nicht gefunden, Rate Limit

### Schritt 5 – GitHub Pages aktivieren
- In Repo-Settings: Pages auf Branch `main`, Ordner `/viewer`
- URL testen: `https://[owner].github.io/rf-dojos/viewer/`

---

## Offene Entscheidungen (vor Implementierungsstart klären)

1. **GitHub Username** des Repo-Owners – für alle API-URLs nötig
2. **Repo öffentlich oder privat?** – GitHub Pages kostenlos nur bei öffentlich
3. **Token-Scope** – `public_repo` reicht wenn Repo öffentlich ist
4. **Sollen alte Dojos archiviert werden?** – PRs bleiben offen oder werden nach dem Abend geschlossen/gemergt?