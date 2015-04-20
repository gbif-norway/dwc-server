package Artsnavn;

use TokyoCabinet;

our $db = TokyoCabinet::TDB->new;
if(!$db->open("artsnavn/artsnavn.db", $db->OREADER)) {
  my $ecode = $db->ecode();
  die("artsnavn error: " . $db->errmsg($ecode) . "\n");
}

our %cache;
sub addtaxonomy {
  my ($dwc, $kingdom, $overwrite) = @_;
  my ($genus, $epithet);
  if($$dwc{genus}) {
    $genus = $$dwc{genus};
  } elsif($$dwc{scientificName}) {
    ($genus, $epithet) = split(/\s/, $$dwc{scientificName}, 2);
  } else {
    $dwc->adderror("Missing scientificName", "name");
    return;
  }
  if($cache{$genus}) {
    $name = $cache{$genus};
  } else {
    my $q = TokyoCabinet::TDBQRY->new($db);
    if($kingdom) {
      $q->addcond("Rike", $q->QCSTREQ, $kingdom);
    }
    $q->addcond("Slekt", $q->QCSTREQ, $genus);
    my $results = $q->search();
    if(@{$results} < 1) {
      my $l = scalar @{$results};
      die("Couldn't find $genus in Artsnavnebasen\n");
      return;
    } elsif(@{$results} > 1) {
      my $l = scalar @{$results};
    }
    $name = $db->get($$results[0]);
    $cache{$genus} = $name;
  }

  if($overwrite) {
    $$dwc{specificEpithet} = $epithet if $epithet;
    $$dwc{genus} = $$name{Slekt};
    $$dwc{family} = $$name{Familie};
    $$dwc{order} = $$name{Orden};
    $$dwc{class} = $$name{Klasse};
    $$dwc{phylum} = $$name{Rekke};
    $$dwc{kingdom} = $$name{Rike};
    $dwc->addinfo("Added higher taxonomic ranks from Artsnavnebasen", "name");
  }
}

1;

