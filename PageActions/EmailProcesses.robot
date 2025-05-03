*** Settings ***
Resource        ConfigManagement.robot
Resource        TextLog.robot
Library         ../Libraries/SendEmail.py
Variables       ../Variables/GlobalVariables.py

*** Variables ***
${MaxRetries}       3

     
*** Keywords ***
End Job Report Email
    [Arguments]    ${Attachment}
    TRY
        ${RetryCount}        Set Variable    0

        #Setting required values in variables 
        ${BackSlash}       Set Variable        \\ 
        ${ForwardSlash}    Set Variable        / 

        #Replace backward slash in filepath with forward slash
        # ${FilePath}       Replace String      ${FilePath}    ${BackSlash}    ${ForwardSlash}

        #Setting Current date and To address to variables
        ${CurrentDate}    Get Current Date    result_format=${NormalDateFormat}
        ${RecipientTo}    Set Variable        ${CONFIG}[RecipientTo]
        
        #Setting CC recipients based on condition
        TRY
            ${RecipientCc}    Set Variable If    '${CONFIG}[RecipientCc]' != 'None'    ${CONFIG}[RecipientCc]    None
        EXCEPT   AS    ${Exception}
            ${RecipientCc}    Create List        
        END
        

        #Setting the email subject and body
        ${Subject}        Set Variable       TML Invoice Creation Run Report: ${CurrentDate}
        ${EmailBody}      Set Variable       The detailed run report for todays run is as follows:\n\n

        FOR    ${Attempt}    IN RANGE    ${MaxRetries}
            ${MailStatus}    SendEmail.SendEmail   ${Subject}   ${EmailBody}   ${RecipientTo}   ${RecipientCc}   ${Attachment}    ${ReportSheetName}    ${SenderEmail}   ${EmailPassword} 
            IF  ('${MailStatus}' == 'True')
                ${Log}           Set Variable       Email report sent successfully on attempt ${Attempt+1}.
                Text File Log    Info               End Job Report Email   ${Log}
                Log              ${Log}
                BREAK
            ELSE IF    ('${MailStatus}' == 'False')
                ${Log}           Set Variable       Email sending failed on attempt ${Attempt+1}. Stopping retry.
                Text File Log    Info               End Job Report Email   ${Log}
                Log              ${Log}
                BREAK
            ELSE
                ${Log}           Set Variable       Waiting for email status update... Retrying (Attempt ${Attempt+2}/${MaxRetries})
                Text File Log    Info               End Job Report Email   ${Log}
                Log              ${Log}
                Sleep            ${LONG_WAIT}
            END
        END 

        ${Log}               Set Variable    Completed sending end email report process.
        Text File Log        Info            End Job Report Email    ${Log}
        Log                  ${Log}
        RETURN               ${MailStatus}

    EXCEPT    AS    ${Exception}
        Log                  ${Exception}
        Text File Log        Error           End Job Report Email    ${Exception}
        RETURN               False
    END       