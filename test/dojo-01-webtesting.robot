*** Settings ***
Library             Browser
Library             tricentis.home.Home                 WITH NAME    Home
Library             tricentis.truck.Truck               WITH NAME    Truck
Library             tricentis.insurant.Insurant         WITH NAME    Insurant
Library             tricentis.product.Product           WITH NAME    Product
Library             tricentis.price_option.PriceOption  WITH NAME    PriceOption
Library             tricentis.quote.Quote               WITH NAME    Quote

Suite Setup         Initialize Browser
Suite Teardown      Close Browser
Test Setup          Home.Open Landing Page
Test Teardown       Close Page


*** Test Cases ***

TestAngebot
    Get Title    ==    Tricentis Vehicle Insurance

Insurance Quote Calculator With Page Objects
    Home.Start Truck Insurance Quote
    Truck.Enter Vehicle Data
    ...    Audi
    ...    88
    ...    01/01/2004
    ...    5
    ...    Diesel
    ...    700
    ...    2100
    ...    30000
    ...    ABC-123
    ...    15000
    Insurant.Enter Insurant Data
    ...    Max
    ...    Mustermann
    ...    01/01/1980
    ...    Musterstraße 1
    ...    12345
    ...    Musterstadt
    ...    Germany
    ...    Employee
    ${start_date}=    Product.Get Start Date More Than One Month In The Future
    Product.Enter Product Data
    ...    ${start_date}
    ...    20000000
    ...    Full Coverage
    PriceOption.Select Platinum Price Option
    Quote.Send Quote
    ...    max.mustermann@example.com
    ...    0049201123456
    ...    max.mustermann
    ...    SecretPassword123!
    ...    xxx
    Quote.Quote Should Be Sent Successfully

*** Keywords ***
Initialize Browser
    # Register Keyword To Run On Failure    Take Screenshot
    New Browser    headless=True    args=["--no-sandbox"]
    New Context
    ...    userAgent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
