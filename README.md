# NAME

gbvconverter - MARCXML GND authority record conversion webservice

[![Build Status](https://travis-ci.org/gbv/gbvconverter.svg)](https://travis-ci.org/gbv/gbvconverter)
[![Latest Release](https://img.shields.io/github/release/gbv/gbvconverter.svg)](https://github.com/gbv/gbvconverter/releases)

# DESCRIPTION

**gbvconverter** provides a webservice to convert MARCXML authority records of GND.

# SYNOPSIS

The application is automatically started as service, listening on port 6100.

    sudo service gbvconverter {status|start|stop|restart}

The main page on <http://localhost:6100/> provides API documentation.

The command line client `gbvconvert` can also be used without installation:

    git clone https://github.com/gbv/gbvconverter.git
    carton install 
    ./bin/gbvconvert -f marcxml -t json some-marc-file.xml

# INSTALLATION

The application is packaged as Debian package. No binaries are included, so the
package should work on all architectures. It is tested with Ubuntu 12.04 LTS.

Files are installed at the following locations:

* `/srv/gbvconverter/` - application
* `/var/log/gbvconverter/` - log files
* `/etc/default/gbvconverter` - server configuration
* `/etc/gbvconverter` - application configuration

# CONFIGURATION

See `/etc/default/gbvconverter` for basic configuration. Settings are not modified
by updates. Restart is needed after changes. Only simple key value-pairs are
allowed with the following keys:

* `PORT` - port number (required, 6100 by default)

* `WORKERS` - number of parallel connections (required, 5 by default). If put 
   behind a HTTP proxy, this number is not affected by slow cient connections 
   but only by the time of processing each request.

* `PROXY` - optional space-or-comma-separated list of trusted IPs or IP-ranges
   (e.g. `192.168.0.0/16`) to take from the `X-Forwarded-For` header.
   The special value `*` can be used to trust all IPs.

The HTML client can be customized by putting static files into directory
`/etc/gbvconverter/htdocs` to override files in `/srv/gbvconverter/htdocs`.

# SEE ALSO

Changelog is located in `debian/changelog` in the source code repository.

Source code and issue tracker at <https://github.com/gbv/gbvconverter>. See
file `CONTRIBUTING.md` for details.
