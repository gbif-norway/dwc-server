#!/usr/bin/python
# encoding: utf-8

import re
import sys
import time
import datetime

import unicodecsv
import sqlalchemy as sql

if len(sys.argv) < 2:
  sys.exit()

dbname = sys.argv[1]

engine = sql.create_engine("mysql://root@localhost")

conn = engine.connect()
conn.execute("commit")
conn.execute("drop database %s" % dbname)

conn.execute("create database %s" % dbname)
conn.close()

engine = sql.create_engine("mysql://root@localhost/%s"
    % dbname)
metadata = sql.MetaData()

sql.Table('main', metadata).drop(engine, checkfirst=True)

metadata = sql.MetaData()
main = sql.Table('main', metadata,
    sql.Column('DateLastModified', sql.Date),
    sql.Column('InstitutionCode', sql.Unicode(30)),
    sql.Column('CollectionCode', sql.Unicode(30)),
    sql.Column('CatalogNumber', sql.Unicode(45)),
    sql.Column('ScientificName', sql.Unicode(100)),
    sql.Column('BasisOfRecord', sql.Unicode(18)),
    sql.Column('Kingdom', sql.Unicode(10)),
    sql.Column('Phylum', sql.Unicode(20)),
    sql.Column('Class', sql.Unicode(25)),
    sql.Column('Orde_r', sql.Unicode(28)),
    sql.Column('Family', sql.Unicode(25)),
    sql.Column('Genus', sql.Unicode(40)),
    sql.Column('Species', sql.Unicode(30)),
    sql.Column('Subspecies', sql.Unicode(36)),
    sql.Column('ScientificNameAuthor', sql.Unicode(100)),
    sql.Column('IdentifiedBy', sql.Unicode(300)),
    sql.Column('YearIdentified', sql.Unicode(10)),
    sql.Column('MonthIdentified', sql.Unicode(10)),
    sql.Column('DayIdentified', sql.Unicode(10)),
    sql.Column('TypeStatus', sql.Unicode(20)),
    sql.Column('CollectorNumber', sql.Unicode(60)),
    sql.Column('FieldNumber', sql.Unicode(32)),
    sql.Column('Collector', sql.Unicode(320)),
    sql.Column('YearCollected', sql.Unicode(10)),
    sql.Column('MonthCollected', sql.Unicode(10)),
    sql.Column('DayCollected', sql.Unicode(10)),
    sql.Column('JulianDay', sql.Integer()),
    sql.Column('TimeOfDay', sql.Unicode(10)),
    sql.Column('ContinentOcean', sql.Unicode(30)),
    sql.Column('Country', sql.Unicode(50)),
    sql.Column('StateProvince', sql.Unicode(60)),
    sql.Column('County', sql.Unicode(60)),
    sql.Column('Locality', sql.Unicode(2200)),
    sql.Column('Longitude', sql.Unicode(50)),
    sql.Column('Latitude', sql.Unicode(50)),
    sql.Column('CoordinatePrecision', sql.Unicode(50)),
    sql.Column('BoundingBox', sql.Unicode(50)),
    sql.Column('MinimumElevation', sql.Unicode(50)),
    sql.Column('MaximumElevation', sql.Unicode(50)),
    sql.Column('MinimumDepth', sql.Unicode(50)),
    sql.Column('MaximumDepth', sql.Unicode(50)),
    sql.Column('Sex', sql.Unicode(32)),
    sql.Column('PreparationType', sql.Unicode(50)),
    sql.Column('IndividualCount', sql.Unicode(15)),
    sql.Column('PreviousCatalogNumber', sql.Unicode(10)),
    sql.Column('RelationshipType', sql.Unicode(10)),
    sql.Column('RelatedCatalogItem', sql.Unicode(10)),
    sql.Column('Notes', sql.Unicode(3003)),
    sql.Column('CollectingMethod', sql.Unicode(100)),
    sql.Column('IdentificationPrecision', sql.Unicode(10)),
    sql.Column('Okologi', sql.Unicode(2000)),
    sql.Column('Habitat', sql.Unicode(512)),
    sql.Column('Substrat', sql.Unicode(60)),
    sql.Column('UTMsone', sql.Unicode(10)),
    sql.Column('UTMost', sql.Unicode(30)),
    sql.Column('UTMnord', sql.Unicode(30)),
    sql.Column('MGRSfra', sql.Unicode(40)),
    sql.Column('MGRStil', sql.Unicode(40)),
    sql.Column('Koordinatkilde', sql.Unicode(2)),
    sql.Column('ElevationKilde', sql.Unicode(2)),
    sql.Column('Status', sql.Unicode(30)),

    sql.Column('NRikeID', sql.Integer()),
    sql.Column('NRekkeID', sql.Integer()),
    sql.Column('NKlasseID', sql.Integer()),
    sql.Column('NOrdenID', sql.Integer()),
    sql.Column('NFamilieID', sql.Integer()),
    sql.Column('NSlektID', sql.Integer()),
    sql.Column('NArtID', sql.Integer()),
    sql.Column('NUartID', sql.Integer()),

    sql.Column('NorskNavnGruppe', sql.Unicode(25)),
    sql.Column('NorskNavnOrden', sql.Unicode(25)),
    sql.Column('NorskNavnFamilie', sql.Unicode(25)),
    sql.Column('NorskNavnSlekt', sql.Unicode(25)),
    sql.Column('NorskNavnArt', sql.Unicode(25)),

    sql.Column('PolygonID', sql.Unicode(25)),
    sql.Column('RelativeAbundance', sql.Unicode(25)),
    sql.Column('Antropokor', sql.Unicode(25)),
    sql.Column('URL', sql.Unicode(256)),

    sql.Column('PLokalitet', sql.Unicode(25)),
    sql.Column('PLongitude', sql.Unicode(25)),
    sql.Column('PLatitude', sql.Unicode(25)),
    sql.Column('PCoordinatePrecision', sql.Unicode(25)),
    sql.Column('SpeciesUnmatched', sql.Unicode(25)),
    sql.Column('CoordinateRemoved', sql.Unicode(25)),
    sql.Column('GBIF_recordNumber', sql.Unicode(25)),
    sql.Column('GBIF_resourceNumber', sql.Unicode(25)),
    sql.Column('OccurrenceID', sql.Unicode(64)),
    sql.Column('AssociatedMedia', sql.Unicode(256)),

    sql.Column('verbatimElevation', sql.Unicode(60)),
    sql.Column('verbatimDepth', sql.Unicode(60)),
    sql.Column('lifeStage', sql.Unicode(60)),
    sql.Column('occurrenceRemarks', sql.Unicode(450)),
    sql.Column('identificationQualifier', sql.Unicode(60)),
    sql.Column('georeferenceRemarks', sql.Unicode(60)),
    sql.Column('datasetName', sql.Unicode(60)),
    sql.Column('organismID', sql.Unicode(60)),
    sql.Column('verbatimCoordinateSystem', sql.Unicode(60)),
    sql.Column('verbatimCoordinates', sql.Unicode(60)),
    sql.Column('verbatimSRS', sql.Unicode(60)),

)

