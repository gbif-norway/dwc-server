use strict;
use 5.14.0;

package DwC::Plugin::Artsnavn;

use TokyoCabinet;

our %cache;
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

sub description {
  return "Basic sanity checks";
}

sub completeness {
}

sub validate {
  my ($plugin, $dwc) = @_;

  my ($raw, $name);

  if($$dwc{genus}) {
    $raw = $$dwc{genus};
  } elsif($$dwc{scientificName}) {
    ($raw, $_) = split(/\s/, $$dwc{scientificName}, 2);
  } else {
    $dwc->log("error", "Missing scientificName", "name");
    return;
  }
  if($cache{$raw}) {
    $name = $cache{$raw};
  } else {
    for(my $i = 0; $i <= $#ranks && !$name; $i += 2) {
      my $rank = $ranks[$i];
      my $key = $ranks[$i + 1];
      my $q = TokyoCabinet::TDBQRY->new($db);

      my $kingdom = $ENV{ARTSNAVN_KINGDOM};
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
    $dwc->log("warning", "Couldn't find $raw in Artsnavnebasen", "name");
  }

  my $keep = $ENV{ARTSNAVN_KEEP};
  if(!$keep) {
    my $rank = $$name{rank};
    $$dwc{genus} = $$name{Slekt} unless grep /^$rank$/, ('order', 'class', 'phylum');
    $$dwc{family} = $$name{Familie} unless grep /^$rank$/, ('order', 'class', 'phylum');
    $$dwc{order} = $$name{Orden} unless grep /^$rank$/, ('class', 'phylum');
    $$dwc{class} = $$name{Klasse} unless grep /^$rank$/, ('phylum');
    $$dwc{phylum} = $$name{Rekke};
    $$dwc{kingdom} = $$name{Rike};

    utf8::decode($$dwc{genus});
    utf8::decode($$dwc{family});
    utf8::decode($$dwc{order});
    utf8::decode($$dwc{class});
    utf8::decode($$dwc{phylum});
    utf8::decode($$dwc{kingdom});

    $dwc->log("info",
      "Added higher taxonomic ranks from Artsnavnebasen", "name");
  }
}

1;

