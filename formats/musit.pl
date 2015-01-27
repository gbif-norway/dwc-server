use strict;
use utf8;

use POSIX;
use Time::Piece;
use Geo::WKT;

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
  } elsif(/^[A-Za-z\-]{2,5}[\d\s\-\,]+$/) {
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
  } elsif(/^\d+°\s*[\d\.]+'\s*[NSEW]\s+\d+°\s*[\d\.]+'\s*[NSEW]$/) {
    "degrees minutes seconds";
  } elsif(/^[NØ]\d+[\s,]+[NØ]\d+\.?$/) {
    "UTM";
  } elsif(/UTM/) {
    "UTM";
  } elsif(/^Euref\. 89 (\d+)/) {
    "UTM (Euref.89)";
  } elsif(/^rikets nät/i) {
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

    'geodeticDatum'             =>  '',

    'verbatimLongitude'         =>  "",
    'verbatimLatitude'          =>  "",
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
    'NArtObsID' => $$_[72],
    'empty' => ""
  };

  warn "relationshipType ($$_[45]) should be empty" if $$_[45];
  warn "relatedCatalogItem ($$_[46]) should be empty" if $$_[46];

  return $dwc;
};

our %months = (
  "jan" => "01", "feb" => "02", "mar" => "03", "apr" => "04",
  "mai" => "05", "jun" => "06", "jul" => "07", "aug" => "00",
  "sep" => "09", "okt" => "10", "nov" => "11", "des" => "12"
);

sub parsedate {
  local $_ = shift;
  my ($d, $mon, $y) = split /[\s\-]/;
  my $m = $months{$mon};
  return "$y-$m-$d";
};

sub clean {
  my $dwc = shift;

  if($$dwc{NArtObsID}) {
    $dwc->adderror("Already provided to Artskart and the GBIF network through Artsobservasjoner");
  }

  $$dwc{dateLastModified} = parsedate($$dwc{dateLastModified});

  my $system = guess($$dwc{verbatimCoordinates});

  if(!$system) {
    $$dwc{verbatimCoordinateSystem} = "";
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
    # $$dwc{coordinateUncertaintyInMeters} = "";
    # $dwc->addwarning("Not georeferenced. Coordinate precision removed.");
  } elsif($system eq "MGRS") {
    if($$dwc{verbatimCoordinates} !~ /^\d\d\w{3}\d+/ && $$dwc{UTMsone}) {
      my $z = $$dwc{UTMsone};
      if($z =~ /^\d\d$/) {
        $z = $z . "?";
      }
      $$dwc{verbatimCoordinates} = "$z$$dwc{verbatimCoordinates}";
    }

    eval {
      my ($mgrs, $d, @b) = GBIFNorway::MGRS::parse($$dwc{verbatimCoordinates});
      if($mgrs) {
        $$dwc{verbatimCoordinateSystem} = "MGRS";
        $$dwc{coordinates} = uc $mgrs;
        if($d > $$dwc{coordinateUncertaintyInMeters}) {
          my $warning = "Coordinate uncertainty. $$dwc{coordinateUncertaintyInMeters} / $d";
          $dwc->addwarning($warning, "coordinateUncertaintyInMeters");
        }
        # $$dwc{coordinateUncertaintyInMeters} = $d;
        $$dwc{latitude} = ""; $$dwc{longitude} = "";
        if(@b) {
          my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
          if($$dwc{verbatimSRS} eq "ED50") {
            @b = map {
              my $ed50 = Geo::Proj4->new("+proj=utm +zone=$$_[0] +ellps=intl +units=m +towgs84=-87,-98,-121");
              $ed50->transform($wgs84, [$$_[1], $$_[2]]);
            } @b;
          } else {
            @b = map {
              my $ed50 = Geo::Proj4->new("+proj=utm +zone=$$_[0] +units=m");
              $ed50->transform($wgs84, [$$_[1], $$_[2]]);
            } @b;
          }
          $$dwc{footprintWKT} = Geo::WKT::wkt_polygon(@b);
        }
      } else {
        die "skal aldri hit!";
      }
    };
    if($@) {
      my $warning = $@ =~ s/\s+$//r =~ s/ at.*//r;
      $dwc->addwarning($warning, "parseMGRS");
      $$dwc{decimalLatitude} = "";
      $$dwc{decimalLongitude} = "";
      $$dwc{verbatimCoordinateSystem} = "Unknown";
    }
  } elsif($system eq "UTM") {
    my $utm;
    my $sone = $$dwc{UTMsone};
    eval {
      $utm = GBIFNorway::UTM::parse($sone, $$dwc{verbatimCoordinates});
    };
    if($@) {
      $dwc->adderror("Unable to parse UTM coordinates");
    }
    if($utm) {
      $$dwc{coordinates} = $utm;
      $$dwc{verbatimCoordinateSystem} = "UTM";
    } else {
      $$dwc{verbatimCoordinateSystem} = "";
    }
  } elsif($system eq "decimal degrees") {
    eval {
      my $raw = $$dwc{verbatimCoordinates};
      my ($lat, $lon) = GBIFNorway::LatLon::parsedec($raw);
      $$dwc{decimalLatitude} = $lat;
      $$dwc{decimalLongitude} = $lon;
      $$dwc{verbatimCoordinateSystem} = "decimal degrees";
    };
    if($@) {
      my $warning = $@ =~ s/\s+$//r =~ s/ at.*//r;
      $dwc->addwarning($warning, "parseDecimalDegrees");
      $$dwc{decimalLatitude} = "";
      $$dwc{decimalLongitude} = "";
      $$dwc{verbatimCoordinateSystem} = "Unknown";
    }
  } elsif($system eq "degrees minutes seconds") {
    eval {
      my $raw = $$dwc{verbatimCoordinates};
      my ($lat, $lon) = GBIFNorway::LatLon::parsedeg($raw);
      $$dwc{decimalLatitude} = $lat;
      $$dwc{decimalLongitude} = $lon;
      $$dwc{verbatimCoordinateSystem} = "degrees minutes seconds";
    };
    if($@) {
      my $warning = $@ =~ s/\s+$//r =~ s/ at.*//r;
      $dwc->addwarning($warning, "parseDegrees");
      $$dwc{decimalLatitude} = "";
      $$dwc{decimalLongitude} = "";
      $$dwc{verbatimCoordinateSystem} = "Unknown";
    }
  } elsif($system eq "Rikets nät") {
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
    if($$dwc{verbatimCoordinates} =~ /^rikets nät (.*)$/) {
      $$dwc{verbatimCoordinates} = $1;
    }
    $$dwc{verbatimCoordinateSystem} = "RT90";
  } elsif($system eq "Unknown") {
    $dwc->addwarning("Unknown coordinate system", "coordinateSystem");
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
    $$dwc{coordinateUncertaintyInMeters} = "";
    $$dwc{verbatimCoordinateSystem} = "unknown";
  } else {
    $dwc->adderror("What?");
  }

  # Datum
  if($$dwc{verbatimSRS}) {
    if($$dwc{verbatimSRS} eq "ED50") {
      $$dwc{geodeticDatum} = "European 1950";
    } elsif($$dwc{verbatimSRS} eq "WGS84") {
      $$dwc{geodeticDatum} = "WGS84";
    }
  } else {
    $$dwc{geodeticDatum} = "";
  }

  return $dwc;
}

$GBIFNorway::filters{musit} = \&GBIFNorway::Musit::filter;
$GBIFNorway::cleaners{musit} = \&GBIFNorway::Musit::clean;

1;

