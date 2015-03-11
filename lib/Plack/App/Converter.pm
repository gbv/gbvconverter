package Plack::App::Converter;
use v5.14.1;

use parent 'Plack::Component';

use Plack::Builder;
use Plack::Request;
use Plack::Util;
use Plack::Util::Accessor qw(formats);
use JSON;
use Storable qw(dclone);

sub prepare_app {
    my ($self) = @_;
    return if $self->{app};

    $self->{conversions} = { };
    foreach (keys %{$self->{formats}}) {
        $self->{formats}->{$_}->{name} = $_;
        if ( my $target = delete $self->{formats}->{$_}->{target} ) {
            $self->{conversions}->{$_} = $target;
            $self->{formats}->{$_}->{target} = [ keys %$target ];

            while (my($key,$value) = each %$target) {
                Plack::Util::load_class($value);
                no strict 'refs';
                $target->{$key} = \&{$value."::convert"};
            }
        }
    }

    # List of formats in JSON
    my $formats = JSON->new->pretty->encode($self->{formats});

    $self->{app} = builder {
        enable 'ContentLength';
        builder {
            mount '/formats' => sub {
                [ 200, [ 'Content-Type' => 'application/json' ], [ $formats ] ];
            };
            mount '/convert' => sub { $self->convert(@_) };
            mount '/' => sub { [404,[],['Not Found']] };
        };
    };
}

sub convert {
    my ($self, $env) = @_;

    if ($env->{REQUEST_METHOD} ne 'POST') {
        return [ 405, [], ['Method Not Allowed'] ];
    }
    
    my $req = Plack::Request->new($env);
    my $input   = $req->query_parameters->{'input'} // 'upload';
    my $uploads = $req->uploads;
    my ($file)  = values %$uploads;

    if ( $input ne 'upload' ) {
        return [ 400, [], ['Only input=upload supported'] ];
    } elsif ( !%$uploads or !$file ) {
        return [ 400, [], ['Missing upload file'] ];
    } elsif ( $uploads->keys > 1 ) {
        # TODO: some formats may support multiple files
        return [ 400, [], ['Too many upload files'] ];
    }

    my %format = (
        input => $self->guess_format(
            name => $req->parameters->{from},
            type => $file->content_type,
            file => $file->filename
        ),
        output => $self->guess_format( 
            name => $req->parameters->{to},
            type => $req->header('Accept') 
        )
    );

    foreach ( qw(input output) ) {
        if ( !$format{$_} ) {
            return [ 400, [], ["Missing ${_}format"] ];
        } 
        $format{$_} = $self->{formats}->{$format{$_}};
        if (!$format{$_}) {
            return [ 400, [], ["Unknown ${_}format"] ];
        }
    }

    my $from = $format{input}->{name};
    my $to   = $format{output}->{name};

    if ( !$self->{conversions}->{$from} ) {
        return [ 400, [], ["Invalid input format"] ];
    }
    my $conversion = $self->{conversions}->{$from}->{$to};
    if (!$conversion) {
        return [ 400, [], ["Unsupported output format"] ];
    }

    # construct response
    my @headers;
    my $outputfile = $file->filename;
    my $ext = $format{output}->{extension};
    $outputfile = $file->filename.'.'.$ext unless $outputfile =~ s/\.([^.]+)$/.$ext/;
    push @headers, 'Content-Disposition' => "attachment; filename=\"$outputfile\"";
 
    push @headers, 'Content-Type' => $format{output}->{type};
    my $files = { $file->filename => $file->path };
    return [ 200, \@headers, $conversion->( $files ) ];
}

sub guess_format {
    my ($self, %properties) = @_;
    
    return $properties{name} if defined $properties{name};

    my @formats = grep { $self->{formats}->{$_}->{type} eq $properties{type} }
                   keys %{$self->{formats}};

    if (@formats != 1 and $properties{file} and $properties{file} =~ /\.([^.]+)$/) {
        my $extension = $1 // '';
        @formats = grep { $self->{formats}->{$_}->{extension} eq $extension } 
                   keys %{$self->{formats}};
    }

    return @formats == 1 ? $formats[0] : undef;
}

sub call {
    my ($self, $env) = @_;
    $self->{app}->($env);
}

1;
__END__

=head1 SYNOPSIS

  my $app = Plack::App::Convert->new( formats => $formats );

=head1 DESCRIPTION

Provides a web API to convert data via HTTP POST requests.

A converter is a code reference to transform a hash with original filenames to
local files into a PSGI body
(L<https://metacpan.org/pod/distribution/PSGI/PSGI.pod#Body>).

=cut
