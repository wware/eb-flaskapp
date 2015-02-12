#!/usr/bin/env python

"""
Assumes that you have a PostgreSQL user with username and password both
"postgres", and that the DB "mydb" either doesn't exist or is expendable.

https://help.ubuntu.com/community/PostgreSQL
http://www.sqlalchemy.org/
http://docs.sqlalchemy.org/en/rel_0_9/core/engines.html
http://www.pythoncentral.io/introductory-tutorial-python-sqlalchemy/
"""

from sqlalchemy import create_engine, Column, ForeignKey, Integer, String
from sqlalchemy.orm import scoped_session, sessionmaker, relationship
from sqlalchemy.ext.declarative import declarative_base


# The DB needs to exist before you can create this engine.
engine = create_engine(
    'postgresql://postgres:postgres@localhost/mydb',
    convert_unicode=True)
db_session = scoped_session(sessionmaker(autocommit=False,
                                         autoflush=False,
                                         bind=engine))

# This is the base class for models in SQLAlchemy.
Base = declarative_base()
Base.query = db_session.query_property()


class Entry(Base):
    """
    To get rid of the table and its sequence, without
    dropping the entire DB, type
    $ sudo -u postgres psql mydb
    psql (9.3.5)
    Type "help" for help.

    mydb=# drop table entry cascade;
    mydb=# <control-d>
    """
    __tablename__ = 'entry'
    id = Column(Integer, primary_key=True)
    title = Column(String(250), nullable=False)
    text = Column(String(250), nullable=False)
