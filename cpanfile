requires 'perl', '5.14.1';

requires 'Plack::Middleware::CrossOrigin';
requires 'Plack::Middleware::XForwardedFor';
requires 'Plack::Middleware::Rewrite';

test_requires 'Plack::Util::Load';

# not listed here because implied by required Debian packages:
# - Plack and Starman
# - JSON
# - Marc::File
