use strict;
use warnings;

use Geo::Coordinates::UTM;

package GBIFNorway::MGRS;

our %distance = (
  1 => 5000,
  2 => 500,
  3 => 50,
  4 => 5,
  5 => 0.5
);

sub expand {
  my $m = shift;
  if(length($m) < 5) {
    $m = $m . $distance{length($m)};
  }
  return $m;
};

sub zone {
  # return "35W";
  my $raw = shift;
  if ($raw =~ /^JH|JJ|JK|JL|JM|JN|JP|JQ|JR|KH|KJ|KK|KL|KM|KN|KP|KQ|KR|KS|LH|LJ|LK|LL|LM|LN|LP|LQ|LR|MH|MJ|MK|ML|MM|MN|MP|MQ|NH|NJ|NK|NL|NM|NN|NP|NQ|PH|PJ|PK|PL|PM|PN|PP|PQ$/) {
    return "32V";
  }
  if ($raw =~ /^LV|LA|LB|LC|LD|LE|MR|MV|MA|MB|MC|MD|ME|NR|NS|NT|NU|NV|NA|NB|NC|ND|NE|PR|PS|PT|PU|PV|PA|PB|PC|PD|PE$/) {
    return "32W";
  }
  if ($raw =~ /^UC|UD|UE|UF|UG|UH|UJ|UK|UL|UM|VC|VD|VE|VF|VG|VH|VJ|VK|VL|WC|WD|WE|WF|WG|WH|WJ|WK|WL|XC|XD|XE|XF|XG|XH|XJ|XK|XL|XM$/) {
    return "33V";
  }
  if ($raw =~ /^UN|UP|UQ|UR|US|UT|UU|UV|VM|VN|VP|VQ|VR|VS|VT|VU|VV|WM|WN|WP|WQ|WR|WS|WT|WU|WV|XN|XP|XQ|XR|XS|XT|XU|XV$/) {
    return "33W";
  }
  if ($raw =~ /^CR|CS|CT|CU|CV|CA|CB|CC|CD|CE|DR|DS|DT|DU|DV|DA|DB|DC|DD|DE|ER|ES|ET|EU|EV|EA|EB|EC|ED|EE|FR|FS|FT|FU|FV|FA|FB|FC|FD|FE$/) {
    return "34W";
  }
  if ($raw =~ /^LS|LT|LU|MS|MT|MU$/) {
    return "35W";
  }
  if ($raw =~ /^CQ$/) { # Sverige
    return "34V";
  }
  if ($raw =~ /^UA$/) { # Danmark
    return "33U";
  }
  if ($raw =~ /^PG$/) { # Danmark
    return "32U";
  }
  die "Unable to determine MGRS grid zone";
}

