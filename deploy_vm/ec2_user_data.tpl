#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo yum install -y unzip
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Attempting to pull deployment from S3"
sudo aws s3 cp s3://octovmwebsitearm/deployment.zip deployment.zip


sudo unzip deployment.zip
sudo cp frontend/* /var/www/html/

