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