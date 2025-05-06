import pandas as pd
import smtplib
from email.message import EmailMessage
from ExcelOperations import delete_excel_sheet
import ssl

def SendEmail(Subject, EmailBody, RecipientTo, RecipientCc, Attachment, SheetName, SenderEmail, EmailPassword):  
  try:
    #Convert recipients into list
    ToEmails = RecipientTo.split(";")
    CcEmails = RecipientCc.split(";") if RecipientCc else []

    # Read Excel file and convert to HTML table
    DataFrame = pd.read_excel(Attachment, sheet_name=SheetName)
    HtmlTable = DataFrame.to_html(index=False, border=1, justify="center", classes="StatusTable")

    # HTML email styling
    StyledHtml = f"""
    <html>
    <head>
      <style>
        .StatusTable {{
          border-collapse: collapse;
          width: 100%;
          font-family: Arial, sans-serif;
          font-size: 13px;
        }}
        .StatusTable th, .StatusTable td {{
          border: 1px solid #ddd;
          padding: 8px;
          text-align: center;
        }}
        .StatusTable th {{
          background-color: #f2f2f2;
          font-weight: bold;
        }}
      </style>
    </head>
    <body>
      <p>Hi Team,<br></p>
      <p>{EmailBody}<br></p>
      {HtmlTable}
      <p><br><br>Thanks & Regards,<br>RPA Bot</p>
    </body>
    </html>
    """

    # Build EmailMessage
    Message = EmailMessage()
    Message["From"] = SenderEmail
    Message["To"] = ", ".join(ToEmails)
    if CcEmails:
      Message["Cc"] = ", ".join(CcEmails)
    Message["Subject"] = Subject
    Message.set_content("This is an HTML email. Please view it in a compatible email client.")
    Message.add_alternative(StyledHtml, subtype='html')

    #Deleting Report Sheet
    # delete_excel_sheet(Attachment, SheetName)

    # Attach the Excel file
    with open(Attachment, "rb") as File:
      FileData = File.read()
      FileName = "EndJobReport.xlsx"
    Message.add_attachment(
      FileData,
      maintype="application",
      subtype="vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      filename=FileName
    )

    # Send email
    AllRecipients = ToEmails + CcEmails
    SslContext = ssl.create_default_context()
    with smtplib.SMTP_SSL("smtp.gmail.com", 465, context=SslContext) as SmtpServer:
      SmtpServer.login(SenderEmail, EmailPassword)
      SmtpServer.send_message(Message, to_addrs=AllRecipients)

    return True
  except Exception as e:
    return False
