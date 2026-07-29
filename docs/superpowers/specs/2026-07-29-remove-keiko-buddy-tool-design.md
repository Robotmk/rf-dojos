# Rückbau: Keiko-Buddy/Timer-Tool entfernen – Design

## Kontext

Das Keiko-Buddy/Timer-Tool (`viewer/keiko.html`, Ably-basiert: Timer,
Meilenstein-Broadcasts, Buddy-Hilferuf mit Ton) wurde in einer früheren
Session vollständig gebaut und final reviewt. Der Nutzer hat entschieden,
dass dies zu viel Komplexität für den eigentlichen Zweck ist. Das
Buddy-System soll stattdessen rein offline/organisatorisch laufen, wie es
`manual.md` bereits beschreibt (Buddy-Paare vorab zuteilen, 5-Minuten-Limit,
Organisator als zweite Lifeline) – ganz ohne digitales Tool.

## Ziel

`viewer/keiko.html` und alle zugehörigen Ably-/Timer-/Ton-Bezüge werden aus
dem aktiven Repo-Inhalt entfernt: kein totes UI-Feature, keine veraltete
Setup-Anleitung, kein ungenutztes `config.yaml`-Schema.

## Umfang

**Löschen:**
- `viewer/keiko.html`
- `viewer/keiko-testplan.md`

**Anpassen:**
- `dojos/dojo-01-web-testing/config.yaml`: Abschnitte `buddies:` und
  `timer:` entfernen. `dojo:` und `rounds:` bleiben unverändert.
- `viewer/README.md`: Abschnitt „## Keiko Timer & Buddy (`keiko.html`)"
  komplett entfernen.
- `SETUP.md`: Abschnitt „## 3. Keiko-Tool – Ably einrichten" entfernen,
  sowie alle Verweise darauf in:
  - Abschnitt 1 Einleitung (nennt aktuell „Ably-Key für das Keiko-Tool")
  - Abschnitt 4 „Was Teilnehmer brauchen" (Keiko-Tool-Link, Ably-Key-Zeile)
  - Abschnitt 6 „Generalprobe" (verweist auf `keiko-testplan.md`)
  - Abschnitt 7 Checkliste (Keiko-Tool-Link/Ably-Key-Punkt)
  - Nachfolgende Abschnittsnummern entsprechend anpassen, damit die
    Nummerierung durchgehend bleibt.

## Nicht-Ziele / bleibt unverändert

- `manual.md` – die dortigen „Keiko"-Erwähnungen bezeichnen die japanische
  Übungsphase, nicht das Tool, und werden nicht angefasst.
- `docs/superpowers/specs/2026-07-28-keiko-buddy-timer-design.md` und
  `docs/superpowers/plans/2026-07-28-keiko-buddy-timer-tool.md` – historische
  Design-/Plan-Dokumente bleiben als Aufzeichnung stehen (git-Historie
  dokumentiert bereits, dass das Feature gebaut und später zurückgebaut
  wurde; rückwirkendes Löschen der Historie bringt keinen Mehrwert).
- `viewer/index.html` (Hyōka-Viewer) – bleibt vollständig unverändert, hat
  keine Abhängigkeit zum Keiko-Tool.

## Testing

Reine Lösch-/Text-Änderung ohne Code-Logik. Verifikation: `python3 -c
"import yaml; yaml.safe_load(...)" ` bestätigt, dass `config.yaml` nach dem
Entfernen der beiden Abschnitte weiterhin valide ist und `dojo:`/`rounds:`
unverändert vorhanden sind; manuelles Durchlesen der geänderten
Markdown-Dateien auf durchgehende Abschnittsnummerierung und fehlende
Keiko-Restverweise (`grep -i keiko`/`grep -i ably`).
