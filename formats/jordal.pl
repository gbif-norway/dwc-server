use strict;
use utf8;

package GBIFNorway::Jordal;

sub filter {
  return $_;
}

sub clean {
  my $dwc = shift;
  $$dwc{verbatimCoordinateSystem} = "UTM";
  $$dwc{verbatimCoordinates} = "32V " . $$dwc{e} . " " . $$dwc{n};
  $$dwc{basisOfRecord} = "HumanObservation";
  $$dwc{scientificName} = "Breutelia";

  return $dwc;
}

$GBIFNorway::names{jordal} = 1;
$GBIFNorway::filters{jordal} = \&GBIFNorway::Jordal::filter;
$GBIFNorway::cleaners{jordal} = \&GBIFNorway::Jordal::clean;

1;
