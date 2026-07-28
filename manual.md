# 🥋 Robot Framework Web Testing Dojo
## Konzept & Moderationsleitfaden
*Wiederholbares Format für die RFUGM*

> **Was ist ein Dojo?**
> Ein Dojo ist der traditionelle Übungsraum der japanischen Kampfkünste – ein Ort, an dem man nicht zuhört, sondern macht. Kein Vortrag von vorne. Kein Frontalunterricht. Jeder übt seine eigene Kata. Und am Ende lernen alle voneinander.
>
> Genau das ist das Prinzip dieses Meetup-Formats.

---

# Teil 1 – Das Konzept

## Grundidee

Alle Teilnehmer lösen dieselbe Aufgabe – jeder für sich, auf eigene Art. Am Ende vergleichen alle ihre Lösungen. Die Unterschiede sind der eigentliche Inhalt des Abends.

Kein Vortrag. Kein Musterlösungs-Foliensatz. Lernen von allen Seiten.

## Die zwei Phasen

| Zeit  | Phase               | Inhalt                                                    |
|-------|---------------------|-----------------------------------------------------------|
| 18:30 | Ankommen & Warm-up  | Vorstellungsrunde, Buddy-Zuteilung, Aufgabe erklären      |
| 19:00 | 🥋 Keiko (Randori)  | Jeder implementiert seinen Test – alleine, ohne KI        |
| 20:00 | Pause               | Fuel & RAM-Kühlung // sponsored by Checkmk 🍕🍺           |
| 20:15 | 🔍 Hyōka            | Jeder zeigt seine Lösung live – Vergleich & Diskussion    |
| 21:15 | Zanshin             | Was nehme ich heute mit? – kurze Abschlussrunde           |
| 21:30 | Offen               | Networking, Gespräche, weiteres Tüfteln                   |

## Das Buddy-System

Jeder Teilnehmer arbeitet alleine – aber hat einen Buddy an seiner Seite. Der Buddy ist kein Teampartner, sondern ein Joker.

- Jedes Buddy-Paar besteht aus einer erfahrenen und einer weniger erfahrenen Person
- Der Buddy darf max. 5 Minuten befragt werden – danach läuft die eigene Uhr wieder
- Die Lösung bleibt immer die eigene
- Der Organisator ist die zweite Lifeline: gibt Hinweise, aber keine Lösungen

> **Warum Buddy statt Team?**
> Teams produzieren eine Lösung. Buddies produzieren viele Lösungen – und genau diese Vielfalt ist das Lernmaterial des Abends. Jeder Ansatz zählt, keine Idee geht in der Gruppe unter.

## Wiederholbarkeit – das Format für jedes Dojo

Dieses Konzept ist nicht auf Web Testing beschränkt. Es funktioniert für jedes Robot Framework Thema:

- API Testing
- Datenbankanbindung
- Custom Keywords & Libraries
- CI/CD Integration
- Reporting & Logging

Was sich von Dojo zu Dojo ändert: die Aufgabe, die eingebauten Challenges und die Demo-Zielapplikation. Das Format bleibt gleich.

---

# Teil 2 – Das Regelwerk des Dojo

Das Regelwerk wird am Anfang jedes Dojos gemeinsam laut vorgelesen. Es gilt als Ehrenkodex – nicht als Kontrolle.

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

> **Wie das Regelwerk eingeführt wird:**
> Der Organisator liest die Regeln nicht vor – er lässt sie von einem Teilnehmer laut vorlesen. Das schafft sofort Verbindlichkeit und ein „wir haben das gemeinsam beschlossen"-Gefühl.

---

# Teil 3 – Moderationsleitfaden

Dieser Teil begleitet dich live durch den Abend. Jede Phase enthält konkrete Moderationshinweise und Formulierungsvorschläge.

## 18:30 – Ankommen & Warm-up (30 min)

### Vorstellungsrunde

Jeder nennt in 60 Sekunden:

- Name & wie lange schon Robot Framework
- Einen Web-Test-Schmerz: „Was nervt mich beim Web Testing regelmäßig?"

*Moderationshinweis: Notiere die Schmerzen sichtbar – sie kommen beim Hyōka wieder auf.*

### Buddy-Zuteilung

Paare werden vom Organisator vorab festgelegt (basierend auf Vorab-Umfrage). Ankündigung ohne Begründung:

> **Moderationstext:**
> „Ich habe euch heute Abend Buddy-Paare zugeteilt. Euer Buddy ist nicht euer Team – er ist euer Joker. Ihr dürft ihn bis zu 5 Minuten fragen, wenn ihr feststeckt. Die Lösung bleibt eure eigene."

### Aufgabe vorstellen

Aufgabe auf Screen oder Papier zeigen. Challenges erklären. Dann:

> **Moderationstext:**
> „Ihr habt 60 Minuten. Kein Richtig, kein Falsch. Wenn ihr nicht fertig werdet – kein Problem. Zeigt beim Hyōka, wie weit ihr gekommen seid und was ihr dabei gelernt habt."

