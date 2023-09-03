# super-octo-adventures
Hey everyone! Welcome to my super octo adventure. This repository holds three different deployment strategies for a website on AWS. Let me give a brief overview of these strategies.

## S3 Bucket Deployment

## Virtual Machine Deployment

## Containerized Deployment

# Scripts
The following scripts are made for ease of management: reset.sh, vmdeploy.sh, s3deploy.sh, containerdeploy.sh
These will be explained below:

reset.sh - Resets the environment by destroying content from deploy_s3, deploy_vm, deploy_container but leaving 
certificate related content

vmdeploy.sh - deploys deploy_vm module including the following resources: networking (1x VPC, 4x subnets, 
1x route table, 1x internet gateway), 1x application loadbalancer, 1x autoscaling group, and 1x S3 bucket

s3deploy.sh - deploys deploy_s3 module including the following resources: 2x CloudFront distributions and 2x S3 buckets

containerdeploy.sh - deploys deploy_container module including the following resources: TBD

Note: switching between these deployments quickly can run into DNS caching issues locally and at the name server or isp level. This may remove your ability to connect to the website until that records TTL dies.