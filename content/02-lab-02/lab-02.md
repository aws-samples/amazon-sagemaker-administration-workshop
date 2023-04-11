
# Lab 2: data protection
This lab shows how to protect data in your ML environment. 

---

## Content
In this lab you're going to do:
- Protect data at rest using encryption with AWS KMS
- Protect data in transit using encryption
- Implement RBAC and ABAC for data protection
- Implement S3 access control using IAM policies, VPC endpoints, and VPC endpoint policies
- Control access to SageMaker resources by using tags

## Where your data must be protected
The ML workflow can process, copy, generate, and store datasets resulting in multiple persistent or ephemeral data copies. All these copies represent additional threat vectors for data protection. You must be aware of them, monitor them, and implement a corresponding mitigation.

The following diagram shows possible location and default encryption state of your data:

![](../../static/design/ml-development-data-lifecycle.drawio.svg)

The following table summarizes the characteristics of these possible data copies and a recommended protection approach:

Data location | Encryption | Lifetime | Data protection approach
---|---|---|---
Memory of the Jupyter notebooks, processing, and training job instances | Always-on memory encryption for [Graviton2](https://aws.amazon.com/ec2/graviton/), Ice Lake, and AMD EPYC based instances | Ephemeral | Use always-on memory encryption for critical data on supporting compute instances, see [Graviton-based instances for model deployment](https://aws.amazon.com/about-aws/whats-new/2022/10/amazon-sagemaker-adds-new-graviton-based-instances-model-deployment/) and [available Studio instance types](https://docs.aws.amazon.com/sagemaker/latest/dg/notebooks-available-instance-types.html)
SageMaker Studio EFS volume | At rest, by default with an AWS managed key | Persistent | Recommended to use a KMS key instead of an AWS managed key, use `KmsKeyId` parameter in SageMaker API
EBS volumes attached to Studio notebook instances | At rest, both OS and ML data volumes are encrypted by default with an AWS managed key | Ephemeral | Recommended to use a KMS key instead of an AWS managed key, use `KmsKeyId` parameter in SageMaker API
EBS volumes attached to SageMaker processing, batch transform, and training job containers | At rest, by default with an AWS managed key | Ephemeral | Recommended to use a KMS key instead of an AWS managed key, use `KmsKeyId` parameter in SageMaker API
Output from processing, training, and batch transform jobs stored in an S3 bucket | At rest, by default with an AWS managed key for S3 | Persistent | Recommended to use a KMS key instead of an AWS managed key, use `S3KmsKeyId` parameter in SageMaker API. Use S3 VPC endpoint policies to prevent write to any unauthorized S3 buckets. Enforce usage of the designated KMS key for `PutObject` S3 operation
[Data capture](https://docs.aws.amazon.com/sagemaker/latest/dg/model-monitor-data-capture.html) configurations with SageMaker endpoints and batch transform | At rest, by default with an AWS managed key | Persistent | Recommended to use a KMS keys, use `KmsKeyId` in [`DataCaptureConfig`](https://docs.aws.amazon.com/sagemaker/latest/APIReference/API_DataCaptureConfig.html) for encryption on EBS volume attached to the ML instance hosting the endpoint.
Notebook cell output | No encryption | Ephemeral | Use Studio notebooks [lifecycle configuration scripts](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-lcc.html) to remove cell output periodically using [`jupyter/nbconvert`](https://github.com/jupyter/nbconvert). Start with the example for [auto-shutdown](https://github.com/aws-samples/sagemaker-studio-auto-shutdown-extension)
Git-committed notebook with cell output | No encryption | Persistent | Use Git [pre-commit hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) to remove cell output, implement automated scanning in Git repositories
Git-committed datasets | No encryption | Persistent | Implement automated scanning in Git repositories, use pre-commit hooks
Shared Studio notebooks | At rest, by default with an AWS managed key | Persistent | Recommended to use a KMS key instead of an AWS managed key, use `S3KmsKeyId`. Disable notebook sharing at the domain level. Disable cell output sharing.
Another EC2 instance via Studio terminal or a processing or training script | Potentially no encryption | Persistent | Implement network isolation with VPC Security Groups for Studio and block any data transfer to unauthorized EC2 instances. Log all IP traffic.
SageMaker [Feature Store](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store.html) | At rest, by default with an AWS managed key | Persistent | Recommended to use a KMS key instead of an AWS managed key for offline and online store. Refer to [Security and Access Control](https://docs.aws.amazon.com/sagemaker/latest/dg/feature-store-security.html) for Feature Store
Another Amazon S3 bucket | Potentially no encryption | Persistent | Use S3 VPC endpoint policies to prevent write to any unauthorized S3 buckets and prevent any unencrypted write.
[Amazon Athena](https://docs.aws.amazon.com/athena/latest/ug/what-is.html) query result table | Not encrypted by default | Persistent | Refer to [Data protection in Athena](https://docs.aws.amazon.com/athena/latest/ug/security-data-protection.html) and [Encrypting Athena query results stored in Amazon S3](https://docs.aws.amazon.com/athena/latest/ug/encrypting-query-results-stored-in-s3.html)
Amazon EMR cluster | as configured | Persistent | Use Amazon EMR encryption approaches. Refer to [Data protection in Amazon EMR](https://docs.aws.amazon.com/emr/latest/ManagementGuide/data-protection.html)

❗ Certain Nitro-based SageMaker instances include local storage, depending on the instance type. Local storage volumes are encrypted using a hardware module on the instance. You can't use a KMS key on an instance type with local storage. For a list of instance types that support local instance storage, see [Instance Store Volumes](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/InstanceStorage.html#instance-store-volumes).

## Step 1: implement data encryption

### AWS KMS keys
The default encryption is performed with [AWS managed key](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#aws-managed-cmk). The AWS managed keys in your account that are created, managed, and used on your behalf by an AWS service integrated with AWS KMS.

You have permission to view the AWS managed keys in your account, view their key policies, and audit their use in AWS CloudTrail logs. However, you cannot change any properties of AWS managed keys, rotate them, change their key policies, or schedule them for deletion. And, you cannot use AWS managed keys in cryptographic operations directly; the service that creates them uses them on your behalf.

The recommended practice is to create and use [customer managed keys](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#customer-cmk). Customer managed keys are KMS keys in your AWS account that you create, own, and manage. You have full control over these KMS keys, including establishing and maintaining their key policies, IAM policies, and grants, enabling and disabling them, rotating their cryptographic material, adding tags, creating aliases that refer to the KMS keys, and scheduling the KMS keys for deletion.

### Using KMS key policies
Unlike other AWS resource policies, an AWS KMS key policy does not automatically give permission to the account or any of its principals. To give permission to any principal, including the account principal, you must give the permissions explicitly in the key policy.

Let's look at the key policy for Studio EFS/EBS KMS key we created in the Lab 1. 
The policy consists of three parts.

1. Enable IAM policies and allow access to the key for the AWS account:
```json
{
    "Sid": "Enable IAM User Permissions"
    "Effect": "Allow",
    "Principal": {
        "AWS": "arn:aws:iam::<ACCOUNT-ID>:root"
    },
    "Action": "kms:*",
    "Resource": "*"
}
```

It's important to understand, that this policy statement doesn't give any IAM principal permission to use the KMS key. Instead, it allows the account to use IAM policies to delegate the key permissions for all actions (`kms:*`) to the IAM policy statements attached to an IAM role. 

2. Allow users to use the KMS key:
```json
{
    "Sid": "Allow use of the key for Studio roles",
    "Effect": "Allow",
    "Principal": {
        "AWS": [
            "arn:aws:iam::949335012047:role/sagemaker-admin-workshop-iam-StudioRoleMLOps-1LJMIG785A20T",
            "arn:aws:iam::949335012047:role/sagemaker-admin-workshop-iam-StudioRoleDataScience-WDT8LXMFY2TX"
        ]
    },
    "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
    ],
    "Resource": "*"
}
```

You can add IAM users, IAM roles, and other AWS accounts to the list of key users allowed to use the KMS key. In this workshop you allow two user profile execution roles to use the key for cryptographic operations.

3. Allow users to use the KMS key with AWS services
```json
{
    "Sid": "Allow use of the key with AWS services",
    "Effect": "Allow",
    "Principal": {
        "AWS": [
            "arn:aws:iam::949335012047:role/sagemaker-admin-workshop-iam-StudioRoleMLOps-1LJMIG785A20T",
            "arn:aws:iam::949335012047:role/sagemaker-admin-workshop-iam-StudioRoleDataScience-WDT8LXMFY2TX"
        ]
    },
    "Action": [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant"
    ],
    "Resource": "*",
    "Condition": {
        "Bool": {
            "kms:GrantIsForAWSResource": "true"
        }
    }
}
```

This key policy statement allows the key user to create, view, and revoke grants on the KMS key, but only when the grant operation request comes from an [AWS service integrated with AWS KMS](https://aws.amazon.com/kms/features/#AWS_Service_Integration). The `kms:GrantIsForAWSResource` policy condition doesn't allow the user to call these grant operations directly.

In a real-world environment you should consider the following recommended practices for managing your AWS KMS keys:
- Keep all KMS keys in a separate hardened and controlled account with only few administration roles
- Have a dedicated key administration role and give explicit key administration permissions in the key policy to this role
- Enable AWS CloudTrail to log and monitor all operations on the KMS keys

### Enforcing usage of a designated KMS key

## Step 2: implement data access control

Identity-based and resource-based IAM policies

![](../../static/design/data-protection-abac.drawio.svg)

### Control access to SageMaker resources by using tags
https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html#access-tag-policy


## Step 3: implement data perimeter

### Amazon S3 access control with VPC endpoint polices
Developing ML models requires access to sensitive data stored on specific S3 buckets. You might want to implement controls to guarantee that:

- Only specific Studio domains or SageMaker workloads and users can access these buckets
- Each Studio domain or SageMaker workload have access to the defined S3 buckets only

We implement this requirement by using an S3 VPC Endpoint in your private VPC and configuring VPC Endpoint and S3 bucket policies.

First, start with the S3 bucket policy attached to the **specific S3 bucket**:
```json
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::<s3-bucket-name>/*",
                "arn:aws:s3:::<s3-bucket-name>"
            ],
            "Condition": {
                "StringNotEquals": {
                    "aws:sourceVpce": "<s3-vpc-endpoint-id>"
                }
            }
        }
    ]
}
```
The bucket policy explicitly denies all access to the bucket which does not come from the **designated VPC endpoint**.

Second, attach the following permission policy to the **S3 VPC Endpoint**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::<s3-bucket-name>",
                "arn:aws:s3:::<s3-bucket-name>/*"
            ]
        }
    ]
}
```
This policy allows access the designated S3 buckets only.

This combination of S3 bucket policy and VPC endpoint policy, together with Amazon SageMaker Studio VPC connectivity, establishes that SageMaker Studio can only access the referenced S3 bucket, and this S3 bucket can only be accessed from the VPC endpoint.

❗ You will not be able to access these S3 buckets from the AWS console or `aws cli`.

All network traffic between Amazon SageMaker Studio and S3 is routed via the designated S3 VPC Endpoint over AWS private network and never traverses public internet.

You may consider to enable access to other S3 buckets via S3 VPC endpoint policy, for example to shared public SageMaker buckets, to enable additional functionality in the Amazon SageMaker Studio, like [JumpStart](https://docs.aws.amazon.com/sagemaker/latest/dg/studio-jumpstart.html).
If you want to have access ot JumpStart, you must add the following statement to the S3 VPC endpoint policy:
```json
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "*",
      "Condition": {
        "StringEqualsIgnoreCase": {
          "s3:ExistingObjectTag/SageMaker": "true"
        }
      }
    }
```

### Test S3 access via VPC endpoints
To verify the access to the Amazon S3 buckets for the data science environment, you can run the following commands in the Studio terminal:

```sh
aws s3 ls
```
![aws s3 ls](../img/s3-ls-access-denied.png)

The S3 VPC endpoint policy blocks access to S3 `ListBuckets` operation.

```sh
aws s3 ls s3://<sagemaker deployment data S3 bucket name>
```
![aws s3 ls allowed](../img/s3-ls-access-allowed.png)

You can access the data science environment's data or models S3 buckets.

```sh
aws s3 mb s3://<any available bucket name>
```
![aws s3 mb](../img/s3-mb-access-denied.png)

The S3 VPC endpoint policy blocks access to any other S3 bucket.

```sh
aws sts get-caller-identity
```
![get role](../img/sagemaker-execution-role.png)

All operations are performed under the SageMaker user profile execution role.

### Use VPC controls in SageMaker jobs
By default, containers access S3 via VPC Endpoints within the Platform VPC without traversing the public network. For more control, the customer may alternately connect the instance to a customer VPC for privately managed egress, and can require this through an [IAM condition key](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonsagemaker.html#amazonsagemaker-policy-keys) on a policy attached to the role passed to SageMaker. [VPC mode](https://docs.aws.amazon.com/sagemaker/latest/dg/train-vpc.html) should be chosen when the S3 buckets containing the input/output data have policies restricting their access to specific customer-managed VPC Endpoints. Amazon SageMaker performs download and upload operations against Amazon S3 using your Amazon SageMaker Execution Role in isolation from the training container.

### Amazon S3 access points
You can control access to datasets with [Amazon S3 access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points.html). A recommended practices is to define a designated access point for each application or team which requires a specific set of data entitlements. Implement access point policies enforcing usage of designated KMS keys and object tags. There is a default quota of 10,000 access points per account per Region. You can request a service quota increase if you need more than 10,000 access point for a single account in a single Region.

Consider [access points restrictions and limitations](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-points-restrictions-limitations.html)

## Step 4: implement resource isolation using tags

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "SageMaker:Create*",
                "SageMaker:Update*"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "aws:TagKeys": [
                        "sagemaker:domain-arn"
                    ]
                }
            }
        },
        {
            "Effect": "Deny",
            "Action": [
                "SageMaker:Update*",
                "SageMaker:Delete*",
                "SageMaker:Describe*"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotLikeIfExists": {
                    "aws:ResourceTag/sagemaker:domain-arn": "arn:aws:sagemaker:us-east-1:906545278380:domain/d-hrcfizeddzyj"
                }
            }
        }
    ]
}
```

## Conclusion

## Continue with the next lab
You can move to the [lab 3](../02-lab-02/lab-03.md) which demonstrates how to implement monitoring, governance guardrails and security controls.

## Additional resources
The following resources provide additional details and reference for data security and access topics.

- [Data protection in SageMaker Studio Administration Best Practices](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/data-protection.html)
- [Building a Data Perimeter on AWS](https://docs.aws.amazon.com/whitepapers/latest/building-a-data-perimeter-on-aws/building-a-data-perimeter-on-aws.html)
- [Protect Data at Rest Using Encryption](https://docs.aws.amazon.com/sagemaker/latest/dg/encryption-at-rest.html)
- [Configuring Amazon SageMaker Studio for teams and groups with complete resource isolation](https://aws.amazon.com/fr/blogs/machine-learning/configuring-amazon-sagemaker-studio-for-teams-and-groups-with-complete-resource-isolation/)
- [Key policies in AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)
- [What is ABAC for AWS?](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html)

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0