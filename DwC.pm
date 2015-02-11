use utf8;

use DateTime;
use POSIX;
use Geo::Coordinates::UTM;
use Geo::Proj4;
use MGRS;
use GeoCheck;

use utf8;

package DwC;

sub new {
  my $me = shift;
  my $record = shift;
  $$record{_row} = shift;
  $$record{info} = [];
  $$record{errors} = [];
  $$record{warnings} = [];
  return bless $record;
}

sub triplet {
  my $me = shift;
  return "$$me{institutionCode}:$$me{collectionCode}:$$me{catalogNumber}"
}

our @terms = (
  "dateLastModified", "institutionCode", "collectionCode", "catalogNumber",
  "scientificName", "basisOfRecord",
  "kingdom", "phylum", "class", "order", "family", "genus",
  "specificEpithet", "infraspecificEpithet","scientificNameAuthorship",
  "identifiedBy", "dateIdentified",
  "typeStatus", "recordNumber", "fieldNumber", "recordedBy",
  "year", "month", "day", "startDayOfYear", "eventTime",
  "continent", "country", "stateProvince", "county", "municipality", "locality",
  "decimalLongitude", "decimalLatitude", "coordinateUncertaintyInMeters",
  "geodeticDatum",
  "minimumElevationInMeters", "maximumElevationInMeters",
  "minimumDepthInMeters", "maximumDepthInMeters",
  "sex", "preparations", "individualCount",
  "otherCatalogNumbers",
  "occurrenceRemarks", "samplingProtocol", "identificationRemarks",
  "habitat", "footprintWKT",
  "verbatimCoordinateSystem", "verbatimCoordinates", "verbatimSRS",
  "associatedMedia", "organismID"
);

sub addinfo {
  my $dwc = shift;
  push($$dwc{info}, shift);
}

sub adderror {
  my $dwc = shift;
  push($$dwc{errors}, shift);
}

sub addwarning {
  my $dwc = shift;
  push($$dwc{warnings}, shift);
}

# fix
sub validategeography {
  eval {
    my $dwc = shift;
    my ($lat, $lon) = ($$dwc{decimalLatitude}, $$dwc{decimalLongitude});
    my $prec = $$dwc{coordinateUncertaintyInMeters};
    my $pol;

    #my $mun = GeoCheck::georef($lat, $lon, 'municipality');
    #if($mun) {
    #  $$dwc{municipality} = $mun;
    #}

    if($$dwc{stateProvince} && $$dwc{county}) {
      my $county = $$dwc{county};
      # v stygg hack
      if($county eq "FROGN" || $county eq "Frogn") {
        $county = "Frogn*";
      }
      if($county eq "SANDEFJORD" || $county eq "Sandefjord") {
        $county = "Sandefjord*";
      }
      if($county eq "NOME" || $county eq "Nome") {
        $county = "Nome*";
      }

      my $id = "county_" . $$dwc{stateProvince} . "_" . $county;
      return if GeoCheck::inside($id, $lat, $lon);
      my ($p, $d) = GeoCheck::distance($id, $lat, $lon);
      return if($prec && $d < $prec);
      $pol = GeoCheck::polygon($id);
      $d = int($d);

      my $sug = GeoCheck::georef($lat, $lon, 'county');
      if($sug) {
        $dwc->addwarning("$d meters outside $county ($sug?)", "geography");
      } else {
        $dwc->addwarning("$d meters outside $county", "geography");
      }
      $dwc->addinfo($pol) if $pol;
    }
    if($$dwc{stateProvince}) {
      my $id = "stateprovince_" . $$dwc{stateProvince};
      return if GeoCheck::inside($id, $lat, $lon);
      my ($p, $d) = GeoCheck::distance($id, $lat, $lon);
      return if($prec && $d < $prec);
      $pol = GeoCheck::polygon($id);
      $d = int($d);
      my $sp = $$dwc{stateProvince};
      my $sug = GeoCheck::georef($lat, $lon, 'stateprovince');
      if($sug) {
        $dwc->addwarning("$d meters outside $sp ($sug?)", "geography");
      } else {
        $dwc->addwarning("$d meters outside $sp", "geography");
      }
      $dwc->addinfo($pol) if $pol;
    }
  };
}

