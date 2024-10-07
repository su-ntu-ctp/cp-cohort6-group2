import json
import boto3
import os

# Initialize the DynamoDB client
dynamodb = boto3.client('dynamodb')

# Get the DynamoDB table name from environment variables
table_name = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    # Get the body from the event object
    json_payload = event.get('body', '{}')  # Ensure default to '{}' if the body is missing or empty
    print("Raw payload:", json_payload)

    # Load the body into a dictionary
    try:
        payload = json.loads(json_payload)  # Convert the JSON string into a dictionary
    except json.JSONDecodeError as e:
        return {
            'statusCode': 400,
            'body': json.dumps(f"Invalid JSON: {str(e)}")
        }

    print("Parsed payload:", payload)

    # Extract order details from the payload
    order_id = payload.get('order_id')
    fruit = payload.get('fruit')
    quantity = payload.get('quantity')
    
    # Check for missing fields and return a 400 error if any are missing
    if not order_id or not fruit or not quantity:
        return {
            'statusCode': 400,
            'body': json.dumps("Missing order_id, fruit, or quantity")
        }

    print(f"Order ID: {order_id}, Fruit: {fruit}, Quantity: {quantity}")
    
    # Define the item to be stored in DynamoDB
    item = {
        'order_id': {'S': order_id},
        'fruit': {'S': fruit},
        'quantity': {'N': str(quantity)}
    }

    # Put the item in the DynamoDB table
    try:
        dynamodb.put_item(TableName=table_name, Item=item)
        print(f"Order {order_id} stored successfully in DynamoDB")
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f"Failed to store order in DynamoDB: {str(e)}")
        }

    # Return success response
    return {
        'statusCode': 200,
        'body': json.dumps(f"Order {order_id} processed successfully!")
    }


