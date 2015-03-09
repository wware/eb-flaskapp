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

Let's skip the virtual machine and go straight to EC2.
* Go to the
  [EC2 console page](https://console.aws.amazon.com/ec2/v2/home)
  and hit the big blue *Launch Instance* button.
* Choose the Ubuntu 64-bit server option and hit *Continue*.
* On the next page, make sure *Auto-assign Public IP* is ENABLED and that
  the instance belongs to a PUBLIC subnet.
* Two pages later, make sure you choose a security group with inbound traffic
  allowed on ports 22 (ssh) and 80 (http) for source `0.0.0.0/0`, and all
  outbound traffic allowed for destination `0.0.0.0/0`. Choose a key pair
  that you know you have access to.
* Review all your settings and launch. It will take several minutes for the
  instance to boot up.

Once the instance has started, do this on your local machine:
```bash
INSTANCE=ec2-52-1-12-222.compute-1.amazonaws.com     # for example
scp -i ~/.ec2/ec2.pem prep.sh ubuntu@${INSTANCE}:~
scp -i ~/.ec2/ec2.pem cruft.uue ubuntu@${INSTANCE}:~
ssh -i ~/.ec2/ec2.pem ubuntu@${INSTANCE}
```

Having SSHed into the instance, run `prep.sh`. Then you can cd into the `eb-flaskapp`
directory and run the `go.sh` script. This will start a server process that runs
the app.
