use strict;
use utf8;

package GBIFNorway::DwC;

sub filter {
  return $_;
}

sub clean {
  my $dwc = shift;
  if($$dwc{eventDate} && $$dwc{eventDate} =~ /\-/) {
    my ($y, $m, $d) = split /-/, $$dwc{eventDate};
    $$dwc{year} = $y;
    $$dwc{month} = $m;
    $$dwc{day} = $d;
  }
  if($$dwc{dateIdentified}
    && $$dwc{dateIdentified} =~ /\-/) {
    my ($y, $m, $d) = split /-/, $$dwc{dateIdentified};
    $$dwc{yearIdentified} = $y;
    $$dwc{monthIdentified} = $m;
    $$dwc{dayIdentified} = $d;
  }

  $$dwc{_scientificName} = $$dwc{scientificName};
  $$dwc{scientificName} = "$$dwc{genus} $$dwc{specificEpithet}";
  if($$dwc{scientificName} =~ /\s*/) {
    $$dwc{scientificName} = $$dwc{_scientificName};
  }

  return $dwc;
}

$GBIFNorway::names{dwc} = 1;
$GBIFNorway::filters{dwc} = \&GBIFNorway::DwC::filter;
$GBIFNorway::cleaners{dwc} = \&GBIFNorway::DwC::clean;

1;
