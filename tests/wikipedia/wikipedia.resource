*** Settings ***
Documentation       Shared settings and keywords for the Wikipedia tests.
Library             Browser    timeout=30s


*** Variables ***
${EN}       https://en.wikipedia.org/wiki
${FI}       https://fi.wikipedia.org/wiki


*** Keywords ***
Open Wikipedia Browser
    [Documentation]    One browser per test file, like in an ordinary test run.
    New Browser    chromium    headless=True
    New Context    viewport={'width': 1280, 'height': 900}    locale=en-US
    New Page

Open Article
    [Documentation]    Opens the page and checks its main heading.
    [Arguments]    ${url}    ${heading}
    Go To    ${url}
    Get Text    id=firstHeading    ==    ${heading}

Section Should Exist
    [Documentation]    The article has a main section (h2) with this id.
    [Arguments]    ${id}
    Get Element Count    css=h2[id="${id}"]    ==    1

Loaded Images
    [Documentation]    Number of images on the page that have finished loading.
    ${count}=    Evaluate JavaScript    ${None}
    ...    () => [...document.images].filter((i) => i.complete && i.naturalWidth > 0).length
    RETURN    ${count}
