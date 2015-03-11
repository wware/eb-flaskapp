#!/bin/bash

for x in vpc sg instances
do
    ansible-playbook create_${x}.yml || exit 1
done
