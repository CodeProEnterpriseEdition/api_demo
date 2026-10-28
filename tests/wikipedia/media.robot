*** Settings ***
Documentation       Images and large pages: an image loads, images load while
...                 scrolling, a long article and a large table.
Resource            wikipedia.resource
Suite Setup         Open Wikipedia Browser
Suite Teardown      Close Browser    ALL
Test Tags           media
Test Timeout        2 minutes


*** Test Cases ***
Infobox Image Loads
    [Tags]    smoke
    Open Article    ${EN}/Finland    Finland
    # ${0} is a number: Get Property returns a number and does not convert the
    # expected value.
    Get Property    css=table.infobox img >> nth=0    naturalWidth    >    ${0}

Images Load While Scrolling
    [Tags]    heavy
    Open Article    ${EN}/Helsinki    Helsinki
    ${before}=    Loaded Images
    FOR    ${i}    IN RANGE    15
        Scroll By    vertical=100%
        Sleep    0.3s
    END
    Wait For Load State    networkidle    timeout=30s
    ${after}=    Loaded Images
    Should Be True    ${after} > ${before}
    ...    msg=No more images loaded while scrolling (${before} -> ${after}).

Long Article Loads Completely
    [Tags]    heavy
    Open Article    ${EN}/World_War_II    World War II
    Scroll To    vertical=bottom
    Wait For Load State    networkidle    timeout=30s
    Section Should Exist    Aftermath
    Get Element Count    css=ol.references > li    >=    300

Large Table Has All Rows
    [Tags]    heavy
    Go To    ${EN}/List_of_countries_and_dependencies_by_population
    Get Text    id=firstHeading    contains    by population
    Get Element Count    css=table.wikitable >> nth=0 >> css=tr    >=    200
