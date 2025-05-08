*** Settings ***
Documentation   This robot files consist of the main processes in the whole project.
Library         RPA.Browser.Selenium
Library         RPA.Browser.Playwright
Library         RPA.JavaAccessBridge
Library         RPA.Desktop
Library         DateTime
Library         OperatingSystem
Library         RPA.FileSystem
Resource        ConfigManagement.robot
Resource        TextLog.robot
Resource        Status.robot
Resource        InitialActions.robot
Resource        ExceptionHandling.robot
Resource        DigitalSign_Sikuli.robot
Resource        FileRemoving.robot
Library         ../Libraries/ExcelOperations.py
Library         ../Libraries/GoogleDrive.py
Library         ../Libraries/Common.py
Variables       ../PageObjects/PageSelectors.py
Variables       ../Variables/GlobalVariables.py

*** Variables ***  
@{MonthList}  
@{TmlNoList} 
@{NewTmlNoList}
&{MatchDictionary}
&{ReadDictionary}
&{AppendDictionary} 
@{InvoiceStatusList}  
&{StatusDictionary}
@{ListOfLoginId}
@{BranchNameList}
${ActionRetryLimit}    2
${TotalInvoice}
${SuccessCount}
${FailureCount}

*** Keywords ***

TML Invoice Process Loop
    [Arguments]    ${ListOfLoginId}    ${DataTable}
    TRY
        ${CreationStatus}    ${StatusFilePath}    Create Status Excel File
        IF  ${CreationStatus}
            ${Log}           Set Variable    Successfully created the status tracker file.
            Text File Log    Info            TML Invoice Process Loop    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Creation of status tracker file failed.
            Text File Log    Error           TML Invoice Process Loop    ${Log}
            Fail             ${Log}
        END
        
        #Setting Maximum Retry Count
        ${ConfigRetryCount}    Evaluate         ${CONFIG}[RetryCount]
        Set GlobalVariable     ${MaxRetries}    ${ConfigRetryCount}

        #Set Current Date
        ${CurrentDate}        Get Current Date       result_format=%d_%m_%Y

        #Check whether file exist in Status folder in Google Drive
        ${FileExistInDrive}       ${StatusFileName}    Check File Exists    ${CLIENT_CONFIG}[StatusFolderId]    ${CurrentDate} 
        IF  ${FileExistInDrive}
            #Set Designation Path
            ${DesignationPath}    Set Variable     ${EXECDIR}/Input/${StatusFileName}
            ${ForcedRunEnable}    Evaluate         True
            ${DownloadStatus}     Download File    ${CLIENT_CONFIG}[StatusFolderId]    ${StatusFileName}    ${DesignationPath}
            IF  ${DownloadStatus}
                ${Log}            Set Variable    Status file for forced run downloaded successfully.
                Text File Log     Info            TML Invoice Process Loop    ${Log}
                Log               ${Log}
            ELSE
                ${Log}            Set Variable    Exception occurred while downloading status file for forced run.
                Text File Log     Info            TML Invoice Process Loop    ${Log}
                Fail              ${Log}
            END
            ${ForcedRunTable}     Forced Run List    ${DesignationPath}    ${ReportSheetName}

            #Removing Values From Login ID List
            Remove Values From List    ${ListOfLoginId}    @{ListOfLoginId}

            #Used a For Loop to append required Login IDs to the list variable
            FOR    ${Dict}    IN    @{ForcedRunTable}
                Append To List    ${ListOfLoginId}       ${Dict}[Login ID]
                Append To List    ${BranchNameList}      ${Dict}[Position]
            END
        ELSE
            ${ForcedRunEnable}    Evaluate        False
            ${Log}                Set Variable    No status file in Google Drive folder, so resuming normal run.
            Text File Log         Info            TML Invoice Process Loop    ${Log}
            Log                   ${Log}
        END       

        FOR    ${LoginId}    IN    @{ListOfLoginId}

            #Filtering the list data from config excel as key value pair based on the provided column value for Lgin IDs
            IF  ${ForcedRunEnable}
                ${ListOfDictionary}    ExcelOperations.Filter Data Table For Specific Column Value    ${DataTable}    Login ID            ${LoginId}
                ${ListOfDictionary}    ExcelOperations.Filter Table    ${ListOfDictionary}            Branch Name     ${BranchNameList}
            ELSE
                ${ListOfDictionary}    ExcelOperations.Filter Data Table For Specific Column Value    ${DataTable}    Login ID             ${LoginId}
            END
            
            ${LengthOfList}        Get Length      ${ListOfDictionary}
            
            ${IterationCounter}    Evaluate         0
            
            FOR    ${Dictionary}    IN    @{ListOfDictionary} 
                ${IterationCounter}           Evaluate    ${IterationCounter} + 1
                ${RetryCount}                 Evaluate    0
                ${InvalidCredentialStatus}    Evaluate    False
                
                ${Log}           Set Variable    Started processing Login ID: ${Dictionary}[Login ID]
                Text File Log    Info            TML Invoice Process Loop     ${Log}
                Log              ${Log}
                 
                WHILE    ${RetryCount} < ${MaxRetries}
                    TRY
                        IF  ${IterationCounter} == 1
                            #Invoking Login Process
                            ${LoginStatus}    ${InvalidCredentialStatus}    Login Portal    ${Dictionary}
                            IF  ${LoginStatus}
                                ${Log}           Set Variable    Successfully logged into SAP system.
                                Text File Log    Info            TML Invoice Process Loop    ${Log}
                                Log              ${Log}
                                BREAK  
                            ELSE IF    ${InvalidCredentialStatus}
                                ${Log}           Set Variable    Login failed due to invalid credentials.
                                Text File Log    Error           TML Invoice Process Loop    ${Log}
                                Fail             ${Log}
                            ELSE
                                ${Log}           Set Variable    Attempt to log into SAP system was a failure.
                                Text File Log    Error           TML Invoice Process Loop    ${Log}
                                Fail             ${Log}   
                            END
                        END
                        BREAK
                    EXCEPT
                        ${Log}           Set Variable    Login failed for Login ID: ${Dictionary}[Login ID]
                        Text File Log    Error           TML Invoice Process Loop    ${Log}
                        Log              ${Log}
                        
                        ${RetryCount}        Evaluate        ${RetryCount} + 1 
                        IF  ${RetryCount} >= ${MaxRetries}
                            ${Log}                Set Variable             Max retries reached for Login ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                            Text File Log         Info                     TML Invoice Process Loop    ${Log}
                            Log                   ${Log}
                            Set To Dictionary     ${StatusDictionary}      Login ID               ${Dictionary}[Login ID]   
                            Set To Dictionary     ${StatusDictionary}      Status                 Not Completed  
                            Set To Dictionary     ${StatusDictionary}      Position               N/A
                            Set To Dictionary     ${StatusDictionary}      IRN Total              0
                            Set To Dictionary     ${StatusDictionary}      IRN Success            0
                            Set To Dictionary     ${StatusDictionary}      IRN Exception          0
                            Set To Dictionary     ${StatusDictionary}      Upload Total           0
                            Set To Dictionary     ${StatusDictionary}      Upload Success         0 
                            Set To Dictionary     ${StatusDictionary}      Upload Exception       0  
    
                            Append Multiple Cells In Excel Row      ${StatusDictionary}       ${StatusFilePath}       ${ReportSheetName} 
                            Remove From Dictionary                  ${StatusDictionary}       Login ID                Position      IRN Total	   IRN Success	  IRN Exception	    Upload Total	 Upload Success	  Upload Exception    Status    
                        ELSE IF    ${InvalidCredentialStatus}
                            ${RetryCount}         Evaluate                 ${MaxRetries} + 0
                            Set To Dictionary     ${StatusDictionary}      Login ID               ${Dictionary}[Login ID]   
                            Set To Dictionary     ${StatusDictionary}      Status                 Invalid Credentials 
                            Set To Dictionary     ${StatusDictionary}      Position               N/A
                            Set To Dictionary     ${StatusDictionary}      IRN Total              0
                            Set To Dictionary     ${StatusDictionary}      IRN Success            0
                            Set To Dictionary     ${StatusDictionary}      IRN Exception          0
                            Set To Dictionary     ${StatusDictionary}      Upload Total           0
                            Set To Dictionary     ${StatusDictionary}      Upload Success         0 
                            Set To Dictionary     ${StatusDictionary}      Upload Exception       0   
    
                            Append Multiple Cells In Excel Row      ${StatusDictionary}       ${StatusFilePath}       ${ReportSheetName} 
                            Remove From Dictionary                  ${StatusDictionary}       Login ID                Position      IRN Total	   IRN Success	  IRN Exception	    Upload Total	 Upload Success	  Upload Exception    Status    
                            BREAK
                        ELSE
                            RPA.Browser.Playwright.Close Browser
                            Open Website
                        END
                    END
                END

                IF  ${RetryCount} < ${MaxRetries}

                    ${RetryCount}          Evaluate    0
                    WHILE    ${RetryCount} < ${MaxRetries}
                        TRY
                            IF  ${IterationCounter} != 1
                                ${HomePageIconExist}    Element Visible Action    ${loc_direct_home_button}
                                IF  ${HomePageIconExist}
                                    Click Element When Clickable Action           ${loc_direct_home_button}
                                END
                            END
                            
                            #Invoking Navigation To SAP Screen Keyword
                            ${NavigationStatus}     Navigation To SAP Warranty    ${Dictionary}
                            IF  ${NavigationStatus}
                                ${Log}           Set Variable    Successfully navigated to SAP Warranty screen.
                                Text File Log    Info            TML Invoice Process Loop    ${Log}
                                Log              ${Log}
                                BREAK
                            ELSE
                                ${Log}           Set Variable    Navigation to SAP Warranty screen failed.
                                Text File Log    Error           TML Invoice Process Loop    ${Log}
                                Fail             ${Log}
                            END
                        EXCEPT
                            ${Log}           Set Variable    Navigation to SAP Warranty screen failed for Login ID: ${Dictionary}[Login ID]
                            Text File Log    Error           Navigation To SAP Warranty    ${Log}
                            Log              ${Log}
                            
                            ${RetryCount}    Evaluate        ${RetryCount} + 1
                            IF  ${RetryCount} >= ${MaxRetries}
                                ${Log}           Set Variable    Max retries reached for Login ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                                Text File Log    Info            TML Invoice Process Loop    ${Log}
                                Log              ${Log}
                            ELSE
                                ${HomePageIconExist}       Element Visible Action      ${loc_direct_home_button}
                                ${SessionTimeoutExist}     Element Visible Action      ${loc_session_timeout}
                                IF  ${SessionTimeoutExist}
                                    ${RetryLoopStatus}     Retry Scenario Position     ${Dictionary}
                                    IF  ${RetryLoopStatus}
                                        ${Log}           Set Variable    Successfully closed the browser and logged in again.
                                        Text File Log    Info            TML Invoice Process Loop    ${Log}
                                        Log              ${Log}
                                        CONTINUE
                                    END
                                ELSE IF    ${HomePageIconExist}
                                    Click Element When Clickable Action              ${loc_direct_home_button}
                                END
                            END
                        END
                    END
                    
                    #Setting Dictionary For End Report
                    Set To Dictionary       ${StatusDictionary}      Login ID       ${Dictionary}[Login ID]    
                    Set To Dictionary       ${StatusDictionary}      Position       ${Dictionary}[Branch Name]

                    #Appending Data To Excel  
                    Append Multiple Cells In Excel Row      ${StatusDictionary}     ${StatusFilePath}      ${ReportSheetName} 
                    Remove From Dictionary                  ${StatusDictionary}     Login ID               Position 

                    ${GenerationIRNStatus}    ${TotalInvoice}    ${SuccessCount}     ${FailureCount}    Setting Filters And Generate Invoices   ${Dictionary}
                    IF  ${GenerationIRNStatus}  
                        ${Log}           Set Variable    Successfully completed IRN generation process.
                        Text File Log    Info            TML Invoice Process Loop    ${Log}
                        Log              ${Log}
                    ELSE
                        ${Log}           Set Variable    Exception occurred during IRN generation process.
                        Text File Log    Error           TML Invoice Process Loop    ${Log}
                        Log              ${Log}
                    END  
                    
                    Set To Dictionary         ${StatusDictionary}     IRN Total         ${TotalInvoice}
                    Set To Dictionary         ${StatusDictionary}     IRN Success       ${SuccessCount}
                    Set To Dictionary         ${StatusDictionary}     IRN Exception     ${FailureCount}
        
                    #Appending Data To Excel  
                    Update Excel Cell         ${StatusFilePath}       Position      ${Dictionary}[Branch Name]    ${StatusDictionary}    ${ReportSheetName}   
                    Remove From Dictionary    ${StatusDictionary}     IRN Loop	    IRN Total	   IRN Success	  IRN Exception
                    
                    #Removing Items From Month List
                    Remove Values From List    ${MonthList}          @{MonthList}

                    # Unselecting the frame
                    # Unselect Frame

                    #Invoking Setting Filters and Generate Invoices Keyword
                    ${UploadStatus}     ${TotalInvoice}    ${SuccessCount}     ${FailureCount}    ${DataExcelPath}    Setting Filters And Uploading Invoices    ${Dictionary}  
                    IF  ${UploadStatus}  
                        ${Log}           Set Variable    Successfully completed invoice uploading process.
                        Text File Log    Info            TML Invoice Process Loop    ${Log}
                        Log              ${Log}
                    ELSE
                        ${Log}           Set Variable    Exception occurred during invoice uploading process.
                        Text File Log    Error           TML Invoice Process Loop    ${Log}
                        Log              ${Log}
                    END  
                    Set To Dictionary         ${StatusDictionary}     Upload Loop          Completed
                    Set To Dictionary         ${StatusDictionary}     Upload Total         ${TotalInvoice}
                    Set To Dictionary         ${StatusDictionary}     Upload Success       ${SuccessCount}
                    Set To Dictionary         ${StatusDictionary}     Upload Exception     ${FailureCount}
        
                    #Appending Data To Excel  
                    Update Excel Cell         ${StatusFilePath}       Position             ${Dictionary}[Branch Name]      ${StatusDictionary}    ${ReportSheetName}   
                    Remove From Dictionary    ${StatusDictionary}     Upload Loop	       Upload Total	                   Upload Success	      Upload Exception
                    
                    #Setting the consolidated excel path
                    ${ConsolidatedExcelPath}    RPA.FileSystem.Join Path    ${CONFIG}[ClaimsFolderPath]    ConsolidatedExcel.xlsx
                    Set Global Variable         ${ConsolidatedExcel}        ${ConsolidatedExcelPath}
                    
                    #Check whether data file exist
                    ${DataFiles}        RPA.FileSystem.List Files In Directory    ${DataExcelPath}
                    ${DataFileCount}    Get Length    ${DataFiles}
                    IF  ${DataFileCount} > 0
                        ${FileName}         Get File Name               ${DataFiles}[0]
                        ${DataExcelPath}    RPA.FileSystem.Join Path    ${DataExcelPath}    ${FileName}
                    
                        #Appending data to consolidated data sheet
                        ${AppendStatus}    Append Consolidated Excel    ${DataExcelPath}    ${ConsolidatedExcelPath}

                        IF  ${AppendStatus}  
                            ${Log}           Set Variable    Successfully appened data to the consolidated excel file.
                            Text File Log    Info            TML Invoice Process Loop    ${Log}
                            Log              ${Log}
                        ELSE
                            ${Log}           Set Variable    Exception occurred during appeneding data to the consolidated excel file.
                            Text File Log    Error           TML Invoice Process Loop    ${Log}
                            Log              ${Log}
                        END
                    END

                    #Closing IFrame Page
                    RPA.Browser.Playwright.Close Page
                END 
                
                #Invoking Logout Process
                IF  ${LoginStatus}
                    ${RetryCount}          Evaluate    0
                    WHILE    ${RetryCount} < ${MaxRetries}
                        TRY
                            IF  ${IterationCounter} == ${LengthOfList}
                                # Unselect Frame
                                ${LogoutStatus}    Logout Portal
                                IF   ${LogoutStatus}
                                    ${Log}           Set Variable    Successfully logged out from SAP system.
                                    Text File Log    Info            TML Invoice Process Loop    ${Log}
                                    Log              ${Log}
                                    BREAK
                                ELSE
                                    ${Log}           Set Variable    Attempt to log out from the SAP system was a failure.
                                    Text File Log    Error           TML Invoice Process Loop    ${Log}
                                    Fail             ${Log}
                                END
                            END
                            BREAK  
                        EXCEPT
                            ${Log}           Set Variable    Logout failed for Login ID: ${Dictionary}[Login ID]
                            Text File Log    Error           TML Invoice Process Loop    ${Log}
                            Log              ${Log}
                            
                            ${RetryCount}    Evaluate    ${RetryCount} + 1
                            IF  ${RetryCount} >= ${MaxRetries}
                                ${Log}           Set Variable    Max retries reached for Logout ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                                Text File Log    Info            TML Invoice Process Loop    ${Log}
                                Log              ${Log} 
                            END
                        END
                    END 
                END
                ${Log}           Set Variable    Completed processing Login ID: ${Dictionary}[Login ID]
                Text File Log    Info            TML Invoice Process Loop    ${Log} 
                Log              ${Log}  

                # Unselecting the frame
                # Unselect Frame
            END
        END

        #Invoke Update Status In Excel Keyword
        ${StatusReportUpdate}                Update Final Status In Report
        IF  ${StatusReportUpdate}  
            ${Log}           Set Variable    Successfully completed status updating process.
            Text File Log    Info            TML Invoice Process Loop    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred during status updation.
            Text File Log    Error           TML Invoice Process Loop    ${Log}
            Log              ${Log}
        END

        RETURN    True
    EXCEPT  AS    ${Exception}
        Log       ${Exception} 
        Text File Log    Error   TML Invoice Process Loop    ${Exception} 
        RETURN           False       
    END   

