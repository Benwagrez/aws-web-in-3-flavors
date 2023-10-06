#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo yum install -y mod_ssl
sudo yum install -y unzip
sudo systemctl start httpd
sudo systemctl enable httpd

echo "Deploying SSL Certificates..."
sudo aws --region=us-east-2 ssm get-parameter --name "/octoweb/SSL/cert" --with-decryption --output text --query Parameter.Value > localhost.crt
sudo aws --region=us-east-2 ssm get-parameter --name "/octoweb/SSL/key" --with-decryption --output text --query Parameter.Value > localhost.key
sudo cp localhost.crt /etc/pki/tls/certs/localhost.crt
sudo cp localhost.key /etc/pki/tls/private/localhost.key
sudo systemctl restart httpd


echo "Deploying web content..."
sudo aws s3 cp s3://octovmwebsitearm/deployment.zip deployment.zip
sudo unzip deployment.zip
sudo cp -r frontend/* /var/www/html/


echo "Cleaning up system files..."
sudo rm -R frontend
sudo rm localhost.crt
sudo rm localhost.key

