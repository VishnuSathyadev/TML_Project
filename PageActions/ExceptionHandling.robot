*** Settings ***
Documentation   This robot files consist of the main processes in the whole project.
Library         RPA.Browser.Selenium
Library         RPA.Desktop
Resource        ConfigManagement.robot
Resource        TextLog.robot
Resource        InitialActions.robot
Resource        InvoiceTmlProcess.robot
Variables       ../PageObjects/PageSelectors.py
Variables       ../Variables/GlobalVariables.py

*** Variables *** 
${MaxRetries}    2

*** Keywords ***

Retry Scenario Login
    [Arguments]        ${Dictionary}
    TRY
        ${Log}                  Set Variable    Started processing Retry Scenario Login.
        Text File Log           Info            Retry Scenario Login    ${Log}
        Log                     ${Log}

        #Closing IFrame Page
        RPA.Browser.Playwright.Close Page

        #Logging out from SAP System
        ${LogoutStatus}         Logout Portal
        IF  ${LogoutStatus}
            ${Log}              Set Variable    Successfully logged out from SAP system.
            Text File Log       Info            Retry Scenario Login    ${Log}
            Log                 ${Log}
        ELSE
            ${Log}              Set Variable    Attempt to log out from the SAP system was a failure.
            Text File Log       Error           Retry Scenario Login    ${Log}
            Log                 ${Log}
        END

        #Close Current Browser
        RPA.Browser.Playwright.Close Browser
        
        #Invoking Open Website Keyword
        ${Status}               Open Website
        IF  ${Status}
            ${Log}              Set Variable    Successfully opened login page.
            Text File Log       Info            Retry Scenario Login    ${Log}
            Log                 ${Log}
        ELSE
            ${Log}              Set Variable    Exception occurred while opening login page.
            Text File Log       Error           Retry Scenario Login    ${Log}
            Fail                ${Log}
        END

        ${ReachedHomePage}       Wait Until Element Available With Timeout    ${loc_home_page_check}    ${MEDIUM_WAIT}
        IF  ('${ReachedHomePage}' == 'False')
            ${LoginStatus}       ${InvalidCredentialStatus}    Login Portal    ${Dictionary}
            IF  ${LoginStatus}
                ${Log}           Set Variable    Successfully logged into SAP system.
                Text File Log    Info            Retry Scenario Login    ${Log}
                Log              ${Log} 
            ELSE IF    ${InvalidCredentialStatus}
                ${Log}           Set Variable    Login failed due to invalid credentials.
                Text File Log    Error           Retry Scenario Login    ${Log}
                Fail             ${Log}
            ELSE
                ${Log}           Set Variable    Attempt to log into SAP system was a failure.
                Text File Log    Error           Retry Scenario Login    ${Log}
                Fail             ${Log}   
            END
        END

        ${RetryCount}          Evaluate    0
        WHILE    ${RetryCount} < ${MaxRetries}
            TRY
                ${HomePageIconExist}    Element Visible Action    ${loc_direct_home_button}
                IF  ${HomePageIconExist}
                    Click Element When Clickable Action           ${loc_direct_home_button}
                END
                
                #Invoking Navigation To SAP Screen Keyword
                ${NavigationStatus}     Navigation To SAP Warranty    ${Dictionary}
                IF  ${NavigationStatus}
                    ${Log}           Set Variable    Successfully navigated to SAP Warranty screen.
                    Text File Log    Info            Retry Scenario Login    ${Log}
                    Log              ${Log}
                    BREAK
                ELSE
                    ${Log}           Set Variable    Navigation to SAP Warranty screen failed.
                    Text File Log    Error           Retry Scenario Login    ${Log}
                    Fail             ${Log}
                END
            EXCEPT
                ${Log}           Set Variable    Navigation to SAP Warranty screen failed for Login ID: ${Dictionary}[Login ID]
                Text File Log    Error           Retry Scenario Login    ${Log}
                Log              ${Log}
                
                ${RetryCount}    Evaluate        ${RetryCount} + 1
                IF  ${RetryCount} >= ${MaxRetries}
                    ${Log}           Set Variable    Max retries reached for Login ID: ${Dictionary}[Login ID]. Moving to the next Login ID.
                    Text File Log    Info            Retry Scenario Login    ${Log}
                    Log              ${Log}
                ELSE
                    ${HomePageIconExist}    Element Visible Action    ${loc_direct_home_button}
                    IF  ${HomePageIconExist}
                        Click Element When Clickable Action           ${loc_direct_home_button}
                    END
                END
            END
        END

        RETURN           True

    EXCEPT       AS      ${Exception}
        Log              ${Exception}
        Text File Log    Error               Retry Scenario Login    ${Exception}
        RETURN           False
    END


