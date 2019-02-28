use strict;
use warnings;

use utf8;

package GBIFNorway::LatLon;

sub parsedec {
  local $_ = shift;
  my ($lat, $lon);
  s/,/./g; s/^\s*//; s/\s*$//; s/^Long&Lat: //; s/[\.\s+]+/\./; s/°//i;
  if (/^([\-\d\.]+)°?([EW])\s*([\-\d\.]+)°?([NS])$/) {
    ($lon, $lat) = ($1, $3);
    if($2 eq "W") { $lon = -$lon };
    if($4 eq "S") { $lat = -$lat };
  } elsif (/^([\-\d\.]+)\s*°?\s*([NS])\s*([\-\d\.]+)\s*°?\s*([EW])?$/) {
    ($lat, $lon) = ($1, $3);
    if($2 eq "S") { $lat = -$lat };
    if($4 && $4 eq "W") { $lon = -$lon };
  } elsif (/^\s*([\-\d\.]+)\s+([\-\d\.]+)\s*$/) {
    ($lat, $lon) = ($1, $2);
  } else {
    die("Unable to parse verbatim coordinates $_");
  }
  $lat =~ s/^\.//; $lon =~ s/^\.//;
  return ($lat, $lon);
};

sub parsedeg {
  local $_ = shift;
  my ($y, $x, $lat, $lon, $s, $w);
  my ($ym, $ys, $xm, $xs) = (0, 0, 0, 0);

  s/^\s+|\s+$//g;
  s/N\.\s*Br\./N/i; s/Ø\.L\./E/i; s/, sydgr/S/i; s/^Lat\.\s*//i; s/n\./N/i;
  s/östl\.(v\.\s*F\.)?//i;
  s/,/\./g; s/\&//;


  if(/^(\d+) (\d+)N (\d+) (\d+)E$/) {
    $y = $1; $ym = $2; $x = $3; $xm = $4;
  } elsif(/^(\d+) (\d+)N (\d+)E$/) {
    $y = $1; $ym = $2; $x = $3;
  } elsif(/^(\d+) (\d+)N (\d+)W$/) {
    $y = $1; $ym = $2; $x = $3;
    $w = 1;
  } elsif(/^([\d\.]+)([NS])\s+([\d\.]+)\s+([\d\.]+)([EW])$/) {
    $y = $1; $s = 1 if $2 eq "S";
    $x = $3; $xm = $4; $w = 1 if $5 eq "W";
  } elsif(/^([\d\.]+)\s+([\d\.]+)([NS])\s+([\d\.]+)\s+([\d\.]+)([EW])$/) {
    $y = $1; $ym = $2; $s = 1 if $3 eq "S";
    $x = $4; $xm = $5; $w = 1 if $6 eq "W";
  } elsif(/^(\d+) (\d+)N (\d+) (\d+)W$/) {
    $y = $1; $ym = $2; $x = $3; $xm = $4;
    $w = 1;
  } elsif(/^(\d+)°\s*(\d+)'\s*(\d+)?['"]*\s*([NS])?$/) {
    $y = $1; $ym = $2; $ys = $3 if $3;
    $s = 1 if $4 && $4 eq "S";
  } elsif(/^([NS])\s*(\d+)°(\d+)'(\d+)?"?\s*([EW])(\d+)°(\d+)'(\d+)?"?$/) {
    ($y, $ym) = ($2, $3);
    ($x, $xm) = ($6, $7);
    $ys = $4 if $4; $xs = $8 if $8;
    $s = 1 if $1 eq "S"; $w = 1 if $5 eq "W";
  } elsif(/^(\d+)°?\s*([\d\.]+)'\s*([\d\.]+)?['"]*\s*([NSEW])?[\s\.]*(\d+)°?\s*([\d\.]+)'\s*([\d\.]+)?["']*\s*([NSEW])?/) {
    ($y, $ym) = ($1, $2);
    ($x, $xm) = ($5, $6);
    $ys = $3 if $3; $xs = $7 if $7;
    $s = 1 if ($4 && $4 eq "S") || ($8 && $8 eq "S");
    $w = 1 if ($4 && $4 eq "W") || ($8 && $8 eq "W");
    if(($4 && $4 =~ /[EW]/) || ($8 && $8 =~ /[NS]/)) {
      ($y, $ym, $ys, $x, $xm, $xs) = ($x, $xm, $xs, $y, $ym, $ys);
    }
  } else {
    die("Unable to parse verbatim coordinates");
  }
  $xs = 0 if(!$xs || $xs eq ".");
  $ys = 0 if(!$ys || $ys eq ".");
  $lat = defined($y) ? $y + ($ym / 60) + ($ys / 3600) : "";
  $lon = defined($x) ? $x + ($xm / 60) + ($xs / 3600) : "";

  $lat = -$lat if $s; $lon = -$lon if $w;

  return ($lat, $lon);
};

1;

