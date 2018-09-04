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

This library is free software; you can redistribute it and/or modify it under the MIT/Expat license.

=end pod

our class CI-Gen {
    has Str $.basedir;
    has Str %.params;
    has Str $.theme;

    method base-spurt($path, $contents) {
        my $p = IO::Path.new("$.basedir/$path");
        IO::Path.new($p.dirname).mkdir;
        return spurt $p, $contents;
    }

    method travis-yml-spurt($contents) {
        my $fn = ".travis.yml";
        return self.base-spurt($fn, $contents);
    }

    method generate($name) {

        if (not $.theme eq ('dzil'|'latemp'|'XML-Grammar-Fiction'))
        {
            die "unknown theme";
        }
        my $dzil = ($.theme eq 'dzil');
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

        if ($.theme eq 'XML-Grammar-Fiction')
        {
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
       }

       my $travis-cache = q:to/END_OF_PROGRAM/;
cache:
    directories:
        - $HOME/perl_modules
END_OF_PROGRAM

       if ($.theme eq 'latemp')
       {
           self.travis-yml-spurt(q:c:to/END_OF_PROGRAM/);
{$travis-cache}
os: linux
dist: trusty
before_install:
    - sudo apt-get update -qq
    - sudo apt-get --no-install-recommends install -y ack-grep asciidoc build-essential cmake cpanminus dbtoepub docbook-defguide docbook-xsl docbook-xsl-ns fortune-mod hunspell inkscape myspell-en-gb libdb5.3-dev libgd-dev libhunspell-dev libncurses-dev libpcre3-dev libperl-dev mercurial myspell-en-gb lynx optipng perl python3 python3-setuptools python3-pip silversearcher-ag tidy valgrind wml xsltproc xz-utils zip
    - sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
    - go get -u github.com/tdewolff/minify/cmd/minify
    - cpanm local::lib
    - eval "$(perl -Mlocal::lib=$HOME/perl_modules)"
    - cpanm Alien::Tidyp App::XML::DocBook::Builder Pod::Xhtml YAML::XS
    - cpanm --notest HTML::Tidy
    - cpanm Alien::TidyHTML5
    - (git clone https://github.com/robrwo/html-tidy5 && cd html-tidy5 && cpanm --installdeps . && perl Makefile.PL && make && make test && make install) && rm -fr html-tidy5
    # For wml
    - cpanm --notest Bit::Vector Class::XSAccessor GD Getopt::Long IO::All Image::Size Term::ReadKey
    # For quadp
    - cpanm --notest Class::XSAccessor Config::IniFiles HTML::Links::Localize
    - bash bin/install-git-cmakey-program-system-wide.bash 'git' 'src' 'https://github.com/thewml/website-meta-language.git'
    - bash bin/install-git-cmakey-program-system-wide.bash 'git' 'installer' 'https://github.com/thewml/latemp.git'
    - {q«"cpanm $(perl -MYAML::XS=LoadFile -e 'print join q( ), sort {$a cmp $b} keys(%{LoadFile(q(bin/required-modules.yml))->{required}->{perl5_modules}})')"»}
    - gem install compass compass-blueprint
    - sudo -H `which python3` -m pip install beautifulsoup4 bs4 cookiecutter Zenfilter
    - a='latemp' ; v='0.10.0' ; b="$a-$v" ; arc="$b.tar.xz"; ( wget http://web-cpan.shlomifish.org/latemp/download/"$arc" && tar -xvf "$arc" && (cd "$b" && mkdir b && cd b && cmake .. && make && sudo make install) && rm -fr "$b" )
    - ( cd .. && git clone https://github.com/thewml/wml-extended-apis.git && cd wml-extended-apis/xhtml/1.x && bash Install.bash )
    - ( cd .. && git clone https://github.com/thewml/latemp.git && cd latemp/support-headers && perl install.pl )
    - ( cd .. && git clone https://github.com/shlomif/wml-affiliations.git && cd wml-affiliations/wml && bash Install.bash )
    - bash -x bin/install-npm-deps.sh
    - bash -x bin/install-tidyp-systemwide.bash
    - bash bin/install-git-cmakey-program-system-wide.bash 'git' 'installer' 'https://github.com/shlomif/quad-pres'
    {q«- echo '{"amazon_sak":"invalid"}' > "$HOME"/.shlomifish-amazon-sak.json»}
    - ( cd "$HOME" && git clone https://github.com/w3c/markup-validator.git )
    - pwd
    - echo "HOME=$HOME"
    - bash -x bin/install-npm-deps.sh
    - sudo ln -s /usr/bin/make /usr/bin/gmake
script:
    - bash -x bin/run-ci-build.bash
END_OF_PROGRAM
       }
       elsif ($dzil)
       {
           my $d = $.params{'subdirs'};

           my $p5-vers = <5.26 5.24 5.22 5.20 5.18 5.16 5.14>;

           self.base-spurt(".appveyor.yml", q:c:to/END_OF_PROGRAM/);
environment:
    install_berry_perl: "cmd /C git clone https://github.com/stevieb9/berrybrew && cd berrybrew/bin && berrybrew.exe install %version% && berrybrew.exe switch %version%"
    install_active_perl: "cmd /C choco install activeperl --version %version%"

    matrix:
        - install_perl: "%install_berry_perl%"
          version: "5.26.0_64"
        - install_perl: "%install_berry_perl%"
          version: "5.24.2_64"
        - install_perl: "%install_berry_perl%"
          version: "5.22.3_64"
        - install_perl: "%install_berry_perl%"
          version: "5.20.3_64"
        - install_perl: "%install_berry_perl%"
          version: "5.18.4_64"
        - install_perl: "%install_berry_perl%"
          version: "5.16.3_64"
        - install_perl: "%install_berry_perl%"
          version: "5.14.4_64"
        - install_perl: "%install_berry_perl%"
          version: "5.12.3_32"
        - install_perl: "%install_active_perl%"
          version: "5.24.1.2402"

install:
    # Install perl
    - cmd: "%install_perl%"
      # Make sure we are in project root
    - cmd: "cd %APPVEYOR_BUILD_FOLDER%"
      # Set path for berrybrew
    - SET PATH=C:\\berrybrew\\%version%\\c\\bin;C:\\berrybrew\\%version%\\perl\\site\\bin;C:\\berrybrew\\%version%\\perl\\bin;%PATH%
      # ActivePerl does not include cpanminus
    - cpan      App::cpanminus
    - cpanm -nq PerlIO::utf8_strict
    - cpanm -nq Mixin::Linewise::Readers
    - cpanm -nq Params::Validate
    - cpanm -nq Getopt::Long::Descriptive
    - cpanm -nq Log::Dispatch::Output Software::LicenseUtils Config::MVP::Reader::INI Config::MVP::Assembler Text::Template Data::Section App::Cmd::Tester Log::Dispatchouli MooseX::Types::Perl String::Formatter MooseX::SetOnce CPAN::Uploader Config::MVP::Section Perl::PrereqScanner App::Cmd::Setup Config::MVP::Reader Software::License Config::MVP::Reader::Findable::ByExtension Config::MVP::Reader::Finder Pod::Eventual Mixin::Linewise::Readers Config::MVP::Assembler::WithBundles App::Cmd::Command::version Config::INI::Reader App::Cmd::Tester::CaptureExternal Term::Encoding
    - cpanm -nq Module::Build
    - cpanm -nq Dist::Zilla
    # Module files for this distribution are not in root
    - cmd: "cd {$d}"
    - dzil authordeps | cpanm -nq
    - dzil listdeps   | cpanm -nq
    - cpanm -nq Test::EOL Test::NoTabs Test::Pod Test::Pod::Coverage Pod::Coverage::TrustPod

build: off

test_script:
    - dzil test

shallow_clone: true

matrix:
    allow_failures:
        - install_perl: "%install_berry_perl%"
          version: "5.16.3_64"
        - install_perl: "%install_berry_perl%"
          version: "5.14.4_64"
        - install_perl: "%install_berry_perl%"
          version: "5.12.3_32"
        - install_perl: "%install_active_perl%"
          version: "5.24.1.2402"
END_OF_PROGRAM














           self.travis-yml-spurt(q:c:to/END_OF_PROGRAM/);
{$travis-cache}
sudo: false
language: perl
perl:
    - 'blead'
{($p5-vers.map: -> $x {"    - '" ~ $x.Str ~"'\n"}).join('')}
matrix:
    allow_failures:
        - perl: 'blead'
    fast_finish: true
before_install:
    - git config --global user.name "TravisCI"
    - git config --global user.email $HOSTNAME":not-for-mail@travis-ci.org"
    - cpanm local::lib
    - eval "$(perl -Mlocal::lib=$HOME/perl_modules)"
install:
    - cpanm --quiet --skip-satisfied Dist::Zilla Pod::Weaver::Section::Support
    - "(cd {$d} && dzil authordeps          --missing | grep -vP '[^\\\\w:]' | xargs -n 5 -P 10 cpanm --quiet)"
    - "(cd {$d} && dzil listdeps   --author --missing | grep -vP '[^\\\\w:]' | cpanm --verbose)"
script:
    - "(cd {$d} && dzil smoke --release --author)"
END_OF_PROGRAM
   }
   else
   {
       self.travis-yml-spurt(q:to/END_OF_PROGRAM/);
{$travis-cache}
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
}
