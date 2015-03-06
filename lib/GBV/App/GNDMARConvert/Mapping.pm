package GBV::App::GNDMARConvert::Mapping;
use v5.14.1;

use parent 'Exporter';
our @EXPORT = qw(marc_fields marc_subfield marc_file_to_json);

# get first set of fields with same tag
sub marc_fields {
    my ($record, @fields) = @_;

    $record = $record->{record};
    @fields = map { qr{$_} } @fields;

    my @result;
    for my $field (@fields) {
        for my $var (@$record) {
            next if $var->[0] !~ $field;
            push @result, $var;
            last unless wantarray;
        }
        last if @result;
    }
    return @result;
}

# get first (!) subfield
sub marc_subfield {
    my ($subfield, @fields) = @_;
    for my $field (@fields) {
        for (my $i=3; $i<@$field; $i+=2) {
            if ($field->[$i] eq $subfield) {
                return $field->[$i+1];
            }
        }
    }        
}

use MARC::File::XML (BinaryEncoding => 'UTF-8', DefaultEncoding => 'UTF-8', RecordFormat => 'MARC21');
use GBV::App::GNDMARConvert::Decoder;

sub marc_file_to_json {
    my $file   = MARC::File::XML->in(shift);
    my $record = $file->next;
    $record = decode_marc($record);

    return $record;
}

1;
