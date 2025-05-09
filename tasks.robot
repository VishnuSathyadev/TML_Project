*** Settings ***
Documentation       Template robot main suite.
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

*** Tasks ***
        
Popular TML Process
    TRY
        ${Log}               Set Variable    Started processing Popular TML Process.
        Text File Log        Info            Popular TML Process    ${Log}
        Log                  ${Log}

        #Reading Config File for Bot
        ${BotConfigStatus}    Read Config File
        IF  ${BotConfigStatus}
            ${Log}           Set Variable    Successfully completed reading bot config file.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Exception occurred while reading bot config file.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log} 
        END

        #Reading Client Config Sheet which returns Dataframe and list of Login IDs
        ${ClientConfigStatus}    ${ListOfLoginId}    ${DataTable}    Read Client Config File
        IF  ${ClientConfigStatus}
            ${Log}           Set Variable    Successfully completed reading client config file.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while reading client config file.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log}
        END

        #Invoking Open Website Keyword
        ${Status}            Open Website
        IF  ${Status}
            ${Log}           Set Variable    Successfully opened login page.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while opening login page.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log}
        END

        #Looping through each LoginID from config sheet
        ${Status}    TML Invoice Process Loop    ${ListOfLoginId}    ${DataTable}
        IF  ${Status}
            ${Log}           Set Variable    Successfully completed TML Loop.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while processing TML Loop.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log}
        END

        #Formating Excel Headers
        ${FormatStatus}    Format Excel Headers    ${StatusFilePath}
        ${FormatStatus}    Format Excel Headers    ${ConsolidatedExcel}

        #Uploading all PDFs and Excel Data To Google Drive
        ${UploadClaimsToDriveStatus}         Uploading Files To Google Drive       
        IF  ${UploadClaimsToDriveStatus}
            ${Log}           Set Variable    Successfully uploaded the files to Google Drive.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while uploading the files to Google Drive.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log}
        END
        
        #Uploading Tracker Excel  To Google Drive
        ${UploadToDriveStatus}               Uploading Status Excel To Google Drive
        IF  ${UploadToDriveStatus}
            ${Log}           Set Variable    Successfully uploaded the tracker excel to Google Drive.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while uploading the tracker excel to Google Drive.
            Text File Log    Error           Popular TML Process    ${Log}
            Fail             ${Log}
        END

        #Invoking End Job Report Email Keyword
        ${MailStatus}        End Job Report Email    ${StatusFilePath}
        IF  ${MailStatus}
            ${Log}           Set Variable    Successfully completed TML End Job Report Mail.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while processing TML End Job Report Mail.
            Text File Log    Error           Popular TML Process    ${Log}
            Log              ${Log}
        END
        
        #Cleaning up unwanted files from local machine
        ${CleanUpStatus}    Directories To CleanUp Files
        IF  ${CleanUpStatus}
            ${Log}           Set Variable    Successfully removed all unwanted files from RDP.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while removing files from RDP.
            Text File Log    Error           Popular TML Process    ${Log}
            Log              ${Log}
        END

        #Deleting Status Tracker File
        RPA.FileSystem.Remove File           ${StatusFilePath}

        ${Log}               Set Variable    Completed processing Popular TML Process.
        Text File Log        Info            Popular TML Process    ${Log}
        Log                  ${Log}

        #Triggering TML Email Process
        ${TriggerStatus}    Run Batch File    batch_path
        IF  ${TriggerStatus}
            ${Log}           Set Variable    Successfully triggered the TML Email Process.
            Text File Log    Info            Popular TML Process    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while triggering the Email Process.
            Text File Log    Error           Popular TML Process    ${Log}
            Log              ${Log}
        END
        
    EXCEPT         AS        ${Exception}
        Log                  ${Exception}
        Text File Log        Error          Popular TML Process    ${Exception}
    END