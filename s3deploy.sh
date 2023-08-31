#!/bin/bash

# Running Terraform apply
terraform apply -var-file="terraform.tfvars" -var="deployS3=true"