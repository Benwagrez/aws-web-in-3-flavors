# super-octo-adventures


# Scripts
The following scripts are made for ease of management: reset.sh, vmdeploy.sh, s3deploy.sh, containerdeploy.sh
These will be explained below:

reset.sh - Resets the environment by destroying content from deploy_s3, deploy_vm, deploy_container but leaving 
certificate related content

vmdeploy.sh - deploys deploy_vm module including the following resources: networking (1x VPC, 4x subnets, 
1x route table, 1x internet gateway), 1x application loadbalancer, 1x autoscaling group, and 1x S3 bucket

s3deploy.sh - deploys deploy_s3 module including the following resources: 2x CloudFront distributions and 2x S3 buckets

containerdeploy.sh - deploys deploy_container module including the following resources: TBD
