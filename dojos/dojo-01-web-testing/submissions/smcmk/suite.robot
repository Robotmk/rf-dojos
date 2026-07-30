*** Settings ***
Documentation   A car insurance quote workflow on a sample application using the Browser Library.
...             Covers the complete process from vehicle and insurant data entry through product configuration, price selection, and quote submission via email.

# Load common keywords from a shared file
Resource  Resources/BrowserCommon.resource 
Library   DateTime

Suite Setup     BrowserCommon.Browser Init
Test Setup      Test Initialization

*** Variables ***
${URL}   http://sampleapp.tricentis.com/

*** Test Cases ***
Create Quote for Car
    Enter Vehicle Data for Automobile
    Enter Insurant Data
    Enter Product Data
    Select Price Option
    Send Quote
    End Test

*** Keywords ***

Test Initialization
    New Context    locale=en-GB
    New Page       url=${URL}

Enter Vehicle Data for Automobile
    Click    div.main-navigation >> "Automobile"
    Select Options By    id=make    text    Audi
    Fill Text    id=engineperformance    110
    Fill Text    id=dateofmanufacture    06/12/1980
    Select Options By    id=numberofseats    text    5
    Select Options By    id=fuel    text    Petrol    
    Fill Text    id=listprice    30000
    Fill Text    id=licenseplatenumber    DMK1234
    Fill Text    id=annualmileage   10000 
    Click    id=nextenterinsurantdata

Enter Insurant Data
    [Arguments]    ${firstname}=Max    ${lastname}=Mustermann
    Fill Text    id=firstname    Max
    Fill Text    id=lastname    Mustermann
    Fill Text    id=birthdate    01/31/1980
    Check Checkbox    *css=label >> id=gendermale
    Fill Text    id=streetaddress    Test Street
    Select Options By    id=country    text    Germany
    Fill Text    id=zipcode    40123
    Fill Text    id=city    Essen
    Select Options By    id=occupation    text    Employee
    Click    text=Cliff Diving
    Click    id=nextenterproductdata

Enter Product Data
    ${today}=    Get Current Date
    ${now_in_60d}=    Add Time To Date    ${today}    60 days    result_format=%m/%d/%Y
    Fill Text    id=startdate    ${now_in_60d}
    Select Options By    id=insurancesum    text    7.000.000,00
    Select Options By    id=meritrating    text    Bonus 1
    Select Options By    id=damageinsurance    text    No Coverage
    Check Checkbox    *css=label >> id=EuroProtection
    Select Options By    id=courtesycar    text    Yes
    Click    id=nextselectpriceoption

Select Price Option
    [Arguments]    ${price_option}=Silver
    Click    *css=label >> css=[value=${price_option}]
    Click    id=nextsendquote

Send Quote
    Fill Text    id=email    max.mustermann@example.com
    Fill Text    id=phone    0049201123456
    Fill Text    id=username   max.mustermann
    Fill Text    id=password    SecretPassword123!
    Fill Text    id=confirmpassword    SecretPassword123!
    Fill Text    id=Comments    Some comments                 
    ${promise}=     Promise To    Wait For Response     matcher=https://sampleapp.tricentis.com/101/tcpdf/pdfs/quote.php     timeout=15
    Click    id=sendemail
    ${body}=    Wait For    ${promise}
    Log    ${body}[status]
    Log    ${body}[body]
    Wait For Elements State    "Sending e-mail success!"
    Click    "OK"

End Test
    Close Context
    Close Browser