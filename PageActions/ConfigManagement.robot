***Settings ***
Documentation  This robot file initializes configuration dictionary which can be used throughout the project.
Library        RPA.Excel.Files
Library        RPA.Browser.Selenium
Library        RPA.Browser.Playwright
Library        RPA.Desktop
Library        String
Library        RPA.Windows
Library        OperatingSystem
Library        Collections
Resource       TextLog.robot
Library        ../Libraries/ExcelOperations.py
Library        ../Libraries/GoogleDrive.py
Variables      ../Variables/GlobalVariables.py


*** Variables ***
${InputExcelPath}

*** Keywords ***

Read Client Config File
    [Documentation]    Reads values from Client Excel config file and stores them as a list of dictionary.
    TRY
        ${Log}               Set Variable    Started reading client config file.
        Text File Log        Info            Read Client Config File                 ${Log}
        Log                  ${Log}
        
        #Setting Client Config File Name
        ${ClientConfigFileName}    Get File Name     ${CONFIG}[ClientConfigPath]

        #Download Client Config From Google Drive
        ${DownloadStatus}     Download File    ${ConfigFolderId}     ${ClientConfigFileName}       ${CONFIG}[ClientConfigPath]
        IF  ${DownloadStatus}
            ${Log}            Set Variable    Successfully downloaded the client config from Google Drive.
            Text File Log     Info            Read Client Config File    ${Log}
            Log               ${Log}
        ELSE
            ${Log}            Set Variable    Exception occurred while downloading client config from the Google Drive.
            Text File Log     Info            Read Client Config File    ${Log}
            Fail              ${Log}
        END

        ${DataTable}         ExcelOperations.Read Excel File                     ${CONFIG}[ClientConfigPath]      ${CONFIG}[ClientConfigSheetName]
        ${List_Of_Ids}       ExcelOperations.Unique Column Values As List        ${DataTable}                     Login ID

        #Reading Sheet2 for Dictionary Values
        &{OutClientConfig}     Create Dictionary
        Open Workbook          ${CONFIG}[ClientConfigPath]
        ${Table}               Read Worksheet As Table    name=${CONFIG}[ClientConfigSheetName2]    header=${True}
        FOR    ${row}    IN    @{Table}
            ${Name}            Set Variable         ${row['Name']}
            ${Name}            Strip String         ${Name}
            ${Value}           Set Variable         ${row['Value']}
            ${Value}           Convert To String    ${Value}
            ${Value}           Strip String         ${Value}

            IF  ("${Name}" != "${null}") and ("${Value}" != "${null}")
                Set To Dictionary    ${OutClientConfig}         ${Name}        ${Value}
            END
        END
        Set Global Variable              ${CLIENT_CONFIG}            ${OutClientConfig}
        Close Workbook

        ${Log}               Set Variable    Completed reading client config file.
        Text File Log        Info            Read Client Config File                 ${Log}
        Log                  ${Log}
        RETURN               True            ${List_Of_Ids}                          ${DataTable}

    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log        Error   Read Client Config File     ${Exception}
        RETURN      False    None    None
    END

Read Config File 
    [Documentation]    Reads values from the Bot config Excel file and stores them as global dictionary variables.
    TRY
        ${Log}               Set Variable    Started reading config file for bot.
        Text File Log        Info            Read Config File        ${Log} 
        Log                  ${Log}
          
        &{OutConfig}         Create Dictionary
        ${ConfigFilePath}    Set Variable        ${EXECDIR}${ConfigFile}
        Open Workbook        ${ConfigFilePath}
        ${Table}             Read Worksheet As Table    header=${True}
        FOR    ${row}    IN    @{Table}
            ${Name}            Set Variable         ${row['Name']}
            ${Name}            Strip String         ${Name}
            ${Value}           Set Variable         ${row['Value']}
            ${Value}           Convert To String    ${Value}
            ${Value}           Strip String         ${Value}

            IF  ("${Name}" != "${null}") and ("${Value}" != "${null}")
                Set To Dictionary    ${OutConfig}         ${Name}        ${Value}
            END
        END
        Set Global Variable              ${CONFIG}            ${OutConfig}
        Close Workbook
        ${Log}           Set Variable    Completed reading config file for bot.
        Text File Log    Info            Read Config File     ${Log}
        Log              ${Log} 
        RETURN           True
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error           Read Config File     ${Exception}
        RETURN           False
    END


