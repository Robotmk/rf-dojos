*** Settings ***
Library     Browser  timeout=20s


*** Keywords ***

Browser Init
    # If there is no env var ROBOTMK_HEADLESS_HOST, always show the UI
    New Browser  headless=%{ROBOTMK_HEADLESS_HOST=false}  slowMo=1s

Session Init
    [Arguments]  ${url}
    New Context    locale=en-US
    New Page    ${url}

Take A Screenshot
    Take Screenshot  EMBED  fileType=jpeg  quality=80