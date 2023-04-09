# Lab 3: Monitoring, governance, and security controls
This lab shows how to implement auditing, monitoring, and governance guardrails for your ML environments and workloads. The hands-on examples contain implementation of preventive, detective, and corrective security controls.

---

## Content
In this lab you're going to do:
- Use AWS services [AWS CloudTrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html), [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch_concepts.html), and [Amazon S3 server access logging](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerLogs.html) to monitor the access to API, resources, and to capture SageMaker job logs and metrics
- Implement preventive security controls with IAM policy conditions
- Implement detective and corrective security controls with [AWS Config](https://docs.aws.amazon.com/config/latest/developerguide/WhatIsConfig.html), [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html), and [AWS Security Hub](https://docs.aws.amazon.com/securityhub/latest/userguide/what-is-securityhub.html)
- Learn what governance guardrails you can implement for ML workloads
- Use [Amazon GuardDuty](http://aws.amazon.com/guardduty/) to monitor for malicious and unauthorized activities
- Use [Amazon Macie](http://aws.amazon.com/macie/) to find and classify personally identifiable information (PII) in the training and inference data

## Step 1: logging and monitoring

### Monitoring with CloudWatch

### Logging with CloudTrail

[Source identity](https://docs.aws.amazon.com/sagemaker/latest/dg/monitor-user-access.html)



```sh
aws sagemaker update-domain \
    --domain-id <DOMAIN-ID> \
    --domain-settings-for-update "ExecutionRoleIdentityConfig=USER_PROFILE_NAME"
```

### Configure Amazon S3 server access logging

## Step 2: security controls

### Preventive
[SageMaker IAM conditions and actions](https://docs.aws.amazon.com/sagemaker/latest/dg/security-iam.html)

#### IAM policies
We use an IAM role policy which enforce usage of specific security controls. For example, all SageMaker workloads must be created in the VPC with specified security groups and subnets:
```json
{
    "Condition": {
        "Null": {
            "sagemaker:VpcSubnets": "true"
        }
    },
    "Action": [
        "sagemaker:CreateNotebookInstance",
        "sagemaker:CreateHyperParameterTuningJob",
        "sagemaker:CreateProcessingJob",
        "sagemaker:CreateTrainingJob",
        "sagemaker:CreateModel"
    ],
    "Resource": [
        "arn:aws:sagemaker:*:<ACCOUNT_ID>:*"
    ],
    "Effect": "Deny"
}
```
[List of IAM policy conditions for Amazon SageMaker](https://docs.aws.amazon.com/service-authorization/latest/reference/list_amazonsagemaker.html). For more examples, refer to the [developer guide](https://docs.aws.amazon.com/sagemaker/latest/dg/security_iam_id-based-policy-examples.html).

We use an Amazon S3 bucket policy explicitly denies all access which is **not originated** from the designated S3 VPC endpoints:
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
                    "aws:sourceVpce": ["<s3-vpc-endpoint-id1>", "<s3-vpc-endpoint-id2>"]
                }
            }
        }
    ]
}
```

S3 VPC endpoint policy allows access only to the specified S3 project buckets with data, models and CI/CD pipeline artifacts, SageMaker-owned S3 bucket and S3 objects which are used for product provisioning.

List of common guardrails in [Permission management](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/permissions-management.html)

### Test preventive IAM policies
Try to start a training job without VPC attachment:
```python
container_uri = sagemaker.image_uris.retrieve(region=session.region_name, 
                                              framework='xgboost', 
                                              version='1.0-1', 
                                              image_scope='training')

xgb = sagemaker.estimator.Estimator(image_uri=container_uri,
                                    role=sagemaker_execution_role, 
                                    instance_count=2, 
                                    instance_type='ml.m5.xlarge',
                                    output_path='s3://{}/{}/model-artifacts'.format(default_bucket, prefix),
                                    sagemaker_session=sagemaker_session,
                                    base_job_name='reorder-classifier',
                                    volume_kms_key=ebs_kms_id,
                                    output_kms_key=s3_kms_id
                                   )

xgb.set_hyperparameters(objective='binary:logistic',
                        num_round=100)

xgb.fit({'train': train_set_pointer, 'validation': validation_set_pointer})
```

You get `AccessDeniedException` because of the explicit `Deny` in the IAM policy:

![start-training-job-without-vpc](../img/start-training-job-without-vpc.png)
![accessdeniedexception](../img/accessdeniedexception.png)

IAM policy:
```json
{
    "Condition": {
        "Null": {
            "sagemaker:VpcSubnets": "true",
            "sagemaker:VpcSecurityGroup": "true"
        }
    },
    "Action": [
        "sagemaker:CreateNotebookInstance",
        "sagemaker:CreateHyperParameterTuningJob",
        "sagemaker:CreateProcessingJob",
        "sagemaker:CreateTrainingJob",
        "sagemaker:CreateModel"
    ],
    "Resource": [
        "arn:aws:sagemaker:*:<ACCOUNT_ID>:*"
    ],
    "Effect": "Deny"
}
```

Now add the secure network configuration to the `Estimator`:
```python
network_config = NetworkConfig(
        enable_network_isolation=False, 
        security_group_ids=env_data["SecurityGroups"],
        subnets=env_data["SubnetIds"],
        encrypt_inter_container_traffic=True)
```

```python
xgb = sagemaker.estimator.Estimator(
    image_uri=container_uri,
    role=sagemaker_execution_role, 
    instance_count=2, 
    instance_type='ml.m5.xlarge',
    output_path='s3://{}/{}/model-artifacts'.format(default_bucket, prefix),
    sagemaker_session=sagemaker_session,
    base_job_name='reorder-classifier',

    subnets=network_config.subnets,
    security_group_ids=network_config.security_group_ids,
    encrypt_inter_container_traffic=network_config.encrypt_inter_container_traffic,
    enable_network_isolation=network_config.enable_network_isolation,
    volume_kms_key=ebs_kms_id,
    output_kms_key=s3_kms_id

  )
```

You are able to create and run the training job.

### Detective controls
Logging and monitoring. You can use the following AWS services:
- AWS CloudWatch
- AWS CloudTrail
- VPC Flow Logs
- AWS Security Hub
- Amazon GuardDuty
- Amazon Macie

https://sagemaker-workshop.com/security_for_sysops/detective/detective_lab.html

### Corrective controls
Re-active correction of user actions. For example, you can stop ML instances if the instance type is not approved for use by the data scientist.

Use:
- AWS Config
- IAM Access Analyser
- Amazon Security Hub

## Step 3: guardrails for ML environments

## Conclusion

## Additional resources
- [Logging and monitoring in SageMaker Studio Administration Best Practices whitepaper](https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/logging-and-monitoring.html)
- [Monitoring in AWS Well-Architected Framework Machine Learning Lens](https://docs.aws.amazon.com/wellarchitected/latest/machine-learning-lens/ml-lifecycle-phase-monitoring.html)
- [SageMaker IAM conditions and actions](https://docs.aws.amazon.com/sagemaker/latest/dg/security-iam.html)
- [Amazon SageMaker for SysOps workshop](https://sagemaker-workshop.com/security_for_sysops.html)

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0