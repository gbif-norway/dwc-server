use strict;
use utf8;

package GBIFNorway::GBIF;

our %names;
open NAMES, '<', "tmp/navn.txt";
while(<NAMES>) {
  my ($name, $uuid) = split /\t/;
  $uuid =~ s/\s$//;
  $names{$uuid} = $name;
}

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

  $$dwc{_scientificName} = $$dwc{scientificName};
  $$dwc{scientificName} = "$$dwc{genus} $$dwc{specificEpithet}";
  if($$dwc{scientificName} =~ /\s*/) {
    $$dwc{scientificName} = $$dwc{_scientificName};
  }

  my $name = $names{$$dwc{datasetKey}};
  $$dwc{occurrenceRemarks} = "$name (http://gbif.org/dataset/$$dwc{datasetKey}). $$dwc{occurrenceRemarks}";
  $$dwc{occurrenceRemarks} =~ s/\s+$//;

  return $dwc;
}

$GBIFNorway::names{gbif} = 1;
$GBIFNorway::filters{gbif} = \&GBIFNorway::GBIF::filter;
$GBIFNorway::cleaners{gbif} = \&GBIFNorway::GBIF::clean;

1;
