*** Settings ***
Library     Collections
Library     RPA.Excel.Files
Library     RPA.Robocorp.WorkItems
Library     RPA.Tables


*** Tasks ***
Produce items
    [Documentation]
    ...    Get source Excel file from work item.
    ...    Read rows from Excel.
    ...    Creates output work items per row.
    ${path}=    Get Work Item File    orders.xlsx    ${OUTPUT_DIR}${/}orders.xlsx
    Open Workbook    ${path}
    ${table}=    Read Worksheet As Table    header=True
    FOR    ${row}    IN    @{table}
        ${variables}=    Create Dictionary
        ...    Name=${row}[Name]
        ...    Zip=${row}[Zip]
        ...    Item=${row}[Item]
        Create Output Work Item
        ...    variables=${variables}
        ...    save=True
    END
