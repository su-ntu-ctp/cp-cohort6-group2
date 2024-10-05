import json
import boto3
import os

# Initialize the DynamoDB client
dynamodb = boto3.client('dynamodb')

# Get the DynamoDB table name from environment variables
table_name = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    # Example: Get order details from the event and store it in DynamoDB
    order_id = event['order_id']
    fruit = event['fruit']
    quantity = event['quantity']
    
    # Define the item to be stored in DynamoDB
    item = {
        'order_id': {'S': order_id},
        'fruit': {'S': fruit},
        'quantity': {'N': str(quantity)}
    }

    # Put the item in the DynamoDB table
    dynamodb.put_item(TableName=table_name, Item=item)

    return {
        'statusCode': 200,
        'body': json.dumps(f"Order {order_id} processed successfully!")
    }
