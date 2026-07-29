# Dojo #1 – Web Testing

**Ziel-Applikation:** https://www.saucedemo.com
**Datum:** 2026-07-30

## Die Aufgabe

Implementiere einen Robot-Framework-Test, der folgenden Ablauf testet:

1. Login mit gültigen Credentials
2. Einen Artikel in den Warenkorb legen
3. Checkout durchführen (Formular ausfüllen, Bestellung abschicken)
4. Verifizieren, dass die Bestätigungsseite korrekt erscheint

## Eingebaute Challenges

| Challenge | Warum spannend |
|---|---|
| Login-Daten nicht hardcoden | Zeigt Umgang mit Variables, Resource Files oder Secrets |
| Wait-Handling | Wie wartet man sauber auf dynamische Elemente? |
| Screenshot bei Fehler | Bewusster Umgang mit Teardown und Fehlerbehandlung |
| Mindestens 1 Custom Keyword | Wie strukturiert jemand seinen Code? |

## Für Fortgeschrittene (optional)

- Page Object Model umsetzen
- Resource File Struktur anlegen
- Test in mehrere Test Cases aufsplitten
- Browser Library statt SeleniumLibrary – oder beide vergleichen

## Workflow

Der allgemeine Ablauf (Fork, Branch, Template kopieren, PR) und das
Regelwerk stehen in der [Anleitung für Teilnehmer](../../TEILNEHMER.md).
Für dieses Dojo gilt:

- Dojo-ID: `dojo-01-web-testing`
- PR-Titel: `[dojo-01-web-testing] [github-username]`
