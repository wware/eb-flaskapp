Fun with Ansible
====

I'm working from the book [Ansible for AWS](https://leanpub.com/ansible-for-aws)
([Github repo](https://github.com/yankurniawan/ansible-for-aws)).
I've had to do a couple of small things. For instance I need a
[fresher version of Ansible](http://docs.ansible.com/intro_installation.html#latest-releases-via-apt-ubuntu)
than the one Ubuntu offers.

```bash
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ansible/ansible
sudo apt-get update
sudo apt-get install ansible
```

To spin up my little AWS setup, I need to do this:

```bash
export AWS_ACCESS_KEY=AAAAAAAAAAAAAAAAAAAA
export AWS_SECRET_KEY=BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
./everybody.sh
```

My plan is to make the Redis/RQ stuff work in a couple of instances. The client
instance should be publicly available and probably offer a flask app that enqueues
a call to the `count_words_at_url` function, and a back-office worker instance
that does the work.

Hmm, I've hit a glitch. I've defined roles that should populate my two instances
with some files, and eventually make them run the right code. But there appear to
be two unrelated tracks of development.
* One involves site.yml and the hosts file and it picks up the roles, but it
  doesn't do anything with setting up all the stuff I've been doing with the
  VPC and security groups and subnets and instances.
* The other is the stuff I've done here, basically most of chapter 6 in the
  *Ansible for AWS* book.

Also I can't talk to my worker instance. I did these things to TEMPORARILY
make the worker publicly SSH-able.
* Switch the worker into the client security group, making it publicly visible.
* Allocate an Elastic IP for it, and associate it with that IP.
* Add a "0.0.0.0/0 igw-1234abcd" rule to the private subnet, also needed to make it
  publicly visible.

My conclusion is that Ansible is not supposed to do everything in one big command
invocation. You can't maintain idempotency that way. You need to do things in
stages, and you enjoy idempotency at each stage.
* Set up your VPC, security groups, subnets, and instances, making all the instances
  publicly reachable. (PROBLEMATIC: there is a limit of five Elastic IPs - but maybe
  a solution to that will be forthcoming.)
* Deploy code on everybody using the site.yml/roles stuff.
* Bury the instances that are supposed to be buried and release their Elastic IPs.
  Enforce privacy and correct routing as needed.

I'm not sure this is correct.

SSH cleverness
----

Once you've set up instances, you can set up chained SSH access like this.

```bash
$ scp -i ~/.ec2/ec2.pem ~/.ec2/ec2.pem ubuntu@public-ip:~
$ scp -i ~/.ec2/ec2.pem ~/.ssh/id_dsa.pub ubuntu@public-ip:~/pubkey
$ ssh -i ~/.ec2/ec2.pem ubuntu@public-instance-blah
public$ cat pubkey >> ~/.ssh/authorized_keys
public$ chmod 400 ec2.pem
public$ scp -i ec2.pem pubkey ubuntu@10.0.1.hidden:~
public$ ssh -i ec2.pem ubuntu@10.0.1.hidden
hidden$ cat pubkey >> ~/.ssh/authorized_keys
hidden$ rm pubkey
hidden$ exit
public$ rm ec2.pem pubkey
public$ exit
```

The chaining uses SSH agent (the "-A" command line option). Here's how.

```bash
$ ssh -A ubuntu@public-instance-blah
public_inst$ ssh ubuntu@10.0.1.private
private$ # VOILA, you're in
private$ exit
public_inst$ exit
```

Configuring instances
----

I've been doing a lot of trial and error trying to get Ansible to configure my instances
using all that "roles" stuff. I am not having any luck with it and my patience for it is
wearing thin. So I'm going to try a different approach.

I'm going to prepare AMI images with the configuration already done. This little project
will use two images, a client and a worker. To prepare each image I will start with a
clean Ubuntu AMI on the public subnet (since I need that to reach apt repositories) and
configure everything via SSH. I'll write down the AMI IDs, which I'll then use in
`create_instances.sh`.

The preamble for both images is this.

```bash
sudo add-apt-repository ppa:rwky/redis
sudo apt-get update
sudo apt-get install -y python-pip redis-server
sudo pip install rq requests
```

The worker image has some more preamble.

```bash
cat << EOF > redis-server.conf
description "redis server"
start on runlevel [23]
stop on shutdown
exec sudo -u redis /usr/bin/redis-server /etc/redis/redis.conf
respawn
EOF
sudo cp redis-server.conf /etc/init

sudo sed -i 's/^daemonize yes/daemonize no/' /etc/redis/redis.conf
```

Both images have the file `task.py` in the ubuntu user's home directory.

```python
import requests

def count_words_at_url(url):
    resp = requests.get(url)
    return len(resp.text.split())
```

The client task has this `run.py` script as well.

```python
#!/usr/bin/env python

import time
from rq import Queue
from redis import Redis
from task import count_words_at_url

# Tell RQ what Redis connection to use
redis_conn = Redis(host="10.0.1.128")
q = Queue(connection=redis_conn)  # no args implies the default queue

# Delay execution of count_words_at_url('http://nvie.com')
job = q.enqueue(count_words_at_url, 'http://nvie.com')
print job.result   # => None

# Wait until the worker is finished
time.sleep(2)
print job.result   # => 889
```

The worker has a `worker.py` script.

```python
#!/usr/bin/env python
import os
import sys
from rq import Queue, Connection, Worker

pathname = os.path.dirname(sys.argv[0])
sys.path.insert(0, pathname)

import task

with Connection():
    qs = map(Queue, sys.argv[1:]) or [Queue()]
    w = Worker(qs)
    w.work()
```

and the line `@reboot /home/ubuntu/worker.py` has been added to the ubuntu user's crontab.

Allowing the worker instances to have internet access
----

In order to do this, you need to
[set up a NAT instance](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html),
which is a third instance in my little network.

What I wonder is, could I let my public instance do this? Is it really necessary to
set up a third instance? Probably there is a security benefit. If somebody hacks the
NAT instance, they haven't hacked your application server.