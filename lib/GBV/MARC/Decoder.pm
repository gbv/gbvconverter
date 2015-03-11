package GBV::MARC::Decoder;
use v5.14;

use parent 'Exporter';

our @EXPORT = qw(decode_marc marc_fields marc_subfield);

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


sub decode_marc {
    decode(undef, shift, '001');
}

# copied from Catmandu::Importer::MARC::Decoder;
sub decode {
    my ($self, $record, $id) = @_;
    return unless eval { $record->isa('MARC::Record') };
    my @result = ();
 
    push @result , [ 'LDR' , undef, undef, '_' , $record->leader ];
 
    for my $field ($record->fields()) {
        my $tag  = $field->tag;
        my $ind1 = $field->indicator(1);
        my $ind2 = $field->indicator(2);
 
        my @sf = ();
 
        if ($field->is_control_field) {
            push @sf , '_', $field->data;
        }
 
        for my $subfield ($field->subfields) {
            push @sf , @$subfield;
        }
 
        push @result, [$tag,$ind1,$ind2,@sf];
    }
 
    my $sysid = undef;
 
    if ($id =~ /^00/ && $record->field($id)) {
        $sysid = $record->field($id)->data();
    }
    elsif ($id =~ /^(\d{3})([\da-zA-Z])$/) {
        my $field = $record->field($1);
        $sysid = $field->subfield($2) if ($field);
    }
    elsif (defined $id  && $record->field($id)) {
        $sysid = $record->field($id)->subfield("a");
    }
 
    return { _id => $sysid , record => \@result };
}

1;
