package GBV::App::GNDMARConvert;
use v5.14.1;

our $VERSION="0.0.0";
our $NAME="gndmarconvert";

use parent 'Plack::App::Converter';

use Plack::Builder;

## TODO: more conversions
use File::Temp qw(tempfile);
use GBV::App::GNDMARConvert::Mapping;
###

my $FORMATS = {
    marcxml => { 
        type => 'application/marcxml+xml',
        title => 'MARCXML',
        docs => 'http://www.loc.gov/standards/marcxml/',
        extension => 'xml',
        targets => {
            json => \&marcxml2json,
            'json-ld' => \&marcxml2jsonld,
        }
    },
    json => {
        type => 'application/json',
        title => 'JSON',
        extension => 'json',
    },
    'json-ld' => {
        type => 'application/ld+json',
        title => 'JSON-LD',
        extension => 'json'
    },
};

sub marcxml2json {
    my ($input) = @_; # Plack::Request::Upload
    my $filename = $input->tempname;
    my $json = marc_file_to_json($filename);
    # $fh = tempfile();
    return [ JSON->new->pretty->utf8->encode($json) ];
}

sub marcxml2jsonld {
    my ($input) = @_; # Plack::Request::Upload
    # ...
    return [ "" ]
}

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
        Plack::App::Converter->new( 
            formats => $FORMATS 
        );
    };
}    

1;
