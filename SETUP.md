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
   Die Liste aller Dojos zum Reinspringen steht auf der
   [Startseite](README.md#mitmachen) – nicht im Viewer.
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
`ORGANISATOR.md`, Teil 1 „Das Buddy-System" und Regelwerk Punkt 5): Buddy-Paare
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
  explorer_blacklist: ["*.png", "*.pyc", "*__pycache__/*", "output.xml"]

rounds:                          # Hyōka-Viewer: Themen-Runden
  - id: structure
    title: "Verzeichnisstruktur"
    description: "Wie ist das Projekt aufgebaut?"
    show: tree                   # tree | file
  - id: locators
    title: "Locator-Strategie"
    description: "Wie werden Elemente gefunden?"
    show: file
    default_open: ["tests/*.robot"]     # welche Datei(en) beim Öffnen der Runde aktiv sind
    explorer:
      blacklist: ["*.md"]               # rundenspezifisch, zusätzlich zum dojo-weiten explorer_blacklist
      whitelist: ["tests/*", "resources/*"]  # falls gesetzt: NUR diese Dateien werden überhaupt angezeigt
    search: "locator|css|xpath|id="     # markiert Dateien mit Treffern im Explorer (🔶)
  # ... weitere Runden, siehe bestehende config.yaml als Vorlage
```

**Wichtige Semantik der neuen Felder** (Task 1-8 dieses Plans):
- `explorer_blacklist` (Dojo-Ebene) und `explorer.blacklist` (Runden-Ebene) werden
  **vereinigt** (union), nie ersetzt – eine Runde kann also nur zusätzliche
  Muster hinzufügen, nicht dojo-weite Muster wieder freischalten.
- Glob-Muster werden relativ zum Wurzelverzeichnis der jeweiligen Einreichung
  (`dojos/<dojo-id>/submissions/<teilnehmer>/`) abgeglichen. `*` matcht dabei
  auch über `/` hinweg (es gibt kein separates `**`) – z. B. matcht
  `*__pycache__/*` sowohl `__pycache__/x.pyc` als auch
  `resources/__pycache__/x.pyc`.
- `default_open` wird gegen **alle** Dateien geprüft (ungefiltert) – auch
  gegen vom Explorer-Filter eigentlich ausgeblendete Dateien. Das ist so
  gewollt (z. B. um bewusst eine geblacklistete Datei vorzuöffnen).
- `search`-Badges (🔶 im Explorer) werden dagegen nur für die nach
  Blacklist/Whitelist **sichtbaren** (gefilterten) Dateien berechnet.

Für ein **neues Dojo**:
1. `dojos/dojo-02-<thema>/` anlegen, `config.yaml` + `README.md` +
   `submissions/_template/` analog zu `dojo-01-web-testing` kopieren.
2. Buddy-Paare vorab per Umfrage/Erfahrungslevel festlegen – organisatorisch,
   nicht im Repo gepflegt (siehe Teil 3).
3. URLs mit `?dojo=dojo-02-<thema>` statt `dojo-01-web-testing` verwenden.
4. An `viewer/index.html` selbst muss nichts verändert werden – es liest
   alles aus `config.yaml`.

---

## 5. Kurz-Checkliste

### Vor dem Abend

- [ ] Viewer einmal vor dem Abend im Zielbrowser öffnen (mit echtem
      `?dojo=`-Parameter), damit die vendorten Monaco-Editor-Assets
      (~mehrere MB, `viewer/vendor/monaco/`) bereits im Browser-Cache liegen.
      Verhindert, dass der erste Request am Abend selbst vom Venue-WLAN
      abhängt.
- [ ] Buddy-Paare sind final festgelegt (nicht öffentlich sichtbar machen,
      nur für dich als Organizer relevant)

### Am Abend selbst

- [ ] Beamer/Screen-Share für den Hyōka-Viewer funktioniert
- [ ] Regelwerk (siehe `TEILNEHMER.md`) ausgedruckt oder auf Screen bereit
