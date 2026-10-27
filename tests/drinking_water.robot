*** Settings ***
Documentation       Drinking water quality by area (Tampereen Vesi, Vellamo API).
...                 The values are simulation results, not laboratory analyses.
Resource            resources/tampere.resource


*** Test Cases ***
Measurements Are Known
    ${data}=    Get Json    ${VELLAMO}/measurements.json
    ${slugs}=    Evaluate    sorted(m['slug'] for m in $data)
    Should Be Equal    ${slugs}    ${{ ['cl', 'hardness', 'ph', 't'] }}

Drinking Water pH Is Within Limits Everywhere
    [Documentation]    Quality recommendation for drinking water pH in Finland: 6.5-9.5.
    ${areas}=    Get Json    ${VELLAMO}/latest.json
    ${count}=    Get Length    ${areas}
    Should Be True    ${count} > 100    Only ${count} areas
    ${ph}=    Evaluate
    ...    {a['name']: (a.get('latest_measurements') or {}).get('ph') for a in $areas if (a.get('latest_measurements') or {}).get('ph') is not None}
    Should Not Be Empty    ${ph}
    ${outside}=    Evaluate    {name: value for name, value in $ph.items() if not 6.5 <= value <= 9.5}
    Should Be Empty    ${outside}    pH outside 6.5-9.5: ${outside}
    ${average}=    Evaluate    round(sum($ph.values()) / len($ph), 2)
    Log    ${count} areas, ${{ len($ph) }} with a pH value, average pH ${average}.