Retry Scenario Invoice Type Loop
    [Arguments]        ${Dictionary}    ${Month}    ${loc_invoice_status_value}
    TRY
        ${Log}               Set Variable    Started processing Retry Scenario Invoice Type Loop.
        Text File Log        Info            Retry Scenario Invoice Type Loop    ${Log}
        Log                  ${Log}

        #Invoking Retry Scenario Login
        ${RetryLoginStatus}    Retry Scenario Login    ${Dictionary}
        IF  ${RetryLoginStatus}
            ${Log}           Set Variable    Successfully closed the browser and logged in again.
            Text File Log    Info            Retry Scenario Invoice Type Loop    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while trying to re-login.
            Text File Log    Info            Retry Scenario Invoice Type Loop    ${Log}
            Fail             ${Log}
        END
        
        #Selecting the frame to work on
        RPA.Browser.Selenium.Select Frame    ${loc_filter_frame}

        ${WarrantyScreenCheck}    Wait Until Element Available    ${loc_gst_screen_header}
        IF  ${WarrantyScreenCheck}
            ${Log}           Set Variable    Successfully reached invoice filtering screen.
            Text File Log    Info            Retry Scenario Invoice Type Loop    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Couldn't reach invoice filtering screen.
            Text File Log    Error           Retry Scenario Invoice Type Loop    ${Log}
            Fail             ${Log}
        END

        Sleep                ${SHORT_WAIT}
        ${DealerCode}        Get Value Action    ${loc_dealer_code}
        IF  ('${DealerCode}' != '')
            ${Log}           Set Variable    Dealer code available, so processing the invoice uploading steps.
            Text File Log    Info            Retry Scenario Invoice Type Loop    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    No Dealer code found.
            Text File Log    Error           Retry Scenario Invoice Type Loop    ${Log}
            Fail             ${Log}    
        END

        Press Key Action     ${loc_month_select}    CONTROL+a+DELETE
        Input Text Action    ${loc_month_select}    ${Month}

        #Selecting current invoice status
        Click Element Action      ${loc_invoice_status}
        Click Element Action      ${loc_invoice_status_value}

        ${Log}               Set Variable    Completed processing Retry Scenario Invoice Type Loop.
        Text File Log        Info            Retry Scenario Invoice Type Loop    ${Log}
        Log                  ${Log}
        RETURN               True

    EXCEPT       AS      ${Exception}
        Log              ${Exception}
        Text File Log    Error               Retry Scenario Login    ${Exception}
        RETURN           False
    END
    

