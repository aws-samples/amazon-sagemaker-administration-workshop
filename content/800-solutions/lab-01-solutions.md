# Solutions for the assignments in the lab 1
These are the solution for the assignments in the lab 1

## Solution for the assignment 01-01
> Demonstrate a permission escalation use case where a low-privilege role can pass execution to a high-privilege role because of incorrect `iam:PassRole` permission setup.

We're going to implement the following demonstration of the permission escalation which exploits incorrect `iam:PassRole` permission setup:

1. Have a high privilege role, for example `S3:*` for any S3 bucket
2. Create a Studio notebook which reads from an S3 bucket which cannot be accessed by the user profile execution role. The same notebooks outputs the data in the cell. 
3. If you run the notebook in Studio under the user profile execution role, the read operation for the restricted S3 bucket fails in the notebook, because the execution role doesn't have read permission for this S3 bucket.
4. Create a [notebook job](https://docs.aws.amazon.com/sagemaker/latest/dg/notebook-auto-run.html) and specify the high privilege role as the job execution role. This requires `iam:PassRole` permission for the user profile execution role which creates the notebook job.
5. Run the notebook job. The job succeeded because the job execution role has the needed permissions
6. Open the notebook job output notebook and see the data dump in the output. So you were able to demonstrate the escalation of permissions.
7. Fix the issue with using a proper `iam:PassRole` configuration.

---

Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
SPDX-License-Identifier: MIT-0