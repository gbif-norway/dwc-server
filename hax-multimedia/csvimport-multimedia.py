#!/usr/bin/python
# encoding: utf-8

import re
import sys
import time
import datetime
import emails
import unicodecsv
import sqlalchemy as sql

if len(sys.argv) < 2:
  sys.exit()

dbname = sys.argv[1]
core_file = open(sys.argv[2], 'r')
engine = sql.create_engine("mysql://root@localhost")
conn = engine.connect()
conn.execute("commit")
try:
  conn.execute("create database %s CHARACTER SET utf8;" % dbname)
except:
  pass
conn.close()

engine = sql.create_engine("mysql://root@localhost/%s" % dbname)
metadata = sql.MetaData()
sql.Table('work', metadata).drop(engine, checkfirst=True)
reader = unicodecsv.DictReader(core_file, delimiter='\t')
metadata = sql.MetaData()
columns = [sql.Column(column_name, sql.Text()) for column_name in reader.fieldnames]
work = sql.Table('work', metadata, *columns)
metadata.create_all(engine, checkfirst=True)
connection = engine.connect()
connection.execute('SET NAMES utf8;')
connection.execute('SET CHARACTER SET utf8;')
connection.execute('SET character_set_connection=utf8;')
for row in reader:
  connection.execute(work.insert(), row)

hasmain = engine.dialect.has_table(connection, "main")

if hasmain:
  existing = connection.execute("SELECT count(*) FROM main").fetchone()[0]
  potential = connection.execute("SELECT count(*) FROM work").fetchone()[0]
  import pdb; pdb.set_trace()
  if existing - potential >= 10:
    msg = emails.Message(subject="[gbif.no] reduksjon i antall poster (%s)" % dbname, text="Færre poster i %s enn ved forrige publisering!\nFra %s til %s.\nFortsetter som normalt." % (dbname, existing, potential), mail_from="noreply@data.gbif.no")
    msg.send(to="christian.svindseth@nhm.uio.no")
    msg.send(to="gbif-drift@nhm.uio.no")
    msg.send(to="b.p.lofall@nhm.uio.no")
  if (existing / 2) > potential:
    msg = emails.Message(subject="[gbif.no] voldsom reduksjon i antall poster (%s)" % dbname, text="Færre poster i %s enn ved forrige publisering!\nFra %s til %s.\nAvbryter dataimport." % (dbname, existing, potential), mail_from="noreply@data.gbif.no")
    msg.send(to="christian.svindseth@nhm.uio.no")
    msg.send(to="gbif-drift@nhm.uio.no")
    msg.send(to="b.p.lofall@nhm.uio.no")
    sys.exit()

transaction = connection.begin()
try:
  if hasmain: connection.execute("DROP TABLE main")
  connection.execute("RENAME TABLE work TO main")
  transaction.commit()
except:
  transaction.rollback()
  raise