Setting Filters And Generate Invoices
    [Documentation]     Setting up filters Month-Year, Invoice Type, Invoice Status for GST invoice IRN generation.
    [Arguments]         ${Dictionary}  
    TRY
        ${Log}           Set Variable    Started processing Setting Filters And Generate Invoices
        Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
        Log              ${Log}
        
        #Initializing Values for Invoice Counts
        ${TotalInvoice}    Evaluate    0
        ${SuccessCount}    Evaluate    0
        ${FailureCount}    Evaluate    0
        ${RetryCount}      Evaluate    0

        WHILE    ${RetryCount} < ${MaxRetries}
            TRY
                Sleep                ${SHORT_WAIT}
                ${Value}             RPA.Browser.Playwright.Get Property    //object    data
                Log To Console       ${Value}
                New Page             ${Value}
                Set Viewport Size    ${WIDTH}    ${HEIGHT}

                ${Status}            ${MonthList}    ${InvoiceTypeList}    SAP Screen Check And Setting Lists For Loops
                IF  ${Status}
                    ${Log}           Set Variable     SAP screen check and setting lists completed successfully.
                    Text File Log    Info             Setting Filters And Generate Invoices     ${Log}
                    Log              ${Log} 
                ELSE
                    ${Log}           Set Variable     Exception occurred while setting lists.
                    Text File Log    Error            Setting Filters And Generate Invoices      ${Log}
                    Fail             ${Log}
                END
                
                # Select Frame    ${loc_filter_frame}

                FOR    ${Month}    IN    @{MonthList}
                    Sleep                        ${SHORT_WAIT}
                    # Click Element Action         ${loc_month_select}    
                    # Press Key Action             ${loc_month_select}    Control+a+Delete
                    Input Text Action            ${loc_month_select}    ${Month}

                    #Selecting current invoice status
                    Click Element Action         ${loc_invoice_status}
                    Click Element Action         ${loc_pending_with_dealer}
                    ${RetryCountLoop}            Evaluate    0

                    FOR    ${InvoiceType}    IN    @{InvoiceTypeList}
                        WHILE    ${RetryCountLoop} < ${MaxRetries}
                            TRY
                                ${InvoiceType}       Strip String    ${InvoiceType}
                                ${Status}            Setting Filters And Start Search    ${InvoiceType}    ${loc_pending_with_dealer}
                                IF  ${Status}
                                    ${Log}           Set Variable    Setting filters and initiating search completed successfully.
                                    Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                    Log              ${Log}
                                ELSE
                                    ${Log}           Set Variable    Exception occurred while setting filters and initiating search.
                                    Text File Log    Error           Setting Filters And Generate Invoices    ${Log}
                                    Fail             ${Log}
                                END
                            
                                ${LoaderInvisibleCheck}    Wait Until Element Available With Timeout    ${loc_loader_display}            ${MEDIUM_WAIT}
                                ${LoaderInvisibleCheck}    Wait Until Element Dissapears                ${loc_loader_display}   
                                ${ActionButtonExist}       Wait Until Element Available With Timeout    ${loc_row_one_action_button}     ${DEFAULT_WAIT} 
                                ${CurrentDate}             Get Current Date                             result_format=${NormalDateFormat}
                                
                                IF  ${ActionButtonExist}
                                    ${Log}                     Set Variable                         Data available for this branch on ${Month} for Invoice Type: ${InvoiceType}.
                                    Text File Log              Info                                 Setting Filters And Generate Invoices    ${Log}
                                    Log                        ${Log}
                                    ${CountText}               Get Text Action                      ${loc_invoice_count}
                                    ${RegexOut}                Get Regexp Matches                   ${CountText}            ${InvoiceCount_Regex}
                                    ${InvoiceCount}            Set Variable                         ${RegexOut}[0]
                                    ${InvoiceCount}            Strip String                         ${InvoiceCount}
                                    ${OriginalInvoiceCount}    Strip String                         ${InvoiceCount}
                                    ${TotalInvoice}            Evaluate                             ${TotalInvoice} + ${InvoiceCount}
                                ELSE
                                    ${Log}                     Set Variable                         No data available for this branch on ${Month} for Invoice Type: ${InvoiceType}.
                                    Text File Log              Info                                 Setting Filters And Generate Invoices     ${Log}
                                    Log                        ${Log}
                                    Set To Dictionary          ${StatusDictionary}      Login               ${Dictionary}[Login ID]    
                                    Set To Dictionary          ${StatusDictionary}      Position            ${Dictionary}[Branch Name]
                                    Set To Dictionary          ${StatusDictionary}      Invoice Month       ${Month}
                                    Set To Dictionary          ${StatusDictionary}      Invoice Type        ${InvoiceType}
                                    Set To Dictionary          ${StatusDictionary}      IRN Status          No Data 
                                    Set To Dictionary          ${StatusDictionary}      IRN Total           0
                                    Set To Dictionary          ${StatusDictionary}      IRN Success         0
                                    Set To Dictionary          ${StatusDictionary}      IRN Exception       0

                                    #Appending Data To Excel  
                                    Append Multiple Cells In Excel Row      ${StatusDictionary}    ${StatusFilePath}      ${BriefTrackerSheet} 
                                    Remove From Dictionary                  ${StatusDictionary}    Login                  Position      Invoice Month     Invoice Type      IRN Status     IRN Total	   IRN Success	  IRN Exception
                                    BREAK
                                END
                                
                                ${AlreadyDropdownSelected}     Element Visible Action           ${loc_dropdown_hudread}
                                IF  ${AlreadyDropdownSelected}
                                    ${Log}                     Set Variable                     The dropdown value '100' is already selected.
                                    Text File Log              Info                             Setting Filters And Uploading Invoices    ${Log}
                                    Log                        ${Log}
                                ELSE
                                    Click Element Action       ${loc_show_dropdown}
                                    Click Element Action       ${loc_choose_invoice_count}
                                    ${LoaderInvisibleCheck}    Element Visible Action            ${loc_loader_display}    
                                    ${LoaderInvisibleCheck}    Wait Until Element Dissapears     ${loc_loader_display} 
                                END

                                #Removing items from NewTmlNo List
                                Remove Values From List     ${TmlNoList}    @{TmlNoList}

                                #Invoking Fetch TML Number Process
                                ${FetchStatus}         ${TmlNoList}     Fetch All TML Numbers    ${InvoiceCount}
                                IF  ${FetchStatus}
                                    ${Log}             Set Variable     Fetching all TML reference numbers process completed successfully.
                                    Text File Log      Info             Setting Filters And Generate Invoices    ${Log}
                                    Log                ${Log}
                                ELSE
                                    ${Log}             Set Variable     Exception occurred while fetching all TML reference numbers.
                                    Text File Log      Error            Setting Filters And Generate Invoices    ${Log}
                                    Fail               ${Log}
                                END

                                #Selecting the first page again to procced further process
                                ${FirstPageButtonExist}         Element Visible Action           ${loc_first_page_button}
                                IF  ${FirstPageButtonExist}
                                    Click Element Action        ${loc_first_page_button}
                                    ${LoaderInvisibleCheck}     Wait Until Element Available     ${loc_loader_display}
                                    ${LoaderInvisibleCheck}     Wait Until Element Dissapears    ${loc_loader_display}
                                END

                                ${IterationCount}         Evaluate              0
                                ${ActionRowCount}         Evaluate              1
                                ${CurrentSuccessCount}    Evaluate              0
                                ${CurrentFailureCount}    Evaluate              0
                                ${RemainingInvoices}      Convert To Integer    ${InvoiceCount}

                                WHILE    ${ActionRowCount} <= ${RemainingInvoices}
                                    ${Counter}                Evaluate        0
                                    ${GenerationIRNStatus}    Evaluate        False

                                    WHILE    ${Counter} < ${ActionRetryLimit}
                                        TRY
                                            ${Counter}                     Evaluate                ${Counter}+1                                  
                                            ${TmlReferenceNo}              Set Variable            ${TmlNoList}[${IterationCount}]
                                            
                                            IF  ${Counter}==1
                                                Set To Dictionary          ${StatusDictionary}      Login              ${Dictionary}[Login ID]   
                                                Set To Dictionary          ${StatusDictionary}      Position           ${Dictionary}[Branch Name]  
                                                Set To Dictionary          ${StatusDictionary}      Invoice Month      ${Month}
                                                Set To Dictionary          ${StatusDictionary}      Invoice Type       ${InvoiceType} 
                                                Set To Dictionary          ${StatusDictionary}      Reference No       ${TmlReferenceNo} 
                                                Set To Dictionary          ${StatusDictionary}      Processed Date     ${CurrentDate}
                                                
                                                Append Multiple Cells In Excel Row      ${StatusDictionary}    ${StatusFilePath}       ${TrackerSheetName} 
                                                Remove From Dictionary                  ${StatusDictionary}    Login      Position    Invoice Month    Invoice Type     Reference No    Processed Date
                                            END
                                            
                                            #Logic to click next page
                                            IF  (${PageLimit} < ${ActionRowCount})
                                                ${NextClickCounter}             Evaluate                         ${ActionRowCount} / ${PageLimit}
                                                ${NextClickCounter}             Convert To Integer               ${NextClickCounter}
                                                WHILE  ${NextClickCounter} > 0
                                                    Click Element Action        ${loc_next_page_button}
                                                    ${LoaderInvisibleCheck}     Wait Until Element Available     ${loc_loader_display}
                                                    ${LoaderInvisibleCheck}     Wait Until Element Dissapears    ${loc_loader_display}
                                                    ${NextClickCounter}         Evaluate                         ${NextClickCounter} - 1
                                                END
                                            END

                                            ${Status}            ${TmlRefNoList}      Get TML Number List
                                            ${TmlCount}          Get Length           ${TmlRefNoList}
                                            FOR    ${ClickCount}    IN RANGE    0    ${TmlCount}
                                                ${RowCount}            Evaluate             ${ClickCount} + 2
                                                ${Value}               Get text Action      (//tr[contains(@class, 'ng-star-inserted')]) [${RowCount}]/td[6]
                                                ${Value}               Strip String         ${Value}
                                                
                                                ${ActionButtonCount}    Evaluate    ${RowCount} - 1

                                                IF  '${Value}' == '${TmlReferenceNo}'
                                                    Click Element Action    (//button[@icon="pi pi-pencil"])[${ActionButtonCount}]
                                                    Exit For Loop
                                                ELSE
                                                    Continue For Loop                                        
                                                END
                                            END

                                            Set To Dictionary          ${ReadDictionary}       Invoice Type         ${InvoiceType}    
                                            Set To Dictionary          ${ReadDictionary}       Reference No         ${TmlReferenceNo}

                                            #Reading Status Tracker Excel
                                            ${ExcelTrackerStatus}      ${ExcelTrackerData}     Read Status Excel Tracker    ${TrackerSheetName}    ${ReadDictionary}    ${StatusFilePath}

                                            Remove From Dictionary     ${ReadDictionary}       Invoice Type                 Reference No 
                                                
                                            IF  ('${ExcelTrackerData[0]}[Generate IRN & GST]' != 'Completed') and ('${GenerationIRNStatus}' == 'False')
                                                ${GenerationIRNStatus}      ${GenerateIrnNotFlag}      Generate IRN and GST Invoices   ${Dictionary}    ${TmlReferenceNo}    ${InvoiceType}

                                                IF  ${GenerationIRNStatus}
                                                    ${Log}                     Set Variable           Generate IRN and GST Invoices completed successfully.
                                                    Text File Log              Info                   Setting Filters And Uploading Invoices    ${Log}
                                                    Log                        ${Log}
                                                    Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                    Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlReferenceNo}
                                                    Set To Dictionary          ${StatusDictionary}    Generate IRN & GST       Completed 
                                                    ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                    Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                    Remove From Dictionary     ${StatusDictionary}    Generate IRN & GST   
                                                    ${SuccessCount}            Evaluate               ${SuccessCount} + 1
                                                    ${CurrentSuccessCount}     Evaluate               ${CurrentSuccessCount} + 1 
                                                ELSE
                                                    ${Log}                     Set Variable           Exception occurred while Generating IRN and GST Invoices.
                                                    Text File Log              Error                  Setting Filters And Uploading Invoices    ${Log}
                                                    IF  ${Counter} == ${ActionRetryLimit}
                                                        Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                        Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlReferenceNo}
                                                        Set To Dictionary          ${StatusDictionary}    Generate IRN & GST       Failed 
                                                        Set To Dictionary          ${StatusDictionary}    Status                   Failed
                                                        Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                        ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                        Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                        Remove From Dictionary     ${StatusDictionary}    Generate IRN & GST       Status     Comments
                                                    END
                                                    Fail                       ${Log}                            
                                                END
                                            END
                                            
                                            ${CloseButtonCheck}         Element Visible Action          ${loc_gstirn_close_button}
                                            IF  ${CloseButtonCheck}
                                                Click Element Action    ${loc_gstirn_close_button}
                                            END
                                            # ${FirstPageButtonExist}     Wait Until Element Available    ${loc_first_page_disabled}
                                            BREAK
                                        EXCEPT    AS    ${Exception}
                                            Log         ${Exception}
                                            ${CloseButtonCheck}         Element Visible Action     ${loc_gstirn_close_button}
                                            IF  ${CloseButtonCheck}
                                                Click Element Action    ${loc_gstirn_close_button}
                                            END
                                            # ${FirstPageButtonExist}     Wait Until Element Available    ${loc_first_page_disabled}

                                            IF  '${Counter}' == '${ActionRetryLimit}'
                                                ${FailureCount}           Evaluate                 ${FailureCount} + 1
                                                ${CurrentFailureCount}    Evaluate                 ${CurrentFailureCount} + 1
                                                ${ActionRowCount}         Evaluate                 ${ActionRowCount} + 1
                                            END

                                            #Check if Filter Screen Available or not
                                            ${WarrantyScreenCheck}    Wait Until Element Available With Timeout    ${loc_gst_screen_header}    ${MEDIUM_WAIT}
                                            IF  ${WarrantyScreenCheck}
                                                ${Log}           Set Variable    Successfully reached back to invoice filtering screen.
                                                Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                                Log              ${Log}
                                            ELSE
                                                ${Log}           Set Variable    Couldn't reach invoice filtering screen.
                                                Text File Log    Error           Setting Filters And Generate Invoices    ${Log}
                                                ${RetryDataStatus}    Retry Scenario Invoice Data    ${Dictionary}    ${Month}    ${loc_pending_with_dealer}    ${InvoiceType}  
                                                IF  ${RetryDataStatus}
                                                    ${Log}           Set Variable    Successfully closed the browser and logged in again.
                                                    Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                                    Log              ${Log}
                                                    CONTINUE
                                                END
                                            END
                                        END
                                    END
                                    ${LoaderInvisibleCheck}        Wait Until Element Available With Timeout    ${loc_loader_display}            ${DEFAULT_WAIT}
                                    ${LoaderInvisibleCheck}        Wait Until Element Dissapears                ${loc_loader_display}
                                    ${WarrantyScreenCheck}         Wait Until Element Available                 ${loc_gst_screen_header}
                                    ${ActionButtonExist}           Wait Until Element Available With Timeout    ${loc_row_one_action_button}     ${DEFAULT_WAIT}
                                    IF  ${WarrantyScreenCheck} and ${ActionButtonExist}
                                        ${CountText}               Get Text Action         ${loc_invoice_count}
                                        ${RegexOut}                Get Regexp Matches      ${CountText}              ${InvoiceCount_Regex}
                                        ${InvoiceCount}            Set Variable            ${RegexOut}[0]
                                        ${RemainingInvoices}       Strip String            ${InvoiceCount}
                                        ${RemainingInvoices}       Convert To Integer      ${RemainingInvoices}
                                    ELSE
                                        ${RemainingInvoices}       Evaluate                0
                                    END
                                    ${IterationCount}              Evaluate                ${IterationCount} + 1
                                END

                                IF  ${OriginalInvoiceCount} == ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      Login               ${Dictionary}[Login ID]    
                                    Set To Dictionary       ${StatusDictionary}      Position            ${Dictionary}[Branch Name]
                                    Set To Dictionary       ${StatusDictionary}      Invoice Month       ${Month}
                                    Set To Dictionary       ${StatusDictionary}      Invoice Type        ${InvoiceType}
                                    Set To Dictionary       ${StatusDictionary}      IRN Status          Completed 
                                    Set To Dictionary       ${StatusDictionary}      IRN Total           ${OriginalInvoiceCount}
                                    Set To Dictionary       ${StatusDictionary}      IRN Success         ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      IRN Exception       ${CurrentFailureCount}
                                ELSE
                                    Set To Dictionary       ${StatusDictionary}      Login               ${Dictionary}[Login ID]    
                                    Set To Dictionary       ${StatusDictionary}      Position            ${Dictionary}[Branch Name]
                                    Set To Dictionary       ${StatusDictionary}      Invoice Month       ${Month}
                                    Set To Dictionary       ${StatusDictionary}      Invoice Type        ${InvoiceType}
                                    Set To Dictionary       ${StatusDictionary}      IRN Status          Not Completed 
                                    Set To Dictionary       ${StatusDictionary}      IRN Total           ${OriginalInvoiceCount}
                                    Set To Dictionary       ${StatusDictionary}      IRN Success         ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      IRN Exception       ${CurrentFailureCount}
                                END

                                #Appending Data To Excel  
                                Append Multiple Cells In Excel Row      ${StatusDictionary}     ${StatusFilePath}      ${BriefTrackerSheet} 
                                Remove From Dictionary                  ${StatusDictionary}     Login                  Position      Invoice Month     Invoice Type      IRN Status    IRN Total	   IRN Success	  IRN Exception    
                                BREAK 
                            EXCEPT    AS    ${Exception}
                                Log         ${Exception}
                                Text File Log    Error       Invoice Type Loop    ${Exception}
                                ${RetryCountLoop}    Evaluate    ${RetryCountLoop} + 1
                                IF  ${RetryCountLoop} >= ${MaxRetries}
                                    ${Log}           Set Variable    Max retries reached for Invoice Type: ${InvoiceType}. Moving to the next Invoice Type.
                                    Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                    Log              ${Log}
                                    BREAK
                                ELSE
                                    ${WarrantyScreenCheck}    Wait Until Element Available With Timeout    ${loc_gst_screen_header}    ${MEDIUM_WAIT}
                                    IF  ${WarrantyScreenCheck}
                                        ${Log}           Set Variable    Successfully reached back to invoice filtering screen.
                                        Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                        Log              ${Log}
                                    ELSE
                                        ${Log}           Set Variable    Couldn't reach invoice filtering screen.
                                        Text File Log    Error           Setting Filters And Generate Invoices    ${Log}
                                        ${RetryLoopStatus}    Retry Scenario Invoice Type Loop    ${Dictionary}    ${Month}    ${loc_pending_with_dealer}   
                                        IF  ${RetryLoopStatus}
                                            ${Log}           Set Variable    Successfully closed the browser and logged in again.
                                            Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                                            Log              ${Log}
                                            CONTINUE
                                        END
                                    END
                                END
                            END
                        END
                    END
                END 
                BREAK           
            EXCEPT    AS    ${Exception}
                Log         ${Exception}
                Text File Log    Error       Setting Filters And Generate Invoices    ${Exception}
                
                ${RetryCount}    Evaluate    ${RetryCount} + 1
                IF  ${RetryCount} >= ${MaxRetries}
                    ${Log}           Set Variable    Max retries reached for Login ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                    Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                    Log              ${Log}
                ELSE
                    ${RetryLoginStatus}    Retry Scenario Login    ${Dictionary}
                    IF  ${RetryLoginStatus}
                        ${Log}           Set Variable    Successfully closed the browser and logged in again.
                        Text File Log    Info            Setting Filters And Generate Invoices    ${Log}
                        Log              ${Log}
                        CONTINUE
                    END
                END
            END    
        END
        ${Log}           Set Variable     Completed processing  Setting Filters And Generate Invoices  
        Text File Log    Info             Setting Filters And Generate Invoices     ${Log}
        Log              ${Log}
        RETURN           True             ${TotalInvoice}    ${SuccessCount}        ${FailureCount}
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error            Setting Filters And Uploading Invoices    ${Exception}
        RETURN           False            ${TotalInvoice}    ${SuccessCount}        ${FailureCount}
    END

