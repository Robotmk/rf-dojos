# Viewer: Rundenbeschreibung inline & Dojo-Übersicht – Design

## Kontext

`viewer/index.html` (Hyōka-Viewer) zeigt aktuell in der linken Navigation
pro Runde nur den Titel; die Beschreibung (`round.description` aus
`config.yaml`) ist als natives `title`-Attribut (Browser-Tooltip) hinterlegt
und damit erst nach Hover sichtbar. Außerdem setzt der Viewer voraus, dass
die URL bereits einen `?dojo=<id>`-Parameter enthält – ohne diesen Parameter
versucht `init()` aktuell, ein Dojo mit `dojoId === null` zu laden, was in
einem 404 gegen die GitHub-API endet.

Dieses Design ergänzt zwei kleine, unabhängige UI-Verbesserungen im
bestehenden `viewer/index.html`:

1. Rundenbeschreibung wird sichtbar (nicht per Hover) unter dem Rundentitel
   angezeigt.
2. Wird der Viewer ohne `?dojo=`-Parameter geöffnet, zeigt er eine
   Übersicht aller im Repo vorhandenen Dojos zur Auswahl an, statt in einen
   Fehlerzustand zu laufen.

## Nicht-Ziele

- Keine Änderung an `viewer/keiko.html` oder am `config.yaml`-Schema.
- Keine zusätzliche Manifest-Datei zur Pflege der Dojo-Liste – die Liste
  wird zur Laufzeit über die GitHub-API ermittelt.
- Kein Anzeigen von Datum/Ziel-App in der Dojo-Liste – nur der Titel.

## 1. Rundenbeschreibung inline

`renderRoundsNav()` baut pro Runden-Eintrag (`<li>`) zwei Kindelemente statt
eines einzelnen Textknotens:

- Ein Element mit dem Rundentitel (`round.title`, per `textContent`).
- Ein `<small class="round-description">`-Element mit der Beschreibung
  (`round.description`, per `textContent`; leer, falls nicht gesetzt).

Das bisherige `li.title = round.description` (Tooltip) entfällt ersatzlos.
Neues CSS-Regel `.round-description` rendert die Beschreibung kleiner und in
gedämpfter Farbe (analog zu `#status-bar`s bestehendem Stil), damit sie sich
optisch klar vom Titel absetzt, ohne viel vertikalen Platz zu beanspruchen.

Alle dynamischen Werte werden weiterhin ausschließlich über `textContent`
gesetzt (kein `innerHTML`) – konsistent mit dem bereits mehrfach in diesem
Repo etablierten Sicherheitsmuster gegen HTML-Injection über
config-/repo-abgeleitete Strings.

## 2. Dojo-Übersicht als Startseite

**Auslöser:** `init()` prüft `state.dojoId` (aus `getUrlParam('dojo')`). Ist
er falsy (kein `?dojo=`-Parameter oder leer), wird statt der bisherigen
Kette (`loadConfig` → `loadOpenPRs`) eine neue Funktion `loadDojoList()`
aufgerufen; die restliche PR-/Config-Lade-Logik wird für diesen Fall
übersprungen.

**Datenermittlung:** `loadDojoList()` ruft `githubFetch('/repos/<owner>/rf-dojos/contents/dojos')`
auf (GitHub Contents API, listet den Inhalt des `dojos/`-Verzeichnisses).
Einträge mit `type !== 'dir'` werden verworfen. Für jeden verbleibenden
Verzeichnis-Eintrag (`entry.name` = Dojo-ID) wird anschließend dessen
`config.yaml` geladen (gleicher Mechanismus wie im bestehenden `loadConfig`,
inkl. UTF-8-sicherem Base64-Decode), um `dojo.title` zu extrahieren.
Schlägt das Laden/Parsen der `config.yaml` für ein einzelnes Dojo fehl
(kaputte YAML, fehlendes `dojo.title`), wird für diesen Eintrag ersatzweise
die Ordner-ID als Titel verwendet – ein einzelnes defektes Dojo darf nicht
die gesamte Liste verhindern (jeder Config-Ladevorgang läuft in einem
eigenen try/catch, Fehler werden nur in die Konsole geloggt).

**Sortierung:** alphabetisch nach Ordner-ID (`entry.name`), aufsteigend.

**Rendering:** Die Liste wird im bestehenden `#content`-Bereich als
`<ul>` mit einem `<li><a href="?dojo=<id>">…</a></li>` pro Dojo gerendert
(Linktext per `textContent`). Rounds-Navigation und Teilnehmer-Tabs bleiben
auf dieser Ansicht leer – dafür ist keine Sonderbehandlung nötig, da
`state.config`/`state.prs` in diesem Zustand ohnehin `null`/`[]` sind und
die bestehenden Render-Funktionen das bereits abfangen (Task 9 der
ursprünglichen Viewer-Implementierung). Der Header-Titel zeigt in diesem
Zustand einen generischen Text (z.B. „Dojos auswählen“) statt eines
Dojo-Titels.

**Fehlerbehandlung:** Schlägt der Contents-API-Call auf `dojos/` selbst fehl
(z.B. Rate Limit), greift der bereits bestehende Fehlerbanner-Mechanismus
(`showError`) aus der ursprünglichen Fehlerbehandlungs-Task unverändert.

## Testing

Wie beim Rest des Viewers: kein automatisiertes Test-Framework. Verifikation
über `node --check` (Syntax) sowie – wo isolierbar – Node-Scratch-Skripte für
reine Logikanteile (z.B. Sortierung/Filterung der Dojo-Liste, falls als
eigenständige Funktion umgesetzt). Interaktive Prüfung (klickbare Links,
sichtbare Beschreibungen) erfolgt manuell im Browser.

## Offene Entscheidungen

Keine – beide Punkte wurden mit dem Nutzer geklärt (Datenquelle: GitHub-API-
Scan von `dojos/`; Listen-Inhalt: nur Titel, sortiert nach Ordner-ID).
