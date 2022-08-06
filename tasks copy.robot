*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser
Library             OperatingSystem
Library             RPA.Robocorp.Vault
Library             RPA.FTP
Library             RPA.Tables
Library             RPA.RobotLogListener
Library             RPA.PDF
Library             RPA.JavaAccessBridge
Library             RPA.Email.ImapSmtp
Library             RPA.Archive
Library             RPA.Dialogs


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order
${Output_folder}    ${CURDIR}{/}output
${image_folder}     ${CURDIR}{/}image_files
${pdf_folder}       ${CURDIR}{/}pdf_files
${csv_url}          https://robotsparebinindustries.com/orders.csv
${orders_file}      ${CURDIR}{/}orders.csv
${zip_file}         ${output_folder}${/}pdf_archive.zip


*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    Directory Cleanup
    Get The Program Author Name From Our Vault
    ${username}=    Get The User Name
    ${orders}=    Get Orders
    Open the robot order Website
    FOR    ${current_row}    IN    @{orders}
        Accept and close the popup
        Fill the from    ${current_row}
        Wait Until Keyword Succeeds    10x    2sec    Preview the robot
        Wait Until Keyword Succeeds    10x    2sec    Submit the order
        ${orderid}    ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    ${img_filename}    ${pdf_filename}
        Go to order another robot
    END

    Log Out And Close The Browser
    Create a ZIP file of the receipts
    Display the success dialog    USER_NAME=${username}


*** Keywords ***
Open the robot order Website
    Open Available Browser    ${url}

Directory Cleanup
    Log To Console    Cleaning up content from previous test runs
    Create Dictionary    ${Output_folder}
    Create Dictionary    ${pdf_folder}
    Create Dictionary    ${image_folder}

    Empty Directory    ${Output_folder}
    Empty Directory    ${pdf_folder}
    Empty Directory    ${image_folder}

Get The Program Author Name From Our Vault
    Log To Console    Getting Secret from our Vault
    ${secret}=    Get Secret    mysecrets
    Log    ${secret}[whowrotethis] is the author of this file    console=Yes

Get Orders
    Download    ${csv_url}    overwrite=True
    ${table}=    Read table from CSV    ${orders_file}    header=True
    RETURN    ${table}

Accept and close the popup
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button    ${btn_yep}

Fill the from
    [Arguments]    ${current_row}
    Set Local Variable    ${order_no}    ${current_row}[Order number]
    Set Local Variable    ${head}    ${current_row}[Head]
    Set Local Variable    ${body}    ${current_row}[Body]
    Set Local Variable    ${legs}    ${current_row}[Legs]
    Set Local Variable    ${address}    ${current_row}[Address]

    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]

    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${order_no}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio button    ${input_body}    ${body}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}

    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]

    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    Mute Run On Failure    Page Should Contain Element

    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take a screenshot of the robot
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}

    ${orderid}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${fully_qualified_img_filename}    ${image_folder}${/}${orderid}.png
    Sleep    1sec
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}
    RETURN    ${orderid}    ${fully_qualified_img_filename}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf
    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    RETURN    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Log To Console    Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}
    Open Pdf    ${PDF_FILE}
    @{myfiles}=    Create List    ${IMG_FILE}:x-0,y=0
    Add Files To Pdf    ${myfiles}    ${PDF_FILE}    ${True}
    Close PDF    ${PDF_FILE}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Log Out And Close The Browser
    Close Browser

 Create a ZIP file of the receipts
    Archive Folder With Zip    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Get The User Name
    Add heading    I am your RoboCorp Order Genie
    Add text input    myname    label=What is thy name, oh sire?    placeholder=Give me some input here
    ${result}=    Run dialog
    RETURN    ${result.myname}

Display the success dialog
    [Arguments]    ${USER_NAME}
    Add icon    Success
    Add heading    Your orders have been processed
    Add text    Dear ${USER_NAME} - all orders have been processed. Have a nice day!
    Run dialog    title=Success
