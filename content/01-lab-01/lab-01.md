# Lab 1: Amazon SageMaker domain setup, network security, IAM, and user management
This lab shows how to create a secure environment for your data science workloads, starting with the network. You learn concepts of SageMaker domain, domain network modes, and network traffic controls.

## Content
In this lab you're going to do:
- Create SageMaker IAM execution roles for Studio users
- Setup Amazon VPC and a network perimeter
- Create AWS KMS encryption keys for data
- Onboard to Amazon SageMaker domain
- Create and configure user profiles
- Experiment with IAM and IAM Identity Center authentication modes
- Experiment with network controls

## Overview of SageMaker domain, user profiles, and user profile execution roles

### Domain
An [SageMaker domain](https://docs.aws.amazon.com/sagemaker/latest/dg/sm-domain.html) consists of an associated Amazon Elastic File System (Amazon EFS) volume; a list of authorized users; and a variety of security, application, policy, and Amazon Virtual Private Cloud (Amazon VPC) configurations.

### User profile
A [user profile](https://docs.aws.amazon.com/sagemaker/latest/dg/domain-user-profile.html) represents a single user within a Domain. It is the main way to reference a user for the purposes of sharing, reporting, and other user-oriented features. This entity is created when a user onboards to the Amazon SageMaker Domain.

The user profile's Studio application is directly associated with the user profile and has an isolated Amazon EFS directory, an execution role associated with the user profile, and Kernel Gateway applications.

### User profile execution role
Each user profile has a designated IAM execution role which is part of the user profile settings. This role must have, at a minimum, an attached trust policy that grants SageMaker permission to assume the role. 

User perform all activities in Studio and Studio notebooks under this execution role. This role's permissions control what a specific user profile can do in Studio and what resources can be accessed and operated from the Studio notebooks.

Refer to [SageMaker roles](https://docs.aws.amazon.com/sagemaker/latest/dg/sagemaker-roles.html) in the Developer Guide for more details on the execution roles.

### Execution role setup
The following diagram shows the recommended setup of execution roles:

![](../../static/design/identity-and-access-management.drawio.svg)

1. All users are authenticated and authorized by IAM and sign in the AWS console of the AWS account. Alternatively, users can be authenticated and authorized in your organization IdP and federated into AWS account using [AWS IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html).
2. The user IAM role controls what the user can do in AWS console and the AWS account.
3. IAM role permission policies define access to operations, resources, and data.
4. SageMaker domain contains a designated user profile the user can sign in to.
5. Each profile has a dedicated execution role which defines what the user can do in Studio and Studio notebooks.
6. The recommended practice is to to create a dedicated IAM role for the execution of SageMaker jobs, SageMaker Pipelines, model deployment, hosting, and monitoring. Each IAM role must follow the least privilege principle. You must scope each execution role based on the actions it must perform and the data and resources it must access.
7. If you use [AWS Organizations](https://aws.amazon.com/organizations/), you can implement [Service Control Policies](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps.html) (SCPs) to centrally control the maximum available permissions for all accounts and all IAM roles in your organization. The SCP is an effective way to limit permissions given by IAM permission policies attached to the IAM roles.


## Step 1: create SageMaker IAM execution roles
You have the following options to provision required SageMaker IAM execution roles:
- Use operational process for IAM role management
- Use IaC such as CloudFormation templates
- Use SageMaker [role manager](https://docs.aws.amazon.com/sagemaker/latest/dg/role-manager.html) interactively in the AWS Console. In SageMaker role manager you can provision roles based on pre-defined [persona references](https://docs.aws.amazon.com/sagemaker/latest/dg/role-manager-personas.html).

This workshop uses a provided CloudFormation [template](../../cfn-templates/iam-roles.yaml) to provision the following IAM roles:
- `StudioRoleDefault`: minimal privilege role which is set as default for SageMaker domain
- `StudioRoleDataScience`: user profile execution role scoped for Data Scientist persona
- `StudioRoleMLOps`: user profile execution role scoped for MLOps engineer persona
- `VPCFlowLogsRole`: VPC Flow Logs role for publishing logs to CloudWatch

Take some time to examine the attached permission policies for each role. Consider the following:
- None of the roles has [`AmazonSageMakerFullAccess`](https://docs.aws.amazon.com/sagemaker/latest/dg/security-iam-awsmanpol.html) policy attached and each has only a limited set of permissions. In your real-world SageMaker environment you need to scope the role's permissions based on your requirements for operations and data access.
- `StudioRoleDefault` has only a custom policy `SageMakerReadOnlyPolicy` attached with a restrictive list of allowed actions. 
-  Both user profile execution roles, `StudioRoleDataScience` and `StudioRoleMLOps`, additionally have custom polices `SageMakerStudioDataScienceAccessPolicy` and `SageMakerStudioMLOpsAccessPolicy` allowing usage of particular services on per-need-to-use-for-the-persona-role basis.
- Each user profile execution role has a deny-only policy `SageMakerDeniedServicesPolicy` with explicit deny on some potentially destructive SageMaker API calls, such as `DeleteDomain` and `DeleteUserProfile`. The policy also denies using SageMaker Notebook Instances.
- No role as any access to S3 data. You'll add the permissions for S3 in the [data security lab](../02-lab-02/lab-02.md).

In this lab the workshop don't use designated execution roles for SageMaker workloads such as jobs, Pipelines, Model Monitoring and hosting. You'll create and use these execution roles in other labs.

### Deploy the CloudFormation template
Use the provided IAM template:
```sh
aws cloudformation deploy \
    --template-file cfn-templates/iam-roles.yaml \
    --stack-name sagemaker-admin-workshop-iam \
    --capabilities CAPABILITY_NAMED_IAM 
```

```sh
aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"
```

## Step 2: setup Amazon VPC
Before you start with with SageMaker domain creation, you need to setup a network environment. 

### Recommended network setup and practices
While the [Zero Trust](https://aws.amazon.com/security/zero-trust/) conceptual model decreases reliance on network location, the role of network controls and perimeters remains important to the overall security architecture. 

Use [Amazon Virtual Private Cloud](http://aws.amazon.com/vpc/?vpc-blogs.sort-by=item.additionalFields.createdDate&vpc-blogs.sort-order=desc) (Amazon VPC) to enable network isolation and control connectivity to only the services and users you need.

Use [AWS PrivateLink](https://docs.aws.amazon.com/whitepapers/latest/aws-vpc-connectivity-options/aws-privatelink.html) and [VPC endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html) to connect your private services inside the VPC to public AWS services without need to traverse public network and to use an internet gateway in your VPC. 

Use [Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html) to control the inbound and outbound traffic for the resources the security group associated with, such as VPC endpoints or [elastic network interface](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html) (ENI). For monitoring all network traffic on ENIs you can use [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html).

The following diagram shows a minimal network configuration for the data science account with the single Availability Zone (AZ) and without internet connectivity for the private subnet:

![](../../static/design/network-architecture.drawio.svg)

Each SageMaker domain has own VPC configuration, so you can configure a domain to use a shared or a dedicated VPC. Each domain uses its own EFS file system, data from different domains never shares the same EFS volume.

You need to [plan VPC and subnet IP capacity](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html) to ensure that you you have enough IPs to support the usage volume and expected growth.

SageMaker Studio injects one ENI into your VPC for each unique EC2 instance used to run KernelGateway apps and Studio notebooks. When you launch SageMaker training or processing jobs with a VPC configuration, each job injects two ENIs per subnet per compute instance (one ENI for the data agent and one for the algorithm per instance).

Each used VPC endpoint injects an ENI per AZ configured. For example, if you use 10 VPC endpoint to communicate with AWS services and setup your SageMaker domain in three Availability Zones, 30 ENIs are injected into your VPC.

For VPC network planning and configuration, refer to the [Network management](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html) in the SageMaker Studio Administration Best Practices.

You can implement multi-layer network traffic control and sophisticated firewall rules by using [AWS Network Firewall](https://aws.amazon.com/network-firewall/). Refer to [Securing Amazon SageMaker Studio internet traffic using AWS Network Firewall](https://aws.amazon.com/blogs/machine-learning/securing-amazon-sagemaker-studio-internet-traffic-using-aws-network-firewall/) blog post for examples.

### Amazon VPC
An Amazon VPC is a logically isolated virtual network environment that you control. When you create an VPC, it doesn't allow ingress or egress network traffic. By adding VPC endpoints, [internet gateways](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) (IGW), [NAT gateways](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) (NATGW) or AWS Transit Gateway you begin to configure your private network environment to communicate with other network resources. In this workshop communication between your SageMaker domain and any AWS service are done explicitly through private connectivity to the AWS services via VPC endpoints. 

In your production environment we recommend to create multiple subnets in multiple Availability Zones to support high availability and resilience of your ML workloads.

### VPC endpoints
A VPC endpoint allows you to establish a private, secure connection between your VPC and AWS services or services in other VPCs using private IP addresses, as if those services were hosted directly in your VPC.
A VPC endpoint is a managed highly available virtual device. VPC endpoint has an IP address within your VPC. You can control traffic to and from the VPC endpoint by security groups and [endpoint policies](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-access.html).

Security groups and VPC endpoint policies are foundational controls to implement defense-in-depth and bring a multi-layered approach to network security of your environment.

### Provision a VPC
Use the provided CloudFormation [template](../../cfn-templates/network-vpc.yaml) to provision a new VPC or use an existing VPC in your AWS account.

## Step 3: create AWS KMS keys

## Step 4: onboard to SageMaker domain
When onboarding, you can choose to use either AWS IAM Identity Center (successor to AWS Single Sign-On) (IAM Identity Center) or AWS Identity and Access Management (IAM) for authentication methods. 

https://docs.aws.amazon.com/sagemaker/latest/dg/gs-studio-onboard.html


## Step 5: create user profiles

## Step 6: sign in to Studio

- via AWS console
- via a presigned URL
- via IAM Identity Center

Each user signs in to their Studio environment via a presigned URL from an AWS IAM Identity center portal without the need to go to the console in their AWS account. You custom profile management backend uses an API call [`CreatePresignedDomainUrl`](https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_CreatePresignedDomainUrl.html) to generate a _presigned URL_ for the user.

Studio supports several access control enforcements you can use to limit access to Studio for:

- clients residing only in a designated VPC
- sign-in requests originated only from a designated IP address or CIDR
- sign-in requests originated only via a designated VPC endpoint

To implement Studio notebooks access restrictions, you must use [IAM policy conditions](https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#api-access-policy) in the requesting user IAM role. For more details refer to [restrict access to the Studio IDE](https://aws.amazon.com/about-aws/whats-new/2020/12/secure-sagemaker-studio-access-using-aws-privatelink-aws-iam-sourceip-restrictions/) documentation in the Developer Guide and to [Securing access to the pre-signed URL](http://aws.amazon.com/blogs/machine-learning/secure-amazon-sagemaker-studio-presigned-urls-part-1-foundational-infrastructure/) blog post for a hands-on example of a custom API to generate a presigned URL for Studio access.



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
The following resources provide additional details and reference for SageMaker network security, IAM roles, and user management.

- [Infrastructure Security in Amazon SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-security.html)
- [Amazon SageMaker - Onboard to Domain developer guide](https://docs.aws.amazon.com/sagemaker/latest/dg/gs-studio-onboard.html)
- [SageMaker Studio Administration Best Practices - Network management](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html)
- [New ML Governance Tools for Amazon SageMaker – Simplify Access Control and Enhance Transparency Over Your ML Projects](https://aws.amazon.com/blogs/aws/new-ml-governance-tools-for-amazon-sagemaker-simplify-access-control-and-enhance-transparency-over-your-ml-projects/)
- [Secure Training and Inference with VPC](https://sagemaker.readthedocs.io/en/v2.101.0/overview.html#secure-training-and-inference-with-vpc)
- [Access an Amazon SageMaker Studio notebook from a corporate network](https://aws.amazon.com/blogs/machine-learning/access-an-amazon-sagemaker-studio-notebook-from-a-corporate-network/)
- [Secure Amazon SageMaker Studio presigned URLs (blog series)](https://aws.amazon.com/blogs/machine-learning/secure-amazon-sagemaker-studio-presigned-urls-part-1-foundational-infrastructure/)
- [Secure multi-account model deployment with Amazon SageMaker (blog series)](https://aws.amazon.com/blogs/machine-learning/part-1-secure-multi-account-model-deployment-with-amazon-sagemaker/)
- [Team and user management with Amazon SageMaker and AWS SSO](https://aws.amazon.com/blogs/machine-learning/team-and-user-management-with-amazon-sagemaker-and-aws-sso/)

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0