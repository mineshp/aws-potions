#!/bin/bash

sudo yum update
sudo yum install ruby
sudo yum install wget
wget https://aws-codedeploy-eu-west-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status