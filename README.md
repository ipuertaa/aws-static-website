# Serverless website (AWS Cloud)

This project is the prototype of a robotics academy website. In this case, the main goal of the project is to deploy the cloud underlying infrastructure for the website using terraform as Infrastructure as Code tool.


## Architecture

<img width="800" alt="image" src="https://github.com/user-attachments/assets/3ac9d7a1-8561-4e9f-85b5-ab0fb1740e81" />


**Frontend (Amazon S3 + CloudFront):** A user accesses the website through CloudFront, which retrieves the static content from S3.

**Form Submission (API Gateway):** The user fills out and submits the registration form, which sends a POST request to the API Gateway endpoint.

**Data Processing (AWS Lambda):** API Gateway invokes the Lambda function, passing the form data as JSON for processing.

**Data Storage (Amazon DynamoDB):** The Lambda function writes the processed data to DynamoDB, completing the registration flow.

### Sercices overview
- Amazon S3:
  - Is used to store the static files for the front end of the application, including the HTML, CSS, and JavaScript files
  - The S3 bucket is configured as a static website. The bucket policy allows CloudFront to serve the content securely over HTTPS
  - To ensure security, an Origin Access Control (OAC) is used to limit direct access to the S3 bucket and enforce that files can only be retrieved via CloudFront

- CloudFront:
  -  Deliver the static content stored in the S3 bucket.
  -  A CloudFront distribution is created with the S3 bucket as the origin. The distribution retrieves content from the S3 bucket and serves it via a secure HTTPS endpoint (custom CloudFront domain name)
 
- Amazon API Gateway:
  - API Gateway serves as the entry point for handling form submissions from the frontend
  - A REST API is configured with a single POST endpoint at /registration. This endpoint receives data from the registration form in JSON format
  - To allow cross-origin requests from the CloudFront domain, CORS headers are enabled on the API.
  - The API is integrated with a Lambda function, enabling it to trigger backend logic without the need for traditional server infrastructure
 
- AWS Lambda:
  - The Lambda function processes incoming form data and stores it in DynamoDB
  - The Lambda function is written in Python and deployed with IAM permissions to allow access to the DynamoDB table.
  - It extracts the form data, generates a unique user ID, and writes the data to DynamoDB

- Amazon DynamoDB:
  - DynamoDB is used as the database to store registration details

## Technologies used:
- Terraform
- Python
- HTML
- CSS
- JavaScript

## What I learned
- Serverlessarchitecture design
- Handling user data (registration form)
- API concepts and configuration
- CORS concepts and configuration
- Terraform capabilities as Infrastructure as Code tool

## Future improvments:
- Security:
  - Configure AWS Secrets Manager to store the API endpoint
- User experience:
  - Configure a custom domain name
  - Improve the design
  - Set up notifications to alert if the registration succeed or not
- Automate some processes if possible    
