#!/bin/bash

# Zipping website content into deploy_vm
7z a -tzip ./deployment.zip ./frontend


# Running Terraform apply
terraform apply -var-file="terraform.tfvars" -var="deployvm=true"