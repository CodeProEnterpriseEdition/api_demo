*** Settings ***
Documentation       Moving between pages: links, back button, language versions,
...                 categories and a random article.
Resource            wikipedia.resource
Suite Setup         Open Wikipedia Browser
Suite Teardown      Close Browser    ALL
Test Tags           navigation
Test Timeout        2 minutes


*** Test Cases ***
Link Opens Another Article And Back Returns
    [Tags]    smoke
    Open Article    ${EN}/Finland    Finland
    Click    css=#mw-content-text a[title="Helsinki"] >> nth=0
    Get Text    id=firstHeading    ==    Helsinki
    Go Back
    Get Text    id=firstHeading    ==    Finland

Language Link Opens Finnish Article
    [Tags]    finnish
    Open Article    ${EN}/Finland    Finland
    # The language links are in a menu, so take the address and open it.
    ${address}=    Get Property    css=a.interlanguage-link-target[lang="fi"]    href
    Go To    ${address}
    Get Text    id=firstHeading    ==    Suomi
    Get Url    contains    fi.wikipedia.org

Category Lists The Article
    Open Article    ${EN}/Finland    Finland
    Click    css=#catlinks a[title="Category:Countries in Europe"]
    Get Text    id=firstHeading    contains    Countries in Europe
    Get Element Count    css=#mw-pages a[title="Finland"]    ==    1

Random Article Opens
    Go To    ${EN}/Special:Random
    Get Url    not contains    Special:Random
    Get Text    id=firstHeading    !=    ${EMPTY}
