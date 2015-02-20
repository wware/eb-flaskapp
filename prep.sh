#!/bin/bash -e

# Run this on the EC2 instance. First do these things on your dev machine.
#     scp -i ~/.ec2/ec2.pem prep.sh ubuntu@ec2-52-1-12-222.compute-1.amazonaws.com:~
#     scp -i ~/.ec2/ec2.pem cruft.uue ubuntu@ec2-52-1-12-222.compute-1.amazonaws.com:~
#     ssh -i ~/.ec2/ec2.pem ubuntu@ec2-52-1-12-222.compute-1.amazonaws.com

sudo apt-get update
sudo apt-get install -y python-virtualenv python-pip python-dev \
    postgresql postgresql-server-dev-all git mcrypt sharutils

uudecode cruft.uue
mdecrypt dotssh.tgz.nc     # this step requires a password
tar xfz dotssh.tgz
rm -f dotssh.tgz*

git clone git@github.com:wware/eb-flaskapp.git
