#!/bin/bash -e

sudo apt-get update
sudo apt-get install -y python-virtualenv python-pip python-dev \
    postgresql postgresql-server-dev-all git mcrypt sharutils

uudecode cruft.uue
mdecrypt dotssh.tgz.nc     # this step requires a password
tar xfz dotssh.tgz
rm -f dotssh.tgz*

git clone git@github.com:wware/eb-flaskapp.git

echo "create database mydb;" | sudo -u postgres psql
cat eb-flaskapp/pg.dump | sudo -u postgres psql mydb
sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'postgres';"
