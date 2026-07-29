# Remove Keiko Buddy/Timer Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the Ably-based Keiko buddy/timer tool (`viewer/keiko.html`) and every reference to it, restoring the buddy system to the purely organizational/offline process already described in `manual.md`.

**Architecture:** Pure deletion and documentation-trim work — no application logic changes. `viewer/index.html` (Hyōka viewer) is untouched and has no dependency on the removed tool.

**Tech Stack:** N/A — file deletions and Markdown/YAML edits only.

## Global Constraints

- `manual.md` bleibt vollständig unverändert (dortige „Keiko"-Erwähnungen sind der japanische Phasenname, kein Tool-Bezug).
- `docs/superpowers/specs/2026-07-28-keiko-buddy-timer-design.md` und `docs/superpowers/plans/2026-07-28-keiko-buddy-timer-tool.md` bleiben als historische Dokumente unverändert stehen — nicht löschen, nicht anpassen.
- `viewer/index.html` bleibt vollständig unverändert.
- Nach Abschluss darf `grep -ri "keiko\|ably" --include="*.md" --include="*.yaml" .` (außerhalb von `docs/superpowers/` und `manual.md`) keine Treffer mehr liefern.

---

### Task 1: Keiko-Tool und alle Referenzen entfernen

**Files:**
- Delete: `viewer/keiko.html`
- Delete: `viewer/keiko-testplan.md`
- Modify: `dojos/dojo-01-web-testing/config.yaml` (Abschnitte `buddies:`/`timer:` entfernen)
- Modify: `viewer/README.md` (Abschnitt „Keiko Timer & Buddy" entfernen)
- Modify: `SETUP.md` (komplette Neufassung ohne Keiko/Ably-Bezüge, siehe unten)

**Interfaces:** Keine — reine Lösch-/Textarbeit, keine Code-Schnittstellen betroffen.

- [ ] **Step 1: Dateien löschen**

```bash
git rm viewer/keiko.html viewer/keiko-testplan.md
```

- [ ] **Step 2: `config.yaml` bereinigen**

Entferne aus `dojos/dojo-01-web-testing/config.yaml` die kompletten Abschnitte
`buddies:` und `timer:` (inklusive aller Unterzeilen). Nach dem Entfernen
muss die Datei mit `dojo:` und `rounds:` enden (letzter Eintrag: die
`teardown`-Runde). Die Datei sieht danach so aus:

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
    filename_pattern: "*.robot|*.resource"

  - id: teardown
    title: "Teardown & Fehlerbehandlung"
    description: "Screenshot-Strategie, Cleanup, Suite Teardown"
    show: file
    filename_pattern: "*.robot"
    highlight: "Teardown|Screenshot|Run Keyword If Test Failed"
```

- [ ] **Step 3: `viewer/README.md` bereinigen**

Entferne den kompletten Abschnitt ab der Überschrift „## Keiko Timer &
Buddy (`keiko.html`)" bis zum Dateiende. Die Datei endet danach mit dem
bestehenden Punkt 4 (Tastatursteuerung):

```markdown
# Viewer – Bedienungsanleitung

1. Repo-Settings → Pages → Branch `main`, Ordner `/ (root)` (`/viewer` steht im
   Branch-Ordner-Dropdown nicht zur Auswahl; bei Root-Deployment bleibt
   `viewer/index.html` trotzdem unter demselben Pfad erreichbar).
2. URL bookmarken: `https://<owner>.github.io/rf-dojos/viewer/?dojo=<dojo-id>`
   Alternativ die Viewer-URL ohne `?dojo=` öffnen: dann erscheint eine
   Übersicht aller Dojos im Repo, aus der man das gewünschte anklicken kann.
3. Beim ersten Öffnen: GitHub Personal Access Token (Scope `public_repo`)
   eintragen. Wird nur lokal im Browser gespeichert.
4. Tastatursteuerung: `←`/`→` = Teilnehmer wechseln, `↑`/`↓` = Runde wechseln.
```

- [ ] **Step 4: `SETUP.md` komplett neu fassen**

Ersetze den gesamten Dateiinhalt durch folgende Fassung (Keiko/Ably-Abschnitt
entfernt, nachfolgende Abschnitte umnummeriert, `config.yaml`-Beispiel ohne
`buddies:`/`timer:`, Checkliste ohne Keiko-Punkte):

```markdown
# Einrichtung – von Null zum startklaren Dojo-Abend

Diese Anleitung führt einmalig durch die Einrichtung von GitHub Pages und
dem GitHub-Token für den Hyōka-Viewer. Sie richtet sich an den Organisator
(dich) – Teilnehmer brauchen in der Regel keinen eigenen Zugang, siehe
[Teil 3](#3-was-teilnehmer-brauchen).

---

## 1. Repo veröffentlichen & GitHub Pages aktivieren

1. Repo zu GitHub pushen (falls noch nicht geschehen):
   ```bash
   git remote add origin https://github.com/<dein-github-username>/rf-dojos.git
   git push -u origin main
   ```
2. In den Repo-Settings: **Settings → Pages**
   - **Source:** „Deploy from a branch"
   - **Branch:** `main`, Ordner **`/ (root)`**

   > ⚠️ `/viewer` steht im Ordner-Dropdown **nicht** zur Auswahl – GitHub Pages
   > bietet nur `/ (root)` oder `/docs` an. Mit `/ (root)` bleibt
   > `viewer/index.html` trotzdem exakt unter dem unten genannten Pfad
   > erreichbar, da bei Root-Deployment der komplette Branch gespiegelt wird.
3. Nach ca. 1 Minute ist die Seite live unter:
   ```
   https://<dein-github-username>.github.io/rf-dojos/
   ```
4. Repo öffentlich stellen, falls nicht schon geschehen (GitHub Pages ist bei
   privaten Repos nur mit GitHub-Team/Enterprise-Lizenz verfügbar).

---

## 2. Hyōka-Viewer – GitHub-Token einrichten

Der Viewer (`viewer/index.html`) lädt PRs, Dateibäume und Dateiinhalte über
die GitHub-API. Ohne Token: 60 Requests/Stunde (reicht nicht für einen
Abend). Mit Token: 5.000 Requests/Stunde.

1. Auf GitHub: **Settings → Developer settings → Personal access tokens →
   Tokens (classic) → Generate new token**
2. Scope: **`public_repo`** reicht, wenn das Repo öffentlich ist (kein
   Zugriff auf private Repos oder Account-Einstellungen nötig).
3. Token kopieren – **nicht** irgendwo im Repo speichern, nur für dich.
4. Viewer öffnen:
   ```
   https://<owner>.github.io/rf-dojos/viewer/?dojo=dojo-01-web-testing
   ```
   Alternativ die URL ohne `?dojo=...` öffnen – dann zeigt der Viewer eine
   Liste aller Dojos im Repo, von der aus man ins gewünschte springen kann.
5. Beim ersten Öffnen erscheint ein Dialog – Token dort eintragen. Es landet
   ausschließlich in `localStorage` des Browsers, nie im Repo. Falls du
   dich vertippst oder der Token abläuft: über den Button „Token ändern" im
   Header lässt er sich jederzeit zurücksetzen.

**Tastatursteuerung im Viewer:** `←`/`→` wechselt Teilnehmer, `↑`/`↓`
wechselt die Themen-Runde.

---

## 3. Was Teilnehmer brauchen

Teilnehmer brauchen für den Abend selbst kein eigenes Tool und keinen
eigenen Zugang. Das Buddy-System läuft rein organisatorisch (siehe
`manual.md`, Teil 1 „Das Buddy-System" und Regelwerk Punkt 5): Buddy-Paare
werden vorab vom Organisator zugeteilt und am Abend mündlich bekanntgegeben,
das 5-Minuten-Limit und die Zeitnahme handhabst du als Organisator selbst.

Der Hyōka-Viewer-Link ist nur für dich als Moderator relevant (Beamer/
Screen-Share während des Hyōka):
`https://<owner>.github.io/rf-dojos/viewer/?dojo=<dojo-id>`

---

## 4. `config.yaml` für ein Dojo anpassen

Datei: `dojos/<dojo-id>/config.yaml`. Wird vom Hyōka-Viewer gelesen.

```yaml
dojo:
  id: dojo-01-web-testing        # muss zum Ordnernamen passen
  title: "Web Testing Dojo #1"
  date: "2026-07-30"
  target_app: "https://www.saucedemo.com"

rounds:                          # Hyōka-Viewer: Themen-Runden
  - id: structure
    title: "Verzeichnisstruktur"
    description: "Wie ist das Projekt aufgebaut?"
    show: tree                   # tree | file
  # ... weitere Runden, siehe bestehende config.yaml als Vorlage
```

Für ein **neues Dojo**:
1. `dojos/dojo-02-<thema>/` anlegen, `config.yaml` + `README.md` +
   `submissions/_template/` analog zu `dojo-01-web-testing` kopieren.
2. Buddy-Paare vorab per Umfrage/Erfahrungslevel festlegen – organisatorisch,
   nicht im Repo gepflegt (siehe Teil 3).
3. URLs mit `?dojo=dojo-02-<thema>` statt `dojo-01-web-testing` verwenden.
4. An `viewer/index.html` selbst muss nichts verändert werden – es liest
   alles aus `config.yaml`.

---

## 5. Kurz-Checkliste am Abend selbst

- [ ] Beamer/Screen-Share für den Hyōka-Viewer funktioniert
- [ ] Buddy-Paare sind final festgelegt (nicht öffentlich sichtbar machen,
      nur für dich als Organizer relevant)
- [ ] Regelwerk (siehe `manual.md`) ausgedruckt oder auf Screen bereit
```

- [ ] **Step 5: Verifizieren**

Run: `python3 -c "import yaml; d = yaml.safe_load(open('dojos/dojo-01-web-testing/config.yaml')); assert 'buddies' not in d; assert 'timer' not in d; assert d['dojo']['id'] == 'dojo-01-web-testing'; assert len(d['rounds']) == 6; print('VALID')"`
Expected: `VALID`

Run: `grep -rli "keiko\|ably" --include="*.md" --include="*.yaml" . | grep -v "docs/superpowers" | grep -v "^\./manual.md$"`
Expected: keine Ausgabe (leer).

Run: `ls viewer/`
Expected: `README.md`, `index.html`, `logo.png` — kein `keiko.html`, kein `keiko-testplan.md`.

Lies `SETUP.md` einmal durch und bestätige: Abschnittsnummerierung ist
durchgehend (1–5), der Anker-Link „[Teil 3](#3-was-teilnehmer-brauchen)" in
der Einleitung passt zur tatsächlichen Abschnittsnummer.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Remove Keiko buddy/timer tool; buddy system runs offline per manual.md"
```
