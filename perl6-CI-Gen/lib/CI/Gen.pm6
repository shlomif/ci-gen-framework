use v6.c;
unit class CI::Gen:ver<0.0.2>:auth<cpan:SHLOMIF>;


=begin pod

=head1 NAME

CI-Gen - A Don't Repeat Yourself (DRY) framework for generating continuous integration scripts

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

my $local-lib-eval = 'eval "$(perl -I ~/perl_modules/lib/perl5 -Mlocal::lib=$HOME/perl_modules)"';

our class CI-Gen
{
    has Str $.basedir;
    has Str %.params;
    has Str $.theme;

    method !base-spurt($path, $contents)
    {
        my $p = IO::Path.new("$.basedir/$path");
        IO::Path.new($p.dirname).mkdir;
        return spurt $p, $contents;
    }

    method !gen-by-warning(:$syntax) {
        return q:c:to/EOF/
# This file was generated by ci-generate / CI::Gen
# (See https://github.com/shlomif/ci-gen-framework )
# Please do not edit directly.

EOF
    }

    method !calc-golang-version()
    {
        return '1.13';
    }

    method !write-travis-yml(:@pkgs, :$contents)
    {
        my $s = "";
        if (@pkgs)
        {
            $s = "addons:\n    apt:\n        packages:\n" ~ (@pkgs.map: -> $x {(" " x 12) ~ "- $x\n"}).join('');
        }
        my $fn = ".travis.yml";
        return self!base-spurt(
            $fn,
            self!gen-by-warning(syntax => 'yaml') ~ $s ~ $contents
        );
    }

    method !apt-get-inst() {
        return <sudo apt-get --no-install-recommends install -y>;
    }

    method !gen-xml-g(:$param-name, :@pkgs, :%extra_stages, :$xmlg-install is copy) {
        my $travis-bash-prefix = q:c:to/EOF/;
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
EOF

        my $before_install = %extra_stages{'before_install'}:exists ?? %extra_stages{'before_install'} !! '';
        if ($before_install)
        {
            $before_install ~~ s:g:P5:m/^/    /;
        }
        my $apt_str = @pkgs ??
    "   sudo apt-get update -qq\n    {self!apt-get-inst()} {@pkgs}\n" !! "";

        my $xmlg-before-install = q:c:to/EOF/;
elif test "$cmd" = "before_install"
then
{$apt_str}
    . /etc/lsb-release
    if test "$DISTRIB_ID" = 'Ubuntu'
    then
        if test "$DISTRIB_RELEASE" = '14.04'
        then
            sudo dpkg-divert --local --divert /usr/bin/ack --rename --add /usr/bin/ack-grep
        fi
    fi
    cpanm --local-lib=~/perl_modules local::lib
{$before_install}
EOF

        $xmlg-install //= q:to/EOF/;
elif test "$cmd" = "install"
then
    cpanm --notest YAML::XS
    cpanm HTML::T5 Test::HTML::Tidy::Recursive::Strict
    h=~/Docs/homepage/homepage
    mkdir -p "$h"
    git clone https://github.com/shlomif/shlomi-fish-homepage "$h/trunk"
    sudo -H `which python3` -m pip install cookiecutter
    ( cd "$h/trunk" && perl bin/my-cookiecutter.pl )
EOF


        return q:c:to/END_OF_PROGRAM/
{$travis-bash-prefix}
{$xmlg-before-install}
{$xmlg-install}
elif test "$cmd" = "build"
then
    export SCREENPLAY_COMMON_INC_DIR="$PWD/screenplays-common"
    cd {%.params{$param-name}}
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

    method !write-bash(:$param-name, :@pkgs, :%extra_stages = {}, :$xmlg-install is copy)
    {
        return self!base-spurt(".travis.bash", self!gen-xml-g(param-name=>$param-name, pkgs=>@pkgs, extra_stages=>%extra_stages, xmlg-install=>$xmlg-install));
    }

    method !xml-g-write-bash(:$param-name)
    {
        return self!write-bash(
            param-name=>$param-name,
        );
    }

    method generate($name)
    {
        if (not $.theme eq ('dzil'|'latemp'|'perl6'|'XML-Grammar-Fiction'|'XML-Grammar-Vered'))
        {
            die "unknown theme";
        }
        my $dzil = ($.theme eq 'dzil');

        if ($.theme eq 'XML-Grammar-Fiction')
        {
            self!xml-g-write-bash(param-name => 'screenplay_subdir');
        }
        if ($.theme eq 'XML-Grammar-Vered')
        {
            self!xml-g-write-bash(param-name => 'subdirs');
        }

        my $travis-cache = q:to/END_OF_PROGRAM/;
cache:
    directories:
        - $HOME/perl_modules
        - $HOME/tidyall_d
END_OF_PROGRAM

       if ($.theme eq 'latemp')
       {
            self!write-bash(xmlg-install=>"", param-name=>'subdirs',
            extra_stages => {
                'before_install' => q:c:to/END/,
eval "$(GIMME_GO_VERSION={self!calc-golang-version()} gimme)"
go get -u github.com/tdewolff/minify/cmd/minify
{$local-lib-eval}
cpanm App::Deps::Verify App::XML::DocBook::Builder Pod::Xhtml
cpanm HTML::T5
# For wml
cpanm --notest Bit::Vector Carp::Always Class::XSAccessor GD Getopt::Long IO::All Image::Size List::MoreUtils Path::Tiny Term::ReadKey
# For quadp
cpanm --notest Class::XSAccessor Config::IniFiles HTML::Links::Localize
bash bin/install-git-cmakey-program-system-wide.bash 'git' 'src' 'https://github.com/thewml/website-meta-language.git'
bash bin/install-git-cmakey-program-system-wide.bash 'git' 'installer' 'https://github.com/thewml/latemp.git'
sudo -H `which python3` -m pip install beautifulsoup4 bs4 click cookiecutter lxml pycotap rebookmaker vnu_validator Pillow WebTest Zenfilter
perl bin/my-cookiecutter.pl
# For various sites
cpanm --notest HTML::Toc XML::Feed
deps-app plinst -i bin/common-required-deps.yml -i bin/required-modules.yml
gem install asciidoctor compass compass-blueprint
PATH="$HOME/bin:$PATH"
( cd .. && git clone https://github.com/thewml/wml-extended-apis.git && cd wml-extended-apis/xhtml/1.x && bash Install.bash )
( cd .. && git clone https://github.com/thewml/latemp.git && cd latemp/support-headers && perl install.pl )
( cd .. && git clone https://github.com/shlomif/wml-affiliations.git && cd wml-affiliations/wml && bash Install.bash )
bash -x bin/install-npm-deps.sh
bash bin/install-git-cmakey-program-system-wide.bash 'git' 'installer' 'https://github.com/shlomif/quad-pres'
{q«echo '{"amazon_sak":"invalid"}' > "$HOME"/.shlomifish-amazon-sak.json»}
( cd "$HOME" && git clone https://github.com/w3c/markup-validator.git )
pwd
echo "HOME=$HOME"
bash -x bin/install-npm-deps.sh
sudo ln -s /usr/bin/make /usr/bin/gmake
END
            },
        );
        my $travis-api-key = %.params{'travis-api-key'} || '';
        my $username = %.params{'username'} || '';
        my $reponame = %.params{'reponame'} || '';
            self!write-travis-yml(pkgs=><ack-grep build-essential cmake cpanminus dbtoepub docbook-defguide docbook-xsl docbook-xsl-ns fortune-mod graphicsmagick hspell hunspell hunspell-en-gb inkscape libdb5.3-dev libgd-dev libgdbm-dev libgdbm-compat-dev libhunspell-dev libncurses-dev libpcre3-dev libperl-dev libxml2-dev mercurial myspell-he lynx optipng perl python3 python3-setuptools python3-pip silversearcher-ag strip-nondeterminism tidy valgrind wml xsltproc xz-utils zip>, contents=>q:c:to/END_OF_PROGRAM/);
{$travis-cache}
deploy:
    provider: releases
    api_key:
        secure: {$travis-api-key}
    file: site-dest.tar.xz
    on:
        repo: "{$username}/{$reponame}"
        tags: true
    skip_cleanup: true
go:
    - '{self!calc-golang-version()}.x'
os: linux
dist: bionic
rvm:
    - 2.7.0
before_install:
    - . .travis.bash --cmd before_install
install:
    - git clone https://github.com/vim/vim && ( cd vim && git checkout v8.2.1320 && ./configure --with-features=huge && make && sudo make install ) && rm -fr vim
script:
    - export XML_CATALOG_FILES="/etc/xml/catalog $HOME/markup-validator/htdocs/sgml-lib/catalog.xml"
    - TIDYALL_DATA_DIR="$HOME/tidyall_d" bash -x bin/run-ci-build.bash
    - tar -caf site-dest.tar.xz dest/
    - set +x
END_OF_PROGRAM
       }
       elsif ($dzil)
       {
            my @d = %.params{'subdirs'}.split(' ');

            my @p5-vers = (%.params{'p5-vers'} || '5.22 5.24 5.26 5.28 5.30').split(' ');

            my @dzil-deps = <Dist::Zilla Pod::Weaver::Section::Support Perl::Critic Perl::Tidy Test::Code::TidyAll>;

            self!base-spurt(".appveyor.yml", q:c:to/END_OF_PROGRAM/);
{self!gen-by-warning(syntax => 'yaml')}
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
    - cpanm -nq {@dzil-deps.join(' ')}
    # Module files for this distribution are not in root
    - cmd: "cd {@d}"
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

            self!write-travis-yml(contents=>q:c:to/END_OF_PROGRAM/);
{$travis-cache}
sudo: false
addons:
    apt:
        packages:
            - libhunspell-dev
language: perl
perl:
    - 'blead'
{(@p5-vers.map: -> $x {"    - '" ~ $x.Str ~"'\n"}).join('')}
matrix:
    allow_failures:
        - perl: 'blead'
    fast_finish: true
before_install:
    - git config --global user.name "TravisCI"
    - git config --global user.email $HOSTNAME":not-for-mail@travis-ci.org"
    - cpanm --local-lib=~/perl_modules local::lib
    - {$local-lib-eval}
install:
    - cpanm --quiet --skip-satisfied {@dzil-deps.join(' ')}
    - export _dzil_dirs="{@d}"
    - "for d in $_dzil_dirs ; do (cd \"$d\" && dzil authordeps          --missing | grep -vP '[^\\\\w:]' | xargs -n 5 -P 10 cpanm --quiet) ; done"
    - "for d in $_dzil_dirs ; do (cd \"$d\" && dzil listdeps   --author --missing | grep -vP '[^\\\\w:]' | cpanm --verbose) ; done"
script:
    - "for d in $_dzil_dirs ; do (cd \"$d\" && dzil smoke --release --author) || exit -1 ; done"
END_OF_PROGRAM
        }
        elsif ($.theme eq 'perl6')
        {
            my $d = $.params{'subdirs'};
            self!write-travis-yml(contents=>q:c:to/END_OF_PROGRAM/);
os:
  - linux
  - osx
language: perl6
perl6:
  - latest
install:
  - rakudobrew build zef
  - ( cd {$d} && zef install --deps-only . )
script:
  - ( cd {$d} && PERL6LIB=$PWD/lib prove -e perl6 -vr t/ )
sudo: false
END_OF_PROGRAM
        }
        else
        {
            self!write-travis-yml(
                pkgs=><ack-grep cpanminus dbtoepub docbook-defguide docbook-xsl libperl-dev libxml-libxml-perl libxml-libxslt-perl make perl python3-pip python3-setuptools tidy xsltproc>,
                contents=>q:c:to/END_OF_PROGRAM/);
{$travis-cache}
os: linux
dist: xenial
before_install:
    - . .travis.bash --cmd before_install
    - {$local-lib-eval}
    - . .travis.bash --cmd install
    - cpanm App::XML::DocBook::Builder File::Find::Object::Rule HTML::T5 IO::All Path::Tiny {$.theme eq 'XML-Grammar-Vered' ?? 'XML::Grammar::Vered' !! 'XML::Grammar::Screenplay'}
    - git clone https://github.com/shlomif/screenplays-common
perl:
    - "5.26"
python:
    - "3.6"
script:
    - . .travis.bash --cmd build
sudo: required
END_OF_PROGRAM
        }
    }
}