sub validatebasisofrecord {
  my $dwc = shift;
  if($$dwc{basisOfRecord} !~ /^MaterialSample|Preserved specimen|Observation$/i) {
    $dwc->addwarning("Unknown basisOfRecord $$dwc{basisOfRecord}", "core");
  }
}

sub validatecoordinates {
  my $dwc = shift;
  my ($lat, $lon) = ($$dwc{decimalLatitude}, $$dwc{decimalLongitude});
  if ($lat && ($lat < -90 || $lat > 90)) {
    $dwc->addwarning("Latitude $lat out of bounds", "coordinates");
  }
  if ($lon && ($lon < -180 || $lon > 360)) {
    $dwc->addwarning("Longitude $lon out of bounds", "coordinates");
  }
}

sub validatedates {
  my $dwc = shift;
  my $year = ::strftime("%Y", gmtime);
  if($$dwc{year} && ($$dwc{year} > $year || $$dwc{year} < 1750)) {
    $dwc->addwarning("Year out of bounds $$dwc{year}", "date");
  }
  if($$dwc{month} && ($$dwc{month} < 1 || $$dwc{month} > 12)) {
    $dwc->addwarning("Month out of bounds $$dwc{month}", "date");
  }
  if($$dwc{day} && ($$dwc{day} < 1 || $$dwc{day} > 31)) {
    $dwc->addwarning("Day out of bounds $$dwc{day}", "date");
  }
}

