# Dojo #1 – Web Testing (30.07.2026)

(zurück zur [Startseite](https://robotmk.github.io/rf-dojos/))

**Ziel-Applikation:** https://sampleapp.tricentis.com/101/

## Workflow

Der allgemeine Ablauf (Fork, Branch, Template kopieren, PR) und das
Regelwerk stehen in der [Anleitung für Teilnehmer](../../TEILNEHMER.md).

**Für dieses Dojo gilt:**

- Dojo-ID: `dojo-01-web-testing`
- PR-Titel: `[dojo-01-web-testing] <dein-github-username>` (nur die Dojo-ID in eckigen Klammern, Username **ohne** Klammern), z. B. `[dojo-01-web-testing] simonmeggle`

## Deine Aufgaben

### Environment

Bevor Du mit der Implemtierung beginnst, brauchst Du: 

- Python
- NodeJS 
- Robot Framework 
- Browser Library

Bereite das Environment vor und lege die dafür notwendigen Dateien (zb. conda.yaml oder requirements.txt) in deinem Submission-Ordner ab.

### Implementierung 

Implementiere nun einen Robot-Framework-Test, der den Angebots-Rechner der Versicherung testet, indem er die Formularseiten ausfüllt und die Bestätigung überprüft: 

- Vehicle Data: 
  - Make: Audi
  - kw: 88
  - Baujahr: 2004
  - Sitze: 5
  - Diesel
  - Nutzlast: 700 kg
  - Totalgewicht: 2100 kg
  - Listenpreis: 30.000 $
  - Kennzeichen: ABC-123
  - Laufleistung: 15000 km
- Angaben Versicherungsnehmer:
  - Vorname: Max
  - Nachname: Mustermann
  - Geburtsdatum: 01.01.1980
  - Geschlecht: männlich
  - Adresse: Musterstraße 1, 12345 Musterstadt
  - Land: Deutschland
  - Angestellt
  - Hobbies: Bungee
- Product Data: 
  - Versicherungsbeginn: mindestens 1 Monat in der Zukunft
  - Versicherungssumme: 20.000.000 $
  - Vollkasko
  - Europa-Schutz
- Preisoption: Platinum
- Sende Angebot
  - Email: max.mustermann@example.com
  - Telefon: 0049201123456
  - Username: max.mustermann
  - Password: SecretPassword123!
  - Kommentar: xxx
  - Abschicken, warten auf Meldung "*Sending e-mail success!*"

## Eingebaute Challenges

Wenn du die Extra-Herausforderung suchst, dann berücksichtige die folgenden Punkte in deinem Test:

| Challenge | Warum  |
|---|---|
| Login-Daten verschlüsseln | Umgang mit sensitiven Daten |
| Warten auf Übermittlung der Daten | Umgang mit asynchronen Operationen |
| Embedded screenshot bei Fehler | Dokumentation von Fehlerzuständen |
| Resource Files | Auslagern von Keywords |

