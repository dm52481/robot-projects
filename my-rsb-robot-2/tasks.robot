*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.RobotLogListener
Library             RPA.Archive
Library             OperatingSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the Excel file
    Get orders
    Create a ZIP file of receipt PDF files
    [Teardown]    Clean up and close browser


*** Keywords ***
Open the robot order website
    Open Available Browser    url=https://robotsparebinindustries.com/#/robot-order

Get orders
    ${orders}=    Read table from CSV    path=orders.csv    header=True
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot image    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Click Button    order-another
    END

Download the Excel file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Index    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id=address    ${row}[Address]
    Submit the order

Submit the order
    FOR    ${index}    IN RANGE    10
        Click Element When Clickable    order
        ${element_visible}=    Run Keyword And Return Status
        ...    Wait Until Element is Visible
        ...    id:receipt
        ...    timeout=.5s
        IF    ${element_visible}    BREAK
    END

Store the receipt as a PDF file
    [Arguments]    ${Order number}
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${output_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}Order_${Order number}_receipt.pdf
    Html To Pdf    ${receipt_html}    ${output_path}
    RETURN    ${output_path}

Take a screenshot of the robot image
    [Arguments]    ${Order number}
    ${output_path}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}Order_${Order number}_preview.png
    Screenshot    robot-preview-image    ${output_path}
    RETURN    ${output_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=True
    Close Pdf    ${pdf}

Create a ZIP file of receipt PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts${/}    ${OUTPUT_DIR}${/}receipt_pdfs.zip    include=*.pdf

Clean up and close browser
    Remove Directory    ${OUTPUT_DIR}${/}receipts    recursive=True
    Close Browser
