*** Settings ***
Library     Collections
Library     RPA.Browser.Selenium
Library     RPA.Robocorp.WorkItems
Library     RPA.Tables
Library     OperatingSystem


*** Tasks ***
Consume items
    [Documentation]    Login and then cycle through work items.
    TRY
        Log Environment Variables    level=WARN
        Login
        For Each Input Work Item    Handle item
    EXCEPT    AS    ${err}
        Log    ${err}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=APPLICATION
        ...    code=UNCAUGHT_ERROR
        ...    message=${err}
    END


*** Keywords ***
Login
    [Documentation]
    ...    Simulates a login that fails 1/5 times to highlight APPLICATION exception handling.
    ...    In this example login is performed only once for all work items.
    ${Login as James Bond}=    Evaluate    random.randint(1, 5)
    IF    ${Login as James Bond} != 1
        Log    Logged in as Bond. James Bond.
    ELSE
        Fail    Login failed
    END

Action for item
    [Documentation]
    ...    Simulates handling of one work item that fails 1/5 times in
    ...    two different ways to highlight BUSINESS and APPLICATION exception handling
    ...    and how you can handle each differently from the main "Handle item" keyword.
    [Arguments]    ${payload}
    ${Item Action OK}=    Evaluate    random.randint(1, 15)
    IF    ${Item Action OK} not in [1,2,3]
        Log    Did the first thing for: ${payload}
    ELSE IF    ${Item Action OK} == 1
        Fail    Invalid data in payload: ${payload}.
    ELSE IF    ${Item Action OK} == 2
        Fail    Application timed out, try again later.
    ELSE IF    ${Item Action OK} == 3
        Fail    I'm an unexpected error
    END

Handle item
    [Documentation]    Error handling around one work item.
    ${payload}=    Get Work Item Variables
    TRY
        Action for item    ${payload}
        &{vars}=    Create Dictionary
        ...    step_id=%{RC_ACTIVITY_ID=${NONE}}
        Create Output Work Item    ${vars}    save=True
        Release Input Work Item    DONE
    EXCEPT    Invalid data    type=START    AS    ${err}
        # Giving a good error message here means that data related errors can
        # be fixed faster in Control Room.
        # You can extract the text from the underlying error message.
        ${error_message}=    Set Variable
        ...    Data may be invalid, encountered error: ${err}
        Log    ${error_message}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=BUSINESS
        ...    code=INVALID_DATA
        ...    message=${error_message}
    EXCEPT    *timed out*    type=GLOB    AS    ${err}
        ${error_message}=    Set Variable
        ...    Application error encountered: ${err}
        Log    ${error_message}    level=ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=APPLICATION
        ...    code=TIMEOUT
        ...    message=${error_message}
    END
