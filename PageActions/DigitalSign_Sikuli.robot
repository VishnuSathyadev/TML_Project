*** Settings ***
Library         SikuliLibrary  
Library         RPA.Browser.Selenium   
Library         RPA.Browser.Playwright
Library         RPA.FileSystem
Library         OperatingSystem
Library         RPA.Windows
Library         RPA.Desktop
Library         Collections
Library         RPA.PDF
Resource        Status.robot
Resource        TextLog.robot
Resource    ConfigManagement.robot
Variables       ../Variables/GlobalVariables.py

*** Variables ***

&{ReadDictionary}
&{StatusDictionary}

*** Keywords ***

Digital Sign Using Sikuli  
    [Arguments]       ${PdfFilePath}    ${TmlRefNumber}    ${InvoiceType}    ${Password}    ${GoogleDrivePath}
    TRY
        ${Log}           Set Variable    Started processing digital sign implementation using Sikuli.
        Text File Log    Info            Digital Sign Using Sikuli    ${Log}
        Log              ${Log}

        ${Parts}         Split String    ${PdfFilePath}    \\
        ${FileName}      Set Variable    ${Parts}[-1]
        ${SavePath}      Join Path       ${EXECDIR}        Output\\${GoogleDrivePath}\\${FileName}    
        # ${SavePath}      Join Path       ${EXECDIR}        ${FileName}

        #Updating Tracker Excel Status
        Set To Dictionary          ${ReadDictionary}      Invoice Type            ${InvoiceType}    
        Set To Dictionary          ${ReadDictionary}      Reference No            ${TmlRefNumber}
        Set To Dictionary          ${StatusDictionary}    Digital Sign            In Progress 
        ${Status}                  Update Excel Rows      ${StatusFilePath}       ${TrackerSheetName}     ${ReadDictionary}    ${StatusDictionary}
        Remove From Dictionary     ${ReadDictionary}      Invoice Type            Reference No
        Remove From Dictionary     ${StatusDictionary}    Digital Sign 

        RPA.Desktop.Open File      ${PdfFilePath}
        Sleep    3s

        # Start the Sikuli application
        Start Sikuli Process

        #Setting Sikuli Image Folder Path
        ${SikuliFolderPath}      Set Variable      ${EXECDIR}/SikuliImages/

        # Verify PDF is opened (optional)
        SikuliLibrary.Wait Until Screen Contain    ${SikuliFolderPath}pdf_header.png    10

        SikuliLibrary.Wait Until Screen Contain    ${SikuliFolderPath}pdf_header.png    10

        # Click on "Search" → " POPULAR MEGA MOTORS " using image recognition
        SikuliLibrary.Click         ${SikuliFolderPath}search_box.png 
        ${PopupExist}               SikuliLibrary.Exists    ${SikuliFolderPath}restore_popup.png    2
        IF  ('${PopupExist}' != 'False')
            SikuliLibrary.Click     ${SikuliFolderPath}popup_close.png
        END
        SikuliLibrary.Input Text    ${SikuliFolderPath}search_type.png              POPULAR MEGA MOTORS (INDIA) PVT LTD
        Sleep    3s
        SikuliLibrary.Click         ${SikuliFolderPath}enter_popluarText
        RPA.Desktop.Press Keys      Enter
        Sleep    3s
        SikuliLibrary.Click         ${SikuliFolderPath}popular_next_button
        Sleep    2s
        SikuliLibrary.Click         ${SikuliFolderPath}clear_serach_total.png
        RPA.Desktop.Press Keys      CTRL    A
        RPA.Desktop.Press Keys      Delete
        SikuliLibrary.Click         ${SikuliFolderPath}close_search_total.png

        # Click on "Search" → "Digitally Sign" using image recognition
        SikuliLibrary.Click         ${SikuliFolderPath}search_box.png 
        SikuliLibrary.Input Text    ${SikuliFolderPath}search_type.png              Digitally Sign   
        SikuliLibrary.Click         ${SikuliFolderPath}select_digitally_sign.png
        Sleep                       ${SHORT_WAIT}
        SikuliLibrary.Mouse Move    ${SikuliFolderPath}to_to.png 
        Sleep                       ${SHORT_WAIT}
        
        #Invoke Drag Selection Keyword 
        ${DragStatus}    Drag Selection To Sign
        IF  ${DragStatus}
            ${Log}           Set Variable    Successfully completed selecting signing area.
            Text File Log    Info            Digital Sign Using Sikuli    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Exception occurred while selecting signing area.
            Text File Log    Error           Digital Sign Using Sikuli    ${Log}
            Fail             ${Log} 
        END

        SikuliLibrary.Wait Until Screen Contain    ${SikuliFolderPath}sign.png    3
        SikuliLibrary.Click                        ${SikuliFolderPath}sign.png 
        SikuliLibrary.Click                        ${SikuliFolderPath}continue.png
        Sleep    2s
        SikuliLibrary.Click                        ${SikuliFolderPath}sign_button.png  

        #Invoke Save PDF Keyword  
        ${SaveStatus}    Save PDF    ${SavePath}    ${SikuliFolderPath}    ${PdfFilePath}
        IF  ${SaveStatus}
            ${Log}           Set Variable    Successfully saved the digitally signed invoice.
            Text File Log    Info            Digital Sign Using Sikuli    ${Log}
            Log              ${Log}   
        ELSE
            ${Log}           Set Variable    Exception occurred while saving the digitally signed invoice.
            Text File Log    Error           Digital Sign Using Sikuli    ${Log}
            Fail             ${Log} 
        END

        Sleep                ${SHORT_WAIT}
        ${Location}          SikuliLibrary.Exists    ${SikuliFolderPath}sign_credential.png    2

        IF  ('${Location}' != 'False')
            SikuliLibrary.Input Text    ${SikuliFolderPath}sign_credential.png    ${Password}
            SikuliLibrary.Click         ${SikuliFolderPath}sign_ok_button.png
        END
        Sleep                           ${SHORT_WAIT}           
        Close All Applications

        ${Log}           Set Variable    Completed processing digital sign implementation using Sikuli.
        Text File Log    Info            Digital Sign Using Sikuli    ${Log}
        Log              ${Log}
        RETURN           True            ${SavePath}
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        Close All Applications
        Text File Log    Error           Digital Sign Using Sikuli    ${Exception}
        RETURN           False           None
    END


Drag Selection To Sign
    TRY
        RPA.Desktop.Move Mouse    offset:-20,-130
        RPA.Desktop.Press Mouse Button 
        RPA.Desktop.Move Mouse    offset:300,120  
        RPA.Desktop.Release Mouse Button
        RETURN      True
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        RETURN      False
    END

Save PDF
    [Arguments]     ${SavePath}    ${SikuliFolderPath}    ${PdfFilePath}
    TRY
        RPA.Windows.Control Window      name:"Save As"  
        RPA.Windows.Set Value           name:"File name:" and path:"1|1|6|3|2|1"      ${SavePath} 
        RPA.Desktop.Press Keys          CTRL    A
        RPA.Desktop.Press Keys          Delete
        RPA.Windows.Set Value           name:"File name:" and path:"1|1|6|3|2|1"      ${SavePath} 
        Sleep                           ${DEFAULT_WAIT}
        RPA.Desktop.Press Keys          Enter
        # SikuliLibrary.Click             ${SikuliFolderPath}save_button.png
        RETURN      True
    EXCEPT    AS    ${Exception}
        Log         ${Exception}
        RETURN      False
    END  

    