package DwC::Plugin::Geography;

use strict;
use 5.14.0;

use Geo::Coordinates::UTM::XS;
use Geo::Coordinates::MGRS::XS qw(:all);
use Geo::Proj4;
use GeoCheck;

sub description {
	return "Handle and validate various coordinate formats";
}

sub validateLatitudeLongitude {
	my ($plugin, $dwc) = @_;
	my ($lat, $lon) = ($$dwc{decimalLatitude}, $$dwc{decimalLongitude});
	if ($lat && ($lat < -90 || $lat > 90)) {
		$dwc->log("warning", "Latitude $lat out of bounds", "coordinates");
	}
	if ($lon && ($lon < -180 || $lon > 360)) {
		$dwc->log("warning", "Longitude $lon out of bounds", "coordinates");
	}
}

sub validateMGRS {
	my ($plugin, $dwc) = @_;
	my $mgrs = $$dwc{coordinates} || $$dwc{verbatimCoordinates};
	my $datum = $$dwc{geodeticDatum};
	my ($lat, $lon);
	eval {
		if($datum eq "European 1950" || $$dwc{verbatimSRS} eq "ED50") {
			my ($zone, $h, $e, $n) = ::mgrs_to_utm($mgrs);
			my $ed50 = Geo::Proj4->new("+proj=utm +zone=$zone$h +ellps=intl +units=m +towgs84=-87,-98,-121");
			my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
			my $point = [$e, $n];
			($lon, $lat) = @{$ed50->transform($wgs84, $point)};
			$$dwc{geodeticDatum} = "WGS84";
			$$dwc{decimalLatitude} = sprintf("%.5f", $lat);
			$$dwc{decimalLongitude} = sprintf("%.5f", $lon);
			$dwc->log("info",
				"MGRS (ED-50) coordinates converted to WGS84 latitude/longitude",
				"geo"
			);
		} else {
			my ($zone, $h, $e, $n) = ::mgrs_to_utm($mgrs);
			my $utm = Geo::Proj4->new("+proj=utm +zone=$zone$h +units=m");
			my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
			my $point = [$e, $n];
			($lon, $lat) = @{$utm->transform($wgs84, $point)};
			$dwc->log("info",
        "MGRS coordinates converted to WGS84 latitude/longitude", "geo");
			$$dwc{geodeticDatum} = "WGS84";
			$$dwc{decimalLatitude} = sprintf("%.5f", $lat);
			$$dwc{decimalLongitude} = sprintf("%.5f", $lon);
		}
	};
	if($@) {
		$dwc->log("warning", "Failed to convert MGRS coordinates: $mgrs", "geo");
		($lat, $lon) = ("", "");
	}
}

sub validateDegreesMinutesSeconds {
	my ($plugin, $dwc) = @_;
	my $raw = "$$dwc{verbatimLongitude} $$dwc{verbatimLatitude}";
	my ($lat, $lon) = GBIFNorway::LatLon::parsedeg($raw);
	$$dwc{decimalLongitude} = $lon;
	$$dwc{decimalLatitude} = $lat;
}

