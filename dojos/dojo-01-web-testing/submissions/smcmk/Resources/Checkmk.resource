*** Settings ***
Library     Browser  timeout=20s

*** Keywords ***

#Login
#    # Fill in username/password, login and verify that it was successful (Customize button is visible)
#    Fill Text  id=input_user  cmkadmin
#    Fill Text  id=input_pass  cmk
#    Click  id=_login
#    Wait For Condition  Text  body  contains  Customize

Login
    [Arguments]  ${username}   ${password}
    # Fill in username/password, login and verify that it was successful (Customize button is visible)
    Fill Text  id=input_user  cmkadmin
    Fill Text  id=input_pass  cmk
    Click  id=_login
    Wait For Condition  Text  body  contains  Customize

Open All Hosts
    # Open All hosts view
    Click  text="Monitor"
    Click  text="All hosts"

#Verify Monitored Host
#    # The ">>>" operator lets us access elements inside iframes
#    # Verify that there is a host "127.0.0.1"
#    Wait For Condition  Text  iframe[name=main] >>> body  contains  127.0.0.1

Verify Monitored Host
    [Arguments]  ${host}
    # The ">>>" operator lets us access elements inside iframes
    # Verify that there is a host "127.0.0.1"
    Wait For Condition  Text  iframe[name=main] >>> body  contains  ${host}