Generate IRN and GST Invoices 
    [Arguments]    ${Dictionary}     ${TmlReferenceNo}     ${InvoiceType}
    TRY                        
        ${Log}           Set Variable     Generation of IRN Started
        Text File Log    Info             Generate IRN and GST Invoices      ${Log}
        Log              ${Log}
        
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display}   
        ${IsGenerateIrnExists}     Wait Until Element Available    ${loc_generate_irn}

        ${TmlVisibleCheck}         Wait Until Element Available    ${loc_tml_row_one_inside}
        
        IF  ${IsGenerateIrnExists}
            Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
            Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlReferenceNo}
            Set To Dictionary          ${StatusDictionary}    Generate IRN & GST       In Progress 
            ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
            Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
            Remove From Dictionary     ${StatusDictionary}    Generate IRN & GST 
            Click Element Action       ${loc_generate_irn}
            Sleep                      ${SHORT_WAIT}
        ELSE
            ${Log}           Set Variable    Generate IRN button not visible.
            Text File Log    Error           Generate IRN and GST Invoices     ${Log}
            Fail             ${Log}
        END

        ${LoaderInvisibleCheck}    Wait Until Element Available    ${loc_loader_display} 
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display} 

        ${IrnExist}    Wait Until Element Available    ${loc_irn_generated}        
        
        IF  ${IrnExist}
            ${IrnText}              Get Text Action    ${loc_irn_generated}
            Click Element Action    ${loc_submit}
            ${GenerateIrnNotFlag}    Evaluate          False
            Sleep        ${SHORT_WAIT}
        ELSE
            ${Log}                   Set Variable    Submit button not visible.
            Text File Log            Error           Generate IRN and GST Invoices     ${Log}
            ${GenerateIrnNotFlag}    Evaluate        True
            Fail                     ${Log}
        END

        ${PopupExists}     Wait Until Element Available   ${loc_save_claim_popup} 

        IF  ${PopupExists}
            Click Element Action    ${loc_popup_submit}
            Sleep                   ${SHORT_WAIT}
        ELSE
            ${Log}           Set Variable    Submit button not visible.
            Text File Log    Error           Generate IRN and GST Invoices     ${Log}
            Fail             ${Log}
        END

        ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display} 
        ${WarrantyScreenCheck}     Wait Until Element Available    ${loc_gst_screen_header}
        IF  ${WarrantyScreenCheck}
            ${Log}           Set Variable    Successfully reached invoice filtering screen.
            Text File Log    Info            SAP Screen Check And Setting Lists For Loops    ${Log}
            Log              ${Log}
        ELSE
            ${Log}                   Set Variable    Couldn't reach invoice filtering screen.
            Text File Log            Error           SAP Screen Check And Setting Lists For Loops    ${Log}
            ${GstIrnCloseExists}     Wait Until Element Available     ${loc_gstirn_close_button}
            IF  ${GstIrnCloseExists}
                Click Element Action    ${loc_gstirn_close_button}
            ELSE
                Log    No Close button Available
            END
        END        
        RETURN    True    ${GenerateIrnNotFlag}
    EXCEPT  AS    ${Exception}
        Log         ${Exception}
        Text File Log           Error                      Generate IRN and GST Invoices     ${Exception}
        ${CloseButtonCheck}     Element Visible Action     ${loc_gstirn_close_button}
        IF  ${CloseButtonCheck}
            Click Element Action    ${loc_gstirn_close_button}
        END
        RETURN          ${False}    ${GenerateIrnNotFlag}
    END 
        

