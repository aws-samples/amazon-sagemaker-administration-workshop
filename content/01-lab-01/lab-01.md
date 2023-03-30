# Lab 1: Amazon SageMaker domain setup, user management, and network security
This lab shows how to create a secure environment for your data science workloads, starting with the network. You learn concepts of SageMaker domain, domain network modes, and network traffic controls.

## Content
In this lab you're going to do:
- Setup Amazon VPC and a network perimeter
- Create AWS KMS encryption keys for data
- Create SageMaker IAM execution roles for Studio users
- Onboard to Amazon SageMaker domain
- Create and configure user profiles
- Experiment with IAM and IAM Identity Center authentication modes
- Experiment with network controls

## Step 1: setup Amazon VPC

![](../../static/design/network-architecture.drawio.svg)

### Amazon VPC
A Virtual Private Cloud (VPC) gives you a self-contained network environment that you control. When initially created the VPC does not allow network traffic into or out of the VPC. It’s only by adding VPC endpoints, Internet Gateways (IGW), or Virtual Private Gateways (VPGW) that you begin to configure your private network environment to communicate with the wider world. For the rest of these labs you can assume that no access to the internet is required and that all communication with AWS services will be done explicitly through private connectivity to the AWS APIs through VPC endpoints. It is also recommend to create multiple subnets in your VPC in multiple availability zones to support highly available deployments and resilient architectures.

To find out more about VPCs and VPC concepts such as routing tables, subnets, security groups, and network access control lists please visit the AWS documentation.

### VPC endpoints
A VPC endpoint allows you to establish a private, secure connection between your VPC and an AWS service without requiring you to configure an Internet Gateway, NAT device, or VPN connection. Using VPC endpoints your VPC resources can communicate with AWS services without ever leaving the AWS network. A VPC endpoint is a highly available virtual device that is managed on your behalf. As a VPC resource an endpoint is given IP addresses within your VPC and security groups assigned to the endpoint can control who can communicate with the endpoint.

In addition to security groups you can also apply VPC endpoint policies to an AWS service endpoint. An endpoint policy is an IAM resource policy that gets applied to a VPC endpoint and governs which APIs can be called on an AWS service through the endpoint. For example, if the following endpoint policy were applied to an Amazon S3 VPC endpoint it would only allow read access to objects in the specified S3 bucket. Actions against other buckets would be denied.

VPC endpoint policies, along with security groups, provide the ability to implement Defense-in-Depth and bring a multi-layered approach to security and who can access what resources within your VPC.

## Step 2: create AWS KMS keys

## Step 3: create SageMaker IAM execution roles

## Step 4: onboard to SageMaker domain

## Step 5: create user profiles

## Step 6: sign in to Studio

- via AWS console
- via a presigned URL
- via IAM Identity Center

## Step 7: control user access with IAM identity-based policies
User access control
User profiles with different execution roles
Prevent users from using AWS Console to start Studio


## Step 8: control network traffic for Studio notebooks
- internet-free environment
- add a NAT gateway
- add a VPC flow logs
- using VPC endpoints and endpoints policies
- specify VPCConfig for SageMaker jobs



## Additional resources
- [Amazon SageMaker - Onboard to Domain developer guide](https://docs.aws.amazon.com/sagemaker/latest/dg/gs-studio-onboard.html)
- [SageMaker Studio Administration Best Practices - Network management](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html)
- [Secure Training and Inference with VPC](https://sagemaker.readthedocs.io/en/v2.101.0/overview.html#secure-training-and-inference-with-vpc)
- [Access an Amazon SageMaker Studio notebook from a corporate network](https://aws.amazon.com/blogs/machine-learning/access-an-amazon-sagemaker-studio-notebook-from-a-corporate-network/)
- [Secure Amazon SageMaker Studio presigned URLs (blog series)](https://aws.amazon.com/blogs/machine-learning/secure-amazon-sagemaker-studio-presigned-urls-part-1-foundational-infrastructure/)
- [Secure multi-account model deployment with Amazon SageMaker (blog series)](https://aws.amazon.com/blogs/machine-learning/part-1-secure-multi-account-model-deployment-with-amazon-sagemaker/)
- [Team and user management with Amazon SageMaker and AWS SSO](https://aws.amazon.com/blogs/machine-learning/team-and-user-management-with-amazon-sagemaker-and-aws-sso/)

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0