#!/bin/bash
# Setting env vars
export ACCOUNT=194189783006 
export REGION=us-east-2 
export REPO=ecr-website-repo

# Zipping web content
7z a -tzip ./deployment.zip ./frontend

# Start docker build
source ./docker/dockerbuild.sh

# Set up core infrastructure
terraform apply -var-file="terraform.tfvars" -var="deploycontainer=true"

# Cleaning up deployment package
rm ./deployment.zip
