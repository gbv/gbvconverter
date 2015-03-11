package GBV::App::Convert::GNDMARC2JSONLD;
use v5.14;

use GBV::App::Convert::MARC2JSON qw(marc2json);
use JSON;

# MARCXML records with GND data (as documented
# <a href="http://www.dnb.de/DE/Standardisierung/Formate/MARC21/marc21_node.html">at DNB</a>
# and <a href="http://www.loc.gov/marc/authority/">at LoC</a>)

sub convert {
    my ($files, %options) = @_;
    my ($filename) = values %$files;

    my $json = marc2json($filename);

    return [ JSON->new->utf8->pretty->encode($json) ];
}

1;

__END__
sub transform {
    my ($marc) = @_;

    my $data = {
# TODO        
#        uri => marc_map($marc,'024a') || undef,
    };

    # TODO: allgemeine Unterfelder: $9U: (Schrift) und $9L: (Sprache)

#    use Data::Printer; p $marc;
    
    $data->{prefLabel} = prefLabel( marc_fields($marc,qw(100 110 111 130 150 151)) );
    # TODO: foaf_name

    # altLabel
 
    # Variant name for the conference or event
    #   411 $a $c $d $e $n $9

    # Variant name for the corporate body
    #   410 $a $b $n $9

    # Variant name for the family = Variant name for the person
    #   400 $a $b $c $9

    # Variant name for the place or geographic name
    #   451 $a $z $9

    # Variant name for the subject heading
    #   450 $a $9

    # Variant name for the work
    #   430 $a $f $m $n $o $p $r $s $9

    exporter('YAML')->add($data);
}

sub prefLabel {
    my @fields = @_;
    return unless @fields;

    my $tag = $fields[0]->[0];
    say $tag; # 100 110 111 130 150 151

    # 100a: Name einer Person oder Familie in der Struktur 'Nachname, Vorname' (1)
    # 100b: Zählung der Person (1)
    # 100c: Beinamen, Gattungsnamen etc. (*)
    # 1009: ???

    # 110a: ...
    # 110b: ...
    # 110n: ...
    # 1109: ???
    
    # 111a: ...
    # 111c: ...
    # 111d: ...
    # 111e: ...
    # 111n: ...
    # 1119: ???

    # 130a: ...
    # 130f: ...
    # 130m: ...
    # 130n: ...
    # 130o: ...
    # 130p: ...
    # 130r: ...
    # 130s: ...
    # 1309: ???

    # 130a: ...
    # 1509: ???
    
    # 151a: Name eines Geografikums (1)
    # 151z: Geografische Unterteilung (*)
    # 1519: ???
    
    # TODO: more subfields
    return marc_subfield('a', $fields[0]);
}


__END__
USAGE:
  ./bin/gndmarconvert -o json $MARCXMLDATEI
