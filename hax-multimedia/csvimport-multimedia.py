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
with open(sys.argv[2], 'r') as core_file:
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

  # Column names
  occurrence_id = True
  column_names = reader.fieldnames
  if 'OCCURRENCEID' not in column_names:
    if 'INSTITUTIONCODE' not in column_names and 'COLLECTIONCODE' not in column_names and 'CATALOGNUMBER' not in column_names:
      import pdb; pdb.set_trace()
    occurrence_id = False
    column_names.append('occurrenceid')
  columns = [sql.Column(column_name, sql.Text()) for column_name in column_names]
  work = sql.Table('work', metadata, *columns)
  metadata.create_all(engine, checkfirst=True)
  connection = engine.connect()
  connection.execute('SET NAMES utf8;')
  connection.execute('SET CHARACTER SET utf8;')
  connection.execute('SET character_set_connection=utf8;')

  for row in reader:
    row_for_insertion = row
    # Christian set it to https://github.com/gbif-norway/dwc-server/blob/238614ab502e3a70ad4b6539f07dc1d1bb3d8d29/bin/dwclean#L111
    if not occurrence_id:
      row_for_insertion['occurrenceid'] = 'urn:catalog:' + row['INSTITUTIONCODE'] + ':' + row['COLLECTIONCODE'] + ':' + row['CATALOGNUMBER'] 
    connection.execute(work.insert(), row_for_insertion)

  hasmain = engine.dialect.has_table(connection, "main")

  if hasmain:
    existing = connection.execute("SELECT count(*) FROM main").fetchone()[0]
    potential = connection.execute("SELECT count(*) FROM work").fetchone()[0]
    print('%s existing %s, potential: %s' % (dbname, existing, potential))
    if existing - potential >= 10:
      msg = emails.Message(subject="[gbif.no] reduction in number of multimedia records (%s)" % dbname, text="Fewer multimedia recors in  %s from %s to %s." % (dbname, existing, potential), mail_from="noreply@data.gbif.no")
      msg.send(to="helpdesk@gbif.no")
    if (existing / 2) > potential:
      msg = emails.Message(subject="[gbif.no] Extreme reduction in number of multimedia records (%s)" % dbname, text="Fewer multimedia recors in  %s from %s to %s. Import stopped." % (dbname, existing, potential), mail_from="noreply@data.gbif.no")
      msg.send(to="helpdesk@gbif.no")
      sys.exit()

  transaction = connection.begin()
  try:
    if hasmain: connection.execute("DROP TABLE main")
    connection.execute("RENAME TABLE work TO main")
    transaction.commit()
  except:
    transaction.rollback()
    msg = emails.Message(subject="[gbif.no] Failed to drop table main for %s" % dbname, text="%s from %s to %s. Import stopped." % (dbname, existing, potential), mail_from="noreply@data.gbif.no")
    msg.send(to="helpdesk@gbif.no")
    raise

