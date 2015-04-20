use strict;
use utf8;

use POSIX;
use Time::Piece;
use Geo::WKT;

use locale;

use GBIFNorway::MGRS;
use GBIFNorway::LatLon;
use GBIFNorway::UTM;

package GBIFNorway::MusitDwC;

sub guess {
  local $_ = shift;
  if(/^$/) {
    "";
  } elsif(/^\d{2}\w{1}\s\w{2}\s[\d\-,]+$/) {
    "MGRS";
  } elsif(/^\d{2}\w{1}\s\w{2}-\w{2}\s[\d\-,]+$/) {
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
  return $_;
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
    $dwc->adderror("Already provided to Artskart and the GBIF network through Artsobservasjoner", "core");
  }

  $$dwc{'dcterms:modified'} = parsedate($$dwc{'dcterms:modified'});

  my $system = guess($$dwc{verbatimCoordinates});

  if(!$system) {
    $$dwc{verbatimCoordinateSystem} = "";
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
  } elsif($system eq "MGRS") {
    eval {
      my ($mgrs, $d, @b) = GBIFNorway::MGRS::parse($$dwc{verbatimCoordinates});
      if($mgrs) {
        $$dwc{verbatimCoordinateSystem} = "MGRS";
        $$dwc{coordinates} = uc $mgrs;
        if($d > $$dwc{coordinateUncertaintyInMeters}) {
          my $warning = "Coordinate uncertainty. $$dwc{coordinateUncertaintyInMeters} / $d";
          $dwc->addwarning($warning, "geo");
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
      $dwc->addwarning($warning, "parseMGRS", "geo");
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
      $dwc->addwarning("Unable to parse UTM coordinates", "geo");
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
      $dwc->addwarning($warning, "parseDecimalDegrees", "geo");
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
      $dwc->addwarning($warning, "parseDegrees", "geo");
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
  } elsif($system =~ "Unknown") {
    $dwc->addwarning("Unknown coordinate system ($$dwc{verbatimCoordinates})", "geo");
    $$dwc{decimalLatitude} = "";
    $$dwc{decimalLongitude} = "";
    $$dwc{coordinateUncertaintyInMeters} = "";
    $$dwc{verbatimCoordinateSystem} = "unknown";
  } else {
    $dwc->adderror("What?", "core");
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

$GBIFNorway::names{musitdwc} = 1;
$GBIFNorway::filters{musitdwc} = \&GBIFNorway::MusitDwC::filter;
$GBIFNorway::cleaners{musitdwc} = \&GBIFNorway::MusitDwC::clean;

1;

