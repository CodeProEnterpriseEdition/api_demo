*** Settings ***
Documentation       Load test: headless Chromium computes in ${THREADS} threads
...                 for the given time on the container's own test page. No
...                 network is used. In every round each thread counts the
...                 primes up to ${LIMIT} once, so a round is ${THREADS}
...                 computations. Computations per minute tell how much work
...                 the run got done, so single and parallel runs can be
...                 compared. The time of every round goes to round-times.txt
...                 (seconds from the start), for the minute-by-minute view.
...
...                 Run: robot --variable DURATION_MIN:3 --variable THREADS:2 load-test.robot
Library             Browser
Library             OperatingSystem


*** Variables ***
${DURATION_MIN}     3
${LIMIT}            2000000
${THREADS}          2
${PAGE}             ${CURDIR}/page.html


*** Test Cases ***
Browser Loads Processor And Memory
    New Browser    chromium    headless=True
    New Page    file://${PAGE}
    ${start}=    Evaluate    time.time()    modules=time
    ${end}=    Evaluate    ${start} + float(${DURATION_MIN}) * 60
    ${times}=    Create List
    WHILE    True    limit=NONE
        ${primes}=    Evaluate JavaScript    ${None}    () => round(${LIMIT}, ${THREADS})
        Should Be Equal As Integers    ${primes}    148933
        ${now}=    Evaluate    time.time()    modules=time
        Evaluate    $times.append(round($now - $start, 1))
        IF    ${now} >= ${end}    BREAK
    END
    ${rounds}=    Get Length    ${times}
    Get Text    id=result    contains    primes 148933
    Log    Rounds ${rounds} in ${THREADS} threads (${DURATION_MIN} min)    console=True
    Create File    ${OUTPUT DIR}/rounds.txt    ${rounds}
    ${lines}=    Evaluate    chr(10).join(map(str, $times))
    Create File    ${OUTPUT DIR}/round-times.txt    ${lines}
    [Teardown]    Close Browser    ALL
