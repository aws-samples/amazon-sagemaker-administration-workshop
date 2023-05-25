# Onboard to domain using IAM Identity Center
In this section you create a domain using IAM authentication method. This is an optional step and is needed if you would like to experiment with domain user onboarding via the IAM Identity Center.

---

## Prerequisites
❗ If you don't have IAM Identity Center set up, follow the [steps to enable IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/get-started-enable-identity-center.html) before starting with creation of the domain. 
You must have permissions to add users and user groups to IAM Identity Center to complete these instructions.
You also must complete deployment of the IAM, VPC, and KMS CloudFormation stacks as described in the [lab 1](./lab-01.md). Make sure you run the `describe-stacks` commands to output the values you need for domain creation:
```sh
aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"
aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"
aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-kms  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"
```

## Create domain
To create the domain, follow the instructions in [Onboard to Amazon SageMaker Domain Using IAM Identity Center](https://docs.aws.amazon.com/sagemaker/latest/dg/onboard-sso-users.html) in the Developer Guide and provide the configuration values as described in the following sections.

### General settings
- **Domain name**: choose a unique name for your domain, for example, `sagemaker-admin-workshop-domain-sso`
- **Authentication**: change to _AWS Identity and Access Management_
- **Permission**
    - _Default execution role_: choose the value of `StudioRoleDefaultArn` output from the IAM stack
    - Leave _Space default execution role_ blank

    ![](../../static/img/create-domain-general-settings-sso.png)

- **Network and Storage Section**:
    - _VPC_: Choose the `vpc-sagemaker-admin-workshop` VPC you provisioned in the previous step
    - _Subnet_: Choose both private subnets
    - _Security group(s)_: Choose the `sg-sm-sagemaker-admin-workshop` security group
    - Choose _VPC Only_ option
    - _Encryption key_: Choose the AWS KMS key `sagemaker-admin-workshop-<REGION>-<ACCOUNT-ID>-kms-efs` you provisioned in the previous step

    ![](../../static/img/create-domain-network-and-storage-sso.png)

### Studio settings
- **Jupyter Lab version**
    - Leave `Jupyter Lab 3.0` version
- **Notebook Sharing Configuration**
    - _Encryption key_: Choose the AWS KMS key `sagemaker-admin-workshop-<REGION>-<ACCOUNT-ID>-kms-s3` you provisioned in the previous step
    - Choose _Disable cell output sharing_
- **SageMaker Project and JumpStart**
    - Leave all options enabled

#### Amazon SageMaker Canvas settings
Disable all configurations. If you keep Canvas configuration enabled, SageMaker adds `AmazonSageMakerCanvasFullAccess` and `AmazonSageMakerCanvasAIServiceAccess` managed policies to the default SageMaker execution role. At this point we don't want to attach any other policies to this role.

### Finish domain provisioning
Choose **Submit** and wait until the domain goes into `InService` status:

![](../../static/img/domain-inservice-sso.png)

## Create users and user groups in IAM Identity Center

## Create and configure user profiles

---

[Back to the Lab 1](./lab-01.md)

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0
