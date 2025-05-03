*** Settings ***
Documentation       Template robot main suite.
Library             RPA.Browser.Playwright
Resource            PageActions/ConfigManagement.robot
Resource            PageActions/InitialActions.robot
Resource            PageActions/InvoiceTmlProcess.robot
Resource            PageActions/EmailProcesses.robot
Resource            PageActions/TextLog.robot
Resource            PageActions/Status.robot
Library             Libraries/ExcelOperations.py
Variables           Variables/GlobalVariables.py
Library             Libraries/Common.py
Library             Libraries/ExcelOperations.py
Library             RPA.Browser.Selenium
Library             XML

*** Variables ***
${TEXT}    000208299630032025
${Month}    Feb-2025
&{Appenddictionary}
${FilePath}    C:/Users/Vishnu Sathyadev/Desktop/TML Project/PDFs With Sign
${Name}        000208299628032025_WAR.pdf
${DOWNLOAD_PATH}    C:/Users/Vishnu Sathyadev/Desktop/TML Project
&{StatusDictionary}
@{StatusList}
${Column1}    Login
${Column2}    
&{Data}    
${DownloadFolderPath}    C:/Users/Vishnu Sathyadev/Desktop/TML Project/SUPPORTING DOC_2.xlsx
${PageDropdownValue}    10
${StatusFilePath}       C:/tml-integration_branch/Input/000208299601052025_WAR.pdf

*** Tasks ***
TestTask

    Digital Sign Using Sikuli    ${StatusFilePath}    1245    AMC    ABC@123
    # New Browser            chromium       headless=${False}
    # New Page             https://demo.automationtesting.in/Frames.html
    Sleep                ${SHORT_WAIT}    
    ${ZeroValue}    Evaluate    0
    ${ActionRowCount}    Evaluate    25
    IF    ${ActionRowCount} < ${PageLimit}
        Log    message     
    END