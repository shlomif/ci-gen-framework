use v6.c;
unit class CI::Gen:ver<0.0.1>:auth<cpan:SHLOMIF>;


=begin pod

=head1 NAME

CI::Gen - blah blah blah

=head1 SYNOPSIS

  use CI::Gen;

=head1 DESCRIPTION

CI::Gen is ...

=head1 AUTHOR

Shlomi Fish <shlomif@shlomifish.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shlomi Fish

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

our class CI-Gen {
    has Str $.basedir;
    method generate($name) {

        spurt "$.basedir/bin/install-tidyp-systemwide.bash", q:to/EOF/;
#!/bin/bash

set -x

bdir="$HOME/tidyp-build"
mkdir -p "$bdir"
cd "$bdir"
wget https://github.com/downloads/petdance/tidyp/tidyp-1.04.tar.gz
tar -xf tidyp-1.04.tar.gz
cd tidyp-1.04
./configure && make && sudo make install && sudo ldconfig
EOF

        spurt "$.basedir/.travis.bash", q:to/END_OF_PROGRAM/;
#! /bin/bash
#
# .travis.bash
# Copyright (C) 2018 Shlomi Fish <shlomif@cpan.org>
#
# Distributed under terms of the MIT license.
#
set -e
set -x
cmd="$1"
shift
if false
then
    :
elif test "$cmd" = "before_install"
then
    sudo apt-get update -qq
    sudo apt-get install -y ack-grep cpanminus docbook-defguide docbook-xsl libperl-dev libxml-libxml-perl libxml-libxslt-perl make perl tidy xsltproc
    sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
    cpanm local::lib
elif test "$cmd" = "install"
then
    cpanm --notest Alien::Tidyp YAML::XS
    bash -x bin/install-tidyp-systemwide.bash
    cpanm --notest HTML::Tidy
elif test "$cmd" = "build"
then
    export SCREENPLAY_COMMON_INC_DIR="$PWD/screenplays-common"
    cd selina-mandrake/screenplay/
    make
    make test
fi
END_OF_PROGRAM
    }
}
