#!/bin/bash

# Zipping website content
7z a -tzip ./deployment.zip ./frontend

# Running Terraform apply without a module selected
terraform apply -var-file="terraform.tfvars"

# Cleaning up deployment package
rm ./deployment.zip