Setting Filters And Uploading Invoices
    [Documentation]    Downloading, Digital Signing and Uploading the invoices to the SAP system.
    [Arguments]        ${Dictionary}    
    TRY
        ${Log}           Set Variable    Started processing Setting Filters and Uploading Invoices process.
        Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
        Log              ${Log}
        
        #Initializing Values for Invoice Counts
        ${TotalInvoice}    Evaluate    0
        ${SuccessCount}    Evaluate    0
        ${FailureCount}    Evaluate    0
        ${RetryCount}      Evaluate    0

        WHILE    ${RetryCount} < ${MaxRetries}
            TRY
                ${Status}            ${MonthList}    ${InvoiceTypeList}    SAP Screen Check And Setting Lists For Loops
                IF  ${Status}
                    ${Log}           Set Variable    SAP screen check and setting lists completed successfully.
                    Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                    Log              ${Log} 
                ELSE
                    ${Log}           Set Variable    Exception occurred while setting lists.
                    Text File Log    Error           Setting Filters And Uploading Invoices    ${Log}
                    Fail             ${Log}
                END

                #Selecting the frame to work on
                # Select Frame    ${loc_filter_frame}

                FOR    ${Month}    IN    @{MonthList}
                    # Sleep                        ${SHORT_WAIT}
                    # Press Key Action             ${loc_month_select}    CONTROL+a+DELETE
                    Input Text Action            ${loc_month_select}    ${Month}

                    #Selecting current invoice status
                    Click Element Action         ${loc_invoice_status}
                    Click Element Action         ${loc_ready_to_upload}
                    ${RetryCountLoop}            Evaluate        0

                    FOR    ${InvoiceType}    IN    @{InvoiceTypeList}
                        WHILE    ${RetryCountLoop} < ${MaxRetries}
                            TRY
                                ${InvoiceType}       Strip String    ${InvoiceType}
                                #Invoking Filter Keyword
                                ${Status}            Setting Filters And Start Search    ${InvoiceType}    ${loc_ready_to_upload}
                                IF  ${Status}
                                    ${Log}           Set Variable    Setting filters and initiating search completed successfully.
                                    Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                    Log              ${Log}
                                ELSE
                                    ${Log}           Set Variable    Exception occurred while setting filters and initiating search.
                                    Text File Log    Error           Setting Filters And Uploading Invoices    ${Log}
                                    Fail             ${Log}
                                END
                                
                                ${LoaderInvisibleCheck}      Wait Until Element Available                 ${loc_loader_display}      
                                ${LoaderInvisibleCheck}      Wait Until Element Dissapears                ${loc_loader_display}    
                                ${ActionButtonExist}         Wait Until Element Available With Timeout    ${loc_row_one_action_button}       ${DEFAULT_WAIT} 

                                #Setting required variable values
                                ${BranchLocation}          Set Variable                         ${Dictionary}[Branch Name]
                                ${CurrentMonthYear}        Get Current Date                     result_format=${DateFormat}
                                ${MonthYearSplit}          Split String                         ${CurrentMonthYear}    -
                                ${CurrentYear}             Set Variable                         ${MonthYearSplit}[1]
                                ${CurrentMonth}            Set Variable                         ${MonthYearSplit}[0]
                                ${CurrentDate}             Get Current Date                     result_format=${NormalDateFormat}
                                ${ExtractExcelName}        Set Variable                         ${BranchLocation}_${CurrentMonth}_${CurrentYear}.xlsx
                                
                                IF  ${ActionButtonExist}
                                    ${Log}                   Set Variable    Data available for this branch on ${Month} for Invoice Type: ${InvoiceType}.
                                    Text File Log            Info            Setting Filters And Uploading Invoices    ${Log}
                                    ${NoDataCheck}           Evaluate        False
                                    Log                      ${Log}

                                    #Setting values to match dictionary
                                    Set To Dictionary          ${MatchDictionary}      Login                  ${Dictionary}[Login ID]    
                                    Set To Dictionary          ${MatchDictionary}      Position               ${Dictionary}[Branch Name]
                                    Set To Dictionary          ${MatchDictionary}      Invoice Month          ${Month}
                                    Set To Dictionary          ${MatchDictionary}      Invoice Type           ${InvoiceType}
                                ELSE
                                    ${Log}                   Set Variable    No data available for this branch on ${Month} for Invoice Type: ${InvoiceType}.
                                    Text File Log            Info            Setting Filters And Uploading Invoices    ${Log}
                                    ${ActionButtonExist}     Evaluate        False
                                    Log                      ${Log} 
                                    
                                    #Setting Excel File Path
                                    ${ExcelFilePath}           Set Variable            ${CONFIG}[ClaimsFolderPath]/Downloads/GST_Invoices/${BranchLocation}/${CurrentYear}/${CurrentMonth}

                                    #Setting values to match dictionary
                                    Set To Dictionary          ${MatchDictionary}      Login                  ${Dictionary}[Login ID]    
                                    Set To Dictionary          ${MatchDictionary}      Position               ${Dictionary}[Branch Name]
                                    Set To Dictionary          ${MatchDictionary}      Invoice Month          ${Month}
                                    Set To Dictionary          ${MatchDictionary}      Invoice Type           ${InvoiceType}

                                    Set To Dictionary          ${StatusDictionary}     Upload Status          No Data 
                                    Set To Dictionary          ${StatusDictionary}     Upload Total           0
                                    Set To Dictionary          ${StatusDictionary}     Upload Success         0
                                    Set To Dictionary          ${StatusDictionary}     Upload Exception       0

                                    #Appending Data To Excel  
                                    Update Excel Rows          ${StatusFilePath}       ${BriefTrackerSheet}    ${MatchDictionary}        ${StatusDictionary} 
                                    Remove From Dictionary     ${MatchDictionary}      Login                   Position                  Invoice Month          Invoice Type          
                                    Remove From Dictionary     ${StatusDictionary}     Upload Status           Upload Total              Upload Success        Upload Exception
                                    BREAK
                                END
                                
                                # #Setting Sheet Name
                                # IF       ('${InvoiceType}' == 'AMC')
                                #     ${SheetName}    Set Variable    AMC Register
                                # ELSE IF  ('${InvoiceType}' == 'FSB Credit')
                                #     ${SheetName}    Set Variable    FSB Register
                                # ELSE IF  ('${InvoiceType}' == 'FMS')
                                #     ${SheetName}    Set Variable    FMS Register
                                # ELSE
                                #     ${SheetName}    Set Variable    Warranty Register
                                # END

                                #Setting Sheet Name
                                ${SheetName}    Set Variable    Invoice Register
                                
                                # ${BranchLocation}          Set Variable                         ${Dictionary}[Branch Name]
                                # ${CurrentMonthYear}        Get Current Date                     result_format=${DateFormat}
                                # ${MonthYearSplit}          Split String                         ${CurrentMonthYear}    -
                                # ${CurrentYear}             Set Variable                         ${MonthYearSplit}[1]
                                # ${CurrentMonth}            Set Variable                         ${MonthYearSplit}[0]
                                # ${CurrentDate}             Get Current Date                     result_format=${NormalDateFormat}
                                # ${ExtractExcelName}        Set Variable                         ${BranchLocation}_${CurrentMonth}_${CurrentYear}.xlsx

                                #Setting Download Paths
                                ${DownloadPath}            Set Variable                         ${CONFIG}[ClaimsFolderPath]/Downloads/GST_Invoices/${BranchLocation}/${CurrentYear}/${CurrentMonth}/${CurrentDate}
                                ${SignSavePath}            Set Variable                         ${CONFIG}[ClaimsFolderPath]/Uploads/GST_Invoices/${BranchLocation}/${CurrentYear}/${CurrentMonth}/${CurrentDate}   
                                ${Status}                  Create Provided Directory            ${DownloadPath}
                                ${Status}                  Create Provided Directory            ${SignSavePath}
                                ${ExcelFilePath}           Set Variable                         ${CONFIG}[ClaimsFolderPath]/Downloads/GST_Invoices/${BranchLocation}/${CurrentYear}/${CurrentMonth}
                                ${GoogleDrivePath}         Set Variable                         GST_Invoices/${BranchLocation}/${CurrentYear}/${CurrentMonth}/${CurrentDate}
                                ${ExcelPath}               RPA.FileSystem.Join Path             ${ExcelFilePath}        ${ExtractExcelName}      
                                
                                #Checking whether dropdown value as 100 already selected
                                ${AlreadyDropdownSelected}     Element Visible Action           ${loc_dropdown_hudread}
                                IF  ${AlreadyDropdownSelected}
                                    ${Log}                     Set Variable                     The dropdown value '100' is already selected.
                                    Text File Log              Info                             Setting Filters And Uploading Invoices    ${Log}
                                    Log                        ${Log}
                                ELSE
                                    Click Element Action       ${loc_show_dropdown}
                                    Click Element Action       ${loc_choose_invoice_count}
                                    ${LoaderInvisibleCheck}    Element Visible Action            ${loc_loader_display}    
                                    ${LoaderInvisibleCheck}    Wait Until Element Dissapears     ${loc_loader_display} 
                                END
                                
                                ${CountText}               Get Text Action                      ${loc_invoice_count}
                                ${RegexOut}                Get Regexp Matches                   ${CountText}            ${InvoiceCount_Regex}
                                ${InvoiceCount}            Set Variable                         ${RegexOut}[0]
                                ${InvoiceCount}            Strip String                         ${InvoiceCount}
                                ${OriginalInvoiceCount}    Strip String                         ${InvoiceCount}
                                ${TotalInvoice}            Evaluate                             ${TotalInvoice} + ${InvoiceCount}
                                
                                #Invoking Data Extraction and Appending to Excel Process
                                ${ExtractionStatus}    ${TmlRefList}      Data Extraction From Screen    ${ExcelPath}    ${SheetName}    ${Dictionary}[Branch Name]    ${InvoiceCount}
                                IF  ${ExtractionStatus}
                                    ${Log}             Set Variable     Data Extraction process completed successfully.
                                    Text File Log      Info             Setting Filters And Uploading Invoices    ${Log}
                                    Log                ${Log}
                                ELSE
                                    ${Log}             Set Variable     Exception occurred while extracting data from screen.
                                    Text File Log      Error            Setting Filters And Uploading Invoices    ${Log}
                                    Fail               ${Log}
                                END

                                #Selecting the first page again to procced further process
                                ${FirstPageButtonExist}         Element Visible Action           ${loc_first_page_button}
                                IF  ${FirstPageButtonExist}
                                    Click Element Action        ${loc_first_page_button}
                                    ${LoaderInvisibleCheck}     Wait Until Element Available     ${loc_loader_display}
                                    ${LoaderInvisibleCheck}     Wait Until Element Dissapears    ${loc_loader_display}
                                END

                                ${IterationCount}         Evaluate              0
                                ${ActionRowCount}         Evaluate              1
                                ${RemainingInvoices}      Convert To Integer    ${InvoiceCount}
                                ${CurrentSuccessCount}    Evaluate              0
                                ${CurrentFailureCount}    Evaluate              0

                                WHILE    ${ActionRowCount} <= ${RemainingInvoices}
                                    ${Counter}                Evaluate       0
                                    ${Index}                  Evaluate       ${IterationCount} + 1
                                    ${DownloadStatus}         Evaluate       False
                                    ${UploadStatus}           Evaluate       False
                                    ${DigitalSignStatus}      Evaluate       False

                                    WHILE    ${Counter} < ${ActionRetryLimit}
                                        TRY
                                            ${Counter}             Evaluate             ${Counter}+1
                                            ${TmlValue}            Set Variable         ${TmlRefList}[${IterationCount}]
                                            ${TmlValue}            Strip String         ${TmlValue}
                                            
                                            #Logic to click next page
                                            IF  (${PageLimit} < ${ActionRowCount})
                                                ${NextClickCounter}             Evaluate                         ${ActionRowCount} / ${PageLimit}
                                                ${NextClickCounter}             Convert To Integer               ${NextClickCounter}
                                                # ${NewActionRowCount}            Evaluate                         ${ActionRowCount} % ${PageLimit}   
                                                WHILE  ${NextClickCounter} > 0
                                                    Click Element Action        ${loc_next_page_button}
                                                    ${LoaderInvisibleCheck}     Wait Until Element Available     ${loc_loader_display}
                                                    ${LoaderInvisibleCheck}     Wait Until Element Dissapears    ${loc_loader_display}
                                                    ${NextClickCounter}         Evaluate                         ${NextClickCounter} - 1
                                                END
                                            END

                                            #Removing items from NewTmlNo List
                                            Remove Values From List    ${NewTmlNoList}    @{NewTmlNoList}

                                            ${Status}            ${NewTmlNoList}      Get TML Number List
                                            ${TmlCount}          Get Length           ${NewTmlNoList}
                                            FOR    ${ClickCount}    IN RANGE    0    ${TmlCount}
                                                ${RowCount}             Evaluate             ${ClickCount} + 2
                                                ${Value}                Get text Action      (//tr[contains(@class, 'ng-star-inserted')]) [${RowCount}]/td[6]
                                                ${Value}                Strip String         ${Value}
                                                
                                                ${ActionButtonCount}    Evaluate             ${RowCount} - 1

                                                IF  '${Value}' == '${TmlValue}'
                                                    Click Element Action    (//button[@icon="pi pi-pencil"])[${ActionButtonCount}]
                                                    Exit For Loop
                                                ELSE
                                                    IF  ${ClickCount} == ${TmlCount} - 1
                                                        Fail    Failed to find invoice with TML Reference No: ${TmlValue} to click on.
                                                    END
                                                    Continue For Loop
                                                END
                                            END
                                            
                                            ${TmlRefNumber}        Set Variable             ${TmlValue}

                                            Set To Dictionary          ${ReadDictionary}      Invoice Type         ${InvoiceType}    
                                            Set To Dictionary          ${ReadDictionary}      Reference No         ${TmlRefNumber}

                                            ${ValueCheckStatus}        Check Values In Multiple Columns    ${StatusFilePath}    ${TrackerSheetName}    ${ReadDictionary}    
                                            IF  ('${ValueCheckStatus}' == 'False')
                                                #Updating Tracker For Upload Invoices
                                                Set To Dictionary                      ${StatusDictionary}      Login                 ${Dictionary}[Login ID]   
                                                Set To Dictionary                      ${StatusDictionary}      Position              ${Dictionary}[Branch Name]  
                                                Set To Dictionary                      ${StatusDictionary}      Invoice Month         ${Month}
                                                Set To Dictionary                      ${StatusDictionary}      Invoice Type          ${InvoiceType} 
                                                Set To Dictionary                      ${StatusDictionary}      Reference No          ${TmlRefNumber} 
                                                Set To Dictionary                      ${StatusDictionary}      Processed Date        ${CurrentDate}
                                                Append Multiple Cells In Excel Row     ${StatusDictionary}      ${StatusFilePath}     ${TrackerSheetName} 
                                                Remove From Dictionary                 ${StatusDictionary}      Login    Position     Invoice Month    Invoice Type     Reference No    Processed Date
                                            END
                                            Remove From Dictionary     ${ReadDictionary}      Invoice Type                 Reference No 
                                            
                                            #Setting current invoice suffix name
                                            IF  ('${InvoiceType}' == 'AMC')
                                                ${SuffixName}    Set Variable    AMC
                                            ELSE IF  ('${InvoiceType}' == 'FSB Credit')
                                                ${SuffixName}    Set Variable    FSB
                                            ELSE IF  ('${InvoiceType}' == 'FMS')
                                                ${SuffixName}    Set Variable    FMS
                                            ELSE IF  ('RSO' in '${InvoiceType}')
                                                ${SuffixName}    Set Variable    RSO
                                            ELSE IF  ('Recon' in '${InvoiceType}')
                                                ${SuffixName}    Set Variable    REC
                                            ELSE IF  ('Retro' in '${InvoiceType}')
                                                ${SuffixName}    Set Variable    RET
                                            ELSE IF  ('EWM' in '${InvoiceType}')
                                                ${SuffixName}    Set Variable    EWM
                                            ELSE IF  ('1' in '${InvoiceType}')
                                                ${SuffixName}    Set Variable    EW1
                                            # ELSE IF  ('Extended' in '${InvoiceType}')        #------needs to be confirmed------
                                            #     ${SuffixName}    Set Variable    EWA
                                            ELSE
                                                ${SuffixName}    Set Variable    WAR
                                            END
                                            
                                            ${InvoiceName}       Set Variable    ${TmlRefNumber}_${SuffixName}.pdf

                                            Set To Dictionary          ${ReadDictionary}      Invoice Type         ${InvoiceType}    
                                            Set To Dictionary          ${ReadDictionary}      Reference No         ${TmlRefNumber}

                                            #Reading Status Tracker Excel
                                            ${ExcelTrackerStatus}      ${ExcelTrackerData}    Read Status Excel Tracker    ${TrackerSheetName}    ${ReadDictionary}    ${StatusFilePath} 

                                            #Updating File Name in Tracker Excel
                                            Set To Dictionary          ${StatusDictionary}    File Name               ${InvoiceName} 
                                            ${Status}                  Update Excel Rows      ${StatusFilePath}       ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                            Remove From Dictionary     ${ReadDictionary}      Invoice Type            Reference No
                                            Remove From Dictionary     ${StatusDictionary}    File Name

                                            #Invoking Download GST Invoice Process Keyword
                                            IF  ('${ExcelTrackerData[0]}[Download]' != 'Completed') and ('${DownloadStatus}' == 'False')
                                                ${DownloadStatus}    ${DownloadInvoicePath}    Download GST Invoice    ${DownloadPath}    ${InvoiceName}    ${TmlRefNumber}    ${InvoiceType}
                                                IF  ${DownloadStatus}
                                                    ${Log}                     Set Variable           Download invoice process completed successfully.
                                                    Text File Log              Info                   Setting Filters And Uploading Invoices         ${Log}
                                                    Log                        ${Log}
                                                    Set To Dictionary          ${ReadDictionary}      Invoice Type            ${InvoiceType}    
                                                    Set To Dictionary          ${ReadDictionary}      Reference No            ${TmlRefNumber}
                                                    Set To Dictionary          ${StatusDictionary}    Download                Completed
                                                    Set To Dictionary          ${StatusDictionary}    Status                  Download Completed
                                                    Set To Dictionary          ${StatusDictionary}    Comments                ${Log}
                                                    ${Status}                  Update Excel Rows      ${StatusFilePath}       ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                    Remove From Dictionary     ${ReadDictionary}      Invoice Type            Reference No
                                                    Remove From Dictionary     ${StatusDictionary}    Download                Status                  Comments   
                                                ELSE
                                                    ${Log}                     Set Variable           Exception occurred while downloading invoice.
                                                    Text File Log              Error                  Setting Filters And Uploading Invoices         ${Log}
                                                    IF  ${Counter} == ${ActionRetryLimit}
                                                        Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                        Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlRefNumber}
                                                        Set To Dictionary          ${StatusDictionary}    Download                 Failed 
                                                        Set To Dictionary          ${StatusDictionary}    Status                   Failed
                                                        Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                        ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                        Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                        Remove From Dictionary     ${StatusDictionary}    Download                 Status                  Comments
                                                    END
                                                    Fail                           ${Log}
                                                END
                                            END                                    

                                            # Invoking Digital Signing Process Keyword
                                            IF  ('${ExcelTrackerData[0]}[Digital Sign]' != 'Completed') and ('${DigitalSignStatus}' == 'False')
                                                ${DigitalSignStatus}           ${InvoicePath}         Digital Sign Using Sikuli    ${DownloadInvoicePath}    ${TmlRefNumber}    ${InvoiceType}    ${CLIENT_CONFIG}[Digital Signature Pin]    ${GoogleDrivePath}
                                                IF  ${DigitalSignStatus}
                                                    ${Log}                     Set Variable           Digital signing process completed successfully.
                                                    Text File Log              Info                   Setting Filters And Uploading Invoices         ${Log}
                                                    Log                        ${Log}
                                                    Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                    Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlRefNumber}
                                                    Set To Dictionary          ${StatusDictionary}    Digital Sign             Completed 
                                                    Set To Dictionary          ${StatusDictionary}    Status                   Digital Sign Completed.
                                                    Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                    ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                    Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                    Remove From Dictionary     ${StatusDictionary}    Digital Sign             Status                  Comments
                                                ELSE
                                                    ${Log}                     Set Variable           Exception occurred while digitally signing the invoice.
                                                    Text File Log              Error                  Setting Filters And Uploading Invoices         ${Log}
                                                    IF  ${Counter} == ${ActionRetryLimit}
                                                        Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                        Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlRefNumber}
                                                        Set To Dictionary          ${StatusDictionary}    Digital Sign             Failed 
                                                        Set To Dictionary          ${StatusDictionary}    Status                   Failed
                                                        Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                        ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                        Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                        Remove From Dictionary     ${StatusDictionary}    Digital Sign             Status                  Comments
                                                   END
                                                   Fail                            ${Log}
                                                END
                                            END

                                            #Invoking Upload GST Invoice Process Keyword
                                            IF  ('${ExcelTrackerData[0]}[Upload]' != 'Completed') and ('${UploadStatus}' == 'False')    #---------made it true for testing------------------
                                                ${UploadStatus}               ${FileNotMatchFlag}     Upload GST Invoice    ${InvoicePath}    ${TmlRefNumber}    ${InvoiceType}
                                                IF  ${UploadStatus}
                                                    ${Log}                     Set Variable           Upload invoice process completed successfully.
                                                    Text File Log              Info                   Setting Filters And Uploading Invoices         ${Log}
                                                    Log                        ${Log}
                                                    Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                    Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlRefNumber}
                                                    Set To Dictionary          ${StatusDictionary}    Upload                   Completed 
                                                    Set To Dictionary          ${StatusDictionary}    Status                   Success
                                                    Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                    ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                    Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                    Remove From Dictionary     ${StatusDictionary}    Upload                   Status                  Comments
                                                ELSE
                                                    ${Log}                     Set Variable           Exception occurred while uploading invoice.
                                                    Text File Log              Error                  Setting Filters And Uploading Invoices         ${Log}
                                                    IF  ${Counter} == ${ActionRetryLimit}
                                                        Set To Dictionary          ${ReadDictionary}      Invoice Type             ${InvoiceType}    
                                                        Set To Dictionary          ${ReadDictionary}      Reference No             ${TmlRefNumber}
                                                        Set To Dictionary          ${StatusDictionary}    Upload                   Failed 
                                                        Set To Dictionary          ${StatusDictionary}    Status                   Failed
                                                        Set To Dictionary          ${StatusDictionary}    Comments                 ${Log}
                                                        ${Status}                  Update Excel Rows      ${StatusFilePath}        ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
                                                        Remove From Dictionary     ${ReadDictionary}      Invoice Type             Reference No
                                                        Remove From Dictionary     ${StatusDictionary}    Upload                   Status                  Comments
                                                    END
                                                    Fail                           ${Log}
                                                END
                                            END

                                            # ${UploadToDriveStatus}               Uploading Files To Google Drive       ${GoogleDrivePath}    ${DownloadPath}    ${ExcelPath}
                                            # IF  ${UploadToDriveStatus}
                                            #     ${Log}           Set Variable    Successfully uploaded the files to Google Drive.
                                            #     Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                            #     Log              ${Log}
                                            # ELSE
                                            #     ${Log}           Set Variable    Exception occurred while uploading the files to Google Drive.
                                            #     Text File Log    Error           Setting Filters And Uploading Invoices    ${Log}
                                            #     Log              ${Log}
                                            # END

                                            ${SuccessCount}                 Evaluate                        ${SuccessCount} + 1
                                            ${CurrentSuccessCount}          Evaluate                        ${CurrentSuccessCount} + 1
                                            ${CloseButtonCheck}             Element Visible Action          ${loc_gstirn_close_button}
                                            IF  ${CloseButtonCheck}
                                                Click Element Action        ${loc_gstirn_close_button}
                                            END

                                            ${ActionButtonExist}            Element Visible Action          ${loc_row_one_action_button}        
                                            IF  ${ActionButtonExist}
                                                ${FirstPageButtonExist}     Wait Until Element Available    ${loc_first_page_disabled}
                                            END
                                            BREAK
                                        EXCEPT    AS    ${Exception}
                                            Log         ${Exception}

                                            ${CloseButtonCheck}             Element Visible Action          ${loc_gstirn_close_button}
                                            IF  ${CloseButtonCheck}
                                                Click Element Action        ${loc_gstirn_close_button}
                                            END

                                            ${ActionButtonExist}            Element Visible Action          ${loc_row_one_action_button}        
                                            IF  ${ActionButtonExist}
                                                ${FirstPageButtonExist}     Wait Until Element Available    ${loc_first_page_disabled}
                                            END

                                            IF  '${Counter}' == '${ActionRetryLimit}'
                                                ${FailureCount}            Evaluate    ${FailureCount} + 1
                                                ${CurrentFailureCount}     Evaluate    ${CurrentFailureCount} + 1
                                                ${ActionRowCount}          Evaluate    ${ActionRowCount} + 1
                                            END

                                            #Check if Filter Screen Available or not
                                            ${WarrantyScreenCheck}    Wait Until Element Available With Timeout    ${loc_gst_screen_header}    ${MEDIUM_WAIT}
                                            IF  ${WarrantyScreenCheck}
                                                ${Log}           Set Variable    Successfully reached back to invoice filtering screen.
                                                Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                                Log              ${Log}
                                            ELSE
                                                ${Log}           Set Variable    Couldn't reach invoice filtering screen.
                                                Text File Log    Error           Setting Filters And Uploading Invoices    ${Log}
                                                ${RetryDataStatus}    Retry Scenario Invoice Data    ${Dictionary}    ${Month}    ${loc_ready_to_upload}    ${InvoiceType}  
                                                IF  ${RetryDataStatus}
                                                    ${Log}           Set Variable    Successfully closed the browser and logged in again.
                                                    Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                                    Log              ${Log}
                                                    CONTINUE
                                                END
                                            END
                                        END
                                    END

                                    ${LoaderInvisibleCheck}        Wait Until Element Available With Timeout    ${loc_loader_display}            ${DEFAULT_WAIT}
                                    ${LoaderInvisibleCheck}        Wait Until Element Dissapears                ${loc_loader_display}
                                    ${WarrantyScreenCheck}         Wait Until Element Available                 ${loc_gst_screen_header}
                                    ${ActionButtonExist}           Wait Until Element Available With Timeout    ${loc_row_one_action_button}     ${SHORT_WAIT}
                                    IF  ${WarrantyScreenCheck} and ${ActionButtonExist}
                                        ${CountText}               Get Text Action                 ${loc_invoice_count}
                                        ${RegexOut}                Get Regexp Matches              ${CountText}              ${InvoiceCount_Regex}
                                        ${InvoiceCount}            Set Variable                    ${RegexOut}[0]
                                        ${RemainingInvoices}       Strip String                    ${InvoiceCount}
                                        ${RemainingInvoices}       Convert To Integer              ${RemainingInvoices}
                                    ELSE
                                        ${RemainingInvoices}       Evaluate                        0
                                    END
                                    ${IterationCount}              Evaluate                        ${IterationCount} + 1
                                END

                                IF  ${OriginalInvoiceCount} == ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      Upload Status       Completed 
                                    Set To Dictionary       ${StatusDictionary}      Upload Total        ${OriginalInvoiceCount}
                                    Set To Dictionary       ${StatusDictionary}      Upload Success      ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      Upload Exception    ${CurrentFailureCount}
                                ELSE
                                    Set To Dictionary       ${StatusDictionary}      Upload Status       Not Completed 
                                    Set To Dictionary       ${StatusDictionary}      Upload Total        ${OriginalInvoiceCount}
                                    Set To Dictionary       ${StatusDictionary}      Upload Success      ${CurrentSuccessCount}
                                    Set To Dictionary       ${StatusDictionary}      Upload Exception    ${CurrentFailureCount}
                                END

                                #Appending Data To Excel  
                                Update Excel Rows           ${StatusFilePath}       ${BriefTrackerSheet}    ${MatchDictionary}        ${StatusDictionary}
                                Remove From Dictionary      ${StatusDictionary}     Upload Status           Upload Total	          Upload Success	     Upload Exception
                                Remove From Dictionary      ${MatchDictionary}      Login                   Position                  Invoice Month          Invoice Type  
                                BREAK
                            EXCEPT    AS    ${Exception}
                                Log         ${Exception}
                                Text File Log    Error       Invoice Type Loop    ${Exception}
                                ${RetryCountLoop}    Evaluate    ${RetryCountLoop} + 1
                                IF  ${RetryCountLoop} >= ${MaxRetries}
                                    ${Log}           Set Variable    Max retries reached for Invoice Type: ${InvoiceType}. Moving to the next Invoice Type.
                                    Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                    Log              ${Log}
                                    BREAK
                                ELSE
                                    ${WarrantyScreenCheck}    Wait Until Element Available With Timeout    ${loc_gst_screen_header}    ${MEDIUM_WAIT}
                                    IF  ${WarrantyScreenCheck}
                                        ${Log}           Set Variable    Successfully reached back to invoice filtering screen.
                                        Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                        Log              ${Log}
                                    ELSE
                                        ${Log}           Set Variable    Couldn't reach invoice filtering screen.
                                        Text File Log    Error           Setting Filters And Uploading Invoices    ${Log}
                                        ${RetryLoopStatus}    Retry Scenario Invoice Type Loop    ${Dictionary}    ${Month}    ${loc_ready_to_upload}   
                                        IF  ${RetryLoopStatus}
                                            ${Log}           Set Variable    Successfully closed the browser and logged in again.
                                            Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                                            Log              ${Log}
                                            CONTINUE
                                        END
                                    END
                                END
                            END 
                        END   
                    END
                END
                BREAK
            EXCEPT    AS    ${Exception}
                Log         ${Exception}

                #Incrementing Retry Count Variable
                ${RetryCount}    Evaluate    ${RetryCount} + 1

                IF  ${RetryCount} >= ${MaxRetries}
                    ${Log}           Set Variable    Max retries reached for Login ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                    Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
                    Log              ${Log}
                ELSE
                    ${RetryLoginStatus}    Retry Scenario Login    ${Dictionary}
                    IF  ${RetryLoginStatus}
                        ${Log}             Set Variable            Successfully closed the browser and logged in again.
                        Text File Log      Info                    Setting Filters And Uploading Invoices    ${Log}
                        Log                ${Log}
                        CONTINUE
                    END
                END
            END
        END
        ${Log}           Set Variable    Completed processing Setting Filters and Uploading Invoices process.
        Text File Log    Info            Setting Filters And Uploading Invoices    ${Log}
        Log              ${Log}
        RETURN           True            ${TotalInvoice}    ${SuccessCount}        ${FailureCount}    ${ExcelFilePath}
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error           Setting Filters And Uploading Invoices    ${Exception}
        RETURN           False           ${TotalInvoice}    ${SuccessCount}        ${FailureCount}    ${ExcelFilePath}
    END