metadata.create_all(engine, checkfirst=True)

connection = engine.connect()
#connection.set_character_set('utf8')
connection.execute('SET NAMES utf8;')
connection.execute('SET CHARACTER SET utf8;')
connection.execute('SET character_set_connection=utf8;')

reader = unicodecsv.DictReader(sys.stdin, delimiter='\t')
for raw in reader:
  row = {}
  try:
    modified = datetime.datetime.strptime(raw['modified'], "%Y-%m-%d")
  except:
    modified = None
  row['DateLastModified'] = modified
  row['InstitutionCode'] = raw['institutionCode']
  row['CollectionCode'] = raw['collectionCode']
  row['CatalogNumber'] = raw['catalogNumber']
  row['ScientificName'] = raw['scientificName']
  row['BasisOfRecord'] = raw['basisOfRecord']

  row['Kingdom'] = raw['kingdom']
  row['Phylum'] = raw['phylum']
  row['Class'] = raw['class']
  row['Orde_r'] = raw['order']
  row['Family'] = raw['family']
  row['Genus'] = raw['genus']
  row['Species'] = raw['specificEpithet']
  row['Subspecies'] = raw['infraspecificEpithet']

  row['ScientificNameAuthor'] = raw['scientificNameAuthorship']

  row['IdentifiedBy'] = raw['identifiedBy']
  if raw['dateIdentified'].find("-") >= 0:
    yearid, monthid, dayid = raw['dateIdentified'].split('-')
    row['YearIdentified'] = yearid
    row['MonthIdentified'] = monthid
    row['DayIdentified'] = dayid
  else:
    row['dateIdentified'] = ""

  row['TypeStatus'] = raw['typeStatus']
  row['CollectorNumber'] = raw['recordNumber']
  row['FieldNumber'] = raw['fieldNumber']

  row['Collector'] = raw['recordedBy']

  row['YearCollected'] = raw['year']
  row['MonthCollected'] = raw['month']
  row['DayCollected'] = raw['day']
  row['JulianDay'] = None
  row['TimeOfDay'] = raw['eventTime']
  row['ContinentOcean'] = raw['continent']

  row['Country'] = raw['country']
  row['StateProvince'] = raw['stateProvince']
  row['County'] = raw['county']
  row['Locality'] = raw['locality']

  row['Longitude'] = raw['decimalLongitude']
  row['Latitude'] = raw['decimalLatitude']
  row['CoordinatePrecision'] = raw['coordinateUncertaintyInMeters']
  row['BoundingBox'] = ""

  row['MinimumElevation'] = raw['minimumElevationInMeters']
  row['MaximumElevation'] = raw['maximumElevationInMeters']
  row['MinimumDepth'] = raw['minimumDepthInMeters']
  row['MaximumDepth'] = raw['maximumDepthInMeters']
  row['Sex'] = raw['sex']
  row['PreparationType'] = raw['preparations']
  row['IndividualCount'] = raw['individualCount']
  row['PreviousCatalogNumber'] = raw['otherCatalogNumbers']
  row['RelationshipType'] = ""
  row['RelatedCatalogItem'] = ""

  row['Notes'] = raw['occurrenceRemarks']
  row['CollectingMethod'] = raw['samplingProtocol']
  row['IdentificationPrecision'] = ""
  row['Okologi'] = ""
  row['Habitat'] = raw['habitat']
  row['Substrat'] = ""

  row['OccurrenceID'] = raw['occurrenceID']
  row['URL'] = raw['associatedMedia']
  row['associatedMedia'] = raw['associatedMedia']

  row['verbatimElevation'] = raw['verbatimElevation']
  row['verbatimDepth'] = raw['verbatimDepth']
  row['occurrenceRemarks'] = raw['occurrenceRemarks']
  row['georeferenceRemarks'] = raw.get('georeferenceRemarks')
  row['datasetName'] = raw.get('datasetName')
  row['organismID'] = raw.get('organismID')
  row['verbatimCoordinateSystem'] = raw.get('verbatimCoordinateSystem')
  row['verbatimCoordinates'] = raw.get('verbatimCoordinates')
  row['verbatimSRS'] = raw.get('verbatimSRS')

  try:
    if raw['verbatimCoordinateSystem'] == "UTM":
      utms, utme, utmn = re.split("[, ]", raw['verbatimCoordinates'])
      row['UTMnord'] = utmn
      row['UTMsone'] = utms
      row['UTMost'] = utme
    elif raw['verbatimCoordinateSystem'] == "MGRS":
      raw['MGRSfra'] = raw['verbatimCoordinates']
    elif raw['verbatimCoordinateSystem'] == "decimal degrees":
      pass
    elif raw['verbatimCoordinateSystem'] == "degrees minutes seconds":
      pass
    elif raw['verbatimCoordinateSystem'] == "Unknown":
      pass
    elif raw['verbatimCoordinateSystem'] == "unknown":
      pass
    elif raw['verbatimCoordinateSystem'] == "":
      pass
    else:
      pass
  except Exception:
    pass
    # sys.stdout.write("Eh eh %s\n" % raw['verbatimCoordinateSystem'])

  connection.execute(main.insert(), row)

