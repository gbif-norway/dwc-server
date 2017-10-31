use strict;
use 5.14.0;

package DwC::Plugin::BOLD;

use TokyoCabinet;

our $db = TokyoCabinet::TDB->new;
if(!$db->open("bold/bold.db", $db->OREADER)) {
  my $ecode = $db->ecode();
  die("BOLD db error: " . $db->errmsg($ecode) . "\n");
}

sub description {
  return "Add references to BOLD sequences";
}

sub completeness {
}

sub validate {
  my ($plugin, $dwc) = @_;

  my $id = $$dwc{occurrenceID};
  $id =~ s/urn:catalog://;

  my $rec = $db->get($id);
  if($rec) {
    $$dwc{associatedSequences} = $$rec{url};
    $dwc->log("info", "Added sequence URI from BOLD", "sequence");
  }
}

1;

