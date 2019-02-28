#!/usr/bin/python
# encoding: utf-8

import re
import sys
import time
import datetime

from tokyo import cabinet as tokyocabinet
import sqlalchemy as sql

engine = sql.create_engine("mysql://root@localhost")

conn = engine.connect()
conn.execute("commit")
try:
  conn.execute("drop database bold")
except:
  pass
try:
  conn.execute("create database bold CHARACTER SET utf8;" )
except:
  pass
conn.close()

engine = sql.create_engine("mysql://root@localhost/bold")
metadata = sql.MetaData()

sql.Table('main', metadata).drop(engine, checkfirst=True)

metadata = sql.MetaData()
main = sql.Table('main', metadata,
    sql.Column('dataset', sql.Unicode(64)),
    sql.Column('occurrenceID', sql.Unicode(30)),
    sql.Column('type', sql.Unicode(30)),
    sql.Column('value', sql.Unicode(2048)),
    sql.Column('remarks', sql.Unicode(80)),
    sql.Column('processID', sql.Unicode(80)),
    sql.Column('centers', sql.Unicode(256)),
    sql.Column('date', sql.Unicode(80)),
    sql.Column('marker', sql.Unicode(80)),
    sql.Column('primers', sql.Unicode(80)),
    sql.Column('image', sql.Unicode(256)),
    sql.Column('caption', sql.Unicode(80)),
    sql.Column('photographer', sql.Unicode(80)),
    sql.Column('copyright_year', sql.Unicode(80)),
    sql.Column('copyright_license', sql.Unicode(256)),
    sql.Column('copyright_institution', sql.Unicode(80)),
)

metadata.create_all(engine, checkfirst=True)

connection = engine.connect()
#connection.set_character_set('utf8')
connection.execute('SET NAMES utf8;')
connection.execute('SET CHARACTER SET utf8;')
connection.execute('SET character_set_connection=utf8;')

db = tokyocabinet.TDB()
db.open("bold.db", tokyocabinet.TDBOREADER)

for key in db:
  rec = db.get(key)
  row = {}
  row['dataset'] = "e4deab67-0998-4140-b573-0ba1f624eb3e"
  row["occurrenceID"] = "urn:catalog:" + key
  row["type"] = "BOLD sequence (%s)" % rec['marker']
  row["value"] = rec['sequence']
  row["remarks"] = rec['url']
  row["occurrenceID"] = "urn:catalog:" + key

  row["processID"] = rec['processid']
  row['centers'] = rec['centers']
  row['date'] = rec['date']
  row['marker'] = rec['marker']
  row['primers'] = rec['primers']
  row['image'] = rec['image']
  row['caption'] = rec['caption']
  row['photographer'] = rec['photographer']
  row['copyright_year'] = rec['copyright_year']
  row['copyright_license'] = rec['copyright_license']
  row['copyright_institution'] = rec['copyright_institution']
  
  connection.execute(main.insert(), row)