Retry Scenario Invoice Data
    [Arguments]        ${Dictionary}    ${Month}    ${loc_invoice_status_value}    ${InvoiceType} 
    TRY
        ${Log}               Set Variable    Started processing Retry Scenario Invoice Data.
        Text File Log        Info            Retry Scenario Invoice Data    ${Log}
        Log                  ${Log}

        #Invoking Retry Scenario Login
        ${RetryLoopStatus}    Retry Scenario Invoice Type Loop    ${Dictionary}    ${Month}    ${loc_invoice_status_value}
        IF  ${RetryLoopStatus}
            ${Log}           Set Variable    Successfully closed the browser and logged in again.
            Text File Log    Info            Retry Scenario Invoice Data    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while trying to re-login.
            Text File Log    Info            Retry Scenario Invoice Data    ${Log}
            Fail             ${Log}
        END

        ${InvoiceType}       Strip String    ${InvoiceType}
        ${Status}            Setting Filters And Start Search    ${InvoiceType}    ${loc_invoice_status_value}
        IF  ${Status}
            ${Log}           Set Variable    Setting filters and initiating search completed successfully.
            Text File Log    Info            Retry Scenario Invoice Data    ${Log}
            Log              ${Log}
        ELSE
            ${Log}           Set Variable    Exception occurred while setting filters and initiating search.
            Text File Log    Error           Retry Scenario Invoice Data    ${Log}
            Fail             ${Log}
        END
    
        ${LoaderInvisibleCheck}    Wait Until Element Available With Timeout    ${loc_loader_display}    ${MEDIUM_WAIT}
        ${LoaderInvisibleCheck}    Wait Until Element Dissapears                ${loc_loader_display}  

        ${AlreadyDropdownSelected}     Element Visible Action           ${loc_dropdown_hudread}
        IF  ${AlreadyDropdownSelected}
            ${Log}                     Set Variable                     The dropdown value '100' is already selected.
            Text File Log              Info                             Retry Scenario Invoice Data    ${Log}
            Log                        ${Log}
        ELSE
            Click Element Action       ${loc_show_dropdown}
            Click Element Action       ${loc_choose_invoice_count}
            ${LoaderInvisibleCheck}    Element Visible Action            ${loc_loader_display}    
            ${LoaderInvisibleCheck}    Wait Until Element Dissapears     ${loc_loader_display} 
        END 

        ${Log}               Set Variable    Completed processing Retry Scenario Invoice Data.
        Text File Log        Info            Retry Scenario Invoice Data    ${Log}
        Log                  ${Log}
        RETURN               True

    EXCEPT       AS      ${Exception}
        Log              ${Exception}
        Text File Log    Error               Retry Scenario Login    ${Exception}
        RETURN           False
    END

Retry Scenario Position
    [Arguments]        ${Dictionary}
    TRY
        ${Log}                  Set Variable    Started processing Retry Scenario Position.
        Text File Log           Info            Retry Scenario Position    ${Log}
        Log                     ${Log}

        #Logging out from SAP System
        ${LogoutStatus}         Logout Portal
        IF  ${LogoutStatus}
            ${Log}              Set Variable    Successfully logged out from SAP system.
            Text File Log       Info            Retry Scenario Position    ${Log}
            Log                 ${Log}
        ELSE
            ${Log}              Set Variable    Attempt to log out from the SAP system was a failure.
            Text File Log       Error           Retry Scenario Position    ${Log}
            Log                 ${Log}
        END

        #Close Current Browser
        RPA.Browser.Playwright.Close Browser
        
        #Invoking Open Website Keyword
        ${Status}               Open Website
        IF  ${Status}
            ${Log}              Set Variable    Successfully opened login page.
            Text File Log       Info            Retry Scenario Position    ${Log}
            Log                 ${Log}
        ELSE
            ${Log}              Set Variable    Exception occurred while opening login page.
            Text File Log       Error           Retry Scenario Position    ${Log}
            Fail                ${Log}
        END

        ${ReachedHomePage}       Wait Until Element Available With Timeout    ${loc_home_page_check}    ${MEDIUM_WAIT}
        IF  ('${ReachedHomePage}' == 'False')
            ${LoginStatus}       ${InvalidCredentialStatus}    Login Portal    ${Dictionary}
            IF  ${LoginStatus}
                ${Log}           Set Variable    Successfully logged into SAP system.
                Text File Log    Info            Retry Scenario Position    ${Log}
                Log              ${Log} 
            ELSE IF    ${InvalidCredentialStatus}
                ${Log}           Set Variable    Login failed due to invalid credentials.
                Text File Log    Error           Retry Scenario Position    ${Log}
                Fail             ${Log}
            ELSE
                ${Log}           Set Variable    Attempt to log into SAP system was a failure.
                Text File Log    Error           Retry Scenario Position    ${Log}
                Fail             ${Log}   
            END
        END
        RETURN                   True

    EXCEPT       AS      ${Exception}
        Log              ${Exception}
        Text File Log    Error                  Retry Scenario Position    ${Exception}
        RETURN           False
    END