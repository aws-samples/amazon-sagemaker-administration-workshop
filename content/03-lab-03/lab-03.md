
- Governance and security controls

preventive controls
IAM conditions

SageMaker [conditions and actions](https://docs.aws.amazon.com/sagemaker/latest/dg/security-iam.html)

## Monitoring

[Source identity](https://docs.aws.amazon.com/sagemaker/latest/dg/monitor-user-access.html)

## Security controls

### Preventive

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

#### AWS Service Catalog
Based on pre-defined CloudFormation templates to provision requested resources.

### Detective
Logging and monitoring. You can use the following AWS services:
- AWS CloudWatch
- AWS CloudTrail
- VPC Flow Logs
- AWS Security Hub
- Amazon GuardDuty
- Amazon Macie

https://sagemaker-workshop.com/security_for_sysops/detective/detective_lab.html

### Corrective
Re-active correction of user actions. For example, you can stop ML instances if the instance type is not approved for use by the data scientist.

Use:
- AWS Config
- IAM Access Analyser
- Amazon Security Hub


## Test preventive IAM policies
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

## Conclusion

## Additional resources

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0