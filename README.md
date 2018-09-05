[![Build Status](https://travis-ci.org/shlomif/perl6-CI-Gen.svg?branch=master)](https://travis-ci.org/shlomif/perl6-CI-Gen)

NAME
====

A Don't Repeat Yourself (DRY) framework for generating [continuous integration](https://en.wikipedia.org/wiki/Continuous_integration) scripts

CODE
====

See [this](https://github.com/shlomif/perl6-CI-Gen).

SYNOPSIS
========

    $ git clone ...
    $ zef install --force-install .
    $ ci-generate

DESCRIPTION
===========

This aims to be a framework for generating [continuous integration](https://en.wikipedia.org/wiki/Continuous_integration) scripts (e.g: travis.yml, appveyor.yml, etc.).  Currently it is far from being generic enough.

I don't know about you, but I find it tiresome to maintain all the .travis.yml / .appveyor.yml / etc. configurations for my repositories which are full of copy+paste and duplicate code. CI-Gen eventually aims to generate them based on the https://en.wikipedia.org/wiki/Don%27t_repeat_yourself principle .

Philosophy
==========

We envision eventually having something DRYish similar in spirit to [Dist::Zilla](http://dzil.org/).

Bottom-up design and avoiding https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it .

See https://www.joelonsoftware.com/2002/01/23/rub-a-dub-dub/ :

"This stuff went into classes which were not really designed — I simply added methods lazily as I discovered a need for them. (Somewhere, someone with a big stack of 4×6 cards is sharpening their pencil to poke my eyes out. What do you mean you didn’t design your classes?) "

AUTHOR
======

[Shlomi Fish](http://www.shlomifish.org/)

COPYRIGHT AND LICENSE
=====================

Copyright 2018 Shlomi Fish

This library is free software; you can redistribute it and/or modify it under the MIT/Expat license.
