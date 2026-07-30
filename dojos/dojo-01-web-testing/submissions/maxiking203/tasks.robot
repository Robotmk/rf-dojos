*** Settings ***
Documentation       Angebots-Rechner der Versicherung testet, indem er die Formularseiten ausfüllt und die Bestätigung überprüft  

Library             Browser    enable_playwright_debug=disabled    run_on_failure=Take Screenshot \ EMBED

Name                Dojo #1 – Web Testing

*** Variables ***
${HEADLESS}         false
${BROWSER}          Firefox
${URL}              https://sampleapp.tricentis.com/101/
${PROXY_IP}         px-internetweb.muenchen.de
${PROXY_PORT}       80


*** Test Cases ***
Auto Versicherung
    [Documentation]     Formular fuer Autoverischerung pruefen
    Open Website
    Fill Vehicle Data
    Fill Insurant Data
    No Operation


*** Keywords ***
Open Website
    [Documentation]    Oeffene Versicherungsformular
    New Browser    ${BROWSER}    ${HEADLESS}    proxy={"server": "http://${PROXY_IP}:${PROXY_PORT}"}
    New Page    ${URL}
    Click  css=ul.menu:nth-child(2) > li:nth-child(1)

Fill Vehicle Data
    [Documentation]    Trage Fahrzeugdaten ein
    Select Options By    id=make    value    Audi
    Fill Text    id=engineperformance    88
    Fill Text    id=dateofmanufacture    01/01/2004
    Select Options By    id=numberofseats    value    5
    Select Options By    id=fuel    value    Diesel
    Fill Text    id=listprice    30.000 $
    Fill Text    id=licenseplatenumber    ABC-123
    Fill Text    id=annualmileage    15000
    Click    id=nextenterinsurantdata

Fill Insurant Data
    [Documentation]    Trage Versicherungsnehmer-Daten ein
    Fill Text    id=firstname    Max
    Fill Text    id=lastname    Mustermann
    Fill Text    id=birthdate    01/01/1980
    Click  text="Male"
    Fill Text    id=streetaddress    Musterstraße 1, 12345 Musterstadt
    Select Options By    id=country    value    Germany

