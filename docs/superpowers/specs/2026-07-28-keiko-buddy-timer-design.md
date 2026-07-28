# Keiko Buddy & Timer Tool – Design

## Kontext

Während der Keiko-Phase (siehe `manual.md`) arbeitet jeder Teilnehmer alleine an
seiner Lösung, unterstützt von einem vorab zugeteilten Buddy (1. Lifeline) und
dem Organisator (2. Lifeline). Je nach Abend sitzen Teilnehmer im selben Raum,
auf mehrere Räume verteilt, oder komplett remote (Zoom/Discord/Teams) – der
Organisator kann sie dann nicht mehr per Zuruf erreichen oder sehen, wer gerade
feststeckt.

Dieses Tool ergänzt den bestehenden Hyōka-Viewer (`viewer/index.html`, Code-
Vergleich per PR) um ein zweites, unabhängiges Werkzeug für die Keiko-Phase:
zentral gesteuerter Timer, Broadcast-Nachrichten mit Ton, und ein Hilferuf-
Mechanismus, der zuerst den zugeteilten Buddy erreicht und erst danach den
Organisator.

## Ziel

- Der Organisator kann den 60-Minuten-Keiko-Timer zentral starten.
- Vordefinierte Zeit-Meilensteine (z.B. "noch 15 Minuten") lösen automatisch
  einen Broadcast mit Ton an alle Teilnehmer aus – unabhängig davon, in
  welchem physischen oder virtuellen Raum sie sitzen.
- Ein Teilnehmer kann per Knopfdruck Hilfe anfordern. Der Ruf geht zuerst an
  den eigenen, vorab vereinbarten Buddy (mit Ton), erst bei Nichtreaktion oder
  expliziter Eskalation an den Organisator.
- Funktioniert unabhängig vom physischen Setup (ein Raum, mehrere Räume,
  komplett remote), solange jedes Gerät eine offene Browser-Seite hat.

## Nicht-Ziele

- Kein Ersatz für Video-/Audio-Kommunikation (Zoom, Discord etc.) – das Tool
  ergänzt nur Timer/Signalisierung, überträgt keine Sprache/Video.
- Kein persistenter Chat-Verlauf nach Abend-Ende (Ereignis ist einmalig, keine
  Historisierung nötig).
- Keine Authentifizierung/Zugriffskontrolle über den Ably-Channel-Namen
  hinaus – Vertrauensmodell entspricht dem bereits im Repo etablierten
  GitHub-Token-Muster (Key liegt lokal im Browser, nicht im Repo).

## Architektur

Neue statische Seite `viewer/keiko.html`, Schwesterdatei zu
`viewer/index.html`. Gleiches Prinzip wie der bestehende Viewer: eine
HTML-Datei, keine Build-Pipeline, kein npm, Abhängigkeiten nur via CDN.