Navigation To SAP Warranty
    [Arguments]    ${Dictionary}
    TRY
        ${Log}           Set Variable    Started the navigation process to SAP Warranty Screen.
        Text File Log    Info            Navigation To SAP Warranty    ${Log}
        Log              ${Log}
        
        ${HomePageExist}    Wait Until Element Available    ${loc_home_page_check}
        IF  ${HomePageExist}
            ${Log}           Set Variable    Successfully reached home page.
            Text File Log    Info            Navigation To SAP Warranty    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Home page doesn't exist.
            Text File Log    Error           Navigation To SAP Warranty    ${Log}
            Fail             ${Log}
        END
        
        Click Element When Clickable Action                         ${loc_profile_icon}
        ${ChangePositionsExist}     Wait Until Element Available    ${loc_change_positions}
        IF  ${ChangePositionsExist}
            Click Element Action    ${loc_change_positions}
        ELSE
            ${Log}           Set Variable    Change position option doesn't exist.
            Text File Log    Error           Navigation To SAP Warranty    ${Log}
            Fail             ${Log}    
        END

        #Setting dynamic locator for positions
        ${PositionName}            Set Variable    ${Dictionary}[DSVCM positions]
        ${loc_dynamic_position}    Set Variable    //a[@class="mdc-button mat-mdc-button mat-primary mat-mdc-button-base"]//span[text() = "${PositionName}"]

        ${SelectPositionsExist}     Wait Until Element Available    ${loc_options_page_check}
        IF  ${SelectPositionsExist}
            Click Element When Clickable Action    ${loc_dynamic_position}
            Click Element Action                   ${loc_position_save_button}
        ELSE
            ${Log}           Set Variable    Select position screen doesn't exist.
            Text File Log    Error           Navigation To SAP Warranty    ${Log}
            Fail             ${Log}
        END

        ${SapWarrantyIconExist}     Wait Until Element Available    ${loc_sap_warranty}
        IF  ${SapWarrantyIconExist}
            Click Element Action    ${loc_sap_warranty}
        ELSE
            ${Log}           Set Variable    SAP Warranty option doesn't exist.
            Text File Log    Error           Navigation To SAP Warranty    ${Log}
            Fail             ${Log}
        END

        ${SapWarrantyOpenedCheck}    Wait Until Element Available    ${loc_sap_warranty_open_check}
        IF  ${SapWarrantyOpenedCheck}
            Sleep                   ${SHORT_WAIT}
            Click Element Action    ${loc_sap_warranty_open_check}
            Click Element Action    ${loc_gst_invoice_option}
        ELSE
            ${Log}           Set Variable    Expected screen doesn't exist.
            Text File Log    Error           Navigation To SAP Warranty    ${Log}
            Fail             ${Log}   
        END

        ${Log}           Set Variable    Completed the navigation process to SAP Warranty screen.
        Text File Log    Info            Navigation To SAP Warranty    ${Log}
        Log              ${Log}
        RETURN           True
    EXCEPT    AS    ${Exception}
        Log              ${Exception}
        Text File Log    Error           Navigation To SAP Warranty    ${Exception}
        RETURN           False
    END

