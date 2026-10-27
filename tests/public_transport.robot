*** Settings ***
Documentation       Nysse public transport: lines and real-time bus locations
...                 (ITS Factory Journeys API, no key needed).
Resource            resources/tampere.resource


*** Test Cases ***
Lines Are Listed
    ${data}=    Get Json    ${JOURNEYS}/lines
    Should Be Equal    ${data}[status]    success
    ${count}=    Get Length    ${data}[body]
    Should Be True    ${count} > 50    Only ${count} lines
    Log    Nysse has ${count} lines.

Line 3 Runs From Hervanta
    ${data}=    Get Json    ${JOURNEYS}/lines/3
    Should Contain    ${data}[body][0][description]    Hervanta

Buses On Line 3 Are In Tampere Right Now
    [Documentation]    Real-time locations. At night there may be no buses,
    ...    and then the test is skipped.
    ${data}=    Get Json    ${JOURNEYS}/vehicle-activity    lineRef=3
    ${buses}=    Set Variable    ${data}[body]
    ${count}=    Get Length    ${buses}
    Skip If    ${count} == 0    No buses on line 3 right now.
    FOR    ${bus}    IN    @{buses}
        ${journey}=    Set Variable    ${bus}[monitoredVehicleJourney]
        Should Be Equal    ${journey}[lineRef]    3
        ${lat}=    Convert To Number    ${journey}[vehicleLocation][latitude]
        ${lon}=    Convert To Number    ${journey}[vehicleLocation][longitude]
        Should Be True    61.3 < ${lat} < 61.7 and 23.4 < ${lon} < 24.2
        ...    Bus ${journey}[vehicleRef] is not in the Tampere region: ${lat}, ${lon}
        ${age}=    Evaluate
        ...    (datetime.datetime.now(datetime.timezone.utc) - datetime.datetime.fromisoformat($bus['recordedAtTime'].replace('Z', '+00:00'))).total_seconds()
        ...    modules=datetime
        Should Be True    ${age} < 600    Location of ${journey}[vehicleRef] is ${age} s old
    END
    Log    ${count} buses on line 3 right now.
