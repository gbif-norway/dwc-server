use strict;
use utf8;

package GBIFNorway::NBIC;

sub filter {
  my $dwc = {
    'modified'          =>  $$_{DateLastModified},
    'catalogNumber'             =>  $$_{CollectionCode},
    'institutionCode'           =>  $$_{InstitutionCode},
    #'collectionCode'            =>  $$_{CollectionCode},
    'datasetName'               =>  $$_{DatasetName},
    'scientificName'            =>  $$_{ScientificName},
    'basisOfRecord'             =>  $$_{BasisOfRecord},
    'kingdom'                   =>  $$_{Kingdom},
    'phylum'                    =>  $$_{Phylum},
    'class'                     =>  $$_{Class},
    'order'                     =>  $$_{Order},
    'family'                    =>  $$_{Family},
    'genus'                     =>  $$_{Genus},
    'specificEpithet'           =>  $$_{Species},
    'infraspecificEpithet'      =>  $$_{Subspecies},
    'scientificNameAuthorship'  =>  $$_{ScientificNameAuthor},
    'identifiedBy'              =>  $$_{IdentifiedBy},
    'recordNumber'              =>  $$_{FieldNumber},
    'recordedBy'                =>  $$_{Collector},
    'year'                      =>  $$_{YearCollected},
    'month'                     =>  $$_{MonthCollected},
    'day'                       =>  $$_{DayCollected},
    'country'                   =>  $$_{Country},
    'stateProvince'             =>  $$_{StateProvince},
    'county'                    =>  $$_{County},
    'locality'                  =>  $$_{Locality},
    'decimalLatitude'           =>  $$_{Longitude},
    'decimalLongitude'          =>  $$_{Latitude},
    'minimumElevationInMeters'          =>  $$_{MinimumElevation},
    'maximumElevationInMeters'          =>  $$_{MaximumElevation},
    'mimimumDepthInMeters'              =>  $$_{MimimumDepth},
    'maximumDepthInMeters'              =>  $$_{MaximumDepth},
    'preparations'              =>  $$_{PreparationType},
    'occurrenceRemarks'         =>  $$_{Notes},
    'samplingProtocol'          =>  $$_{CollectingMethod},
    'habitat'                   =>  $$_{Habitat},
    'coordinateUncertaintyInMeters' => $$_{CoordinatePrecision},
    'occurrenceRemarks' => "$$_{Okologi} $$_{Substrat}",
    #'e' => $$_{UTMost},
    #'n' => $$_{UTMnord},
    'empty' => ""
  };
  return $dwc;
}

sub clean {
  my $dwc = shift;

  # Hm?
  #$$dwc{verbatimCoordinateSystem} = "UTM";
  #$$dwc{verbatimCoordinates} = "32V " . $$dwc{e} . " " . $$dwc{n};

  #my $year = substr $$dwc{modified}, 0, 4;
  #my $month = substr $$dwc{modified}, 4, 2;
  #my $day = substr $$dwc{modified}, 6, 2;
  #$$dwc{modified} = "$year-$month-$day";

  if (!$$dwc{catalogNumber}) {
    $dwc->adderror("Missing catalognumber", "core");
  }
  return $dwc;
}

$GBIFNorway::filters{nbic} = \&GBIFNorway::NBIC::filter;
$GBIFNorway::cleaners{nbic} = \&GBIFNorway::NBIC::clean;
$GBIFNorway::names{nbic} = 1;

1;