Data Extraction From Screen
    [Arguments]    ${ExcelPath}    ${SheetName}    ${BranchName}    ${InvoiceCount}
    TRY
        ${Log}           Set Variable    Started data extraction process.
        Text File Log    Info            Data Extraction From Screen    ${Log}
        Log              ${Log}
      
        ${EndRange}      Evaluate        ${InvoiceCount} + 1
        
        #Removing items from TmlNo List
        Remove Values From List    ${TmlNoList}    @{TmlNoList}
        ${RowCount}                Evaluate        2

        FOR    ${LoopCount}    IN RANGE    1   ${EndRange}
                        
            #Setting a List Of TML Numbers
            ${TmlReferenceNo}       Get Text Action     (//tr[contains(@class, 'ng-star-inserted')])[${RowCount}]/td[6]
            ${TmlReferenceNo}       Strip String        ${TmlReferenceNo}
            Append To List          ${TmlNoList}        ${TmlReferenceNo}

            #Setting column name list from config
            ${ColumnNameList}       Split String        ${CONFIG}[ColumnNames]    ,
            ${IterationCount}       Evaluate            1
            
            #Appending Branch Name to Dictionary
            Set To Dictionary    ${AppendDictionary}    Branch Name     ${BranchName}

            #Looping through each column value
            FOR    ${ColumnName}     IN     @{ColumnNameList}
                #Setting column count
                ${ColumnCount}       Evaluate    ${IterationCount} + 2

                #Setting dynamic locators for each column of data
                ${CurrentValue}      Get Text Action        (//tr[contains(@class, 'ng-star-inserted')])[${RowCount}]/td[${ColumnCount}]

                Set To Dictionary    ${AppendDictionary}    ${ColumnName}         ${CurrentValue}
                ${IterationCount}    Evaluate               ${IterationCount}+1
            END
            
            #Appending data to excel
            # Append Data To Excel               ${ExcelPath}    ${SheetName}    ${AppendDictionary}
            Append Data To Excel By Data Type    ${ExcelPath}    ${SheetName}    ${AppendDictionary}

            # Check if next button needs to be clicked after each full page
            ${Remainder}    Evaluate    ${LoopCount} % ${PageLimit}
            ${IsLast}       Evaluate    ${LoopCount} == ${InvoiceCount}
            
            #Setting row count increment
            ${RowCount}     Evaluate    ${RowCount} + 1

            IF  ('${Remainder}' == '0') and not ${IsLast}
                Click Element Action       ${loc_next_page_button}
                ${LoaderInvisibleCheck}    Wait Until Element Available    ${loc_loader_display}
                ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display}
                ${RowCount}                Evaluate    2
            END
        END
        ${Log}           Set Variable     Completed data extraction process.
        Text File Log    Info             Data Extraction From Screen     ${Log}
        Log              ${Log}
        RETURN           True             ${TmlNoList}
    EXCEPT    AS    ${Exception}
        Text File Log    Error            Data Extraction From Screen     ${Exception}
        Log              ${Exception}
        RETURN           False            None
    END

Download GST Invoice
    [Arguments]    ${DownloadPath}    ${FileName}    ${TmlRefNumber}    ${InvoiceType}
    TRY
        ${Log}           Set Variable    Started GST Downloading process.
        Text File Log    Info            Download GST Invoice    ${Log}
        Log              ${Log}
        
        #Waiting for Spinner to close
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display} 
        
        Set To Dictionary          ${ReadDictionary}      Invoice Type            ${InvoiceType}    
        Set To Dictionary          ${ReadDictionary}      Reference No            ${TmlRefNumber}
        Set To Dictionary          ${StatusDictionary}    Download                In Progress 
        ${Status}                  Update Excel Rows      ${StatusFilePath}       ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
        Remove From Dictionary     ${ReadDictionary}      Invoice Type            Reference No
        Remove From Dictionary     ${StatusDictionary}    Download                 
        
        ${DownloadFile}            Set Variable           ${DownloadFolderPath}/${FileName} 
        ${ArchiveFolder}           Set Variable           ${DownloadFolderPath}/Archive

        #Invoke Python code to move all existing PDFs in the download folder to archive folder
        ${Status}                  Move Pdfs To Archive    ${DownloadFolderPath}    ${ArchiveFolder}
        
        #Cross checking whether the file exist, if so delete the file
        ${FileCheck}               File Exist              ${DownloadFile}
        IF  (${FileCheck})
            RPA.FileSystem.Remove File    ${DownloadFile}
        END

        ${DownloadScreenCheck}    Wait Until Element Available    ${loc_download_button}
        ${IrnGeneratedCheck}      Wait Until Element Available    ${loc_irn_no_check}
        IF  ${DownloadScreenCheck} and ${IrnGeneratedCheck}
            ${DownloadPromise}    Promise To Wait For Download    ${DownloadFile}
            ${DownloadStatus}     Run Keyword And Return Status   Click Element Action    ${loc_download_button}
            Wait For              ${DownloadPromise}
        ELSE
            ${Log}           Set Variable    Download button not visible.
            Text File Log    Error           Download GST Invoice    ${Log}
            Fail             ${Log}
        END
        
        #Waiting for Spinner to close
        ${LoaderInvisibleCheck}    Wait Until Element Available With Timeout   ${loc_loader_display}     ${MEDIUM_WAIT}
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears               ${loc_loader_display} 

        IF  ${DownloadStatus}
            ${Log}           Set Variable    Successfully clicked on download button.
            Text File Log    Info            Download GST Invoice    ${Log}
            Log             ${Log}
        ELSE
            ${Log}           Set Variable    Failed to click on download button.
            Text File Log    Error           Download GST Invoice    ${Log}
            Fail             ${Log}
        END
           
        ${PdfExist}          ${LogMessage}       Check Pdf File Until It Exists    ${DownloadFolderPath} 
        ${FileCheck}         File Exist          ${DownloadFile}

        IF  ${FileCheck}
            ${Log}           Set Variable    Invoice PDF downloaded successfully.
            Text File Log    Info            Download GST Invoice    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Invoice PDF downloading failed.
            Text File Log    Error           Download GST Invoice    ${Log}
            Fail             ${Log}   
        END

        # #Switching to Windows automation
        # RPA.Windows.Control Window                       ${loc_download_window}       
        # ${FileName}        Get Value Into                ${loc_download_path_field}
        # ${Path}            Set Variable                  ${DownloadPath}/${FileName}   
        # Type Into          ${loc_download_path_field}    ${Path}         
        # Click Into         ${loc_save_button_download}
        
        ${Path}     RPA.FileSystem.Join Path            ${DownloadPath}    ${FileName}
        ${FileCheck}               File Exist           ${Path}
        IF  (${FileCheck})
            RPA.FileSystem.Remove File                  ${Path}
        END
        RPA.FileSystem.Move File   ${DownloadFile}      ${Path} 
        ${FileCheck}               File Exist           ${Path}

        IF  ${FileCheck}
            ${Log}           Set Variable    Invoice PDF moved successfully to required location.
            Text File Log    Info            Download GST Invoice    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Moving Invoice PDF failed.
            Text File Log    Error           Download GST Invoice    ${Log}
            Fail             ${Log}   
        END

        ${Log}           Set Variable    Completed GST Downloading process.
        Text File Log    Info            Download GST Invoice    ${Log}
        Log              ${Log}
        RETURN           True            ${Path}
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error           Download GST Invoice    ${Exception}
        RETURN           False           None
    END

