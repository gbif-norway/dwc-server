use strict;
use warnings;

use Test::Simple tests => 1;

use GBIFNorway;

do 'formats/musit.pl';

my %dwc = ( verbatimCoordinates => "UTM(32)583319,6549544" );
GBIFNorway::Musit::clean(\%dwc);
ok("verbatimCoordinateSystem", "UTM");

