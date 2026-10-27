*** Settings ***
Documentation       City of Tampere news as an RSS feed: the same HTTP GET as an
...                 API call, but the answer is a fixed XML list of the latest items.
Resource            resources/tampere.resource
Library             XML


*** Test Cases ***
News Feed Is Valid RSS
    ${response}=    Get Response    ${NEWS_FEED}
    Should Contain    ${response.headers}[Content-Type]    xml
    ${rss}=    Parse XML    ${response.text}
    Should Be Equal    ${rss.tag}    rss
    ${items}=    Get Elements    ${rss}    channel/item
    ${count}=    Get Length    ${items}
    Should Be True    ${count} >= 5    Only ${count} news items
    FOR    ${item}    IN    @{items}
        Element Should Exist    ${item}    title
        Element Should Exist    ${item}    pubDate
        ${link}=    Get Element Text    ${item}    link
        Should Start With    ${link}    https://www.tampere.fi/
    END
    ${latest}=    Get Element Text    ${items}[0]    title
    Log    ${count} news items, latest: ${latest}
