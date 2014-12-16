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
  quote_char => undef,
  escape_char => undef,
  sep_char => "\t",
  names => 1,
  binary => 1,
);

my $db = TokyoCabinet::TDB->new;
if(!$db->open("countries.db", $db->OWRITER | $db->OCREAT)) {
  my $ecode = $db->ecode();
  die("error: " . $db->errmsg($ecode) . "\n");
}

while (my $row = $csv->fetch) {
  my $key = $$row{Country};
  if($key) {
    $db->put($key, $row);
  }
}

if($csv->errstr) {
  die($csv->errstr . "\n");
}