## 19:00 – 🥋 Keiko / Randori (60 min)

Alle arbeiten still und alleine. Du als Moderator:

- Gehst durch den Raum und beobachtest – ohne zu kommentieren
- Bist die zweite Lifeline wenn jemand wirklich feststeckt
- Gibst nach 45 min einen kurzen Zeithinweis: „Noch 15 Minuten"
- Unterbrichst bei Bedarf: „Wer möchte, kann jetzt beginnen aufzuräumen für die Präsentation"

## 20:00 – Pause (15 min)

> `// fuel & cooling sponsored by Checkmk 🍕🍺`
>
> Nutze die Pause um Präsentationsreihenfolge festzulegen – am besten: weniger Erfahrene zuerst, damit Erfahrene nicht den Ton setzen.

## 20:15 – 🔍 Hyōka (60 min)

Jeder zeigt seinen Code live am eigenen Laptop (oder Screen-Share). Zeitrahmen: 5–7 min pro Person.

### Struktur je Präsentation

- 2 min: Code kurz zeigen & erklären
- 3–5 min: Diskussion im Kreis

### Leitfragen für die Diskussion

- „Welchen Locator-Ansatz hast du gewählt – und warum?"
- „Wie hast du das Warte-Problem gelöst?"
- „Was würdest du beim nächsten Mal anders machen?"
- „Hat jemand das gleiche Problem anders gelöst?"

> **Wichtig:**
> Als Moderator steuerst du die Diskussion – aber du bewertest nicht. Wenn jemand eine unübliche Lösung zeigt, frag nach dem Warum, bevor jemand anderes sie kommentiert.

## 21:15 – Zanshin – das Nachklingen (15 min)

„Zanshin" bedeutet in den Kampfkünsten das bewusste Nachklingen nach der Übung – der Moment, in dem man verarbeitet, was man gelernt hat.

Jeder sagt in einem Satz:

> **Moderationstext:**
> „Was nimmst du heute Abend mit? Nicht den Code – sondern den Gedanken, die Idee, den Aha-Moment."

---

# Teil 4 – Aufgabe: Web Testing Dojo #1

> **Ziel-Applikation: saucedemo.com**
> Öffentlich verfügbar, stabil, realistisch. Kein Login nötig zum Starten.

## Die Aufgabe

Implementiere einen Robot Framework Test, der folgenden Ablauf testet:

1. Login mit gültigen Credentials
2. Einen Artikel in den Warenkorb legen
3. Checkout durchführen (Formular ausfüllen, Bestellung abschicken)
4. Verifizieren, dass die Bestätigungsseite korrekt erscheint

## Eingebaute Challenges

Diese Herausforderungen sind bewusst Teil der Aufgabe. Wie du sie löst, ist deine Entscheidung.

| Challenge | Warum spannend |
|-----------|----------------|
| **Login-Daten nicht hardcoden** | Zeigt Umgang mit Variables, Resource Files oder Secrets |
| **Wait-Handling** | Dynamische Elemente – wie wartet man sauber auf Seitenübergänge? |
| **Screenshot bei Fehler** | Zeigt bewussten Umgang mit Teardown und Fehlerbehandlung |
| **Mindestens 1 Custom Keyword** | Wie strukturiert jemand seinen Code? Was abstrahiert er – was nicht? |

## Für Fortgeschrittene (optional)

- Page Object Model umsetzen
- Resource File Struktur anlegen
- Test in mehrere Test Cases aufsplitten
- Browser Library statt SeleniumLibrary – oder beide vergleichen

---

# Teil 5 – Vorlage für zukünftige Dojos

Kopiere diesen Abschnitt und passe ihn für jedes neue Dojo an.

## Checkliste Vorbereitung (1 Woche vorher)

- [ ] Thema & Zielapplikation festlegen
- [ ] Aufgabe formulieren (1 Hauptflow + 3–5 Challenges)
- [ ] Vorab-Umfrage verschicken (Erfahrungslevel ermitteln)
- [ ] Buddy-Paare festlegen
- [ ] Ankündigung auf LinkedIn & Luma veröffentlichen
- [ ] Checkmk / Sponsor für Essen & Trinken bestätigen

## Checkliste Abend

- [ ] Beamer / Screen-Share funktioniert
- [ ] Aufgabe auf Papier oder Screen für alle sichtbar
- [ ] Regelwerk ausgedruckt oder auf Screen
- [ ] Buddy-Paare auf Zettel – nicht öffentlich, nur für dich
- [ ] Timekeeper bereit (Keiko: 60 min, jede Präsentation: 7 min)

## Aufgaben-Template

```
Dojo #__ – [Thema]

Ziel-Applikation: _______________
Credentials / Zugangsdaten: _______________

Die Aufgabe:
1. _______________
2. _______________
3. _______________
4. _______________

Challenges:
→ _______________
→ _______________
→ _______________

Optional für Fortgeschrittene:
→ _______________
```
