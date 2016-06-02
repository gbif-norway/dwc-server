package DwC;

use strict;
use utf8;
use 5.14.0;

use Module::Pluggable require => 1, sub_name => '_plugins';

our @PLUGINS = _plugins();
sub plugins { @PLUGINS }

sub new {
  my $me = shift;
  my $record = shift;
  $$record{_row} = shift;
  $$record{info} = [];
  $$record{errors} = [];
  $$record{warnings} = [];
  return bless $record;
}

our @terms = (
  "occurrenceID",
  "modified", "institutionCode", "collectionCode", "catalogNumber",
  "scientificName", "basisOfRecord",
  "kingdom", "phylum", "class", "order", "family", "genus",
  "specificEpithet", "infraspecificEpithet","scientificNameAuthorship",
  "identifiedBy", "dateIdentified",
  "typeStatus", "recordNumber", "fieldNumber", "recordedBy",
  "eventDate", "year", "month", "day", "startDayOfYear", "eventTime",
  "continent", "country", "stateProvince", "county", "municipality", "locality",
  "decimalLongitude", "decimalLatitude", "coordinateUncertaintyInMeters",
  "geodeticDatum",
  "verbatimElevation", "minimumElevationInMeters", "maximumElevationInMeters",
  "verbatimDepth", "minimumDepthInMeters", "maximumDepthInMeters",
  "sex", "preparations", "individualCount",
  "otherCatalogNumbers", "eventID", "locationID",
  "occurrenceRemarks", "samplingProtocol", "identificationRemarks",
  "habitat", "footprintWKT",
  "verbatimLatitude", "verbatimLongitude",
  "verbatimCoordinateSystem", "verbatimCoordinates", "verbatimSRS",
  "associatedMedia", "organismID", "individualID", "datasetKey", "license"
);

sub triplet {
  my $me = shift;
  return "$$me{institutionCode}:$$me{collectionCode}:$$me{catalogNumber}"
}

sub log {
  my ($dwc, $level, $message, $type) = @_;
  $message  =~ s/\n$//;
  push(@{$$dwc{$level}}, [ $message, $type ]);
}

sub printcsv {
  my ($me, $handle, $fields) = @_;
  my $row = join("\t", @{$me}{@$fields});
  $row =~ s/\"/'/g;
  say $handle $row;
}