sub validateUTM {
	my ($plugin, $dwc) = @_;

	my $coordinates = $$dwc{coordinates} || $$dwc{verbatimCoordinates};
	my ($zone, $e, $n) = split(/\s/, $coordinates, 3);
	if($$dwc{geodeticDatum} eq "European 1950" || $$dwc{verbatimSRS} eq "ED50")
	{
		my $ed50 = Geo::Proj4->new("+proj=utm +zone=$zone +ellps=intl +units=m +towgs84=-87,-98,-121");
		if($ed50) {
			my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
			my $point = [$e, $n];
			my ($lon, $lat) = @{$ed50->transform($wgs84, $point)};
			$$dwc{geodeticDatum} = "WGS84";
			$$dwc{decimalLatitude} = sprintf("%.5f", $lat);
			$$dwc{decimalLongitude} = sprintf("%.5f", $lon);
			$dwc->log("info", "UTM coordinates converted to WGS84 latitude/longitude",
				"geo");
		} else {
			$dwc->log("warning", "Broken UTM coordinates", "geo");
		}
	} else {
		my $proj = Geo::Proj4->new("+proj=utm +zone=$zone +units=m +ellps=WGS84");
		if($proj) {

			my $wgs84 = Geo::Proj4->new(init => "epsg:4326");
			my $point = [$e, $n];
			if(!$e || !$n) {
				$dwc->log("warning", "Missing coordinates", "geo");
			} else {
				my ($lon, $lat) = @{$proj->transform($wgs84, $point)};
				$$dwc{geodeticDatum} = "WGS84";
				$$dwc{decimalLatitude} = sprintf("%.5f", $lat);
				$$dwc{decimalLongitude} = sprintf("%.5f", $lon);
				$dwc->log("info",
          "UTM coordinates converted to WGS84 latitude/longitude", "geo");
			}
		} else {
			$dwc->log("warning", "Invalid UTM zone: $zone", "geo");
		}
	}
}

sub validateRT90 {
	my ($plugin, $dwc) = @_;
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
		$dwc->log("info",
      "RT90 (Rikets nät) coordinates converted to WGS84 lat/lon", "geo");
	};
	if($@) {
		$dwc->log("warning", "Unable to convert RT90 (Rikets nät) coordinates",
			"geo");
	}
}

sub validateGeography {
	my ($plugin, $dwc) = @_;
	eval {
		my ($lat, $lon) = ($$dwc{decimalLatitude}, $$dwc{decimalLongitude});
		my $prec = $$dwc{coordinateUncertaintyInMeters};
		my $pol;

		if ($lat == 0 && $lon == 0) {
			return;
		}

		# midlertidig hack
		if($$dwc{stateProvince} eq "Svalbard") { return; }
		if($$dwc{stateProvince} eq "Spitsbergen") { return; }

		if($$dwc{stateProvince} && $$dwc{county}) {
			my $county = $$dwc{county};

			my $id = "county_$county";
			return if GeoCheck::inside($id, $lat, $lon);
			my ($p, $d) = GeoCheck::distance($id, $lat, $lon);
			return if($prec && $d < $prec);
			$pol = GeoCheck::polygon($id);
			$d = int($d);

			my $sug = GeoCheck::georef($lat, $lon, 'county');
			if($sug eq $county) {
				$dwc->log("info", "Matched secondary polygon...", "dev");
			} elsif($sug) {
				$dwc->log("warning", "d meters outside $county ($sug?)", "geo");
			} else {
				$dwc->log("warning", "d meters outside $county", "geo");
			}
			$dwc->log("info", $pol, "geo") if $pol;
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
			if($sug eq $sp) {
				$dwc->log("info", "Matched secondary polygon...", "dev");
			} elsif($sug) {
				$dwc->log("warning", "d meters outside $sp ($sug?)", "geo");
			} else {
				$dwc->log("warning", "d meters outside $sp", "geo");
			}
			$dwc->log("info", $pol, "geo") if $pol;
		}
	};
	if($@) {
		$dwc->log("warning", "geography trouble: $@", "geo");
	}

}

sub validate {
	my ($plugin, $dwc) = @_;

	# First, find WGS84 coordinates
	if($$dwc{decimalLatitude} || $$dwc{decimalLongitude}) {
		$plugin->validateLatitudeLongitude($dwc);
	} elsif($$dwc{verbatimCoordinateSystem} eq "MGRS") {
		$plugin->validateMGRS($dwc);
	} elsif($$dwc{verbatimCoordinateSystem} eq "degrees minutes seconds") {
		$plugin->validateDegreesMinutesSeconds($dwc);
	} elsif($$dwc{verbatimCoordinateSystem} eq "UTM") {
		$plugin->validateUTM($dwc);
	} elsif($$dwc{verbatimCoordinateSystem} eq "RT90") {
		$plugin->validateRT90($dwc);
	}

	# If successful, check geography as well
	$plugin->validateGeography($dwc);
}

1;

