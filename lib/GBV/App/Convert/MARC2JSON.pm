package GBV::App::Convert::MARC2JSON;
use v5.14;

use MARC::File::XML (
    BinaryEncoding => 'UTF-8', DefaultEncoding => 'UTF-8', RecordFormat => 'MARC21'
);
use GBV::MARC::Decoder;
use Unicode::Normalize 'normalize';
use JSON;

use parent 'Exporter';
our @EXPORT_OK = qw(marc2json);

sub marc2json {
    my ($file,%options) = @_;
    my $marc = MARC::File::XML->in($file);
    $marc = decode_marc($marc->next);
    if (($options{normalize} // '') =~ /^NF(K?[CD])$/) {
        my $form = $1;
        $marc->{record} = [
            map {
                [ map { defined $_ ? normalize($form, $_) : undef } @$_ ]
            } @{$marc->{record}}
        ];
    }
    return $marc;
}

sub convert {
    my ($files, %options) = @_;
    my ($filename) = values %$files;

    my $json = marc2json($filename);

    return [ JSON->new->utf8->pretty->encode($json) ];
}

1;
__END__

=head1 SYNOPSIS

    use GBV::App::Convert::MARC2JSON qw(marc2json);
    
    my $json = marc2json('marc.xml');

    my $body = GBV::App::Convert::MARC2JSON::convert({
        1 => 'marc.xml'
    }, normalize => 'NFC' );

=head1 DESCRIPTION

Convert MARC21 XML files to JSON representation as used in L<Catmandu::MARC>.

=cut
