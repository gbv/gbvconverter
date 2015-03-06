package GBV::App::GNDMARConvert;
use v5.14.1;

our $VERSION="0.0.0";
our $NAME="gndmarconvert";

use parent 'Plack::Component';

use Plack::Builder;
use Plack::Request;
use JSON qw(to_json);

my $FORMATS = {
    marcxml => { 
        type => 'application/marcxml+xml',
        title => 'MARCXML',
        docs => 'http://www.loc.gov/standards/marcxml/',
        extension => 'xml',
        targets => [qw(json)],
    },
    json => {
        type => 'application/json',
        title => 'JSON',
        extension => 'json',
    }
};
$FORMATS->{$_}->{name} = $_ for keys %$FORMATS;

sub prepare_app {
    my ($self) = @_;
    return if $self->{app};

    # load config file
    my $config = "/etc/default/$NAME";
    if ( -f $config ) {
        local @ARGV = $config;
        while (<>) {
            next if $_ !~ /^\s*([A-Z][_A-Z0-9]*)\s*=\s*([^#\n]*)/;
            if ($1 eq 'PROXY' and $2 !~ /^[*]\s*$/) {
                $self->{TRUST} = [ split /\s*,\s*|\s+/, $1 ];
            }
        }
    }

    # build middleware stack
    $self->{app} = builder {
        enable_if { $self->{TRUST} } 'XForwardedFor',
            trust => $self->{TRUST};
        enable 'CrossOrigin', origins => '*';
        enable 'Rewrite', rules => sub {
            s{^/$}{/index.html}; return
        };
        enable 'Static', path => qr{\.(html|js|ico|css|png)},
            pass_through => 1, root => "/etc/$NAME/htdocs";
        enable 'Static', path => qr{\.(html|js|ico|css|png)},
            pass_through => 1, root => './htdocs';
        enable 'ContentLength';
        builder {
            mount '/formats' => sub { $self->formats(@_) };
            mount '/convert' => sub { $self->convert(@_) };
            mount '/' => sub { [404,[],['Not Found']] };
        };
    };
}    

sub convert {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    if ($req->method ne 'POST') {
        return [ 405, [], ['Method Not Allowed'] ];
    }

    my $input   = $req->query_parameters->{'input'} // 'upload';
    my $uploads = $req->uploads;
    my ($file)  = values %$uploads;

    if ( $input ne 'upload' ) {
        return [ 400, [], ['Only input=upload supported'] ];
    } elsif ( !%$uploads or !$file ) {
        return [ 400, [], ['Missing upload file'] ];
    } elsif ( $uploads->keys > 1 ) {
        return [ 400, [], ['Too many upload files'] ];
    }

    my %format = (
        input => $self->guess_format(
            name => $req->parameters->{'inputformat'},
            type => $file->content_type,
            file => $file->filename
        ),
        output => $self->guess_format( 
            name => $req->parameters->{'outputformat'},
            type => $req->header('Accept') 
        )
    );

    foreach ( qw(input output) ) {
        if ( !$format{$_} ) {
            return [ 400, [], ["Missing ${_}format"] ];
        } 
        $format{$_} = $FORMATS->{$format{$_}};
        if (!$format{$_}) {
            return [ 400, [], ["Unknown ${_}format"] ];
        }
    }

    if ( $format{input}->{name} ne 'marcxml' ) {
        return [ 400, [], ['Only inputformat=marcxml supported'] ];
    }

    if ( $format{output}->{name} ne 'json' ) {
        return [ 400, [], ['Only outputformat=json supported'] ];
    }

    my @headers;

    my $outputfile = $file->filename;
    my $ext = $format{output}->{extension};
    $outputfile = $file->filename.'.'.$ext unless $outputfile =~ s/\.([^.]+)$/.$ext/;
    push @headers, 'Content-Disposition' => "attachment; filename=\"$outputfile\"";
 
    push @headers, 'Content-Type' => $format{output}->{type};

    my $result = $self->perform_convert( $file, $format{input}, $format{output} );
    return [ 200, \@headers, $result ];
}

sub perform_convert {
    my ($file, $input, $output) = @_;
    return "...";
}

sub guess_format {
    my ($self, %properties) = @_;
    
    return $properties{name} if defined $properties{name};

    my @formats = grep { $FORMATS->{$_}->{type} eq $properties{type} }
                  keys %$FORMATS;

    if (@formats != 1 and $properties{file} and $properties{file} =~ /\.([^.]+)$/) {
        my $extension = $1 // '';
        @formats = grep { $FORMATS->{$_}->{extension} eq $extension } keys %$FORMATS;
    }

    return @formats == 1 ? $formats[0] : undef;
}

sub formats {
    [ 200, [ 'Content-Type' => 'application/json' ], 
        [ JSON->new->pretty->encode($FORMATS) ] 
    ];
}

sub call {
    my ($self, $env) = @_;
    $self->{app}->($env);
}

1;
