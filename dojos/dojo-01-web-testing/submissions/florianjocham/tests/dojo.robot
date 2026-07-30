*** Settings ***
Library     Browser


*** Variables ***
${CALCULATOR_URL}           https://sampleapp.tricentis.com/101/app.php
${AUTOMOBILE_CALCULATOR}    css=


*** Test Cases ***
Test
    [Documentation]    x
    Open Browser    ${CALCULATOR_URL}    chromium
    Befülle Fahrzeugdaten


*** Keywords ***
Befülle Fahrzeugdaten
    [Documentation]    x
    Click    css=#nav_automobile:visible
    Select Options By    css=#make    value    Audi
    Fill Text    selector=#engineperformance    txt=88
    Fill Text    selector=#dateofmanufacture    txt=2004
    Select Options By    css=#numberofseats    value    5
    Select Options By    css=#fuel    value    Diesel
    Fill Text    selector=#listprice    txt=30.000
    Fill Text    selector=#licenseplatenumber    txt=ABC-123
    Fill Text    selector=#annualmileage    txt=15.000
    Sleep    3
    Click    css=#nextenterinsurantdata
    Sleep    5

Befülle Versicherungsnehmer Daten
    [Documentation]    x
    Log    ${EMPTY}

Befülle Produkt Daten
    [Documentation]    x
    Log    ${EMPTY}
