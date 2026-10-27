*** Settings ***
Documentation       City of Tampere open data portal (CKAN API): search and
...                 DataStore table queries.
Resource            resources/tampere.resource


*** Test Cases ***
Portal Responds
    ${data}=    Get Json    ${PORTAL}/status_show
    Should Be True    ${data}[success]
    Should Contain    ${data}[result][site_title]    Tampere

Search Finds Swimming Halls
    ${data}=    Get Json    ${PORTAL}/package_search    q=uimahallit
    Should Be True    ${data}[result][count] >= 1
    ${names}=    Evaluate    [p['name'] for p in $data['result']['results']]
    List Should Contain Value    ${names}    tampereen-kaupungin-uimahallit

Swimming Halls As A Table Query
    [Documentation]    DataStore returns the rows of a dataset like a database table.
    ${data}=    Get Json    ${PORTAL}/datastore_search    resource_id=${SWIMMING_HALLS}    limit=50
    Should Be True    ${data}[result][total] >= 3
    ${names}=    Evaluate    [r['NIMI'] for r in $data['result']['records']]
    List Should Contain Value    ${names}    Pyynikin uimahalli
    Log    Swimming halls: ${names}

Filter By Postal Code
    ${data}=    Get Json    ${PORTAL}/datastore_search    resource_id=${SWIMMING_HALLS}
    ...    filters={"POSTINUMERO": 33540}
    Should Be Equal As Integers    ${data}[result][total]    1
    Should Be Equal    ${data}[result][records][0][NIMI]    Tampereen uintikeskus
