use strict;
use utf8;

package GBIFNorway::Dugnad;

sub filter {
  return $_;
}

sub clean {
  my $dwc = shift;
  if($$dwc{eventDate} && $$dwc{eventDate} =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
    my ($y, $m, $d) = split /-/, $$dwc{eventDate};
    $$dwc{year} = $y;
    $$dwc{month} = $m;
    $$dwc{day} = $d;
  }
  if($$dwc{dateIdentified}
    && $$dwc{dateIdentified} =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
    my ($y, $m, $d) = split /-/, $$dwc{dateIdentified};
    $$dwc{yearIdentified} = $y;
    $$dwc{monthIdentified} = $m;
    $$dwc{dayIdentified} = $d;
  }

  if($$dwc{decimalLatitude}) {
    my $lat = $$dwc{decimalLatitude};
    my $lon = $$dwc{decimalLongitude};

    $lat =~ s/-/°/; $lon =~ s/-/°/;
    $lat =~ s/\*/°/; $lon =~ s/\*/°/;

    $lat =~ s/S/'S/i; $lon =~ s/S/'S/i;
    $lat =~ s/E/'E/i; $lon =~ s/E/'E/i;
    $lat =~ s/W/'W/i; $lon =~ s/W/'W/i;
    $lat =~ s/N/'N/i; $lon =~ s/N/'N/i;

    eval {
      my ($dlat, $dlon) = GBIFNorway::LatLon::parsedeg("$lat $lon");
      $$dwc{decimalLatitude} = $dlat;
      $$dwc{decimalLongitude} = $dlon;
    };
    if($@) {
      $$dwc{decimalLatitude} = "";
      $$dwc{decimalLongitude} = "";
    }
    $$dwc{verbatimCoordinateSystem} = "degrees minutes seconds";
    $$dwc{verbatimCoordinates} = "$lat $lon";
  }

  $$dwc{_scientificName} = $$dwc{scientificName};
  $$dwc{scientificName} = "$$dwc{genus} $$dwc{specificEpithet}";
  if($$dwc{scientificName} =~ /\s*/) {
    $$dwc{scientificName} = $$dwc{_scientificName};
  }

  return $dwc;
}

$GBIFNorway::names{dugnad} = 1;
$GBIFNorway::filters{dugnad} = \&GBIFNorway::Dugnad::filter;
$GBIFNorway::cleaners{dugnad} = \&GBIFNorway::Dugnad::clean;

1;
