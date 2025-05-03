*** Settings ***
Documentation    This robot file can be used to initialize the applications required during the process.
Library          Collections
Library          DateTime
Library          String
Library          RPA.Browser.Selenium    auto_close=${False}
Resource         ConfigManagement.robot
Resource         TextLog.robot
Variables        ../PageObjects/PageSelectors.py
Variables        ../Variables/GlobalVariables.py

*** Variables ***
${WIDTH}     1918
${HEIGHT}    1078


*** Keywords ***
Open Website
    [Arguments]    
    TRY
        ${Log}           Set Variable    Opening Chrome Browser Application.
        Text File Log    Info            Open Website    ${Log}
        Log              ${Log}
        
        ${DownloadDirectory}      Set Variable               ${EXECDIR}/Input/Downloads
        Set Global Variable       ${DownloadFolderPath}      ${DownloadDirectory}

        New Browser               chromium                   headless=${False}
        New Context               acceptDownloads=${True}   
        New Page                  ${CONFIG}[Url]
        Set Viewport Size         ${WIDTH}                   ${HEIGHT}
        Sleep                     ${SHORT_WAIT}

        ${Log}           Set Variable    Successfully Opened Chrome Browser Application.
        Text File Log    Info            Open Website    ${Log}
        Log              ${Log}
        RETURN           True
    EXCEPT       AS      ${Exception}
        Log              ${Exception} 
        Text File Log    Error           Open Website    ${Exception}
        RETURN           False       
    END   

Login Portal
    [Arguments]    ${ListOfDictionary}
    TRY
        ${Log}           Set Variable    Started processing logging process to Popular's SAP System.
        Text File Log    Info            Login Portal    ${Log}
        Log              ${Log}

        ${LoginScreenPresent}    Wait Until Element Available    ${loc_login_header}
            IF  ${LoginScreenPresent}
                ${Log}           Set Variable    Successfully reached login screen.
                Text File Log    Info            Login Portal    ${Log}
                Log              ${Log}
            ELSE
                ${Log}           Set Variable    Unable to reach login screen.
                Text File Log    Error           Login Portal    ${Log}
                Fail             ${Log} 
            END

        ${LoginUsernameFieldPresent}    Element Visible Action    ${loc_login_username}
            IF  ${LoginUsernameFieldPresent}
                Input Text Action    ${loc_login_username}    ${ListOfDictionary}[Login ID]
            ELSE
                ${Log}           Set Variable    The username field is not visible.
                Text File Log    Error           Login Portal    ${Log}
                Fail             ${Log}
            END

        ${LoginPasswordPresent}    Element Visible Action    ${loc_login_password}
            IF  ${LoginPasswordPresent}
                Input Text Action    ${loc_login_password}    ${ListOfDictionary}[Present Password] 
            ELSE
                ${Log}           Set Variable    The password field is not visible.  
                Text File Log    Error           Login Portal    ${Log}
                Fail             ${Log} 
            END

        ${SigninButtonPresent}    Element Visible Action    ${loc_login_button}
            IF  ${SigninButtonPresent}
                Click Element Action    ${loc_login_button}
            ELSE
                ${Log}           Set Variable    The login button is not visible.
                Text File Log    Error           Login Portal    ${Log}
                Fail             ${Log}
            END
        
        ${ReachedHomePage}    Wait Until Element Available    ${loc_home_page_check}
            IF  ${ReachedHomePage}
                ${Log}           Set Variable    Successfully reached the Home page.
                Text File Log    Info            Login Portal    ${Log}
                Log              ${Log}
            ELSE
                ${InvalidCredentialStatus}    Wait Until Element Available With Timeout    ${loc_invalid_credentials}    ${SHORT_WAIT}
                ${Log}           Set Variable    Couldn't reach the Home page.
                Text File Log    Error           Login Portal    ${Log}
                Fail             ${Log}   
            END

        ${Log}           Set Variable    Successfully logged into Popular's SAP System.
        Text File Log    Info            Login Portal    ${Log}
        Log              ${Log}
        RETURN           True            None

    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Text File Log    Error    Login Portal    ${Exception}
        RETURN           False    ${InvalidCredentialStatus}
    END        

Logout Portal
    TRY
        ${Log}           Set Variable    Started processing logging off process from Popular's SAP System.
        Text File Log    Info            Logout Portal    ${Log}
        Log              ${Log}
        
        Sleep                   ${SHORT_WAIT}
        ${HomePageIconExist}    Element Visible Action    ${loc_direct_home_button}
        IF  ${HomePageIconExist}
            Click Element When Clickable Action     ${loc_direct_home_button}
            Click Element When Clickable Action     ${loc_profile_icon}
            Click Element Action    ${loc_log_out_button}
            ${LogoutCheck}    Wait Until Element Dissapears    ${loc_direct_home_button}
            IF  ${LogoutCheck}
                ${Log}           Set Variable    Successfully logged out from Popular's SAP System.
                Text File Log    Info            Logout Portal    ${Log}
                Log              ${Log}
            ELSE
                ${Log}           Set Variable    Attempt to log out from Popular's SAP System failed.
                Text File Log    Error           Logout Portal    ${Log}
                Fail             ${Log} 
            END
        ELSE
            ${Log}           Set Variable    Home button not visible.  
            Text File Log    Error           Logout Portal    ${Log}
            Fail             ${Log}   
        END

        ${Log}           Set Variable    Completed processing logging off process from Popular's SAP System.  
        Text File Log    Info            Logout Portal    ${Log}
        Log              ${Log}
        RETURN           True
    EXCEPT    AS    ${Exception}
        Log         ${Exception} 
        Text File Log    Error    Logout Portal   ${Exception} 
        RETURN           False      
    END