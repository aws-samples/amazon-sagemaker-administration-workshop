#!/bin/bash

# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

#############################################################################################
# 1st level templates
# These templates do not contain any nested templates and can be directly deployed from the file
# no `aws cloudformation package` is needed


# iam-roles.yaml
aws cloudformation deploy \
    --template-file cfn-templates/iam-roles.yaml \
    --stack-name sagemaker-admin-workshop-iam \
    --capabilities CAPABILITY_NAMED_IAM 

aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"


export DS_ROLE_ARN=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='StudioRoleDataScienceArn'].OutputValue")

export MLOPS_ROLE_ARN=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='StudioRoleMLOpsArn'].OutputValue")

export FLOWLOGS_ROLE_ARN=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-iam  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='VPCFlowLogsRoleArn'].OutputValue")

# network-vpc.yaml
aws cloudformation deploy \
    --template-file cfn-templates/network-vpc.yaml \
    --stack-name sagemaker-admin-workshop-vpc \
    --parameter-overrides \
    AvailabilityZones=${AWS_DEFAULT_REGION}a\,${AWS_DEFAULT_REGION}b \
    NumberOfAZs=2 \
    VPCCIDR=192.168.0.0/16  \
    PrivateSubnet1ACIDR=192.168.0.0/20 \
    PrivateSubnet2ACIDR=192.168.16.0/20 \
    CreateVPCFlowLogsToCloudWatch=YES \
    VPCFlowLogsRoleArn=$FLOWLOGS_ROLE_ARN

aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"

export VPCE_KMS_ID=$(
aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='VPCEndpointKMSId'].OutputValue"
)

# kms-keys.yaml
aws cloudformation deploy \
    --template-file cfn-templates/kms-keys.yaml \
    --stack-name sagemaker-admin-workshop-kms \
    --parameter-overrides \
    StudioRoleDataScienceArn=$DS_ROLE_ARN \
    StudioRoleMLOpsArn=$MLOPS_ROLE_ARN \
    VPCEndpointKMSId=$VPCE_KMS_ID

aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-kms  \
    --output table \
    --query "Stacks[0].Outputs[*].[OutputKey, OutputValue]"


# network-natgw.yaml
export AZ_NAMES=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='AvailabilityZones'].OutputValue")
export AZ_NUMBER=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='NumberOfAZs'].OutputValue")
export VPC_ID=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue")
export PRIVATE_RT_IDS=$(aws cloudformation describe-stacks \
    --stack-name sagemaker-admin-workshop-vpc  \
    --output text \
    --query "Stacks[0].Outputs[?OutputKey=='PrivateRouteTableIds'].OutputValue")

aws cloudformation deploy \
    --template-file cfn-templates/network-natgw.yaml \
    --stack-name sagemaker-admin-workshop-natgw \
    --parameter-overrides \
    AvailabilityZones=$AZ_NAMES \
    NumberOfAZs=$AZ_NUMBER \
    ExistingVPCId=$VPC_ID \
    ExistingPrivateRouteTableIds=$PRIVATE_RT_IDS \
    PublicSubnet1CIDR=192.168.64.0/20 \
    PublicSubnet2CIDR=192.168.96.0/20 \
    PublicSubnet3CIDR=192.168.112.0/20 

