# Einrichtung – von Null zum startklaren Dojo-Abend

Diese Anleitung führt einmalig durch die Einrichtung von GitHub Pages, dem
GitHub-Token für den Hyōka-Viewer und dem Ably-Key für das Keiko-Tool. Sie
richtet sich an den Organisator (dich) – Teilnehmer brauchen nur die fertigen
URLs und ggf. den Ably-Key, siehe [Teil 4](#4-was-teilnehmer-brauchen).

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
5. Beim ersten Öffnen erscheint ein Dialog – Token dort eintragen. Es landet
   ausschließlich in `localStorage` des Browsers, nie im Repo. Falls du
   dich vertippst oder der Token abläuft: über den Button „Token ändern" im
   Header lässt er sich jederzeit zurücksetzen.

**Tastatursteuerung im Viewer:** `←`/`→` wechselt Teilnehmer, `↑`/`↓`
wechselt die Themen-Runde.

---

## 3. Keiko-Tool – Ably einrichten

Das Keiko-Tool (`viewer/keiko.html`, Timer + Buddy-System) synchronisiert
alle Browser-Tabs live über [Ably](https://ably.com), einen Pub/Sub-Dienst.
Kein eigener Server nötig.

1. Kostenlosen Account auf [ably.com](https://ably.com) anlegen.
2. Eine neue **App** anlegen (z.B. „rf-dojos-keiko").
3. Im App-Dashboard unter **API Keys** einen Key mit den Capabilities
   **`publish`** und **`subscribe`** erzeugen (keine weiteren Rechte nötig –
   insbesondere keine Channel-Administration).
4. Diesen Key **vor dem Abend an alle Teilnehmer verteilen** (z.B. per Slack/
   Discord/E-Mail) – jede:r trägt ihn beim ersten Öffnen des Tools einmalig
   ein. Auch dieser Key landet nur lokal in `localStorage`, analog zum
   GitHub-Token. Falscher/kaputter Key lässt sich über „Ably-Key ändern" im
   Header jederzeit korrigieren.
5. URL für dich (Organizer) und alle Teilnehmer:
   ```
   https://<owner>.github.io/rf-dojos/viewer/keiko.html?dojo=dojo-01-web-testing
   ```
   Falls die Seite mal nicht unter `<owner>.github.io` läuft, zusätzlich
   `&owner=<owner>` an die URL anhängen.
6. Beim ersten Öffnen: Rolle wählen (**Organizer** für dich, **Teilnehmer**
   für alle anderen) und bei Teilnehmern zusätzlich den eigenen Namen aus der
   Liste (kommt aus `config.yaml`, siehe Teil 4).

**Bekannte Grenzen (kein Bug):**
- Ably behält die Channel-History nur wenige Minuten vor. Ein Teilnehmer,
  der lange nach dem Timer-Start neu lädt, sieht ggf. weiterhin `--:--`.
- Nach einem Reload ist der Ton stumm, bis einmal auf „🔊 Ton aktivieren"
  geklickt wird (Browser-Autoplay-Policy).

---

## 4. Was Teilnehmer brauchen

Kurzfassung für die Ankündigungs-Mail vor dem Abend:

- **Hyōka-Viewer-Link** (nur für dich als Moderator relevant, Teilnehmer
  brauchen ihn i.d.R. nicht): `https://<owner>.github.io/rf-dojos/viewer/?dojo=<dojo-id>`
- **Keiko-Tool-Link** (für alle): `https://<owner>.github.io/rf-dojos/viewer/keiko.html?dojo=<dojo-id>`
- **Ably-Key** zum Eintragen im Keiko-Tool (von dir verteilt, siehe Teil 3)
- Beim Öffnen: Rolle „Teilnehmer" wählen, eigenen Namen aus der Liste
  auswählen.

---

## 5. `config.yaml` für ein Dojo anpassen

Datei: `dojos/<dojo-id>/config.yaml`. Wird von **beiden** Tools gelesen.

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

buddies:                         # Keiko-Tool: Buddy-Paare
  - a: alice
    b: bob
  - a: charlie
    b: diana

timer:                           # Keiko-Tool: Timer-Einstellungen
  duration_minutes: 60
  buddy_timeout_minutes: 2       # nach dieser Zeit ohne Reaktion eskaliert
                                  # ein Hilferuf automatisch zum Organizer
  milestones:
    - at_minute: 45               # verstrichene Minuten seit Timer-Start,
      message: "Noch 15 Minuten!" # NICHT Uhrzeit
    - at_minute: 58
      message: "Zeit ist um – bitte aufräumen für die Präsentation."
```

**Wichtig:** `at_minute` zählt ab dem Moment, in dem der Organizer den Timer
startet – nicht ab Mitternacht o.ä. Wird `duration_minutes` geändert, prüfen
ob die Milestone-Zeitpunkte noch sinnvoll sind (z.B. bei 90 statt 60 Minuten
sollte „Noch 15 Minuten" bei `at_minute: 75` liegen, nicht `45`).

Für ein **neues Dojo**:
1. `dojos/dojo-02-<thema>/` anlegen, `config.yaml` + `README.md` +
   `submissions/_template/` analog zu `dojo-01-web-testing` kopieren.
2. Buddy-Paare vorab per Umfrage/Erfahrungslevel festlegen und eintragen.
3. URLs mit `?dojo=dojo-02-<thema>` statt `dojo-01-web-testing` verwenden.
4. An `viewer/index.html`/`viewer/keiko.html` selbst muss nichts verändert
   werden – beide lesen alles aus `config.yaml`.

---

## 6. Vor dem echten Abend: Generalprobe

Vollständigen Testlauf mit mehreren Browser-Fenstern (Organizer + 2
Teilnehmer aus einem Buddy-Paar) durchführen – Checkliste in
[`viewer/keiko-testplan.md`](viewer/keiko-testplan.md). Deckt u.a. ab:
Timer-Sync, manuelle und automatische Broadcasts, Buddy-Hilferuf inkl.
Eskalation/Timeout, Verbindungsabbruch, Ton nach Reload, falscher Ably-Key.

---

## 7. Kurz-Checkliste am Abend selbst

- [ ] Beamer/Screen-Share für den Hyōka-Viewer funktioniert
- [ ] Keiko-Tool-Link + Ably-Key wurden vorab an alle verteilt
- [ ] Buddy-Paare in `config.yaml` sind final (nicht öffentlich sichtbar
      machen, nur für dich als Organizer relevant)
- [ ] Eigenes Gerät: Rolle „Organizer" gewählt, Timer noch nicht gestartet
- [ ] Regelwerk (siehe `manual.md`) ausgedruckt oder auf Screen bereit
