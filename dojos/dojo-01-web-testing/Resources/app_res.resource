*** Settings ***
Library    Browser
Resource    ../Resources/app_res.resource
Variables   ../Config/variables.py

*** Keywords ***
Open App
    New Browser    ${BROWSER}    headless=false
    New Context    viewport={'width': 1920, 'height': 1080}
    New Page       ${URL_BASE}
    Get Title      ==    Tricentis Vehicle Insurance
    Log    You entered the app successfully!

Enter Calculator UI
    #  Click    xpath=//div[@class='main-navigation']//a[@id='nav_automobile']
    Click    xpath=//div[@class='main-navigation']//a[@id='nav_automobile']
    Sleep    5s

Enter Vehicle Data
    [Arguments]
    ...            ${Make}       #  Audi
    ...            ${kw}         #  88
    ...            ${year}       #  2004
    ...            ${seats}      #  5
    ...            ${fuel}       # Diesel
    ...            ${price}      #  30000
    ...            ${mileage}    # 15000

    Select Options By  id=make  value  Audi
    Fill Text    id=engineperformance  88
    Fill Text    id=dateofmanufacture  07/09/2024
    Select Options By  id=numberofseats  value  5
    Select Options By  id=fuel  value  Diesel
    Fill Text    id=listprice  30000
    Fill Text    id=licenseplatenumber  XSMUN897
    Fill Text    id=annualmileage  15000
    Click    id=nextenterinsurantdata
    Sleep    5s
    Log    Vehicle Data entered