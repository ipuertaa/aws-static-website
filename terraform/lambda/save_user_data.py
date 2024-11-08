import json
import boto3
from uuid import uuid4

# DynamoDB object
dynamodb = boto3.resource('dynamodb')
# Use the dynamodb object to select the table
table = dynamodb.Table('usersDB')


def lambda_handler(event, context):
    
    # Create a unique ID for the user
    user_id = str(uuid4())

    # Extract values from the request
    student_name = event['student_name']
    parent_name = event['parent_name']
    email = event['email']
    course_name = event['course_name'] 
    additional_info = event.get('additional_info', 'N/A')
    
    # Store data in DynamoDB
    table.put_item(
        Item={
            'user_id': user_id,
            'student_name': student_name,
            'parent_name': parent_name,
            'email': email,
            'course_name': course_name,
            'additional_info': additional_info
        }
    )

    # Return a success message
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': "OPTIONS,GET",
        },
        'body': json.dumps({
            'message': 'Data saved successfully',
            'student_name': student_name
    })
    }
