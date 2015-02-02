use strict;
use warnings;

use utf8;

use Geo::Coordinates::UTM;

package GBIFNorway::UTM;

sub parse {
  my $zone = shift;
  local $_ = shift;
  s/^UTM-ref\.\s*\(WGS84\)\s*//;
  s/^\s+//; s/\s*$//; s/^UTM\:\s*//i; s/^UTM\(\),,\s*//i; s/^UTM\s*//i;
  s/^\(\s//; s/^\(\),$//; s/^[VW,]\s+//i;
  $zone = $1 if(s/^\((\d\d\w?)\)\s*//);
  $zone = $1 if(s/^(\d\d)\s*\w?\s+//);
  s/^,$//;

  my ($easting, $northing);
  if (/^$/) {
    return;
  } elsif(/^(\d+)[\s,]*(\d+)$/) {
    ($easting, $northing) = ($1, $2);
  } elsif(/^(\d+)[A-Z](\d+),(\d+)$/) {
    ($zone, $easting, $northing) = ($1, $2, $3);
  } elsif(/^([\d-]+)[\s,]*([\d-]+)$/) {
    ($easting, $northing) = ($1, $2);
  } elsif(/^sone (\d+): N:?(\d+)[\s,]+[EØ]:?(\d+)/i) {
    ($zone, $northing, $easting) = ($1, $2, $3);
  } else {
    die "Unable to parse UTM coordinates";
  }

  if($zone && $easting && $northing) {
    return "$zone $easting $northing";
  }
}

1;

