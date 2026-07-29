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
      `buddy_timeout_minutes` eskaliert Teilnehmer 1 automatisch (und danach
      kommt **kein** zweiter/doppelter Alarm beim Organizer mehr an)
- [ ] Organizer klickt beim eskalierten Eintrag "Erledigt" (bzw. Teilnehmer 1
      klickt selbst "Erledigt") → Eintrag verschwindet dauerhaft bei allen
- [ ] Einen Tab kurz offline schalten (Flugmodus/WLAN aus) → Verbindungs-
      Banner erscheint, verschwindet nach Wiederverbindung
- [ ] Organizer setzt testweise ein Milestone mit niedrigem `at_minute` (z.B.
      1) in `config.yaml`, startet den Timer → Broadcast feuert automatisch
      genau einmal zum richtigen Zeitpunkt in allen Fenstern (nicht nur der
      manuelle "Senden"-Button)
- [ ] Ein Teilnehmer-Fenster neu laden, nachdem der Organizer den Timer
      gestartet hat → Countdown übernimmt den laufenden Timer per
      Ably-History-Catch-up, sofern der Reload kurz nach dem Start passiert
      (Ably behält History nur wenige Minuten vor; nach längerer Zeit bleibt
      der Countdown auf `--:--` – das ist die bekannte Grenze dieses
      Mechanismus, kein Bug)
- [ ] Nach einem Reload auf "🔊 Ton aktivieren" klicken → kurzer Bestätigungston
      ist hörbar, und nachfolgende Alarme/Broadcasts sind ebenfalls wieder
      hörbar (Autoplay-Policy blockiert sonst den AudioContext stumm)
- [ ] Absichtlich einen falschen Ably-Key eintragen → Fehlerbanner erscheint;
      über "Ably-Key ändern" im Header lässt sich der Key korrigieren und die
      Seite neu laden, ganz ohne DevTools