sub handlecoordinates {
  my $dwc = shift;

  if($$dwc{decimalLatitude} || $$dwc{decimalLongitude}) {
    $dwc->validatecoordinates;
  } elsif($$dwc{verbatimCoordinateSystem} eq "MGRS") {
    my $mgrs = $$dwc{coordinates};
    my ($lat, $lon);

    eval {
      if($$dwc{geodeticDatum} eq "European 1950") {
        my ($zone, $h, $e, $n) = MGRS::mgrs_to_utm($mgrs);
        my $ed50 = Geo::Proj4->new("+proj=utm +zone=$zone$h +ellps=intl +units=m +towgs84=-87,-98,-121");
        my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
        my $point = [$e, $n];
        ($lon, $lat) = @{$ed50->transform($wgs84, $point)};
        $$dwc{geodeticDatum} = "WGS84";
        $$dwc{decimalLatitude} = sprintf("%.5f", $lat);
        $$dwc{decimalLongitude} = sprintf("%.5f", $lon);
        $dwc->addinfo(
          "MGRS (ED-50) coordinates converted to WGS84 latitude/longitude", 
          "coordinates"
        );
      } else {
        my ($zone, $h, $e, $n) = MGRS::mgrs_to_utm($mgrs);
        my $utm = Geo::Proj4->new("+proj=utm +zone=$zone$h +units=m");
        my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
        my $point = [$e, $n];
        ($lon, $lat) = @{$utm->transform($wgs84, $point)};

        $dwc->addinfo("MGRS coordinates converted to WGS84 latitude/longitude",
          "coordinates");
        $$dwc{geodeticDatum} = "WGS84";
        $$dwc{decimalLatitude} = sprintf("%.5f", $lat);
        $$dwc{decimalLongitude} = sprintf("%.5f", $lon);
      }
    };
    if($@) {
      $dwc->addwarning("Failed to convert MGRS coordinates: $mgrs");
      ($lat, $lon) = ("", "");
    }
  } elsif($$dwc{verbatimCoordinateSystem} eq "UTM") {
    my ($zone, $e, $n) = split(/\s/, $$dwc{coordinates}, 3);
    if($$dwc{geodeticDatum} eq "European 1950") {
      my $ed50 = Geo::Proj4->new("+proj=utm +zone=$zone +ellps=intl +units=m +towgs84=-87,-98,-121");
      if($ed50) {
        my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
        my $point = [$e, $n];
        my ($lon, $lat) = @{$ed50->transform($wgs84, $point)};
        $$dwc{geodeticDatum} = "WGS84";
        $$dwc{decimalLatitude} = sprintf("%.5f", $lat);
        $$dwc{decimalLongitude} = sprintf("%.5f", $lon);
        $dwc->addinfo("UTM coordinates converted to WGS84 latitude/longitude",
          "coordinates");
      } else {
        $dwc->addwarning("Broken UTM coordinates");
      }
    } else {
      my $ed50 = Geo::Proj4->new("+proj=utm +zone=$zone +units=m");
      my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
      my $point = [$e, $n];
      my ($lon, $lat) = @{$ed50->transform($wgs84, $point)};
      $$dwc{geodeticDatum} = "WGS84";
      $$dwc{decimalLatitude} = sprintf("%.5f", $lat);
      $$dwc{decimalLongitude} = sprintf("%.5f", $lon);
      $dwc->addinfo("UTM coordinates converted to WGS84 latitude/longitude",
        "coordinates");
    }
  } elsif($$dwc{verbatimCoordinateSystem} eq "RT90") {
    eval {
      $SIG{__WARN__} = sub { die @_; }; #kya~
      my $rt90 = Geo::Proj4->new(init => "epsg:2400");
      my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
      my ($n, $e) = split /[\s,]/, $$dwc{verbatimCoordinates};
      #tmp
      if(!$$dwc{coordinateUncertaintyInMeters}) {
        my $l = length($e);
        if($l == 7) {
          $$dwc{coordinateUncertaintyInMeters} = 1;
        } elsif($l == 6) {
          $$dwc{coordinateUncertaintyInMeters} = 10;
        } elsif($l == 5) {
          $$dwc{coordinateUncertaintyInMeters} = 100;
        } elsif($l == 4) {
          $$dwc{coordinateUncertaintyInMeters} = 1000;
        } elsif($l == 3) {
          $$dwc{coordinateUncertaintyInMeters} = 10000;
        } elsif($l == 2) {
          $$dwc{coordinateUncertaintyInMeters} = 100000;
        } elsif($l == 1) {
          $$dwc{coordinateUncertaintyInMeters} = 1000000;
        }
      }
      $e = $e . "0" while(length($e) < 7);
      $n = $n . "0" while(length($n) < 7);
      my ($lon, $lat) = @{$rt90->transform($wgs84, [$e, $n])};
      $$dwc{geodeticDatum} = "WGS84";
      $$dwc{decimalLatitude} = sprintf("%.5f", $lat);
      $$dwc{decimalLongitude} = sprintf("%.5f", $lon);
      $dwc->addinfo("RT90 (Rikets nät) coordinates converted to WGS84 lat/lon",
        "coordinates");
    };
    if($@) {
      $dwc->addwarning("Unable to convert RT90 (Rikets nät) coordinates");
    }
  }
}

sub validateelevation {
  my $dwc = shift;
  my $mind = $$dwc{minimumDepthInMeters} =~ s/,/\./gr;
  my $maxd = $$dwc{maximumDepthInMeters} =~ s/,/\./gr;
  my $mine = $$dwc{minimumElevationInMeters} =~ s/,/\./gr;
  my $maxe = $$dwc{maximumElevationInMeters} =~ s/,/\./gr;
  if($mind && $maxd && $mind > $maxd) {
    $dwc->addwarning("Depth problem", "elevation");
  }
  if($mine && $maxe && $mine > $maxe) {
    $dwc->addwarning("Elevation problem", "elevation");
  }
}

sub printjson {
  my $me = shift;
  my $fields = shift;
  my $json = JSON::XS->new->pretty->convert_blessed(1);
  my %subset;
  @subset{@$fields} = @{$me}{@$fields};
  say($json->encode(\%subset));
}

sub printcsv {
  my ($me, $handle, $fields) = @_;
  my $row = join("\t", @{$me}{@$fields});
  $row =~ s/\"/'/g;
  say $handle $row;
}

