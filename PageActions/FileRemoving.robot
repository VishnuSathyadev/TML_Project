*** Settings ***
Library           OperatingSystem
Library           DateTime
Library           ../Libraries/Common.py
Resource          TextLog.robot
Resource          ConfigManagement.robot

*** Variables ***
@{FirstList}
@{SecondList}

*** Keywords ***
Directories To CleanUp Files
    TRY
        ${Log}               Set Variable    Started setting directories.
        Text File Log        Info            Directories To CleanUp Files    ${Log}
        Log                  ${Log}
        
        ${OutputPath}        RPA.FileSystem.Join Path    ${EXECDIR}                     Output
        ${InputPath}         RPA.FileSystem.Join Path    ${EXECDIR}                     Input
        ${SikuliPath}        RPA.FileSystem.Join Path    ${EXECDIR}                     Output\\sikuli_captured
        ${ScreenShot}        RPA.FileSystem.Join Path    ${EXECDIR}                     Output\\browser\\screenshot
        ${DownloadPath}      RPA.FileSystem.Join Path    ${CONFIG}[ClaimsFolderPath]    Downloads
        ${UploadPath}        RPA.FileSystem.Join Path    ${CONFIG}[ClaimsFolderPath]    Uploads
        ${MovePath}          RPA.FileSystem.Join Path    ${EXECDIR}                     Output\\Logs

        ${DeleteStatus}      Remove Older Files With Condition    ${EXECDIR}
        IF  ${DeleteStatus}
            ${Log}           Set Variable    Successfully removed all file.
            Text File Log    Info            Directories To CleanUp Files    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Exception occurred while removing files.
            Text File Log    Error           Directories To CleanUp Files    ${Log}
            Fail             ${Log} 
        END

        ${FirstList}         Create List     ${MovePath}    ${InputPath}    ${SikuliPath}    ${ScreenShot}
        
        #Move all files in output to Log folder
        ${MoveStatus}        Move All Files    ${OutputPath}    ${MovePath}
        IF  ${DeleteStatus}
            ${Log}           Set Variable    Successfully moved all file.
            Text File Log    Info            Directories To CleanUp Files    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Exception occurred while moving files.
            Text File Log    Error           Directories To CleanUp Files    ${Log}
            Fail             ${Log} 
        END

        FOR    ${Directory}    IN    @{FirstList}
            ${DeleteStatus}    Remove Older Files    ${Directory}
            IF  ${DeleteStatus}
                ${Log}           Set Variable    Successfully removed all file.
                Text File Log    Info            Directories To CleanUp Files    ${Log}
                Log              ${Log}   
            ELSE
                ${Log}           Set Variable    Exception occurred while removing files.
                Text File Log    Error           Directories To CleanUp Files    ${Log}
                Fail             ${Log} 
            END
        END
        
        ${SecondList}         Create List     ${DownloadPath}    ${UploadPath}    

        FOR    ${Directory}    IN    @{FirstList}
            ${DeleteStatus}    Delete Directory    ${Directory}
            IF  ${DeleteStatus}
                ${Log}           Set Variable    Successfully removed all file.
                Text File Log    Info            Directories To CleanUp Files    ${Log}
                Log              ${Log}   
            ELSE
                ${Log}           Set Variable    Exception occurred while removing files.
                Text File Log    Error           Directories To CleanUp Files    ${Log}
                Fail             ${Log} 
            END
        END
        
        ${Log}               Set Variable    Completed setting directories.
        Text File Log        Info            Directories To CleanUp Files    ${Log}
        Log                  ${Log}
        RETURN               True
    EXCEPT    AS    ${Exception}
        Log                  ${Exception}
        Text File Log        Error           Directories To CleanUp Files    ${Exception}
        RETURN               False
    END


Remove Older Files
    [Arguments]    ${DirectoryPath}
    TRY
        ${Log}               Set Variable    Started removing older files from directories.
        Text File Log        Info            Remove Older Files    ${Log}
        Log                  ${Log}

        ${Files}    RPA.FileSystem.List Files In Directory    ${DirectoryPath}

        FOR    ${File}    IN    @{Files}
            ${Path}             Convert To String    ${File}    
            ${ModTime}          Get Modified Time    ${Path}
            ${CurrentDate}      Get Current Date     result_format=epoch
            ${FileTime}         Convert Date         ${ModTime}                result_format=epoch
            ${AgeInDays}        Evaluate             (${CurrentDate} - ${FileTime}) / 86400

            Run Keyword If      ${AgeInDays} > ${CONFIG}[CleanUpDayCount]      OperatingSystem.Remove File    ${File}
        END

        ${Log}               Set Variable    Completed removing older files from directories.
        Text File Log        Info            Remove Older Files    ${Log}
        Log                  ${Log}
        RETURN               True
    EXCEPT    AS    ${Exception}
        Log                  ${Exception}
        Text File Log        Error      Remove Older Files    ${Exception}
        RETURN               False
    END

Remove Older Files With Condition
    [Arguments]    ${DirectoryPath}
    TRY
        ${Log}               Set Variable    Started removing older files from directories.
        Text File Log        Info            Remove Older Files    ${Log}
        Log                  ${Log}

        ${Files}    RPA.FileSystem.List Files In Directory    ${DirectoryPath}

        FOR    ${File}    IN    @{Files}
            ${FileName}   Get File Name     ${File}

                IF  'Sikuli_java' in '${FileName}'
                ${Path}             Convert To String    ${File}    
                ${ModTime}          Get Modified Time    ${Path}
                ${CurrentDate}      Get Current Date     result_format=epoch
                ${FileTime}         Convert Date         ${ModTime}                result_format=epoch
                ${AgeInDays}        Evaluate             (${CurrentDate} - ${FileTime}) / 86400   
                Run Keyword If      ${AgeInDays} > 1     OperatingSystem.Remove File    ${File}
            END
        END

        ${Log}               Set Variable    Completed removing older files from directories.
        Text File Log        Info            Remove Older Files    ${Log}
        Log                  ${Log}
        RETURN               True
    EXCEPT    AS    ${Exception}
        Log                  ${Exception}
        Text File Log        Error      Remove Older Files    ${Exception}
        RETURN               False
    END