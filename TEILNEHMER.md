# Anleitung für Teilnehmer

Alles, was du als Teilnehmer für einen Dojo-Abend wissen musst: wie der Abend
abläuft, das Regelwerk und wie du deine Lösung einreichst. Was ein Dojo
überhaupt ist, steht auf der [Startseite](README.md).

## Ablauf des Abends

| Zeit  | Phase              | Inhalt                                               |
|-------|--------------------|-------------------------------------------------------|
| 18:30 | Ankommen & Warm-up | Vorstellungsrunde, Buddy-Zuteilung, Aufgabe erklären |
| 19:00 | Keiko (Randori)    | Jeder implementiert seinen Test – alleine, ohne KI   |
| 20:00 | Pause              | Fuel & RAM-Kühlung // sponsored by Checkmk 🍕🍺      |
| 20:15 | Hyōka              | Jeder zeigt seine Lösung live – Vergleich & Diskussion |
| 21:15 | Zanshin            | Was nehme ich heute mit? – kurze Abschlussrunde      |
| 21:30 | Offen              | Networking, Gespräche, weiteres Tüfteln              |

## Das Buddy-System

Jeder Teilnehmer arbeitet alleine – aber hat einen Buddy an seiner Seite. Der
Buddy ist kein Teampartner, sondern ein Joker.

- Jedes Buddy-Paar besteht aus einer erfahrenen und einer weniger erfahrenen Person
- Der Buddy darf max. 5 Minuten befragt werden – danach läuft die eigene Uhr wieder
- Die Lösung bleibt immer die eigene
- Der Organisator ist die zweite Lifeline: gibt Hinweise, aber keine Lösungen

## Regelwerk

Wird am Anfang jedes Dojos gemeinsam laut vorgelesen. Gilt als Ehrenkodex –
nicht als Kontrolle.

| # | Regel | Warum |
|---|-------|-------|
| 1 | **Kein KI – kein Copilot** | Kein ChatGPT, kein GitHub Copilot, keine KI-Autovervollständigung. Auch nicht „nur kurz nachschauen". Der Abend lebt vom echten Wissen der Menschen im Raum. |
| 2 | **Eigenes Wissen zuerst** | Erst selbst denken, dann Buddy fragen, dann Dokumentation. Wer sofort googelt, lernt nichts über seinen eigenen Wissensstand. |
| 3 | **Dokumentation ist erlaubt** | robot-framework.org, Browser Library Docs, Checkmk Docs – alles erlaubt. KI-generierte Antworten nicht. |
| 4 | **Keine Musterlösung** | Es gibt kein Richtig oder Falsch. Jeder Ansatz ist willkommen – auch ein halbfertiger Test mit einer guten Idee drin. |
| 5 | **Buddy-Zeitlimit** | Max. 5 Minuten pro Buddy-Anfrage. Danach: selbst weitermachen. Der Buddy gibt Hinweise, keine fertigen Lösungen. |
| 6 | **Alle zeigen ihren Code** | Beim Hyōka zeigt jeder seine Lösung – auch wenn sie nicht fertig ist. Gerade unfertige Ansätze führen zu den besten Gesprächen. |
| 7 | **Keine Bewertung** | Im Hyōka gibt es keine Noten. Kein „das ist falsch". Nur: „interessant, warum hast du das so gemacht?" |
| 8 | **Respekt im Dojo** | Jeder ist hier, um zu lernen. Erfahrene helfen. Anfänger fragen. Niemand wird für seinen Wissensstand bewertet. |

## Submission-Workflow

### Vorbereitung (vor dem Abend)

1. Repo forken: `github.com/[owner]/rf-dojos`
2. Branch anlegen: `git checkout -b <dojo-id>/[github-username]`
3. Submissions-Template kopieren:
   `cp -r dojos/<dojo-id>/submissions/_template dojos/<dojo-id>/submissions/[github-username]`
4. Aufgabe in `dojos/<dojo-id>/README.md` lesen

`<dojo-id>` ist der Ordnername des jeweiligen Dojos, z. B. `dojo-01-web-testing`
– siehe die Dojo-Liste unter [Mitmachen](README.md#mitmachen) auf der
Startseite.

### Am Abend

1. Test implementieren in `submissions/[github-username]/`
2. Committen und pushen
3. Pull Request öffnen gegen `main` des Original-Repos
   - PR-Titel: `[<dojo-id>] [github-username]`
   - Kein weiterer Text nötig

### Was der Viewer damit macht

Der Organisator nutzt am Abend den [Viewer](viewer/), um alle eingereichten
PRs thematisch nach Runden zu vergleichen (Verzeichnisstruktur, Locator-
Strategie, Custom Keywords, …). Du musst dafür nichts weiter tun – sobald
dein PR offen ist, taucht deine Lösung automatisch dort auf.
