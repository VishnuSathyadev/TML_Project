*** Settings ***
Library      RPA.Excel.Files
Library      OperatingSystem
Library      RPA.FileSystem
Library      DateTime
Library      Collections
Library      RPA.Robocorp.WorkItems
Library      ../Libraries/ExcelOperations.py
Resource     TextLog.robot
Variables    ../Variables/GlobalVariables.py


*** Variables ***
@{ColumnHeaders}       Login       Position      Invoice Month       Invoice Type     Reference No      Generate IRN & GST	    Download          Digital Sign        Upload            File Name          Processed Date      Status             Comments
@{ColumnHeaders2}      Login       Position      Invoice Month       Invoice Type     IRN Status        IRN Total	            IRN Success	      IRN Exception	      Upload Status     Upload Total	   Upload Success	   Upload Exception     
@{ColumnHeaders3}      Login ID    Position      IRN Total	         IRN Success	  IRN Exception	    Upload Total	        Upload Success	  Upload Exception    Status               

*** Keywords ***
Update Status 
    [Documentation]    This keyword will create an excel file and update all the TML process status in that excel file.
    [Arguments]        ${StatusData}    ${UniqueId}    ${StatusFile}    ${SheetName}
    TRY       
        #Update the status in excel by invoking python code
        Update Excel Cell    ${StatusFile}    ${SearchColumnNamne}    ${UniqueId}    @{StatusData}    ${SheetName}

        ${Log}               Set Variable     Successfully updated the status in Excel tracker.
        Text File Log        Info             Update Status     ${Log}
        Log                  ${Log}  
    EXCEPT    AS    ${ErrorMessage}
        Log              ${ErrorMessage}
        Text File Log    Error                Update Status     ${ErrorMessage}
    END

Create Status Excel File
    [Documentation]    This keyword will create an excel file and update all the TML process status in that excel file.
    [Arguments]        
    TRY
        ${CurrentDate}           Get Current Date       result_format=%d_%m_%Y_%H_%M_%S
        ${StatusFile}            Set Variable           ${EXECDIR}/Input/StatusTrackerExcel_${CurrentDate}.xlsx  
        Set Global Variable      ${StatusFilePath}      ${StatusFile}
        ${StatusFileExist}       Does File Exist        ${StatusFile}
        #Create excel file if not exist
        IF  ('${StatusFileExist}'=='${False}')
            Create Workbook    ${StatusFile}            sheet_name=${TrackerSheetName}
            Save Workbook      ${StatusFile}  
            Open Workbook      ${StatusFile}
    
            # Loop through the list to add column headers dynamically for first sheet
            ${Index}    Evaluate    1
            FOR    ${Header}    IN    @{ColumnHeaders}
                Set Cell Value    row=1       column=${Index}    value=${Header}
                ${Index}          Evaluate    ${Index} + 1
            END

            # Loop through the list to add column headers dynamically for second sheet
            Create Worksheet     ${BriefTrackerSheet}
            ${SecondIndex}    Evaluate    1
            FOR    ${Header}    IN    @{ColumnHeaders2}
                Set Cell Value    row=1       column=${SecondIndex}    value=${Header}    
                ${SecondIndex}    Evaluate    ${SecondIndex} + 1
            END

            # Loop through the list to add column headers dynamically for third sheet
            Create Worksheet     ${ReportSheetName}
            ${ThirdIndex}    Evaluate    1
            FOR    ${Header}    IN    @{ColumnHeaders3}
                Set Cell Value    row=1       column=${ThirdIndex}    value=${Header}    
                ${ThirdIndex}     Evaluate    ${ThirdIndex} + 1
            END

            #Saving and closing the workbook
            Save Workbook
            Close Workbook  
        END
        ${Log}               Set Variable     Successfully created the status excel tracker.
        Text File Log        Info             Create Status Excel File     ${Log}
        Log                  ${Log} 
        RETURN    True       ${StatusFile}
    EXCEPT    AS    ${ErrorMessage}
        Log                  ${ErrorMessage}
        Text File Log        Error            Create Status Excel File     ${ErrorMessage}
        RETURN    False      None
    END

Append Cell Value To Excel
    [Documentation]    Append values to Unique ID column dynamically.
    [Arguments]        ${Value}    ${StatusFilePath}    ${ColumnName}    ${SheetName}
    TRY
        Open Workbook         ${StatusFilePath}
        ${SheetData}          Read Worksheet         name=${SheetName}    header=False
        ${RowCount}           Get Length             ${SheetData}
        ${RowCount}           Evaluate               ${RowCount} + 1
        ${ColumnIndex}        Get Column Index       ${ColumnName}            ${SheetName}    ${StatusFilePath}  
        Set Cell Value        row=${RowCount}        column=${ColumnIndex}    value=${Value}
        Save Workbook
        Close Workbook
        ${Log}               Set Variable     Successfully updated Unique ID in Excel tracker.
        Text File Log        Info             Append Unique ID To Excel     ${Log}
        Log                  ${Log}
    EXCEPT    AS    ${ErrorMessage}
        Log                  ${ErrorMessage}
        Text File Log        Error            Append Unique ID To Excel     ${ErrorMessage}
    END

Append Multiple Cells In Excel Row
    [Documentation]    Append values to specified columns dynamically using a dictionary.
    [Arguments]        ${Data}    ${StatusFilePath}    ${SheetName}
    TRY
        Open Workbook         ${StatusFilePath}
        ${SheetData}          Read Worksheet         name=${SheetName}    header=False
        ${RowCount}           Get Length             ${SheetData}
        ${RowCount}           Evaluate               ${RowCount} + 1
        
        # Iterate through the dictionary and update each column
        FOR    ${ColumnName}    ${Value}    IN    &{Data}
            ${ColumnIndex}        Get Column Index       ${ColumnName}            ${SheetName}    ${StatusFilePath}
            Set Cell Value        row=${RowCount}        column=${ColumnIndex}    value=${Value}
        END
        
        Save Workbook
        Close Workbook
        ${Log}               Set Variable     Successfully updated columns in Excel.
        Text File Log        Info             Append Multiple Cells In Excel Row     ${Log}
        Log                  ${Log}
    EXCEPT    AS    ${ErrorMessage}
        Log                  ${ErrorMessage}
        Text File Log        Error            Append Multiple Cells In Excel Row     ${ErrorMessage}
    END
