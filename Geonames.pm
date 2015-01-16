package Geonames;
use TokyoCabinet;
our $db = TokyoCabinet::TDB->new;

if(!$db->open("geonames/countries.db", $db->OREADER)) {
  my $ecode = $db->ecode();
  die("geonames error: " . $db->errmsg($ecode) . "\n");
}
our %continents = (
  'AF' => 'Africa',
  'AN' => 'Antarctica',
  'AS' => 'Asia',
  'EU' => 'Europe',
  'NA' => 'North America',
  'OC' => 'Oceania',
  'SA' => 'South America'
);
sub continent {
  my $country = shift;
  my $info = $db->get($country);
  my $continent = $continents{$$info{Continent}} if $info;
  if(!$continent) {
    # warn "Finner ikke kontinent for $country";
    return "Unknown";
  }
  return $continent;
}

1;
