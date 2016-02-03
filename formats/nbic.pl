use strict;
use utf8;

package GBIFNorway::NBIC;

sub filter {
  my $dwc = {
    'dateLastModified'          =>  $$_{DateLastModified},
    'catalogNumber'             =>  $$_{CatalogNumber},
    'institutionCode'           =>  $$_{InstitutionCode},
    'collectionCode'            =>  $$_{CollectionCode},
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
    'decimalLatitude'           =>  $$_{Latitude},
    'decimalLongitude'          =>  $$_{Longitude},
    'minimumElevation'          =>  $$_{MinimumElevation},
    'maximumElevation'          =>  $$_{MaximumElevation},
    'mimimumDepth'              =>  $$_{MimimumDepth},
    'maximumDepth'              =>  $$_{MaximumDepth},
    'preparations'              =>  $$_{PreparationType},
    'occurrenceRemarks'         =>  $$_{Notes},
    'samplingProtocol'          =>  $$_{CollectingMethod},
    'habitat'                   =>  $$_{Habitat},
    'empty' => ""
  };
  return $dwc;
}

sub clean {
  my $dwc = shift;

  if (!$$dwc{catalogNumber}) {
    $dwc->adderror("Missing catalognumber", "core");
  }
  return $dwc;
}

$GBIFNorway::filters{nbic} = \&GBIFNorway::NBIC::filter;
$GBIFNorway::cleaners{nbic} = \&GBIFNorway::NBIC::clean;
$GBIFNorway::names{nbic} = 1;

1;

