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
Library    RPA.Email.ImapSmtp
Resource    PageActions/FileRemoving.robot

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
${StatusFilePath}       C:\\tml-integration_branch\\Input\\000208299601052025_WAR.pdf
${$GoogleDrivePath}        GST_Invoices/Kollam/2025/May/29-05-2025
@{FolderList}       Test     Test2
${Subject}              Test
${EmailBody}            Hi all
${RecipientTo}          vishnu.s@quadance.com
${RecipientCc}          ${None}
${Attachment}           D:/TML_Process_GIT/TML_Project/Input/StatusTrackerExcel_06_05_2025_09_05_37.xlsx
${path}                 D:\\TML_Process_GIT\\TML_Project\\Output\\ExecutionLog_07_05_2025.txt

${LOG_DIR}              D:\\TML_Process_GIT\\TML_Project\\Output

*** Tasks ***
TestTask
    ${FileExistInDrive}      ${FileName}    Check File Exists    1lhq_zUW-vbdE65NSbxkQdkWFdmznVNk5    StatusExcel.xlsx
    Read Config File
    Read Client Config File
    ${Status}    Uploading Files To Google Drive


    # ${MailStatus}    SendEmail.SendEmail   ${Subject}   ${EmailBody}   ${RecipientTo}   ${RecipientCc}   ${Attachment}    ${ReportSheetName}    cor.rpa.srvclaims@pmmil.com    udzn ybdc jaif akvx 
    # ${FileExistInDrive}      ${FileName}    Check File Exists    1lhq_zUW-vbdE65NSbxkQdkWFdmznVNk5    StatusExcel.xlsx
    FOR    ${File}    IN     @{FolderList}
        ${FileName}          Get File Name            ${File}
    END

    # Digital Sign Using Sikuli    ${StatusFilePath}    1245    AMC    ABCD@1234     ${$GoogleDrivePath}
    # # New Browser            chromium       headless=${False}
 