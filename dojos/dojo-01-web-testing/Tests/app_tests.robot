*** Settings ***
Resource    ../Resources/app_res.resource
Variables   ../Config/variables.py


*** Test Cases ***
Offer_Calculator
    Open App
    Enter Calculator UI
    Enter Vehicle Data    Make=Audi  kw=88  year=2024  seats=5  fuel=Diesel  price=30000  mileage=15000

