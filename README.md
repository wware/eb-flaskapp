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

Deployment
----

First, do this (or whatever is equivalent) on your development machine.

```bash
sudo apt-get install -y ec2-ami-tools ec2-api-tools
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
