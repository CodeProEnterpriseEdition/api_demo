*** Settings ***
Documentation       Searching: the search box, full text search, no results and
...                 redirects.
Resource            wikipedia.resource
Suite Setup         Open Wikipedia Browser
Suite Teardown      Close Browser    ALL
Test Tags           search
Test Timeout        2 minutes


*** Variables ***
${SEARCH}       https://en.wikipedia.org/w/index.php?title=Special:Search&ns0=1&fulltext=1&search=


*** Test Cases ***
Search Box Finds Article
    [Tags]    smoke
    Go To    ${EN}/Main_Page
    Fill Text    css=#searchform input[name="search"]    Tampere
    Keyboard Key    press    Enter
    Get Text    id=firstHeading    ==    Tampere

Full Text Search Lists Results
    Go To    ${SEARCH}sauna+bathing
    Get Element Count    css=li.mw-search-result    >=    10
    Get Text    css=.mw-search-result-heading a >> nth=0    contains    Sauna

Search Without Results Says So
    Go To    ${SEARCH}xqzvwkjhgfpl
    Get Text    css=p.mw-search-nonefound    contains    no results

Redirect Leads To The Right Article
    Open Article    ${EN}/Helsingfors    Helsinki
    Get Text    css=.mw-redirectedfrom    contains    Helsingfors
