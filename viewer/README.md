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

## Keiko Timer & Buddy (`keiko.html`)

1. URL bookmarken: `https://<owner>.github.io/rf-dojos/viewer/keiko.html?dojo=<dojo-id>&owner=<owner>`
   (`owner` nur nötig, falls die Seite nicht direkt unter `<owner>.github.io`
   aufgerufen wird).
2. Vorher in [ably.com](https://ably.com) eine App anlegen und einen API-Key
   mit den Capabilities `publish` **und** `subscribe` erzeugen. Dieser Key
   muss vor dem Event an alle Teilnehmer verteilt werden (z.B. per Chat) –
   jede:r trägt ihn beim ersten Öffnen einmalig ein (nur lokal im Browser
   gespeichert, wie beim GitHub-Token oben).
3. `config.yaml` des Dojos braucht dafür die Abschnitte `buddies:` (Liste von
   `{a, b}`-Paaren) und `timer:` (`duration_minutes`, `buddy_timeout_minutes`,
   `milestones:` mit `at_minute`/`message`). Wichtig: `at_minute` zählt
   **verstrichene** Minuten seit Timer-Start, nicht Uhrzeit – wird
   `duration_minutes` geändert, lohnt sich ein Blick, ob die Milestone-
   Zeitpunkte noch zum neuen Zeitrahmen passen.
4. Ably behält Channel-History standardmäßig nur wenige Minuten vor. Ein
   Teilnehmer, der die Seite lange nach dem Timer-Start neu lädt/öffnet, sieht
   den Countdown ggf. weiterhin als `--:--`, bis der Organizer erneut etwas
   published – das ist eine bekannte Grenze, kein Bug.
