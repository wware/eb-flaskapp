import logging
import sys

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

from flask import (
    Flask,
    session,
    render_template,
    request,
    flash,
    redirect,
    url_for,
    abort
)
from flask.ext.login import (
    LoginManager,
    login_user,
    logout_user,
    current_user,
    login_required,
    UserMixin
)


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

application = Flask(__name__, static_url_path="")
application.secret_key = "bar"

login_manager = LoginManager()
login_manager.init_app(application)
login_manager.login_view = "login"


class Doc(Base):
    """
    To get rid of the table and its sequence, without
    dropping the entire DB, type
    $ sudo -u postgres psql mydb
    psql (9.3.5)
    Type "help" for help.

    mydb=# drop table entry cascade;
    mydb=# <control-d>
    """
    __tablename__ = 'doc'
    id = Column(Integer, primary_key=True)
    title = Column(String(128), nullable=False)
    text = Column(String(4096), nullable=False)


class User(UserMixin):
    def __init__(self, id):
        self.id = id

foo = User('foo')

@login_manager.user_loader
def load_user(userid):
    if userid == 'foo':
        return foo
    else:
        return None

@application.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))

@application.route('/')
def index():
    logger.info("enter index")
    return render_template('index.html')

@application.route('/doc/<docnum>', methods=["GET", "POST"])
@login_required
def doc(docnum):
    logger.info("doc " + str(docnum))
    docnum = int(docnum, 10)
    doc = db_session.query(Doc).filter(Doc.id==docnum)[0]
    if request.method == 'POST':
        doc.text = request.form['text']
        db_session.flush()
        return redirect("/")
    else:
        session["docnum"] = docnum
        session["title"] = doc.title
        session["text"] = doc.text
        return render_template('doc.html')


@application.route("/login", methods=["GET", "POST"])
def login():
    logger.info("enter login")
    if request.method == 'POST':
        if request.form['username'] == 'foo' and request.form['password'] == 'bar':
            login_user(foo, remember=True)
            logger.info("login redirect")
            return redirect(request.args.get("next") or url_for("index"))
        else:
            logger.info("login error")
            flash('Incorrect username or password. Try again.', 'error')

    logger.info("login render template")
    return render_template("login.html");

if __name__ == "__main__":
    if 'init' in sys.argv[1:]:
        Base.metadata.create_all(bind=engine)
        raise SystemExit
    application.run(host="0.0.0.0", debug=True)
