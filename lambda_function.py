import json
import boto3
import os

# Initialize the DynamoDB client
dynamodb = boto3.client('dynamodb')

# Get the DynamoDB table name from environment variables
table_name = os.environ['DYNAMODB_TABLE']

def lambda_handler(event, context):
    try:
        # Get JSON payload from the event
        json_payload = event.get('body')
        if json_payload is None:
            return {
                'statusCode': 400,
                'body': json.dumps("No payload provided.")
            }
        
        payload = json.loads(json_payload)
        
        # Validate required fields
        required_fields = ['order_id', 'fruit', 'quantity']
        for field in required_fields:
            if field not in payload:
                return {
                    'statusCode': 400,
                    'body': json.dumps(f"Missing required field: {field}")
                }
        
        # Extract order details
        order_id = payload.get('order_id')
        fruit = payload.get('fruit')
        quantity = payload.get('quantity')
        
        # Ensure order_id is not None
        if order_id is None:
            return {
                'statusCode': 400,
                'body': json.dumps("Missing required field: order_id")
            }

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
            'body': json.dumps(f"Order {order_id} processed successfully!"),
            'headers': {
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': '*'
            }  
        }

    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'body': json.dumps("Invalid JSON payload.")
        }
    except Exception as e:
        print(f"Error occurred: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps("An internal error occurred.")
        }


# curl -X POST https://2ji0y7x3j7.execute-api.us-east-1.amazonaws.com/prod/orders \
#      -H "Content-Type: application/json" \
#      -d '{"order_id": "123", "fruit": "apple", "quantity": 11}'