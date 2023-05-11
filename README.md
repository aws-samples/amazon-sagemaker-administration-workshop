# Amazon SageMaker administration workshop
This workshop presents the most common administration and configuration topics in the context of Machine Learning (ML) and Amazon SageMaker. In general it follows the recommended practices presented in the [SageMaker Studio Administration Best Practices](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/sagemaker-studio-admin-best-practices.html) whitepaper and gives you a playground environment to experiment with these practices.

Working with hands-on examples, you will learn about the recommended design principles for administering and protecting your ML environments, more specifically Amazon SageMaker domains, Studio UX, and data. You will use AWS services to implement a multi-layer security architecture to help you protect your data, implement resource isolation, and architect a secure network.

## Workshop content
- [Lab 1]((content/01-lab-01/lab-01.md)):
    - Setup of an Amazon SageMaker domain
    - SageMaker execution roles
    - User and profile management for the SageMaker domain
    - Network and data protection in the context of ML workloads and Amazon SageMaker
- [Lab 2]((content/02-lab-02/lab-02.md)):
    - Data and resource isolation using attribute-based access control (ABAC) and role-based access control (RBAC)
- [Lab 3]((content/03-lab-03/lab-03.md)):
    - Governance, monitoring, and security controls

## Infrastructure as Code considerations
The recommended software development practices are to implement infrastructure and any changes to infrastructure as code. 
The AWS Well-Architected Framework Operational Excellence Pillar defines the corresponding [design principles](https://docs.aws.amazon.com/wellarchitected/latest/operational-excellence-pillar/design-principles.html).

In any real-world environment or project you should follow these design principles and implement all infrastructure and resources discussed in this workshop as code.

This workshop provides instructions that you must follow in AWS console or AWS CLI. This is for clarity and keeping workshop flow hands-on rather then reduce it to provisioning of CloudFormation stacks. For some parts of the workshop you're going to use the provided CloudFormation templates, but the majority of the examples follow the manual step-by-step implementation in AWS Console or AWS CLI.

## Don't use workshop examples in the production workload
The workshop contains many recommended practices, source code snippets, CloudFormation templates, and IAM policies demonstrating the implementation of these practices. While all artifacts undergone the specialist and peer reviews, the examples are always a simplified and generalized version of a real-world implementation. There might be also bugs in the examples or some background implementation might change, so the code won't work as expected. 

If you'd like to use the presented approaches and the provided artifacts for your production workloads, always perform a security and code review with your own operation, security, and development teams. Each use case is unique and the discussed topics of administration and security are complex. There might be always some changes and additions required to make the provided code and practices work with your workloads within your environment.

## Cost
If you run the workshop in your account, **you will incur cost** for the VPC, VPC endpoints, storage of the VPC Flow Logs, SageMaker job running time, and potentially other resources you provision as a part of the workshop. We estimate the cost for the foundational resources such as networking and logs at approximately **USD 10-15 per day**. Follow the **Clean-up** instructions after you completed the workshop to stop incurring any cost associated with the workshop resources.

## Getting started
Follow the instructions in the [introduction](content/00-introduction/introduction.md) section.

## Clean-up
❗ To avoid charges, you must remove all provisioned and generated resources from your AWS account. 

Follow the instructions in in the [Clean up](content/900-clean-up/clean-up.md) section.

💡 You don't need to perform a clean-up if you run an AWS-instructor led workshop.

## Dataset
This workshop uses the [direct marketing dataset](https://archive.ics.uci.edu/ml/datasets/bank+marketing) from UCI's ML Repository:
> [Moro et al., 2014] S. Moro, P. Cortez and P. Rita. A Data-Driven Approach to Predict the Success of Bank Telemarketing. Decision Support Systems, Elsevier, 62:22-31, June 2014

## Resources
This is a collection of documentation, blog posts, and code repository links for Amazon SageMaker administration and security topics.

### Whitepapers and documentation
- [SageMaker Studio Administration Best Practices](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/network-management.html)
- [Infrastructure Security in Amazon SageMaker](https://docs.aws.amazon.com/sagemaker/latest/dg/infrastructure-security.html)
- [Building a Data Perimeter on AWS](https://docs.aws.amazon.com/whitepapers/latest/building-a-data-perimeter-on-aws/building-a-data-perimeter-on-aws.html)

### Blog posts

### Hands-on content

## QR code for this repository
You can use the following QR code to link this repository.

![](./static/img/workshop-github-qrcode.png)

[Amazon SageMaker Administration Workshop](https://bit.ly/40RfQAn)

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0