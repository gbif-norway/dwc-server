#!/usr/bin/perl

use strict;
use warnings;
use 5.14.0;
use open qw/:std :utf8/;

use Text::CSV_XS;
use LWP::Simple;
use Parse::CSV;
use TokyoCabinet;
use Data::Dumper;

my $csv = Parse::CSV->new(
  handle => \*STDIN,
  encoding_in => "utf8",
  sep_char => "\t",
  names => 1,
  filter => sub {
    my $row = $_;
    $$row{occurrenceID} =~ s/-/:/g;
    $row;
  }
);

my $db = TokyoCabinet::TDB->new;
if(!$db->open("bold.db", $db->OWRITER | $db->OCREAT)) {
  my $ecode = $db->ecode();
  die("error: " . $db->errmsg($ecode) . "\n");
}

while (my $row = $csv->fetch) {
  my $key = $$row{occurrenceID};
  my $rec = $db->get($key);

  if(!$rec) {
    my $raw = get("http://www.boldsystems.org/index.php/API_Public/combined?ids=" . $$row{processID} . "&format=tsv");

    open my $fh, '<', \$raw;
    my %options = (
      sep_char => "\t",
      handle => $fh,
      names => 1
    );

    my $csv2 = Parse::CSV->new(%options);
    while (my $boldres = $csv2->fetch) {
      $$row{marker} = $$boldres{markercode};
      $$row{sequence} = $$boldres{nucleotides};
      print Dumper($boldres);
    }
    $$row{url} = "http://www.boldsystems.org/index.php/API_Public/sequence?ids=" . $$row{processID};
    $db->put($key, $row);
  }
}

if($csv->errstr) {
  die($csv->errstr . "\n");
}

# $db->setindex("Rike", $db->ITLEXICAL);
# $db->setindex("Rekke", $db->ITLEXICAL);
# $db->setindex("Klasse", $db->ITLEXICAL);
# $db->setindex("Orden", $db->ITLEXICAL);
# $db->setindex("Familie", $db->ITLEXICAL);
# $db->setindex("Slekt", $db->ITLEXICAL);

