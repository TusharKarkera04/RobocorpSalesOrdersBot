*** Settings ***
Documentation   Orders robots from RobotSpareBin Industries Inc.
...             Saves the order HTML receipt as a PDF file.
...             Saves the screenshot of the ordered robot.
...             Embeds the screenshot of the robot to the PDF receipt.
...             Creates ZIP archive of the receipts and the images.
Library        RPA.Browser.Selenium    auto_close=${false}
Library        RPA.Robocorp.Vault
Library        RPA.HTTP
Library        RPA.Excel.Files
Library        RPA.PDF
Library        RPA.Tables
Library        RPA.Archive
Library        RPA.FileSystem
Library        RPA.Dialogs
Library        RPA.JSON 
  

*** Keywords ***
Open the website
    Open Available Browser    https://robotsparebinindustries.com/    maximized=True  

Log In
    ${secret}=    Get Secret    robotsparebin
    Log    ${secret}[username]
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form
    Wait Until Page Contains Element    id=logout

*** Keywords ***
Download Csv File
    [Arguments]        ${strUrl}
    Download    ${strUrl}    target_file=${CURDIR}${/}Data${/}Orders.csv  


*** Keywords ***
Navigate to tab
    Click Element    locator=//a[@href='#/robot-order']

*** Keywords ***
Click Alert Button
    Click Element    locator=//button[text()='OK'] 

        
*** Keywords ***
Read Csv Data and enter in website
    ${sales_reps}=    Read table from CSV    path=${CURDIR}${/}Data${/}Orders.csv    header=True
    FOR    ${row}    IN    @{sales_reps}
        ${orderNumber}=    Submit individual records into Webform    ${row}
        Export the Receipt as PDF    ${orderNumber}
        Save Robot Image    ${orderNumber}
        Attach Robot image with pdf    ${orderNumber}
        Click Element    order-another
        Click Alert Button
    END
     

*** Keywords ***
Submit individual records into Webform
    [Arguments]    ${row}
    ${target_as_string}=    Convert To String    ${row}[Head]
    ${strBody}=    Convert To String    ${row}[Body]
    Wait Until Element Is Visible    body    timeout=10
    Select Radio Button    body    id-body-${strBody}
    Select From List By Value    head        ${target_as_string}
    Input Text    //input[@type='number']    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Click Button    order
    Check Orders Receipt
    [Return]    ${row}[Order number]


*** Keywords ***
Check Orders Receipt
    ${receiptselector}=    Does Page Contain Element    id:receipt    count=${1}
    IF    ${receiptselector} == True
        Log  True
    ELSE
        Click Button    order
        Check Orders Receipt
        Log  else
    END
    

*** Keywords ***
Export the Receipt as PDF
    [Arguments]    ${orderNumber}   
    Wait Until Element Is Visible    id:receipt    timeout=10
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${CURDIR}${/}Data${/}PdfFiles${/}${orderNumber}.pdf


*** Keywords ***
Attach Robot image with pdf
    [Arguments]    ${orderNumber}
    ${listFiles}=    Create List    ${CURDIR}${/}Data${/}RobotImages${/}${orderNumber}.png            
    Add Files To Pdf    ${listFiles}    ${CURDIR}${/}Data${/}PdfFiles${/}${orderNumber}.pdf    append=True  

*** Keywords ***
Save Robot Image
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    id:robot-preview-image    timeout=10
    Set Selenium Speed    0.01 
    Screenshot    robot-preview-image    ${CURDIR}${/}Data${/}RobotImages${/}${orderNumber}.png

*** Keywords ***
Create ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}Data${/}PdfFiles    archive_name=${CURDIR}${/}output${/}PdfArchive.zip
    

Collect Search Query From User
    Add text input    search    label=Enter the URL of the orders CSV file.
    ${response}=    Run dialog
    [Return]    ${response.search}

*** Keywords ***
Logout and Close the Browser
    Click Button    id=logout
    Close Browser

    
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${strUrl}=    Collect Search Query From User
    Open the website
    Log In
    Download Csv File    ${strUrl}
    Navigate to tab
    Click Alert Button
    Read Csv Data and enter in website
    Create ZIP file of the receipts
    [Teardown]         Logout and Close the Browser