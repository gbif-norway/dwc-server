use strict;
use 5.14.0;

package DwC::Plugin::Sanity;

use POSIX;

sub description {
  return "Basic sanity checks";
}

sub validate {
  my ($plugin, $dwc) = @_;

	if(!$$dwc{modified}) {
		$$dwc{modified} = $$dwc{dateLastModified} if $$dwc{dateLastModified};
  	$$dwc{modified} = $$dwc{'dcterms:modified'} if $$dwc{'dcterms:modified'};
	}

  # Normalize, and...
  if($$dwc{basisOfRecord} eq "PRESERVED_SPECIMEN") {
    $$dwc{basisOfRecord} = "PreservedSpecimen";
  } elsif($$dwc{basisOfRecord} eq "Preserved specimen") {
    $$dwc{basisOfRecord} = "PreservedSpecimen";
  } elsif($$dwc{basisOfRecord} eq "FOSSIL_SPECIMEN") {
    $$dwc{basisOfRecord} = "FossilSpecimen";
  } elsif($$dwc{basisOfRecord} eq "LIVING_SPECIMEN") {
    $$dwc{basisOfRecord} = "LivingSpecimen";
  } elsif($$dwc{basisOfRecord} eq "UNKNOWN") {
    $$dwc{basisOfRecord} = "Unknown";
  }

  # ...validate basis of record
  if($$dwc{basisOfRecord} !~ /^MaterialSample|Living specimen|PreservedSpecimen|Observation|Unknown|Fossil specimen$/i) {
    $dwc->log("warning", "Unknown basisOfRecord $$dwc{basisOfRecord}", "core");
  }

	# Date validation
  my $year = strftime("%Y", gmtime);

  #if($$dwc{year} && $$dwc{year} eq "0") $$dwc{year} = undef;
  #if($$dwc{month} && $$dwc{month} eq "00") $$dwc{month} = undef;
  #if($$dwc{day} && $$dwc{day} eq "0000") $$dwc{day} = undef;

  if($$dwc{year} && $$dwc{year} == 0) { $$dwc{year} = undef; }
  if($$dwc{month} && $$dwc{month} == 0) { $$dwc{month} = undef; }
  if($$dwc{day} && $$dwc{day} == 0) { $$dwc{day} = undef; }

  if($$dwc{year} && ($$dwc{year} > $year || $$dwc{year} < 1750)) {
    $dwc->log("warning", "Year out of bounds $$dwc{year}", "date");
  }
  if($$dwc{month} && ($$dwc{month} < 1 || $$dwc{month} > 12)) {
    $dwc->log("warning", "Month out of bounds $$dwc{month}", "date");
  }
  if($$dwc{day} && ($$dwc{day} < 1 || $$dwc{day} > 31)) {
    $dwc->log("warning", "Day out of bounds $$dwc{day}", "date");
  }

	# Validate elevation
  my $mind = $$dwc{minimumDepthInMeters} =~ s/,/\./gr;
  my $maxd = $$dwc{maximumDepthInMeters} =~ s/,/\./gr;
  my $mine = $$dwc{minimumElevationInMeters} =~ s/,/\./gr;
  my $maxe = $$dwc{maximumElevationInMeters} =~ s/,/\./gr;
  if($mind && $maxd && $mind > $maxd) {
    $dwc->log("warning", "Depth problem", "elevation");
  }
  if($mine && $maxe && $mine > $maxe) {
    $dwc->log("warning", "Elevation problem", "elevation");
  }
}

1;

