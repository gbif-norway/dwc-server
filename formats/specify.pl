use strict;
use utf8;

package GBIFNorway::Specify;

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

  $$dwc{basisOfRecord} = "Preserved specimen";

  $$dwc{stateProvince} =~ s/\s*Fylke$//;

  if($$dwc{decimalLatitude} && $$dwc{decimalLatitude} ne "null") {
    $$dwc{verbatimLatitude} = $$dwc{decimalLatitude};
    $$dwc{verbatimLongitude} = $$dwc{decimalLongitude};

    if($$dwc{verbatimLatitude} > 1000 || $$dwc{verbatimLatitude} < -1000) {
      $$dwc{decimalLatitude} = sprintf("%.5f", $$dwc{verbatimLatitude} / 10000000.0);
      $$dwc{decimalLongitude} = sprintf("%.5f", $$dwc{verbatimLongitude} / 10000000.0);
    }
  } else {
    $$dwc{decimalLatitude} = undef;
    $$dwc{decimalLongitude} = undef;
  }

  return $dwc;
}

$GBIFNorway::names{specify} = 1;
$GBIFNorway::filters{specify} = \&GBIFNorway::Specify::filter;
$GBIFNorway::cleaners{specify} = \&GBIFNorway::Specify::clean;

1;

