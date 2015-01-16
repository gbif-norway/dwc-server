use strict;
use utf8;

package GBIFNorway::NODwC;

sub filter {
  my $dwc = {
    'dateLastModified'          =>  $$_[0],
    'institutionCode'           =>  $$_[1],
    'collectionCode'            =>  $$_[2],
    'catalogNumber'             =>  $$_[3],
    'scientificName'            =>  $$_[4],
    'basisOfRecord'             =>  "Preserved specimen", 
    'kingdom'                   =>  $$_[6],
    'phylum'                    =>  $$_[7],
    'class'                     =>  $$_[8],
    'order'                     =>  $$_[9],
    'family'                    =>  $$_[10],
    'genus'                     =>  $$_[11],
    'specificEpithet'           =>  $$_[12],
    'infraspecificEpithet'      =>  $$_[13],
    'scientificNameAuthorship'  =>  $$_[14],
    'identifiedBy'              =>  $$_[15],
    'dateIdentified'            =>  "$$_[16]-$$_[17]-$$_[18]",
    'typeStatus'                =>  $$_[19],
    'recordNumber'              =>  $$_[20],
    'fieldNumber'               =>  $$_[21],
    'recordedBy'                =>  $$_[22],
    'year'                      =>  $$_[23],
    'month'                     =>  $$_[24],
    'day'                       =>  $$_[25],
    'startDayOfYear'            =>  $$_[26], # JulianDay 
    'endDayOfYear'              =>  $$_[26], # JulianDay igjen
    'eventTime'                 =>  $$_[27],
    'continent'                 =>  $$_[28], # ContinentOcean, hm
    'country'                   =>  $$_[29],
    'stateProvince'             =>  $$_[30],
    'county'                    =>  $$_[31],
    'locality'                  =>  $$_[32],

    'verbatimLongitude'         =>  $$_[33],
    'verbatimLatitude'          =>  $$_[34],

    'verbatimLongitude'         =>  $$_[33],
    'verbatimLatitude'          =>  $$_[34],

    'coordinateUncertaintyInMeters' =>  $$_[35],
    'minimumElevationInMeters'  =>  $$_[37],
    'maximumElevationInMeters'  =>  $$_[38],
    'minimumDepthInMeters'      =>  $$_[39],
    'maximumDepthInMeters'      =>  $$_[40],
    'sex'                       =>  $$_[41],
    'preparations'              =>  $$_[42],
    'individualCount'           =>  $$_[43],
    'otherCatalogNumbers'       =>  $$_[44],
    'occurrenceRemarks'         =>  $$_[47],
    'samplingProtocol'          =>  $$_[48],
    'identificationRemarks'     =>  $$_[49],
    'habitat'                   =>  $$_[51],
    'georeferenceSources'       =>  $$_[58],
    'associatedMedia'           =>  $$_[70],
    'dcterms:license'           =>  $$_[71],

    'verbatimCoordinates'       =>  $$_[68],
    'verbatimSRS'               =>  $$_[69],

    'occurrenceID'              =>  $$_[73],
    
    # hm
    'decimalLongitude'          =>  "",
    'decimalLatitude'           =>  "",

    'geodeticDatum'             => "",

    # "norsk tillegg"
    'empty' => ""
  };
  return $dwc;
}

sub clean {
  my $dwc = shift;

  $$dwc{verbatimCoordinateSystem} = "None";

  if (!$$dwc{catalogNumber}) {
    $dwc->adderror("Missing catalognumber", "core");
  } elsif ($$dwc{catalogNumber} =~ /\D/) {
    $dwc->adderror("Invalid catalognumber", "core");
  }

  if($$dwc{verbatimLatitude} && $$dwc{verbatimLongitude}) {
    $$dwc{decimalLatitude} = $$dwc{verbatimLatitude};
    $$dwc{decimalLongitude} = $$dwc{verbatimLongitude};
  } elsif($$dwc{MGRSfra}) {
    my $datum = ($$dwc{MGRSfra} =~ s/\/E// ? "European 1950" : "WGS84");
    $$dwc{MGRSfra} =~ s/\/.?//;
    my ($mgrs, $d) = GBIFNorway::MGRS::parse($$dwc{MGRSfra});
    $$dwc{verbatimCoordinateSystem} = "MGRS";
    $$dwc{geodeticDatum} = $datum;
    $$dwc{coordinates} = $mgrs;
    $$dwc{coordinateUncertaintyInMeters} = $d;
  }
  return $dwc;
}

$GBIFNorway::filters{nodwc} = \&GBIFNorway::NODwC::filter;
$GBIFNorway::cleaners{nodwc} = \&GBIFNorway::NODwC::clean;

1;

