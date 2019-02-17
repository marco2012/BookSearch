#!flask/bin/python
from flask import Flask, jsonify, abort, make_response, request, send_from_directory
import sqlite3, json, logging, re
from flask_httpauth import HTTPBasicAuth
app = Flask(__name__)

db = sqlite3.connect("booksdb",check_same_thread = False)
cursor = db.cursor()
date_format = "%Y-%m-%d"
timestamp_format = re.compile('\d\d\d\d-\d?\d-\d?\dT\d\d:\d\d:\d\d.\d{6}Z')

handler = logging.FileHandler('server.log', mode='a', encoding=None, delay=False)
handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
app.logger.setLevel(logging.DEBUG)
app.logger.addHandler(handler)

auth = HTTPBasicAuth()

@auth.get_password
def get_password(username):
    data = []
    try:
        for line in open('user.cfg','r'):
            data.append(line)
    except IOError:
        abort(500)
    usern = str(data[1]).replace(' ','')
    pwd = str(data[2]).replace(' ','')
    if username == usern[9:-1]:
        return pwd[9:-1]
    return None

@app.route('/sendimg', methods=['POST'])
@auth.login_required
def sendimg():
    app.logger.info('[POST] request to /sendimg from '+request.remote_addr)
    if request.get_json() == None:
        abort(400)
    x=request.get_json()
    cursor.execute('INSERT INTO imgbooks (book, img) VALUES ("' +x['isbn'].strip()+ '","' +x['img']+ '")')
    db.commit()
    return jsonify({'success' : 'task executed'})

@app.route('/getimg', methods=['POST'])
@auth.login_required
def getimg():
    app.logger.info('[POST] request to /sendimg from '+request.remote_addr)
    if request.get_json() == None:
        abort(400)
    x=request.get_json()
    mb=cursor.execute('select img from imgbooks where book="'+x['isbn']+'";').fetchone()
    return json.dumps(mb)

@app.route('/purchase', methods=['POST'])
@auth.login_required
def purchase():
    app.logger.info('[POST] request to /purchase from '+request.remote_addr)
    if request.get_json() == None:
        abort(400)
    x=request.get_json()
    cursor.execute('INSERT INTO books (book, user) VALUES ("' +x['title']+ ' ","' +x['email']+ '")')
    db.commit()
    return jsonify({'success' : 'task executed'})

@app.route('/mybooks', methods=['POST'])
@auth.login_required
def mybooks():
    app.logger.info('[POST] request to /purchase from '+request.remote_addr)
    if request.get_json() == None:
        abort(400)
    x=request.get_json()
    mb=cursor.execute('Select book from books where user="'+x['email']+'";').fetchall()
    l = []
    for i in mb:
        l.append(i[0])
    s=list(set(l))
    return json.dumps(s)

if __name__ == '__main__':
    app.run(host='192.168.43.192')

db.close()
