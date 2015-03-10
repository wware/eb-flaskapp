Fooling with RQ
====

Info:
* [RQ homepage](http://python-rq.org/)
* [Queues](http://python-rq.org/docs/)
* [Workers](http://python-rq.org/docs/workers/)
* [Job (source)](https://github.com/nvie/rq/blob/master/rq/job.py)

Prerequisites:

```bash
sudo apt-get install redis-server
sudo pip install redis rq
redis-server    # to start redis on your local machine
```

The homepage shows the basic pattern for client code. The simplest way to
start a worker process is just to run `rqworker` in the directory where
the task is defined.

Alternatively you can define the worker explicitly, see `worker.py`.

Then you can run `client.py` to run the task. In a real example, the worker
processes would run on dedicated machines. The `Job`class is the
representation of a piece of work on the client.
