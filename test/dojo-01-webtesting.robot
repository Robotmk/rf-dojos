*** Settings ***
Library             Browser

Suite Setup         Initialize Browser
Suite Teardown      Close Browser


*** Test Cases ***

Test Angebot
    No Operation

*** Keywords ***
Initialize Browser
    # Register Keyword To Run On Failure    Take Screenshot
    New Browser    headless=True    args=["--no-sandbox"]
    New Context
    ...    userAgent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
    New Page    https://sampleapp.tricentis.com/101/