Upload GST Invoice
    [Arguments]    ${FilePath}    ${TmlRefNumber}    ${InvoiceType}
    TRY
        ${Log}           Set Variable    Started GST Uploading process.
        Text File Log    Info            Upload GST Invoice    ${Log}
        Log              ${Log}

        #Click on Documents tab to open Upload screen
        Click Element Action       ${loc_documents}
        
        Set To Dictionary          ${ReadDictionary}      Invoice Type            ${InvoiceType}    
        Set To Dictionary          ${ReadDictionary}      Reference No            ${TmlRefNumber}
        Set To Dictionary          ${StatusDictionary}    Upload                  In Progress 
        ${Status}                  Update Excel Rows      ${StatusFilePath}       ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
        Remove From Dictionary     ${ReadDictionary}      Invoice Type            Reference No
        Remove From Dictionary     ${StatusDictionary}    Upload

        ${UploadScreenCheck}    Wait Until Element Available    ${loc_upload_screen_check}
        IF  ${UploadScreenCheck}
            Press Key Action    ${loc_choose_file}    Enter

            #Switching to Windows automation
            RPA.Windows.Control Window                          ${loc_choose_window}   
            Type Into                     ${loc_path_field}     ${FilePath}
            RPA.Desktop.Press Keys        Enter
        ELSE
            ${Log}           Set Variable    Upload page doesn't opened.
            Text File Log    Error           Upload GST Invoice    ${Log}
            Log              ${Log}
        END

        ${UploadButtonStatus}       Run Keyword And Return Status     Click Element Action    ${loc_upload_button} 

        IF  ${UploadButtonStatus}
            ${Log}           Set Variable    Successfully clicked on upload button.
            Text File Log    Info            Upload GST Invoice    ${Log}
            Log             ${Log}
        ELSE
            ${Log}           Set Variable    Failed to click on upload button.
            Text File Log    Error           Upload GST Invoice    ${Log}
            Fail             ${Log}
        END
        
        #Waiting for Spinner to close
        ${LoaderInvisibleCheck}    Wait Until Element Available     ${loc_loader_display}
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears    ${loc_loader_display}

        #Capture Status Message
        ${StatusMsgCheck}          Wait Until Element Available     ${loc_status_message}
        ${StatusMessage}           Get Text Action                  ${loc_status_message}
        ${StatusMessageLower}      Convert To Lower Case            ${StatusMessage}
        ${FileInCorrectMessage}    Set Variable                     Uploaded Invoice & Original invoice does not match
        ${FileInCorrectMessage}    Convert To Lower Case            ${FileInCorrectMessage}
        IF  ('${FileInCorrectMessage}' in '${StatusMessageLower}') or ('error in uploading document' in '${StatusMessageLower}')
            ${FileNotMatchFlag}    Evaluate    True
            Fail                   ${StatusMessage}
        END
        ${FileNotMatchFlag}     Evaluate    False
        Sleep                   ${DEFAULT_WAIT}
        Click Element Action    ${loc_upload_submit_button}

        ${PopupCheck}    Wait Until Element Available    ${loc_popup_submit}
        IF  ${PopupCheck}
            Click Element Action    ${loc_popup_submit}
        ELSE
            ${Log}           Set Variable    Popup window doesn't opened.
            Text File Log    Error           Upload GST Invoice    ${Log}
            Fail             ${Log}
        END
        
        #Waiting for Spinner to close
        ${LoaderInvisibleCheck}    Wait Until Element Available                 ${loc_loader_display}
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears                ${loc_loader_display}

        ${PageCloseCheck}          Wait Until Element Available With Timeout    ${loc_gst_screen_header}    ${LONG_WAIT}
        IF  ${PageCloseCheck}
            ${Log}           Set Variable    Submit screen automatically closed after Invoice Upload.
            Text File Log    Info            Upload GST Invoice    ${Log}
            Log              ${Log}
        ELSE 
            ${CloseButtonCheck}     Wait Until Element Available     ${loc_gstirn_close_button}
            IF  ${CloseButtonCheck}
                Click Element Action    ${loc_gstirn_close_button}
            END
        END

        ${SubmitButtonCloseCheck}    Wait Until Element Dissapears    ${loc_upload_submit_button}
        
        ${Log}           Set Variable    Completed GST Uploading process.
        Text File Log    Info            Upload GST Invoice    ${Log}
        Log              ${Log}
        RETURN           True            ${FileNotMatchFlag}
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error           Upload GST Invoice    ${Exception}
        RETURN           False           ${FileNotMatchFlag}
    END
Setting Filters And Start Search
    [Arguments]    ${InvoiceType}    ${loc_select_item}
    TRY
        #Setting dynamic locator for Invoice Types
        ${loc_dynamic_invoice_type}    Set Variable    //div[@class="menu transition visible"]//div[contains(text(), "${InvoiceType}")][1]   
        #Selecting current invoice type
        Click Element Action    ${loc_invoice_type}
        Click Element Action    ${loc_dynamic_invoice_type}
        
        # #Selecting current invoice status
        # Click Element Action    ${loc_invoice_status}
        # Click Element Action    ${loc_select_item}

        #Clicking Search Button
        Click Element Action    ${loc_search_button}      
        RETURN     True
    EXCEPT    AS    ${Exception}
        Log         ${Exception} 
        Text File Log    Error    Setting Filters And Start Search    ${Exception}
        RETURN           False  
    END

SAP Screen Check And Setting Lists For Loops
    TRY      
        ${WarrantyScreenCheck}    Wait Until Element Available    ${loc_gst_screen_header}
        IF  ${WarrantyScreenCheck}
            ${Log}           Set Variable    Successfully reached invoice filtering screen.
            Text File Log    Info            SAP Screen Check And Setting Lists For Loops    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Couldn't reach invoice filtering screen.
            Text File Log    Error           SAP Screen Check And Setting Lists For Loops    ${Log}
            Fail             ${Log}
        END

        #Fetching Dealer Code From SAP
        ${Comma}              Set Variable        ,            
        ${InvoiceTypeList}    Set Variable        ${CONFIG}[InvoiceType]
        ${InvoiceTypeList}    Split String        ${InvoiceTypeList}        ${Comma}
        Sleep                 ${SHORT_WAIT}    
        ${DealerCode}         Get Text Action     ${loc_dealer_code}
        
        IF  ('${DealerCode}' != '')
            ${Log}           Set Variable    Dealer code available, so processing the invoice uploading steps.
            Text File Log    Info            SAP Screen Check And Setting Lists For Loops    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    No Dealer code found.
            Text File Log    Error           SAP Screen Check And Setting Lists For Loops    ${Log}
            Fail             ${Log}    
        END
        ${CurrentMonthYear}       Get Current Date      result_format=${DateFormat}
        ${PreviousMonthYear}      Get Previous Month    ${CurrentMonthYear}

        Create List       @{MonthList}

        #Removing Items From Month List
        Remove Values From List           ${MonthList}            @{MonthList}

        Append To List    ${MonthList}    ${PreviousMonthYear}    ${CurrentMonthYear}
        # Unselect Frame
        RETURN    True    ${MonthList}    ${InvoiceTypeList}

    EXCEPT    AS    ${Exception}
        Log         ${Exception} 
        Text File Log    Error      SAP Screen Check And Setting Lists For Loops    ${Exception}
        RETURN           False      None    None
    END

Check And Create Folder
    [Arguments]    ${FolderPath}
    TRY
        ${Status}         Run Keyword And Return Status          Directory Should Exist    ${FolderPath}
        IF  ${Status}
            ${Log}           Set Variable    Folder location: ${FolderPath} already exist.
            Text File Log    Info            Check And Create Folder    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Folder location: ${FolderPath} doesn't exist.
            Text File Log    Info            Check And Create Folder    ${Log}
            Log              ${Log}
        END
        Run Keyword If    not os.path.exists("${FolderPath}")    Create Directory          ${FolderPath}
        RETURN            True
    EXCEPT    AS    ${Exception}
        Log         ${Exception} 
        Text File Log    Error      Check And Create Folder    ${Exception}
        RETURN           False      
    END

Generate Unique Number
    TRY
        ${Date}        Get Current Date          result_format=%d%m%Y%H%M%S
        ${RandNo}      Generate Random String    4    [NUMBERS]
        ${UniqueId}    Set Variable              ${Date}_${RandNo}
        RETURN         True                      ${UniqueId}
    EXCEPT    AS    ${Exception}
        Log         ${Exception} 
        Text File Log    Error      Generate Unique Number    ${Exception}
        RETURN           False      None      
    END

Check Pdf File Until It Exists
    [Arguments]    ${FolderPath} 
    TRY
        ${FileCheck}    Evaluate    False  # Initialize the loop condition
        ${Iteration}    Evaluate    1
        WHILE    not ${FileCheck}
            ${FileCheck}    Check Pdf File Exists    ${FolderPath}
            Run Keyword If    not ${FileCheck}    Log    File does not exist yet, checking again...
            Sleep    ${SHORT_WAIT}
            ${Iteration}    Evaluate    ${Iteration} + 1
            IF  ${Iteration} == 15
                BREAK 
            END 
        END
        
        IF  ${FileCheck}
            ${Message}    Set Variable    File downloaded at ${FolderPath}
            RETURN    True    ${Message}
        ELSE
            ${Message}    Set Variable    Attempt to download file at ${FolderPath} was a failure.
            RETURN    False    ${Message}
        END
        
    EXCEPT    AS    ${Exception}
        Log    ${Exception}
        RETURN    False    ${Exception}
    END


