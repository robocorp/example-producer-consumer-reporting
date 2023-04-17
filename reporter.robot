*** Settings ***
Library     RPA.Robocorp.Process
Library     RPA.Robocorp.WorkItems
Library     RPA.Robocorp.Vault
Library     Collections
Library     OperatingSystem


*** Tasks ***
Report Results
    Get information from input work item
    ${time_to_report}=    Is it time to report
    Set To Dictionary    ${PAYLOAD}    reporting=${time_to_report}
    Set Work Item Payload    ${PAYLOAD}
    Save Work Item
    # Resolve do we need to report or not
    IF    ${time_to_report}
        Log To Console    \nTIME TO REPORT\n
    ELSE
        Log To Console    \nTIME TO WAIT\n
    END


*** Keywords ***
Get information from input work item
    ${secrets}=    Get Secret    Reporting
    Set Credentials
    ...    workspace_id=${secrets}[workspace_id]
    ...    process_id=${secrets}[process_id]
    ...    apikey=${secrets}[apikey]
    # Get work item variables coming from Step 2
    ${payload}=    Get Work Item Payload
    Set Task Variable    ${STEP_ID}    ${payload}[step_id]
    Set Task Variable    ${PAYLOAD}    ${payload}

Is it time to report
    [Documentation]    Get all process run work item with Process Library.
    ...    Loop item by item and inspect their states.
    ...    We need to have all step 2 (STEP_ID) items as COMPLETED before reporting.
    ${items}=    List Process Run Work Items    %{RC_PROCESS_RUN_ID=${NONE}}
    Log List    ${items}    level=WARN
    ${time_to_report}=    Set Variable    ${TRUE}
    # Loop through all work items related to this process run
    FOR    ${index}    ${item}    IN ENUMERATE    @{items}
        Log To Console    \nID: ${{$index+1}} ITEM ID: ${item}[id]
        Log To Console    ITEM STATE: ${item}[state]
        # If something is completed, proceed to next item
        IF    "${item}[state]" == "COMPLETED"            CONTINUE
        # Nothing to report if there are still something PENDING
        # break the loop
        IF    "${item}[state]" == "PENDING"
            ${time_to_report}=    Set Variable    ${FALSE}
            BREAK
        END
        Log To Console    ITEM STEP ID: ${item}[activityId]
        # skip item which is not from Step 2
        IF    "${item}[activityId]" != "${STEP_ID}"            CONTINUE
        # if previous checks did not CONTINUE or BREAK already
        # then item is from Step 2 but it is not COMPLETED
        ${time_to_report}=    Set Variable    ${FALSE}
        BREAK
    END
    RETURN    ${time_to_report}
