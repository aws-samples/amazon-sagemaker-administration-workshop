
- Data security 
- Data and resource isolation with ABAC and RBAC
- Multidomain


- start with no S3 access

## Data encryption

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


## Test secure S3 access
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

## Conclusion

## Additional resources
The following resources provide additional details and reference for data security and access topics.

- [Protect Data at Rest Using Encryption](https://docs.aws.amazon.com/sagemaker/latest/dg/encryption-at-rest.html)
- [Configuring Amazon SageMaker Studio for teams and groups with complete resource isolation](https://aws.amazon.com/fr/blogs/machine-learning/configuring-amazon-sagemaker-studio-for-teams-and-groups-with-complete-resource-isolation/)
- [Key policies in AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html)

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0