# Click Element Action
#     [Arguments]    ${locater}
#     Sleep    0.5s
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Run Keywords  RPA.Browser.Selenium.Wait Until Element Is Visible    ${locater}  AND  RPA.Browser.Selenium.Click Element    ${locater}
 
# Right Click Action
#     [Arguments]    ${locater}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Open Context Menu    ${locater}
 
# Input Text Action
#     [Arguments]    ${locater}    ${Value}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keywords  RPA.Browser.Selenium.Wait Until Element Is Visible    ${locater}  AND  RPA.Browser.Selenium.Input Text    ${locater}    ${Value}    True
 
# Mouse Over Action
#     [Arguments]    ${locater}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Mouse Over   ${locater}
 
# Click Element When Clickable Action
#     [Arguments]    ${locater}
#     Sleep                          ${DEFAULT_WAIT}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Click Element When Clickable    ${locater}
 
# Get Text Action
#     [Arguments]    ${locater}
#     ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Get Text    ${locater}
#     RETURN   ${Text} 

# Get Value Action
#     [Arguments]    ${locater}
#     ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Get Value    ${locater}
#     RETURN   ${Text}  
 
# Element Visible Action
#     [Arguments]    ${locater}
#     Sleep       ${SHORT_WAIT}    
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Is Element Visible    ${locater}
#     RETURN   ${Flag}
 
# Clear Element Text Action
#     [Arguments]    ${locater}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Clear Element Text    ${locater}

# Wait Until Element Available
#     [Arguments]    ${locater}
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Run Keyword And Return Status    RPA.Browser.Selenium.Wait Until Element Is Visible    ${locater}    timeout=30s
#     RETURN   ${Flag} 

# Wait For Element To Disappear 
#     [Arguments]    ${locater}
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    RPA.Browser.Selenium.Wait Until Element Is Not Visible    ${locater}    timeout=60s
#     RETURN   ${Flag} 

# Get Message From Attribute
#     [Arguments]    ${locater}    ${attribute}
#     ${Message}    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Get Element Attribute    ${locater}    ${attribute}
#     RETURN    ${Message}

# File Exist
#     [Arguments]    ${path}
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    File Should Exist    ${path}
#     RETURN   ${Flag}

# Press Key Action
#     [Arguments]    ${locater}    ${keyword}
#     Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Selenium.Press Keys    ${locater}    ${keyword}

# Wait For Element To Disappear With Timeout 
#     [Arguments]    ${locater}    ${timeout}
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    RPA.Browser.Selenium.Wait Until Element Is Not Visible    ${locater}    timeout=${timeout}
#     RETURN   ${Flag}

# Wait Until Element Available With Timeout
#     [Arguments]    ${locater}    ${timeout}
#     ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Run Keyword And Return Status    RPA.Browser.Selenium.Wait Until Element Is Visible    ${locater}    timeout=${timeout}
#     RETURN   ${Flag}

Input Select Action
    [Arguments]    ${locater}    ${Value}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keywords  RPA.Browser.Selenium.Wait Until Element Is Visible    ${locater}  AND  RPA.Browser.Selenium.Select From List By Value    ${locater}    ${Value}

Type Into
    [Arguments]    ${locater}    ${Value}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Windows.Set Value    ${locater}    ${Value}

Click Into
    [Arguments]    ${locater}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Windows.Click    ${locater}    

Get Text Into
    [Arguments]    ${locater}
    ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Windows.Get Text    ${locater}
    RETURN   ${Text} 

Get Value Into
    [Arguments]    ${locater}
    ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Windows.Get Value    ${locater}
    RETURN   ${Text}  
 

