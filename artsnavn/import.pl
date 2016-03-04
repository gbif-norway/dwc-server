#!/usr/bin/perl

use strict;
use warnings;
use 5.14.0;
use open qw/:std :utf8/;

use Parse::CSV;
use TokyoCabinet;

my $csv = Parse::CSV->new(
  handle => \*STDIN,
  encoding_in => "utf8",
  quote_char => "\"",
  escape_char => "\\",
  sep_char => ";",
  names => 1,
  binary => 1,
  filter => sub {
    my $row = $_;
    $$row{scientificName} = "$$row{Slekt} $$row{Art}";
    $row;
  }
);

my $db = TokyoCabinet::TDB->new;
if(!$db->open("artsnavn.db", $db->OWRITER | $db->OCREAT)) {
  my $ecode = $db->ecode();
  die("error: " . $db->errmsg($ecode) . "\n");
}

my $n = 0;

while (my $row = $csv->fetch) {
  my $key = "$$row{Rike}-$$row{PK_LatinskNavnID}";
  printf("$key\n");

  next if($$row{Art});
  next if($$row{Underslekt});
  next if($$row{Hovedstatus} ne "Gyldig");

  if($key) {
    $db->put($key, $row);
  }
}

if($csv->errstr) {
  die($csv->errstr . "\n");
}

$db->setindex("Rike", $db->ITLEXICAL);
$db->setindex("Rekke", $db->ITLEXICAL);
$db->setindex("Klasse", $db->ITLEXICAL);
$db->setindex("Orden", $db->ITLEXICAL);
$db->setindex("Familie", $db->ITLEXICAL);
$db->setindex("Slekt", $db->ITLEXICAL);

