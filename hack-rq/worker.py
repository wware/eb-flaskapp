#!/usr/bin/env python

import sys
from rq import Queue, Connection, Worker
import task

with Connection():
    qs = map(Queue, sys.argv[1:]) or [Queue()]
    w = Worker(qs)
    w.work()
