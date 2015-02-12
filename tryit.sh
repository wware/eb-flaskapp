#!/bin/bash

check_ok() {
    if [ "$1" == "$2" ]; then
	echo OK
    else
	echo "Lengths: Got ${#1}, expected ${#2}"
	echo "$1"
	exit 1
    fi
}

echo "DROP DATABASE IF EXISTS mydb;" | sudo -u postgres psql
sudo -u postgres createdb mydb

(python <<EOF
from tr_helper import *
# Create the table for Entry.
Base.metadata.create_all(bind=engine)
EOF
) || exit 1

X=$(echo "\d+" | sudo -u postgres psql mydb)
Y=$(cat <<EOF
                           List of relations
 Schema |     Name     |   Type   |  Owner   |    Size    | Description 
--------+--------------+----------+----------+------------+-------------
 public | entry        | table    | postgres | 8192 bytes | 
 public | entry_id_seq | sequence | postgres | 8192 bytes | 
(2 rows)
EOF
)

check_ok "$X" "$Y"

X=$(echo "SELECT * FROM entry;" | sudo -u postgres psql mydb)
Y=$(cat <<EOF
 id | title | text 
----+-------+------
(0 rows)
EOF
)

check_ok "$X" "$Y"

(python <<EOF
from tr_helper import *
# Create a row in the Entry table.
e = Entry()
e.title, e.text = "my title", "my text"
db_session.add(e)
db_session.commit()
EOF
) || exit 1

X=$(echo "SELECT * FROM entry;" | sudo -u postgres psql mydb)
Y=$(cat <<EOF
 id |  title   |  text   
----+----------+---------
  1 | my title | my text
(1 row)
EOF
)

check_ok "$X" "$Y"

(python <<EOF
from tr_helper import *
# Make sure that a SQLAlchemy query has the expected result.
query = [(e.title, e.text) for e in
         db_session.query(Entry).order_by(Entry.id)]
assert query == [('my title', 'my text')]
EOF
) || exit 1

# Blow away the Entry table but not the database. CASCADE means we're
# also blowing away the ID sequence table.
echo "DROP TABLE entry CASCADE;" | sudo -u postgres psql mydb

# Make sure the mydb DB hasn't disappeared.
X=$(echo "\\l" | sudo -u postgres psql)
Y=$(cat <<EOF
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileges   
-----------+----------+----------+-------------+-------------+-----------------------
 mydb      | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 postgres  | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | 
 template0 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.UTF-8 | en_US.UTF-8 | =c/postgres          +
           |          |          |             |             | postgres=CTc/postgres
(4 rows)
EOF
)

check_ok "$X" "$Y"

X=$(echo "\\d+" | sudo -u postgres psql)
Y=$(cat <<EOF
No relations found.
EOF
)

check_ok "$X" "$Y"
