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
