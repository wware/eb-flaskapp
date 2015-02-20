#!/bin/bash -e

if [ "$(whoami)" != "root" ]
then
    echo "You must be ROOT to go on this ride."
    exit 1
fi

export USER=ubuntu
export BASEDIR=`dirname $0`
export VENV=$BASEDIR/venv

if [ ! -d "$VENV" ]
then
    sudo -u $USER virtualenv -q $VENV --no-site-packages
fi

if [ ! -f "$VENV/updated" -o $BASEDIR/requirements.txt -nt $VENV/updated ]; then
    sudo -u $USER pip install -r $BASEDIR/requirements.txt -t $VENV
    sudo -u $USER touch $VENV/updated
fi

export PYTHONPATH="$BASEDIR:$VENV"
cd $BASEDIR

nohup sudo PYTHONPATH=$PYTHONPATH python application.py 80 &