Wait Until Element Dissapears
    [Arguments]    ${Locator} 
    TRY
        ${ElementVisible}    Evaluate    True  # Initialize the loop condition
        ${Iteration}         Evaluate    1
        WHILE    (${ElementVisible})
            Sleep                0.25s
            ${ElementVisible}    Element Visible Action    ${Locator}
            Run Keyword If       ${ElementVisible}         Log                Element does not dissapers yet, checking again...
            # Sleep              ${DEFAULT_WAIT}
            ${Iteration}         Evaluate                  ${Iteration} + 1
            IF  ${Iteration} == 100
                BREAK 
            END     
        END
        RETURN    True
    EXCEPT    AS    ${Exception}
        Log    ${Exception}
        RETURN    False
    END


#------------------------Playwright--------------------------#
Click Element Action
    [Arguments]    ${locater}
    Sleep    0.5s
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     RPA.Browser.Playwright.Click     ${locater}
 
Right Click Action
    [Arguments]    ${locater}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Open Context Menu    ${locater}
 
Input Text Action
    [Arguments]    ${locater}    ${Value}
   # Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keywords    RPA.Browser.Playwright.Wait For Elements State    ${locater}    visible    timeout=10s    AND    RPA.Browser.Playwright.Type Text    ${locater}    ${Value}     clear=True
    RPA.Browser.Playwright.Type Text    ${locater}    ${Value}    clear=True

Mouse Over Action
    [Arguments]    ${locater}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Mouse Over   ${locater}
 
Click Element When Clickable Action
    [Arguments]    ${locater}
    Sleep                          ${DEFAULT_WAIT}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keywords    RPA.Browser.Playwright.Wait For Elements State    ${locater}    visible    timeout=10s   AND    RPA.Browser.Playwright.Click     ${locater}
 
Get Text Action
    [Arguments]    ${locater}
    ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Playwright.Get Text    ${locater}
    RETURN   ${Text} 

Get Value Action
    [Arguments]    ${locater}
    ${Text}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Playwright.Get Property    ${locater}    Value
    RETURN   ${Text}  
 
Element Visible Action
    [Arguments]    ${locater}
    Sleep       ${SHORT_WAIT}    
    ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    RPA.Browser.Playwright.Wait For Elements State     ${locater}    visible   timeout=0.5s
    RETURN   ${Flag}
 
Clear Element Text Action
    [Arguments]    ${locater}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Playwright.Clear Text    ${locater}

Wait Until Element Available
    [Arguments]    ${locater}
    ${Flag}    Run Keyword And Return Status    RPA.Browser.Playwright.Wait For Elements State     ${locater}    visible   timeout=30s
    RETURN   ${Flag} 

Wait For Element To Disappear 
    [Arguments]    ${locater}
    ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    RPA.Browser.Playwright.Wait For Elements State     ${locater}    visible    timeout=60s
    RETURN   ${Flag} 

Get Message From Attribute
    [Arguments]    ${locater}    ${attribute}
    ${Message}    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Get Element Attribute    ${locater}    ${attribute}
    RETURN    ${Message}

File Exist
    [Arguments]    ${path}
    ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    File Should Exist    ${path}
    RETURN   ${Flag}

Press Key Action
    [Arguments]    ${locater}    ${keyword}
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    RPA.Browser.Playwright.Press Keys    ${locater}    ${keyword}

Wait For Element To Disappear With Timeout 
    [Arguments]    ${locater}    ${timeout}
    ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}    Run Keyword And Return Status    RPA.Browser.Playwright.Wait For Elements State    ${locater}    visible     timeout=${timeout}
    RETURN   ${Flag}

Wait Until Element Available With Timeout
    [Arguments]    ${locater}    ${timeout}
    ${Flag}=    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${SHORT_GLOBAL_RETRY_INTERVAL}     Run Keyword And Return Status    RPA.Browser.Playwright.Wait For Elements State    ${locater}  visible     timeout=${timeout}
    RETURN   ${Flag}
