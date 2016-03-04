use strict;
use warnings;

package Artsnavn;

use TokyoCabinet;

our @ranks = (
  "genus", "Slekt",
  "family", "Familie",
  "order", "Orden",
  "class", "Klasse",
  "phylum", "Rekke"
);

our $db = TokyoCabinet::TDB->new;
if(!$db->open("artsnavn/artsnavn.db", $db->OREADER)) {
  my $ecode = $db->ecode();
  die("artsnavn error: " . $db->errmsg($ecode) . "\n");
}

our %cache;
sub addtaxonomy {
  my ($dwc, $kingdom, $overwrite) = @_;

  my ($raw, $name);

  if($$dwc{genus}) {
    $raw = $$dwc{genus};
  } elsif($$dwc{scientificName}) {
    ($raw, $_) = split(/\s/, $$dwc{scientificName}, 2);
  } else {
    $dwc->adderror("Missing scientificName", "name");
    return;
  }

  if($cache{$raw}) {
    $name = $cache{$raw};
  } else {
    for(my $i = 0; $i <= $#ranks && !$name; $i += 2) {
      my $rank = $ranks[$i];
      my $key = $ranks[$i + 1];
      my $q = TokyoCabinet::TDBQRY->new($db);
      if($kingdom && $kingdom ne "All") {
        $q->addcond("Rike", $q->QCSTREQ, $kingdom);
      }
      $q->addcond($key, $q->QCSTREQ, $raw);
      my $results = $q->search();
      if(@{$results} > 0) {
        $name = $db->get($$results[0]);
        $$name{rank} = $rank;
        $cache{$raw} = $name;
      }
    }
  }
  if(!$name) {
    die("Couldn't find $raw in Artsnavnebasen\n");
  }

  if($overwrite) {
    my $rank = $$name{rank};
    $$dwc{genus} = $$name{Slekt} unless grep /^$rank$/, ('order', 'class', 'phylum');
    $$dwc{family} = $$name{Familie} unless grep /^$rank$/, ('order', 'class', 'phylum');
    $$dwc{order} = $$name{Orden} unless grep /^$rank$/, ('class', 'phylum');
    $$dwc{class} = $$name{Klasse} unless grep /^$rank$/, ('phylum');
    $$dwc{phylum} = $$name{Rekke};
    $$dwc{kingdom} = $$name{Rike};
    $dwc->addinfo("Added higher taxonomic ranks from Artsnavnebasen", "name");
  }
}

1;

