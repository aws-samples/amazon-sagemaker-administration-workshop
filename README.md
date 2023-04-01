# Amazon SageMaker administration and security for practitioners
This workshop presents the most common security and administration topics in the context of Machine Learning (ML) and Amazon SageMaker.

Working with hands-on examples, you will learn about the recommended design principles for securing ML environments. You will use AWS services to implement a multi-layer security architecture to help you protect your data, implement resource isolation, and architect a secure network.

## Workshop content
- [Secure setup of Amazon SageMaker domain](content/01-lab-01/lab-01.md)
- [SageMaker execution roles](content/01-lab-01/lab-01.md)
- [User and profile management for SageMaker domain](content/01-lab-01/lab-01.md)
- [Network and data security in the context of ML workloads and Amazon SageMaker](](content/01-lab-01/lab-01.md)) 
- [Data and resource isolation using attribute-based access control (ABAC) and role-based access control (RBAC)](content/02-lab-02/lab-02.md)
- [Governance, monitoring, and security controls](content/03-lab-03/lab-03.md)

## Getting started
Follow the instructions in the [introduction](content/00-introduction/introduction.md) section.

## Infrastructure as Code considerations
The recommended security and software development practices are to implement infrastructure and any changes to infrastructure as code. 
The AWS Well-Architected Framework Operational Excellence Pillar defines the corresponding [design principles](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/design-principles.html).

In any real-world environment or project you should follow these design principles and implement all infrastructure and security controls discussed in this workshop as code.

This workshop provides instructions that you must follow in AWS console or AWS CLI. This is for clarity and keeping workshop flow hands-on rather then reduce it to CloudFormation stack provisioning. For some parts of the workshop you're going to use the provided CloudFormation templates.

## Clean-up
❗ To avoid charges, you must remove all provisioned and generated resources from your AWS account. 

Follow the instructions in in the [Clean up](content/900-clean-up/clean-up.md) section.

💡 You don't need to perform a clean-up if you run an AWS-instructor led workshop.

## Resources
This is a collection of documentation, blog posts, and code repository links for Amazon SageMaker administration and security topics.

### Whitepapers and documentation
- [SageMaker Studio Administration Best Practices](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html)
- [Infrastructure Security in Amazon SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-security.html)

### Blog posts

### Hands-on content

## QR code for this repository
You can use the following QR code to link this repository.

![]()

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0