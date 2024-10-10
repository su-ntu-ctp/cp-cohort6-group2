import boto3
import os

ses = boto3.client('ses')

def lambda_handler(event, context):
    sender = os.environ['EMAIL_SENDER']
    recipient = os.environ['EMAIL_RECIPIENT']
    subject = "New Fruit Order"
    body_text = "You have a new fruit order!"
    
    response = ses.send_email(
        Source=sender,
        Destination={'ToAddresses': [recipient]},
        Message={
            'Subject': {'Data': subject},
            'Body': {
                'Text': {'Data': body_text}
            }
        }
    )
    return response
