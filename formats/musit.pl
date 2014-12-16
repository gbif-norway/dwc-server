use strict;
use utf8;

use POSIX;
use Time::Piece;

use locale;

use GBIFNorway::MGRS;
use GBIFNorway::LatLon;
use GBIFNorway::UTM;

package GBIFNorway::Musit;

sub guess {
  local $_ = shift;
  if(/^$/) {
    "";
  } elsif(/^\w{2}\s*[\d\s,]+$/) {
    "MGRS";
  } elsif(/^[A-Z\-]{2-5}\s*[\d\s\-,]+$/) {
    "MGRS";
  } elsif(/^[\d\.°,]+\s*[NSEW]\s*[\d\.°,]+\s*[NSEW]$/) {
    "decimal degrees";
  } elsif(/^Long&Lat:/) {
    "decimal degrees";
  } elsif(/^[\d,\s]+\s*°\s*[NSEW]?\s*[\d,\s]+\s*°\s*[NSEW]?$/) {
    "decimal degrees";
  } elsif(/^[\d,\s]+\s*[NSEW]\s*[\d,\s]+\s*[NSEW]$/) {
    "decimal degrees";
  } elsif(/^(Lat\.)?\s*[NSEW\s\d,°-]+\s*[\d-,]+'/) {
    "degrees minutes seconds";
  } elsif(/^[NØ]\d+[\s,]+[NØ]\d+\.?$/) {
    "UTM";
  } elsif(/UTM/) {
    "UTM";
  } elsif(/^Euref\. 89 (\d+)/) {
    "UTM (Euref.89)";
  } elsif(/^Rikets nät/) {
    "Rikets nät";
  } else {
    "Unknown";
  }
};

sub filter {
  my $dwc = {
    'dateLastModified'          =>  $$_[0],
    'institutionCode'           =>  $$_[1],
    'collectionCode'            =>  $$_[2],
    'catalogNumber'             =>  $$_[3],
    'scientificName'            =>  $$_[4],
    'basisOfRecord'             =>  $$_[5],
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

    #'verbatimLongitude'         =>  $$_[33],
    #'verbatimLatitude'          =>  $$_[34],

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

    'verbatimCoordinateSystem'  =>  "",
    'verbatimCoordinates'       =>  $$_[68],
    'verbatimSRS'               =>  $$_[69],

    'decimalLongitude'          =>  "",
    'decimalLatitude'           =>  "",

    'occurrenceID'              =>  $$_[73],

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

  return $dwc;
};

sub clean {
  my $dwc = shift;

  # POSIX::setlocale(POSIX::LC_ALL, "nb_NO.utf8");

  # say STDERR $$dwc{dateLastModified};
  # say STDERR Time::Piece->new->strftime("%b");
  # Time::Piece->strptime($$dwc{dateLastModified}, "%d-%b-%Y %H:%M:%S");
  # parse og %Y-%m-%d 'dateLastModified'

  $$dwc{verbatimLongitude} = ""; $$dwc{longitude} = "";
  $$dwc{verbatimLatitude} = ""; $$dwc{latitude} = "";
  $$dwc{decimalLatitude} = ""; $$dwc{decimalLongitude} = "";

  my $system = guess($$dwc{verbatimCoordinates});

  if(!$system) {
    $$dwc{verbatimCoordinateSystem} = "";
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
  } elsif($system eq "MGRS") {
    if($$dwc{verbatimCoordinates} !~ /^\d\d\w{3}\d+/ && $$dwc{UTMsone}) {
      my $z = $$dwc{UTMsone};
      if($z =~ /^\d\d$/) {
        # warn "gjetter belte V fra $z";
        $z = $z . "V" if $z =~ /^\d\d$/;
      }
      $$dwc{verbatimCoordinates} = "$z$$dwc{verbatimCoordinates}";
    }

    eval {
      my ($mgrs, $d) = GBIFNorway::MGRS::parse($$dwc{verbatimCoordinates});
      if($mgrs) {
        $$dwc{verbatimCoordinateSystem} = "MGRS";
        $$dwc{coordinates} = uc $mgrs;
        $$dwc{coordinateUncertaintyInMeters} = $d;
        $$dwc{latitude} = ""; $$dwc{longitude} = "";
      } else {
        die "skal aldri hit!";
      }
    };
    if($@) {
      $dwc->addWarning("$@");
      $$dwc{decimalLatitude} = "";
      $$dwc{decimalLongitude} = "";
      $$dwc{verbatimCoordinateSystem} = "Unknown";
    }
  } elsif($system eq "UTM") {
    my $sone = $$dwc{UTMsone};
    my $utm = GBIFNorway::UTM::parse($sone, $$dwc{verbatimCoordinates});
    if($utm) {
      $$dwc{coordinates} = $utm;
      $$dwc{verbatimCoordinateSystem} = "UTM";
    } else {
      $$dwc{verbatimCoordinateSystem} = "";
    }
  } elsif($system eq "decimal degrees") {
    my ($lat, $lon) = GBIFNorway::LatLon::parsedec($$dwc{verbatimCoordinates});
    $$dwc{decimalLatitude} = $lat;
    $$dwc{decimalLongitude} = $lon;
    $$dwc{verbatimCoordinateSystem} = "decimal degrees";
  } elsif($system eq "degrees minutes seconds") {
    my ($lat, $lon) = GBIFNorway::LatLon::parsedeg($$dwc{verbatimCoordinates});
    $$dwc{decimalLatitude} = $lat;
    $$dwc{decimalLongitude} = $lon;
    $$dwc{verbatimCoordinateSystem} = "degrees minutes seconds";
  } elsif($system eq "Unknown") {
    $dwc->addWarning("Unknown coordinate system");
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
    $$dwc{verbatimCoordinateSystem} = "unknown";
  } else {
    $dwc->addError("What?");
  }

  # Datum shft
  if($$dwc{verbatimSRS}) {
    if($$dwc{verbatimSRS} eq "ED50") {
      $$dwc{geodeticDatum} = "European 1950";
    } elsif($$dwc{verbatimSRS} eq "WGS84") {
      $$dwc{geodeticDatum} = "WGS84";
    }
  }
  return $dwc;
}

$GBIFNorway::filters{musit} = \&GBIFNorway::Musit::filter;
$GBIFNorway::cleaners{musit} = \&GBIFNorway::Musit::clean;

1;

