
- Data security 
- Data and resource isolation with ABAC and RBAC
- Multidomain

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

All operations are performed under the SageMaker execution role.

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0