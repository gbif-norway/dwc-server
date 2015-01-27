use strict;
use utf8;

package GBIFNorway::DwC;

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

  return $dwc;
}

$GBIFNorway::names{dwc} = 1;
$GBIFNorway::filters{dwc} = \&GBIFNorway::DwC::filter;
$GBIFNorway::cleaners{dwc} = \&GBIFNorway::DwC::clean;

1;
