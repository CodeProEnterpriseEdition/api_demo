*** Settings ***
Documentation       Shared addresses and keywords for the City of Tampere open APIs.
...                 Data: City of Tampere and ITS Factory, licence CC BY 4.0
...                 (https://data.tampere.fi).
Library             RequestsLibrary
Library             Collections


*** Variables ***
${JOURNEYS}         https://data.itsfactory.fi/journeys/api/1
${PORTAL}           https://data.tampere.fi/data/api/3/action
${VELLAMO}          https://vellamo.tampere.fi/api/v1
${NEWS_FEED}        https://www.tampere.fi/ajankohtaista/uutiset.xml
# DataStore table of the swimming halls dataset (tampereen-kaupungin-uimahallit).
${SWIMMING_HALLS}   85db624f-c930-4afb-9be3-3613078bd077
# Seconds: a request fails after TIMEOUT, and a response slower than SLOW is
# logged as a warning.
${TIMEOUT}          20
${SLOW}             5


*** Keywords ***
Get Response
    [Documentation]    HTTP GET that must return 200. Logs the response time.
    [Arguments]    ${url}    &{params}
    ${response}=    GET    ${url}    params=${params}    expected_status=200    timeout=${TIMEOUT}
    ${seconds}=    Evaluate    round($response.elapsed.total_seconds(), 2)
    Log    ${url}: ${seconds} s
    IF    ${seconds} > ${SLOW}    Log    Slow response: ${url} took ${seconds} s    WARN
    RETURN    ${response}

Get Json
    [Documentation]    HTTP GET that must return 200, parsed as JSON.
    [Arguments]    ${url}    &{params}
    ${response}=    Get Response    ${url}    &{params}
    RETURN    ${response.json()}
