#!/bin/bash

# Zipping website content
7z a -tzip ./deployment.zip ./frontend

# Running Terraform apply
terraform apply -var-file="terraform.tfvars" -var="deployS3=true"

# Cleaning up deployment package
rm ./deployment.zip