*** Settings ***
Library    RPA.FileSystem
Library    DateTime
Library    String


*** Variables ***
${FilePath}   

*** Keywords ***
File Creation
    [Documentation]    This keyword create the txt log file if not exist.
    TRY
        ${CurrentDate}    Get Current Date    result_format=%d_%m_%Y
        ${LogFilePath}    Set Variable        ${EXECDIR}/Output/ExecutionLog_${CurrentDate}.txt
        ${FileExist}      Does File Exist     ${LogFilePath}
        IF  ('${FileExist}' == '${False}')
            RPA.FileSystem.Create File        ${LogFilePath}
        END
        RETURN      ${LogFilePath}
    EXCEPT    AS    ${ErrorMessage}
        Log         ${ErrorMessage}
    END

Text File Log
    [Documentation]    This keyword appened time, log level, function name and content.
    [Arguments]        ${Loglevel}    ${FunctionName}    ${Content}
    TRY
        ${FilePath}        File Creation
        ${FunctionName}    Evaluate            "${FunctionName}".ljust(45)
        ${Loglevel}        Evaluate            "${Loglevel}".ljust(5)
        ${CurrentTime}     Get Current Date    result_format=%H:%M:%S:%f
        ${Text}            Set Variable        ${CurrentTime} | ${Loglevel} | Function Name: ${FunctionName} | Message: ${Content}    
        RPA.FileSystem.Append To File          ${FilePath}     ${Text}\n
    EXCEPT    AS    ${ErrorMessage}
        Log         ${ErrorMessage}
    END
    


    