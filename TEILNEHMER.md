# Anleitung für Teilnehmer

Alles, was du als Teilnehmer für einen Dojo-Abend wissen musst: wie der Abend
abläuft, das Regelwerk und wie du deine Lösung einreichst. Was ein Dojo
überhaupt ist, steht auf der [Startseite](README.md).

## Ablauf des Abends

| Zeit  | Phase              | Inhalt                                               |
|-------|--------------------|-------------------------------------------------------|
| 18:30 | Ankommen & Warm-up | Vorstellungsrunde, Buddy-Zuteilung, Aufgabe erklären |
| 19:00 | [Phase 1 - Keiko](#phase-1-keiko-implementierung)       | Jeder implementiert seinen Test   |
| 20:00 | Pause              | Bier & Pizza 🍕🍺      |
| 20:30 | [Phase 2 - Hyōka](#phase-2-hyōka-vergleich--diskussion)              | Vergleich & Diskussion der verschiedenen Lösungen |
| 21:15 | [Phase 3 - Zanshin](#phase-3-zanshin-abschlussrunde)            | Was nehme ich heute mit? – kurze Abschlussrunde      |
|  | Open End              |    |

## Das Buddy-System

Jeder Teilnehmer arbeitet alleine – aber hat einen Buddy an seiner Seite. 

**Die Buddy-Regeln:**

- Jedes Buddy-Paar besteht (nach Möglichkeit) aus einer erfahrenen und einer weniger erfahrenen Person
- Der Buddy sollte nicht länger als 5 Minuten befragt werden
- (Natürlich dürfen die Fragen in beide Richtungen gehen: auch der erfahrene Buddy darf den weniger erfahrenen Buddy fragen, wenn er mal nicht weiterkommt.)
- Die Lösung bleibt immer die _eigene_.
- Buddies sollten in Reichweite zu einandersitzen, aber nicht direkt nebeneinander.
- Wenn das Buddy-Team auch zusammen nicht weiterkommt, ist der Organisator die zweite Rettungsleine.

**Aufgabe:** 

- Arbeitest du **selten** mit Robot Framework bzw. im heutigen Thema? => **Dann ziehe** 🟡
- Arbeitest du **regelmäßig** mit Robot Framework bzw. im heutigen Thema? => **Dann ziehe** 🔴
- Such dir jetzt deinen Buddy mit der anderen Farbe.

## Dieses Regelwerk ist unser Ehrenkodex!

| # | Regel | Warum |
|---|-------|-------|
| 1 | **Wir nutzen keine KI !** | Wir committen uns darauf, zur Lösungsfindung keine KI-Agents, KI-Autovervollständigung etc. zu benutzen - auch nicht, um "_nur kurz nachschauen_". Nutze stattdessen das Buddy-System und tausche Dich aus. Der Abend lebt vom echten Wissen der Menschen im Raum. |
| 2 | **Dokumentation ist erlaubt** | RF User Guide, Library Docs, etc. - alles erlaubt. **KI-generierte Antworten nicht**. |
| 3 | **Eigenes Wissen zuerst** | Dokumentation, Google, Buddy, Organisator - in dieser Reihenfolge.  |
| 4 | **Buddy-Limit** | Max. 5 Minuten pro Buddy-Anfrage. Der Buddy gibt Hinweise, keine fertigen Lösungen. |
| 5 | **Alle zeigen ihren Code** | Beim Hyōka zeigt jeder seine Lösung, auch wenn sie nicht fertig ist. |
| 6 | **Keine Bewertung** | Es gibt keinen Preis zu gewinnen, kein "richtig" oder "falsch". Schon eher: "_spannend, warum hast du das denn so gemacht?_" |
| 7 | **Respekt im Dojo** | Jeder ist hier, um zu lernen. Erfahrene helfen. Anfänger fragen. Niemand wird für seinen Wissensstand bewertet. |

## Voraussetzungen

- Github-Account
- Laptop (MacOS/Windows/Linux)
- Internetzugang
- Git installiert

## Der Dojo-Workflow

### Vorbereitung

**Aufgabe:** (lass Dir ggf. von Deinem Buddy helfen)

Hinweis: `<dojo-id>` ist der Ordnername des jeweiligen Dojos, z. B. `dojo-01-web-testing` - siehe die Dojo-Liste unter [Mitmachen](README.md#mitmachen) auf der Startseite. `<dein-github-username>` ist entsprechend Dein Github-Username, z. B. `simonmeggle`. Beides sind Platzhalter, die Du ohne die spitzen Klammern einsetzt.

1. Stelle sicher, dass Du die Voraussetzungen erfüllst (s.o.)
2. Forke das [Repo](https://github.com/Robotmk/rf-dojos) in Deinen Github-Account
3. Klone Deinen Fork auf Dein Filesystem: `git clone ssh://github.com/<dein-github-username>/rf-dojos.git`
4. Lege einen lokalen Branch mit Deinem Github-Namen an: `git checkout -b <dojo-id>/<dein-github-username>`, z. B. `git checkout -b dojo-01-web-testing/simonmeggle`
5. Kopiere das Arbeits-Template:
   `cp -r dojos/<dojo-id>/submissions/_template dojos/<dojo-id>/submissions/<dein-github-username>`, z. B. `cp -r dojos/dojo-01-web-testing/submissions/_template dojos/dojo-01-web-testing/submissions/simonmeggle`

### Phase 1: Keiko (Implementierung)

Dein Arbeitsverzeichnis: `dojos/<dojo-id>/submissions/<dein-github-username>/`

1. Lies die Aufgabe in `dojos/<dojo-id>/README.md`
2. Test implementieren in `submissions/<dein-github-username>/`
3. Committen und pushen: 
   1. `git add .`
   2. `git commit -m "meine Lösung"`
   3. `git push origin <dojo-id>/<dein-github-username>`, z. B. `git push origin dojo-01-web-testing/simonmeggle`
4. Pull Request öffnen gegen `main` des Original-Repos
   - PR-Titel: **nur** die Dojo-ID steht in eckigen Klammern, danach ein Leerzeichen und Dein Github-Username **ohne** Klammern: `[<dojo-id>] <dein-github-username>`, z. B. `[dojo-01-web-testing] simonmeggle`
     - ⚠️ Der PR-Titel ist das einzige Kriterium, nach dem der Viewer die PRs filtert – bitte genau so eintragen (Username **nicht** in Klammern setzen, sonst findet der Viewer Deinen Submissions-Ordner nicht)!
   - Kein weiterer Text im PR nötig

### Phase 2: Hyōka (Vergleich & Diskussion)

Wir setzen uns zusammen und sehen uns mit dem [Viewer](viewer/) alle eingereichten PRs an.  
Hierbei gehen wir thematisch vor: z.b. Verzeichnisstruktur, Locator-Strategie, Custom Keywords, ... .  
Du musst dafür nichts weiter tun – sobald dein PR gepushed ist, taucht deine Lösung automatisch dort auf.
