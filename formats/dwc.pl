use strict;
use utf8;

package GBIFNorway::DwC;

sub filter {
  my $record = {
    'dateLastModified'          =>  $$_[0],
    'institutionCode'           =>  $$_[1],
    'collectionCode'            =>  $$_[2],
    'catalogNumber'             =>  $$_[3],
    'scientificName'            =>  $$_[4],
    'basisOfRecord'             =>  "Preserved specimen", # $$_[5],
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
    'YearIdentified' => $$_[16],
    'MonthIdentified' => $$_[17],
    'DayIdentified' => $$_[18],
    'BoundingBox' => $$_[36],
    'Okologi' => $$_[50],
    'Substrat' => $$_[52],
    'UTMsone' =>  $$_[53],
    'UTMost' =>  $$_[54],
    'UTMnord' =>  $$_[55],
    'MGRSfra' =>  $$_[56],
    'MGRStil' =>  $$_[57],
    'ElevationKilde' =>  $$_[59],
    'Status' => $$_[60],
    'NRikeID' => $$_[61],
    'NRekkeID' => $$_[62],
    'NKlasseID' => $$_[63],
    'NOrdenID' => $$_[64],
    'NFamilieID' => $$_[65],
    'NSlektID' => $$_[66],
    'NArtID' => $$_[67],
    'NArtObsID' => $$_[72],
    'NUTMsone' => $$_[74],
    'NUTMX' => $$_[75],
    'NUTMY' => $$_[76],
    'empty' => ""
  };

  warn "relationshipType ($$_[45]) should be empty" if $$_[45];
  warn "relatedCatalogItem ($$_[46]) should be empty" if $$_[46];

  $$record{verbatimCoordinateSystem} = "None";

  if($$record{verbatimLatitude} && $$record{verbatimLongitude}) {
    $$record{decimalLatitude} = $$record{verbatimLatitude};
    $$record{decimalLongitude} = $$record{verbatimLongitude};
  }
  elsif($$record{MGRSfra}) {
    my ($zones, $es, $ns) = split(" ", $$record{MGRSfra});
    my ($zone, $zone2) = $zones =~ /-/ ? split("-", $zones) : ($zones, $zones);
    my $datum = ($ns =~ s/\/E// ? "European 1950" : "WGS84");
    $ns =~ s/\/.?//;
    my ($e, $e2) = $es =~ /-/ ? split("-", $es) : ($es, $es);
    my ($n, $n2) = $ns =~ /-/ ? split("-", $ns) : ($ns, $ns);

    $$record{geodeticDatum} = $datum;
    if("$zone$n$e" eq "$zone2$n2$e2") {
      if(length($n) < 5) {
        $n = $n . 5; $e = $e . 5;
      }
      $$record{verbatimCoordinateSystem} = "MGRS";
      if($zone =~ /^\d/) {
        $$record{coordinates} = sprintf("%sV%05s%05s", $zone, $e, $n);
      } else {
        $$record{coordinates} = sprintf("32V%s%05s%05s", $zone, $e, $n);
      }
    } else {
      my $m = 1;
      if(length($n) < 5) {
        my $m = 5 - length($n);
        $n .= '0' x ($m); $n2 .= '0' x ($m);
        $e .= '0' x ($m); $e2 .= '0' x ($m);
      }
      my $nc = (($n + $n2) / 2) + (5 . ("0" x ($m)));
      my $ec = (($e + $e2) / 2) + (5 . ("0" x ($m)));

      my $de = (100 + $e2 - $e) / 2;
      my $dn = (100 + $n2 - $n) / 2;
      my $d = int(sqrt($de*$de + $dn*$dn) + 0.5);

      $$record{verbatimCoordinateSystem} = "MGRS";

      if($zone =~ /^\d/) {
        $$record{coordinates} = sprintf("%sV%05s%05s", $zone, $ec, $nc);
      } else {
        $$record{coordinates} = sprintf("32V%s%05s%05s", $zone, $ec, $nc);
      }
      $$record{coordinateUncertaintyInMeters} = $d;
    }
  }
  return $record;
}

$GBIFNorway::formats{dwc} = \&GBIFNorway::DwC::filter;

