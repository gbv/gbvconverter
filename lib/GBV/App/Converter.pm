package GBV::App::Converter;
use v5.14.1;

our $VERSION="0.0.0";
our $NAME="gbvconverter";

use parent 'Plack::App::Converter';

use Plack::Builder;
use JSON;

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

    my $formats = do { 
        my ($file) = grep { -f $_ } ("formats.json", "/srv/$NAME/formats.json");
        local (@ARGV, $/) = ($file);
        JSON->new->decode(<>);
    };

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
            formats => $formats
        );
    };
}    

1;
