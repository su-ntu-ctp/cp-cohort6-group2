# CapstoneProject-DevOps-CICDpipeline Group 2

# E-commerce Company— BerryFresh

BerryFresh is Your Online Destination for Premium Strawberries From Dandong. With the 
inherent advantages of being located in an internationally recognized high-quality fruit zone at a 40° north latitude, Dandong 99 strawberries are perfect in color, flavor, and taste, and are loved by consumers locally and abroad. Now we are bringing this to Singapore. 

Sourced from local farmers in Dandong, our strawberries are celebrated for their exceptional sweetness and juicy texture. Grown in the region’s ideal climate and fertile soil, these strawberries are harvested at peak ripeness, ensuring you enjoy the freshest and tastiest fruit.

**BerryFresh**, your go-to e-commerce platform dedicated to bringing the finest strawberries from Dandong, China, straight to your door. Our mission is to provide you with fresh, high-quality strawberries that capture the essence of their rich, flavourful heritage.

## Cloud Architecture:
<img width="359" alt="Cloud Architecture 2" src="https://github.com/user-attachments/assets/85ced634-dfc5-4561-baa5-0ca5310beff5">

# DevOps Strategy for BerryFresh

## Objective
To create a high-performance, scalable, and reliable e-commerce platform that delivers an exceptional user experience through efficient content delivery and rapid feature deployment.

## 1. Architecture Design

### Static Content Layer
- **Amazon S3:**
  - Store all static assets such as product images, stylesheets, JavaScript files, and fonts in S3 buckets.
  - Enable versioning and lifecycle policies to manage content effectively and reduce costs.
  - Use S3 bucket policies to control access and ensure security.

- **Amazon CloudFront:**
  - Distribute static assets globally via CloudFront, reducing latency for users regardless of their location.
  - Configure caching policies to optimize content delivery, setting TTL values based on the frequency of updates.
  - Utilize SSL to secure the delivery of content and ensure customer trust.

### Dynamic Content Layer
- **AWS Lambda:**
  - Implement serverless functions to handle dynamic operations such as user authentication, shopping cart management, order processing, and payment integration.
  - Design functions to scale automatically based on incoming traffic, enabling efficient resource use.

- **Amazon DynamoDB:**
  - Use DynamoDB as the primary database for dynamic content such as product listings, user profiles, and order histories.
  - Leverage features like auto-scaling, global tables (if needed for multi-region availability), and DynamoDB Streams for real-time data processing.

## 2. Deployment Strategy
<img width="539" alt="Deployment Strategy" src="https://github.com/user-attachments/assets/b5cb4d68-fe08-4d54-aade-c8fbc8ebcbe0">

### Infrastructure as Code (IaC)
- Utilize Terraform to define the infrastructure components needed for BerryFresh, including S3 buckets, CloudFront distributions, Lambda functions, and DynamoDB tables.
- Maintain version-controlled templates to facilitate consistent and repeatable deployments.

### CI/CD Pipeline
- Implement a CI/CD pipeline using GitHub Actions to automate the build, test, and deployment processes.

## 3. Monitoring and Logging
- **AWS CloudWatch:**
  - Monitor key metrics such as Lambda invocation counts, DynamoDB read/write capacities, and CloudFront cache hit ratios.
  - Set up alarms to notify the team of any anomalies, such as increased error rates or latency issues.

## 4. Security and Compliance
- **IAM Roles and Policies:**
  - Define specific IAM roles and policies to grant least privilege access to services and resources, ensuring that only authorized components can access sensitive data.

## 5. Branching Strategy
- **main Branch:**
  - Represents the production-ready state of the application. Only thoroughly tested code is merged here for deployment to the live environment.

- **feature Branch:**
  - Serves as the integration branch for ongoing development. New features and bug fixes are merged here for testing before promotion to the main branch.

## Summary
This DevOps strategy for BerryFresh leverages AWS services to build a resilient, scalable, and efficient e-commerce platform. By effectively integrating static and dynamic content layers, and employing best practices in monitoring, security, and CI/CD, BerryFresh can deliver a seamless shopping experience to its customers while maintaining rapid deployment cycles. This approach not only enhances performance but also fosters a culture of continuous improvement and innovation.


