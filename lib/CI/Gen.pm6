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

my class CI-Gen {
    has Str $!basedir;
    method generate($name) {

        spurt "$!basedir/bin/install-tidyp-systemwide.bash", q:to/EOF/;
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

    }
}
