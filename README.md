Teeny Flask App
=====

I was asked to write a little web app for a small organization that could
apply rudimentary password protection to some documents. The minimal needs
of the organization allow a single username and password to be shared by
all users.

I first thought of Django but a database was not desired, so I went for the
simpler option of using Flask. I drew on the following sources.

* http://flask.pocoo.org/docs/0.10/tutorial/
* https://flask-login.readthedocs.org/en/latest/
* http://gouthamanbalaraman.com/blog/minimal-flask-login-example.html
* http://stackoverflow.com/questions/16627384/flask-login-with-static-user-always-yielding-401-unauthorized

AWS deployment
----

First, do this (or whatever is equivalent) on your development machine.

```bash
sudo apt-get install -y ec2-ami-tools ec2-api-tools
```

You can create an AMI image from VMware, here is how to install it on Ubuntu:
https://help.ubuntu.com/community/VMware/Player
When creating the VMware instance, make it a small image. I'm trying 5 gig,
fingers crossed. When you get the option to select sets of packages, select
"OpenSSH server" and "PostgreSQL server" but DO NOT choose "LAMP server". You
don't want Apache or MySQL or PHP.

You need this to run the stuff currently in eb-flaskapp:
```bash
sudo apt-get install python-virtualenv python-pip python-dev postgresql-server-dev-all git
```

On the server instantce, you need to create the database and put in the schema, like this:
```bash
$ echo "create database mydb;" | sudo -u postgres psql
$ cat pg.dump | sudo -u postgres psql mydb
```

Then you do need to set the PostgreSQL password manually, like this:
```bash
$ sudo -u postgres psql mydb
psql (9.3.6)
Type "help" for help.

postgres=# \password postgres
Enter new password:
Enter it again:
postgres=# \q
```

You start the server by ssh-ing in, going into the eb-flaskapp directory, and running
```bash
sudo ./go.sh
```

To create the AMI from the VMware image, shut down the VMware instance and go into the
directory where the image is stored, and do these things.

```bash
cd ~/vmware/Ubuntu-64bit
qemu-img convert -O raw Ubuntu-64bit.vmdk output.raw
ec2-bundle-image -i output.raw -r x86_64 -c ~/.ec2/cert-XXXX.pem \
    -k ~/.ec2/pk-XXXX.pem --user 053158212512
export BUCKET=elasticbeanstalk-us-east-1-053158212512
ec2-upload-bundle -b $BUCKET -m /tmp/output.raw.manifest.xml \
    -a ACCESS_KEY -s SECRET_KEY
ec2-register $BUCKET/output.raw.manifest.xml \
    -O ACCESS_KEY -W SECRET_KEY
```

I've learned a heck of a lot about AWS over the past few days but I've neglected to keep
good notes. That is regrettable.

Important stuff:

* https://console.aws.amazon.com/elasticbeanstalk/
* https://console.aws.amazon.com/console/home?region=us-east-1

So I did all that, having built an image using an Ubuntu 14.04 64-bit server ISO, and
what I found was that the result does not qualify for the `t1.micro` instance, which
means I would be charged money to use the AMI that I created.

The alternative is to use the pre-existing Ubuntu t1.micro-able AMI provided by
Amazon and develop a script that works on it. That's not so difficult, it turns out,
see `prep.sh`, `cruft.uue` and `prep-helper.sh` in this repo.
