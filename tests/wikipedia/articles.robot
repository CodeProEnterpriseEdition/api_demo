*** Settings ***
Documentation       Reading articles: title, introduction, main sections and infobox.
Resource            wikipedia.resource
Suite Setup         Open Wikipedia Browser
Suite Teardown      Close Browser    ALL
Test Tags           articles
Test Timeout        2 minutes


*** Test Cases ***
Article Has Title And Introduction
    [Tags]    smoke
    Open Article    ${EN}/Finland    Finland
    Get Text    css=#mw-content-text p:has-text("officially the Republic of Finland") >> nth=0
    ...    contains    Nordic country

Article Has Its Main Sections
    Open Article    ${EN}/Finland    Finland
    FOR    ${section}    IN    History    Geography    Economy    Demographics    Culture
        Section Should Exist    ${section}
    END

Infobox Shows Key Facts
    Open Article    ${EN}/Finland    Finland
    Get Element Count    css=table.infobox    >=    1
    Get Text    css=table.infobox >> nth=0    contains    Capital
    Get Text    css=table.infobox >> nth=0    contains    Helsinki

Finnish Article Has Its Main Sections
    [Tags]    finnish
    Open Article    ${FI}/Suomi    Suomi
    FOR    ${section}    IN    Historia    Maantiede    Talous    Väestö
        Section Should Exist    ${section}
    END
