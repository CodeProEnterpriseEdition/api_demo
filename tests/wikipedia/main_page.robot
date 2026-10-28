*** Settings ***
Documentation       The main page: its sections, the news and today's featured
...                 article (changes every day), in English and Finnish.
Resource            wikipedia.resource
Suite Setup         Open Wikipedia Browser
Suite Teardown      Close Browser    ALL
Test Tags           main-page
Test Timeout        2 minutes


*** Test Cases ***
Main Page Has Its Sections
    [Tags]    smoke
    Go To    ${EN}/Main_Page
    FOR    ${section}    IN    mp-tfa    mp-itn    mp-dyk    mp-otd
        Get Element States    id=${section}    contains    visible
    END

In The News Has Items
    Go To    ${EN}/Main_Page
    Get Element Count    css=#mp-itn li    >=    3

Featured Article Opens
    Go To    ${EN}/Main_Page
    Click    css=#mp-tfa b a >> nth=0
    Get Url    not contains    Main_Page
    Get Text    id=firstHeading    !=    ${EMPTY}
    Get Element Count    css=#mw-content-text p    >    3

Finnish Main Page Has Its Sections
    [Tags]    finnish
    Go To    ${FI}/Wikipedia:Etusivu
    Get Title    contains    Wikipedia
    FOR    ${section}    IN    Uutisissa    Miten_voit_auttaa
        Get Element Count    css=[id="${section}"]    >=    1
    END