Get TML Number List
    [Arguments]     
    TRY
        ${Log}           Set Variable    Started fetching TML Reference Number List.
        Text File Log    Info            Get TML Number List    ${Log}
        Log              ${Log}
        
        ${WarrantyScreenCheck}    Wait Until Element Available    ${loc_gst_screen_header}
        IF  ${WarrantyScreenCheck}
            ${Log}           Set Variable    Successfully reached invoice filtering screen.
            Text File Log    Info            Get TML Number List    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Couldn't reach invoice filtering screen.
            Text File Log    Error           Get TML Number List    ${Log}
            Fail             ${Log}
        END
        
        ${InvoiceCount}    RPA.Browser.Playwright.Get Element Count    ${loc_action_button}
        ${EndRange}        Evaluate    ${InvoiceCount} + 1

        #Removing items from NewTmlNo List
        Remove Values From List     ${NewTmlNoList}    @{NewTmlNoList}

        FOR    ${IterationCount}    IN RANGE    1   ${EndRange}
            #Setting row count
            ${RowCount}             Evaluate        ${IterationCount} + 1
            
            #Setting a List Of TML Numbers
            ${TmlReferenceNo}       Get Text Action     (//tr[contains(@class, 'ng-star-inserted')])[${RowCount}]/td[6]
            ${TmlReferenceNo}       Strip String        ${TmlReferenceNo}
            Append To List          ${NewTmlNoList}     ${TmlReferenceNo}
        END
        
        ${Log}               Set Variable    Completed fetching TML Reference Number List.
        Text File Log        Info            Get TML Number List    ${Log}
        Log                  ${Log}
        RETURN       True    ${NewTmlNoList}

    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        RETURN      False    None 
    END

Read Status Excel Tracker
    [Documentation]          Reads values from tracker excel file and stores them as a list of dictionary.
    [Arguments]              ${SheetName}    ${MatchDictionary}    ${FilePath}
    TRY
        ${Log}                 Set Variable    Started reading status excel tracker file.
        Text File Log          Info            Read Status Excel Tracker                 ${Log}
        Log                    ${Log}
        
        ${DataTable}           ExcelOperations.Read Excel File                                 ${FilePath}       ${SheetName}
        ${ListOfDictionary}    ExcelOperations.Filter Data Table For Multiple Column Values    ${DataTable}      ${MatchDictionary}

        ${Log}                 Set Variable    Completed reading status excel tracker file.
        Text File Log          Info            Read Status Excel Tracker                 ${Log}
        Log                    ${Log}
        RETURN                 True            ${ListOfDictionary}

    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log          Error           Read Status Excel Tracker     ${Exception}
        RETURN                 False           None
    END

Fetch All TML Numbers  
    [Arguments]    ${InvoiceCount}
    TRY
        ${Log}           Set Variable    Started fetching all TML Reference Numbers.
        Text File Log    Info            Fetch All TML Numbers    ${Log}
        Log              ${Log}
      
        ${EndRange}      Evaluate        ${InvoiceCount} + 1
        
        #Removing items from TmlNo List
        Remove Values From List    ${TmlNoList}    @{TmlNoList}
        ${RowCount}                Evaluate        2

        FOR    ${LoopCount}    IN RANGE    1   ${EndRange}
                        
            #Setting a List Of TML Numbers
            ${TmlReferenceNo}       Get Text Action     (//tr[contains(@class, 'ng-star-inserted')])[${RowCount}]/td[6]
            ${TmlReferenceNo}       Strip String        ${TmlReferenceNo}
            Append To List          ${TmlNoList}        ${TmlReferenceNo}

            # Check if next button needs to be clicked after each full page
            ${Remainder}    Evaluate    ${LoopCount} % ${PageLimit}
            ${IsLast}       Evaluate    ${LoopCount} == ${InvoiceCount}

            #Setting row count increment
            ${RowCount}     Evaluate    ${RowCount} + 1

            IF  ('${Remainder}' == '0') and not ${IsLast}
                Click Element Action       ${loc_next_page_button}
                ${LoaderInvisibleCheck}    Wait Until Element Available    ${loc_loader_display}
                ${LoaderInvisibleCheck}    Wait Until Element Dissapears   ${loc_loader_display}
                ${RowCount}                Evaluate    2
            END
        END

        ${Log}           Set Variable     Completed fetching all TML Reference Numbers.
        Text File Log    Info             Fetch All TML Numbers     ${Log}
        Log              ${Log}
        RETURN           True             ${TmlNoList}
    EXCEPT    AS    ${Exception}
        Text File Log    Error            Fetch All TML Numbers     ${Exception}
        Log              ${Exception}
        RETURN           False            None
    END

Digital Signing PDF
    [Arguments]    ${PdfPath}
    TRY
        ${Log}                Set Variable    Started digital signing process of the pdf invoice.
        Text File Log         Info            Digital Signing PDF    ${Log}
        Log                   ${Log}
      
        # #Invoking robot keyword to implement digital signature in the PDF
        # ${Status}    Digital Sign Using Sikuli    $PdfFilePath    $TmlRefNumber    $InvoiceType
        # IF  ${Status}
        #     ${Log}            Set Variable     Digital signing process completed successfully.
        #     Text File Log     Info             Digital Signing PDF         ${Log}
        #     Log               ${Log}
        # ELSE
        #     ${Log}            Set Variable     Exception occurred while digitally signing the invoice.
        #     Text File Log     Error            Digital Signing PDF         ${Log}
        #     Fail              ${Log}
        # END
        ${Log}                Set Variable     Completed digital signing of the pdf invoice.
        Text File Log         Info             Digital Signing PDF     ${Log}
        Log                   ${Log}
        RETURN                True             ${PdfPath} 
    EXCEPT    AS    ${Exception}
        Text File Log         Error            Digital Signing PDF     ${Exception}
        Log                   ${Exception}     
        RETURN                False            None     
    END

Update Final Status In Report
    [Arguments]    
    TRY
        ${Log}                Set Variable    Started updating final status in end report.
        Text File Log         Info            Update Final Status In Report    ${Log}
        Log                   ${Log}
      
        ${DataTable}          ExcelOperations.Read Excel File                    ${StatusFilePath}      ${BriefTrackerSheet}
        ${ListOfLoginId}      ExcelOperations.Unique Column Values As List       ${DataTable}           Login
        
        FOR    ${LoginId}    IN    @{ListOfLoginId}

            #Filtering the list data from the excel as key value pair based on the provided column value for Logins
            ${ListOfDictionary}    ExcelOperations.Filter Data Table For Specific Column Value    ${DataTable}    Login    ${LoginId}

            ${ListOfDictionary}    Filter Not Completed Rows From Data    ${ListOfDictionary}
            ${LengthOfList}        Get Length      ${ListOfDictionary}
            
            IF  ${LengthOfList} > 0
                Set To Dictionary    ${MatchDictionary}      Login ID                ${LoginId} 
                Set To Dictionary    ${StatusDictionary}     Status                  Not Completed  
                Update Excel Rows    ${StatusFilePath}       ${ReportSheetName}      ${MatchDictionary}    ${StatusDictionary}
            ELSE
                Set To Dictionary    ${MatchDictionary}      Login ID                ${LoginId} 
                Set To Dictionary    ${StatusDictionary}     Status                  Completed  
                Update Excel Rows    ${StatusFilePath}       ${ReportSheetName}      ${MatchDictionary}    ${StatusDictionary}
            END
            Remove From Dictionary   ${StatusDictionary}    Status                
            Remove From Dictionary   ${MatchDictionary}     Login ID               
        END

        ${Log}                Set Variable     Completed updating final status in end report.
        Text File Log         Info             Update Final Status In Report     ${Log}
        Log                   ${Log}
        RETURN                True             
    EXCEPT    AS    ${Exception}
        Text File Log         Error            Update Final Status In Report     ${Exception}
        Log                   ${Exception}     
        RETURN                False            
    END

Uploading Files To Google Drive
    [Arguments]    
    TRY
        ${Log}                Set Variable    Started uploading files To Google Drive.
        Text File Log         Info            Uploading Files To Google Drive    ${Log}
        Log                   ${Log}
        
        #Setting up variables for creating paths
        ${CurrentDate}         Get Current Date      result_format=${NormalDateFormat}
        ${MonthYear}           Get Current Date      result_format=${DateFormat}
        ${MonthYearSplit}      Split String          ${MonthYear}    -
        ${CurrentYear}         Set Variable          ${MonthYearSplit}[1]
        ${CurrentMonth}        Set Variable          ${MonthYearSplit}[0]

        ${DownloadPath}        Set Variable          ${CONFIG}[ClaimsFolderPath]/Downloads/GST_Invoices
        ${UploadPath}          Set Variable          ${CONFIG}[ClaimsFolderPath]/Uploads/GST_Invoices

        #Fetching all folders in Upload Path
        ${DirectoryList}      RPA.FileSystem.List Directories In Directory     ${UploadPath}
        
        #Looping through each folder in the provided directory
        FOR    ${Folder}    IN     @{DirectoryList}

            ${FolderName}          Get File Name     ${Folder}
            ${GoogleDrivePath}     Set Variable      GST_Invoices/${FolderName}/${CurrentYear}/${CurrentMonth}/${CurrentDate}
            ${PdfPath}             Set Variable      ${CONFIG}[ClaimsFolderPath]/Uploads/GST_Invoices/${FolderName}/${CurrentYear}/${CurrentMonth}/${CurrentDate}

            #Setting the folder list to be created in Google Drive
            ${FolderList}         Split String       ${GoogleDrivePath}    /    
        
            #Setting the folder Id to upload PDFs
            ${FolderIdPdf}    Create Nested Folders    ${FolderList}    ${CLIENT_CONFIG}[RootFolderId]

            IF  ('${FolderIdPdf}' != 'None')
                
                #Setting the list of all PDFs in the specified location
                ${PdfFiles}    RPA.FileSystem.List Files In Directory    ${PdfPath} 

                FOR    ${File}    IN     @{PdfFiles}
                    ${FileName}          Get File Name            ${File}
                    ${UplaodStatus}      Upload File To Folder    ${FolderIdPdf}    ${File}
                    IF  ${UplaodStatus}
                        ${Log}           Set Variable    Successfully uploaded the PDF file: ${FileName} to Google Drive.
                        Text File Log    Info            Uploading Files To Google Drive    ${Log}
                        Log              ${Log}
                    ELSE
                        ${Log}           Set Variable    Exception occurred while uploading the PDF file: ${FileName} to Google Drive.
                        Text File Log    Error           Uploading Files To Google Drive    ${Log}
                        Log              ${Log}
                    END
                END
            ELSE
                ${Log}                   Set Variable    Couldn't retrieve the folder id to upload the PDFs in Google Drive.
                Text File Log            Error           Uploading Files To Google Drive    ${Log}
                Log                      ${Log} 
            END
        END

        #Fetching all folders in Download Path
        ${DirectoryList}      RPA.FileSystem.List Directories In Directory     ${DownloadPath}

        #Looping through each folder in the provided directory
        FOR    ${Folder}    IN     @{DirectoryList}

            ${FolderName}          Get File Name     ${Folder}
            ${GoogleDrivePath}     Set Variable      GST_Invoices/${FolderName}/${CurrentYear}/${CurrentMonth}
            ${ExcelPath}           Set Variable      ${CONFIG}[ClaimsFolderPath]/Downloads/GST_Invoices/${FolderName}/${CurrentYear}/${CurrentMonth}

            #Setting the folder list to be created in Google Drive
            ${FolderList}         Split String       ${GoogleDrivePath}    /

            #Setting the folder Id to upload Excel Files
            ${FolderIdExcel}      Create Nested Folders    ${FolderList}    ${CLIENT_CONFIG}[RootFolderId]

            IF  ('${FolderIdExcel}' != 'None')

                #Setting the list of all PDFs in the specified location
                ${PdfFiles}    RPA.FileSystem.List Files In Directory    ${ExcelPath}
                
                FOR    ${File}    IN      @{PdfFiles}
                    ${FileName}           Get File Name            ${File}
                    ${UplaodStatus}       Upload File To Folder    ${FolderIdExcel}     ${File}
                    IF  ${UplaodStatus}
                        ${Log}            Set Variable    Successfully uploaded the Excel File to Google Drive.
                        Text File Log     Info            Uploading Files To Google Drive    ${Log}
                        Log               ${Log}
                    ELSE
                        ${Log}            Set Variable    Exception occurred while uploading the Excel File to Google Drive.
                        Text File Log     Error           Uploading Files To Google Drive    ${Log}
                        Log               ${Log}
                    END
                END
            ELSE
                ${Log}                    Set Variable    Couldn't retrieve the folder id to upload the Excel in Google Drive.
                Text File Log             Error           Uploading Files To Google Drive    ${Log}
                Log                       ${Log} 
            END
        END

        ${Log}                Set Variable     Completed uploading files To Google Drive.
        Text File Log         Info             Uploading Files To Google Drive     ${Log}
        Log                   ${Log}
        RETURN                True             
    EXCEPT    AS    ${Exception}
        Text File Log         Error            Uploading Files To Google Drive     ${Exception}
        Log                   ${Exception}     
        RETURN                False            
    END

Uploading Status Excel To Google Drive
    [Arguments]    
    TRY
        ${Log}                Set Variable    Started uploading the tracker excel to Google Drive.
        Text File Log         Info            Uploading Status Excel To Google Drive    ${Log}
        Log                   ${Log}
        
        #Uploading the Tracker Excel To Google rive        
        ${UplaodStatus}       Upload File To Folder        ${CLIENT_CONFIG}[StatusFolderId]     ${StatusFilePath}
        IF  ${UplaodStatus}
            ${Log}            Set Variable    Successfully uploaded the Tracker Excel File to Google Drive.
            Text File Log     Info            Uploading Status Excel To Google Drive    ${Log}
            Log               ${Log}
        ELSE
            ${Log}            Set Variable    Exception occurred while uploading the Tracker Excel File to Google Drive.
            Text File Log     Error           Uploading Status Excel To Google Drive    ${Log}
            Log               ${Log}
        END

        #Uploading Consolidated Excel To Google rive        
        ${UplaodStatus}       Upload File To Folder        ${CLIENT_CONFIG}[RootFolderId]     ${ConsolidatedExcel}
        IF  ${UplaodStatus}
            ${Log}            Set Variable    Successfully uploaded the Consolidated Excel File to Google Drive.
            Text File Log     Info            Uploading Files To Google Drive    ${Log}
            Log               ${Log}
        ELSE
            ${Log}            Set Variable    Exception occurred while uploading the Consolidated Excel File to Google Drive.
            Text File Log     Error           Uploading Files To Google Drive    ${Log}
            Log               ${Log}
        END

        ${Log}                Set Variable     Completed uploading tracker excel to Google Drive.
        Text File Log         Info             Uploading Status Excel To Google Drive     ${Log}
        Log                   ${Log}
        RETURN                True             
    EXCEPT    AS    ${Exception}
        Text File Log         Error            Uploading Status Excel To Google Drive     ${Exception}
        Log                   ${Exception}     
        RETURN                False            
    END