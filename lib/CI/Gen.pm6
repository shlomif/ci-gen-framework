use v6.c;
unit class CI::Gen:ver<0.0.1>:auth<cpan:SHLOMIF>;


=begin pod

=head1 NAME

CI::Gen - A continuous integration scriptology generation framework

=head1 SYNOPSIS

    $ git clone ...
    $ zef install --force-install .
    $ ci-generate

=head1 DESCRIPTION

CI::Gen aims to be a continuous integration scriptology generation framework.
Currently it is far from being generic enough.

I don't know about you, but I find it tiresome to maintain all the .travis.yml
/ .appveyor.yml / etc. configurations for my repositories which are full
of copy+paste and duplicate code. CI-Gen eventually aims to generate them
based on the https://en.wikipedia.org/wiki/Don%27t_repeat_yourself principle .

=head1 Philosophy

Bottom-up design and avoiding https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it .

See https://www.joelonsoftware.com/2002/01/23/rub-a-dub-dub/ :

"This stuff went into classes which were not really designed — I simply added
methods lazily as I discovered a need for them. (Somewhere, someone with a big
stack of 4×6 cards is sharpening their pencil to poke my eyes out. What do you
mean you didn’t design your classes?) "

=head1 AUTHOR

Shlomi Fish <shlomif@shlomifish.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Shlomi Fish

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

our class CI-Gen {
    has Str $.basedir;
    has Str %.params;

    method base-spurt($path, $contents) {
        my $p = IO::Path.new("$.basedir/$path");
        IO::Path.new($p.dirname).mkdir;
        return spurt $p, $contents;
    }

    method generate($name) {

        self.base-spurt("bin/install-tidyp-systemwide.bash", q:to/EOF/);
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

        self.base-spurt(".travis.bash", q:c:to/END_OF_PROGRAM/);
#! /bin/bash
#
# .travis.bash
# Copyright (C) 2018 Shlomi Fish <shlomif@cpan.org>
#
# Distributed under terms of the MIT license.
#
set -e
set -x
arg_name="$1"
shift
if test "$arg_name" != "--cmd"
then
    echo "usage : $0 --cmd [cmd]"
    exit -1
fi
cmd="$1"
shift
if false
then
    :
elif test "$cmd" = "before_install"
then
    sudo apt-get update -qq
    sudo apt-get install -y ack-grep cpanminus dbtoepub docbook-defguide docbook-xsl libperl-dev libxml-libxml-perl libxml-libxslt-perl make perl tidy xsltproc
    sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
    cpanm local::lib
elif test "$cmd" = "install"
then
    cpanm --notest Alien::Tidyp YAML::XS
    bash -x bin/install-tidyp-systemwide.bash
    cpanm --notest HTML::Tidy
    h=~/Docs/homepage/homepage
    mkdir -p "$h"
    git clone https://github.com/shlomif/shlomi-fish-homepage "$h/trunk"
elif test "$cmd" = "build"
then
    export SCREENPLAY_COMMON_INC_DIR="$PWD/screenplays-common"
    cd {%.params{'screenplay_subdir'}}
    m()
    {'{'}
        make DBTOEPUB="/usr/bin/ruby $(which dbtoepub)" \
            DOCBOOK5_XSL_STYLESHEETS_PATH=/usr/share/xml/docbook/stylesheet/docbook-xsl-ns \
        "$@"
    {'}'}
    m
    m test
fi
END_OF_PROGRAM

       self.base-spurt(".travis.yml", q:to/END_OF_PROGRAM/);
cache:
    directories:
        - $HOME/perl_modules
os: linux
dist: trusty
before_install:
    - bash .travis.bash --cmd before_install
    - eval "$(perl -Mlocal::lib=$HOME/perl_modules)"
    - bash .travis.bash --cmd install
    - cpanm File::Find::Object::Rule IO::All XML::Grammar::Screenplay
    - git clone https://github.com/shlomif/screenplays-common
perl:
    - "5.22"
python:
    - "3.5"
script:
    - bash .travis.bash --cmd build
sudo: required
END_OF_PROGRAM
    }
}