sub parse {
  my $raw = shift;
  my ($zones, $es, $ns);
  my @box;

  if($raw =~ /^(\d+\D+)(\d+)$/) { # 32VNP500500
    my $n = length($2) / 2;
    $zones = $1;
    $es = substr($2, 0, $n);
    $ns = substr($2, $n, $n);
  } elsif($raw =~ /^(\w\w) (\d+)$/) {
    my $n = length($2) / 2;
    $zones = $1;
    $es = substr($2, 0, $n);
    $ns = substr($2, $n, $n);
  } else {
    ($zones, $es, $ns) = split(/[\s\,]+/, $raw);
  }

  my ($z, $z2) = $zones =~ /-/ ? split("-", $zones) : ($zones, $zones);
  my ($e, $e2) = $es =~ /-/ ? split("-", $es) : ($es, $es);
  my ($n, $n2) = $ns =~ /-/ ? split("-", $ns) : ($ns, $ns);
  my ($mgrs, $dn, $de);

  if(!defined($n)) {
    die "Missing northing";
  }
  if(length($e) != length($n) || length($e2) != length($n2)) {
    die "Broken MGRS string";
  }
  if(length($e) > 5) {
    die "Broken MGRS string (too long)";
  }

  if($z  !~ /^\d/) {
    my $guess = zone($z);
    if($guess) {
      $z = $guess . "$z";
      my $guess2 = zone($z2);
      if($guess2) {
        $z2 = $guess2 . "$z2";
      } else {
        die "Unable to determine MGRS grid zone designator";
      }
    } else {
      die "Unable to determine MGRS grid zone designator";
    }
  } elsif($z2 !~ /^\d/) {
    if($z =~ /^\d\d\w\w\w$/) {
      $z2 = substr($z, 0, 3) . $z2;
    } else {
      die "Unable to parse MGRS grid zone $z";
    }
  }

  if("$z$e$n" eq "$z2$e2$n2") {
    $dn = $distance{length($n)};
    $de = $distance{length($e)};

    # test
    eval {
      my $n1 = expand($n);
      my $e1 = expand($e);
      my $n2 = $n1 + ($distance{length($n)});
      my $e2 = $e1 + ($distance{length($e)});
      $n1 = $n1 - ($distance{length($n)});
      $e1 = $e1 - ($distance{length($e)});
      my $lol = $distance{length($e)} * 2;
      my $mgrs_tl = sprintf("%s%05s%05s", $z, $e1, $n1);
      my $mgrs_tr = sprintf("%s%05s%05s", $z, $e2, $n1);
      my $mgrs_br = sprintf("%s%05s%05s", $z, $e2, $n2);
      my $mgrs_bl = sprintf("%s%05s%05s", $z, $e1, $n2);

      my ($z, $x, $y);
      ($z, $x, $y) = Geo::Coordinates::UTM::mgrs_to_utm("$mgrs_tl");
      push @box, [$z, $x, $y];
      ($z, $x, $y) = Geo::Coordinates::UTM::mgrs_to_utm("$mgrs_tr");
      push @box, [$z, $x, $y];
      ($z, $x, $y) = Geo::Coordinates::UTM::mgrs_to_utm("$mgrs_br");
      push @box, [$z, $x, $y];
      ($z, $x, $y) = Geo::Coordinates::UTM::mgrs_to_utm("$mgrs_bl");
      push @box, [$z, $x, $y];
    };

    $n = expand($n); $e = expand($e);
    $mgrs = sprintf("%s%05s%05s", $z, $e, $n);
  } elsif("$z" eq "$z2") {
    my $k = $distance{length($n)} * 2;
    ($n, $e) = (expand($n), expand($e));
    ($n2, $e2) = (expand($n2), expand($e2));
    my $nc = int((($n + $n2) / 2) + 0.5);
    my $ec = int((($e + $e2) / 2) + 0.5);
    $de = ($k + $e2 - $e) / 2;
    $dn = ($k + $n2 - $n) / 2;
    $mgrs = sprintf("%s%05s%05s", $z, $ec, $nc);
  } elsif("$e$n" eq "$e2$n2") {
    die "Broken MGRS string";
  } else {
    my $k = $distance{length($n)} * 2;
    ($n, $e) = (expand($n), expand($e));
    ($n2, $e2) = (expand($n2), expand($e2));
    my $from = sprintf("%s%05s%05s", $z, $e, $n);
    my $to = sprintf("%s%05s%05s", $z2, $e2, $n2);
    my ($uz, $ue, $un) = Geo::Coordinates::UTM::mgrs_to_utm($from);
    my ($uz2, $ue2, $un2) = Geo::Coordinates::UTM::mgrs_to_utm($to);
    if($uz ne $uz2) {
      my $proj1 = Geo::Proj4->new("+proj=utm +zone=$uz2");
      my $proj2 = Geo::Proj4->new("+proj=utm +zone=$uz");
      ($ue2, $un2) = @{$proj1->transform($proj2, [$ue2, $un2])};
    }
    my $nc = int((($un + $un2) / 2 + 0.5));
    my $ec = int((($ue + $ue2) / 2 + 0.5));

    $de = ($k + $ue2 - $ue) / 2;
    $dn = ($k + $un2 - $un) / 2;
    $mgrs = Geo::Coordinates::UTM::utm_to_mgrs($uz, $ec, $nc);
  }
  my $d = int(sqrt($de*$de + $dn*$dn) + 0.5);

  return ($mgrs, $d, @box);
};

1;

