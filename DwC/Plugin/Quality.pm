use strict;
use 5.14.0;

package DwC::Plugin::Quality;

use POSIX;

sub description {
  return "Data completeness classification";
}

sub completeness {
  my ($plugin, $dwc) = @_;

  my $quality = 0;
  my $incomplete = 0;
  my $linked = 0;
  
  if(!$$dwc{basisOfRecord} || !$$dwc{scientificName} || !$$dwc{locality}) {
    $incomplete = 1;
  }
  if(!$$dwc{occurrenceID}) { $incomplete = 1; }

  if($$dwc{decimalLatitude} && $$dwc{decimalLongitude}) { $quality++; }
  if($$dwc{eventDate}) { $quality++; }
  if($$dwc{coordinateUncertaintyInMeters}) { $quality++; }
  if($$dwc{country}) { $quality++; }
  if($$dwc{scientificNameAuthorship}) { $quality++; }
  if($$dwc{dateIdentified}) { $quality++; }
  if($$dwc{recordedBy}) { $quality++; }
  if($$dwc{kingdom}) { $quality++; }
  if($$dwc{samplingMethod}) { $quality++; }

  $$dwc{_completeness} = $quality;
  $$dwc{_incomplete} = $incomplete;
}

sub validate {
}

1;