**Realtime-Transport:** [Ably](https://ably.com) (Free Tier). Ably erlaubt –
anders als z.B. Pusher Channels – das direkte Publizieren/Abonnieren aus dem
Browser mit einem eingeschränkten API-Key (Capability nur `publish` +
`subscribe`, keine Account-/Kanal-Verwaltung), ganz ohne eigenen
Auth-Server. Der Ably-Key wird wie der bestehende GitHub-Token einmalig in
ein Textfeld eingegeben und in `localStorage` gehalten – nie im Repo
gespeichert.

Ein Ably-**Channel pro Dojo** (`dojo-{id}-keiko`) verbindet alle Geräte direkt
miteinander: Organizer, Teilnehmer, Buddys.

**Konfiguration:** `config.yaml` des jeweiligen Dojos bekommt einen neuen
optionalen Abschnitt:

```yaml
buddies:
  - a: alice
    b: bob
  - a: charlie
    b: diana

timer:
  duration_minutes: 60
  milestones:
    - at_minute: 45
      message: "Noch 15 Minuten!"
    - at_minute: 58
      message: "Zeit ist um – bitte aufräumen für die Präsentation."
```

Wird analog zu den bestehenden `rounds:` einmalig beim Laden der Seite
gelesen (`GET /repos/{owner}/rf-dojos/contents/dojos/{id}/config.yaml`).

## Rollen (eine Seite, zwei Ansichten)

Beim ersten Öffnen wählt man einmalig die Rolle, gemerkt in `localStorage`:

- **Teilnehmer** (jeder, auch Buddys – es ist dieselbe Rolle): wählt seinen
  Namen aus der `buddies`-Liste aus config.yaml. Sieht danach automatisch,
  wer der eigene Buddy ist. UI zeigt: großer Keiko-Countdown, Button „Ich
  brauche Hilfe", Banner für eingehende Broadcasts/Hilferufe, Ton-Alarm.
- **Organizer** (der Moderator): Timer-Steuerung (Start/Pause/Reset),
  Live-Liste offener Hilferufe (Buddy-Ebene + eskaliert), Freitext-Broadcast
  senden, Log der automatisch ausgelösten Meilensteine.

## Event-/Datenfluss

Alle Kommunikation läuft über Ably-Events auf dem Dojo-Channel:

| Event | Auslöser | Wirkung |
|---|---|---|
| `timer:start` | Organizer startet Timer | Alle Clients berechnen den Countdown lokal ab dem übertragenen `startedAt`-Timestamp (kein Uhren-Drift durch Netzwerk-Latenz) |
| `broadcast` | Manuell (Organizer, Freitext) oder automatisch (Meilenstein aus `config.yaml`) | Banner + Ton bei allen Clients |
| `help:request` | Teilnehmer klickt „Brauche Hilfe" | Geht zuerst an den zugeordneten Buddy (mit Hinweis auf 5-Min-Limit aus dem Regelwerk); erscheint parallel in der Organizer-Ansicht als „läuft" |
| `help:escalate` | Buddy klickt „Eskalieren", oder keine Reaktion des Buddys nach konfigurierbarem Timeout (Default 2 Min) | Hilferuf wandert prominent in die Organizer-Ansicht (mit Ton) |
| `help:resolved` | Buddy oder Teilnehmer markiert „Erledigt" | Eintrag verschwindet aus allen Listen |

Die automatische Eskalation nach Timeout verhindert, dass ein Teilnehmer
hängen bleibt, falls der Buddy die Seite gerade nicht offen hat.

## Benachrichtigung/Ton

- Für jeden Event-Typ ein kurzer, eigener Sound, base64-eingebettet direkt in
  der HTML-Datei (bleibt single-file, kein zusätzlicher Asset-Request).
- Zusätzlich optional die Browser-`Notification`-API (Permission wird bei der
  Namenswahl erfragt) für den Fall, dass jemand den Tab weggeklickt hat.
- Kernmechanismus bleibt der hörbare Ton bei offenem Tab – das ist die
  verlässliche Grundannahme, auf der das Feature aufbaut (Notification-API
  ist ein Bonus, kein Fallback-Ersatz, da z.B. iOS Safari sie stark
  einschränkt).

## Fehlerbehandlung

- Verbindung zu Ably verloren → sichtbares Banner „Verbindung getrennt,
  verbinde neu…"; Ably-SDK reconnected automatisch.
- Buddy nicht online bzw. reagiert nicht → automatische Eskalation nach
  Timeout (siehe oben).
- Kein Ably-Key hinterlegt → Onboarding-Flow analog zum bestehenden
  GitHub-Token-Textfeld im Viewer.
- Kein Netz/Ably down während der Veranstaltung → Tool degradiert auf
  „nutzlos", Kernablauf des Dojo-Abends (Keiko/Hyōka) ist davon nicht
  blockiert, da er auch ohne dieses Tool funktioniert (manuelle Zeitnahme,
  persönliches Nachfragen).

## Testing

Kein klassisches Unit-Testing sinnvoll (reines UI + externer Realtime-Dienst).
Stattdessen: manueller Testlauf vor dem echten Abend mit mehreren
Browser-Tabs/Inkognito-Fenstern unter verschiedenen Namen, um Buddy-Routing,
Timeout-Eskalation und Broadcast-Fanout durchzuspielen.

## Offene Entscheidungen (vor Implementierungsstart klären)

1. Konkreter Ably-Account/Key – wird vom Organisator vor dem ersten Test
   angelegt (Free Tier reicht für die Größenordnung von 8–20 Teilnehmern).
2. Default-Timeout für Buddy-Eskalation (Vorschlag: 2 Minuten) – final vom
   Organisator bestätigen.
3. Genaue Meilenstein-Zeitpunkte/-Texte pro Dojo werden in der jeweiligen
   `config.yaml` gepflegt (kein Hardcoding im Tool).
