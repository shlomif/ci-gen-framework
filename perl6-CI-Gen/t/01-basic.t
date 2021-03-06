use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 13;

my $d = tempdir;

sub test-e(Str $var, Str $blurb) {
    return ok IO::Path.new($var).e, $blurb;
}

my class Dir-wrapper
{
    has Str $.sub;

    method dir() {
        return "$d/$.sub";
    }

    method travis-bash() {
        return "{self.dir()}/.travis.bash";
    }
    method travis-yml() {
        return "{self.dir()}/.travis.yml";
    }

    method test-travis-yml($msg) {
        return test-e self.travis-yml(), $msg;
    }

    method unlike-travis-bash($re) {
        return unlike(slurp(self.travis-bash()), $re);
    }
    method contains-travis-yml($substr) {
        return ok(slurp(self.travis-yml()).contains($substr));
    }
    method like-travis-bash($re) {
        return like(slurp(self.travis-bash()), $re);
    }
    method like-travis-yml($re) {
        return like(slurp(self.travis-yml()), $re);
    }

    method ini() {
        return "{self.dir()}/.ci-gen.ini";
    }

    method spew-ini($content) {
        return spurt(self.ini(), $content);
    }
}

{
    CI::Gen::CI-Gen.new(
        basedir=>"$d/test1",
        params=>
        {
            screenplay_subdir => 'selina-mandrake/screenplay',
        },
        theme => "XML-Grammar-Fiction",
    ).generate('foo');

    # TEST
    test-e "$d/test1/.travis.yml", "basedir";
}

sub run-gen(@args) {
    return run('perl6', '-I.', 'bin/ci-generate', @args);
}

{
    run-gen(['--basedir', "$d/test2", "--param", "screenplay_subdir=foo", '--theme', "XML-Grammar-Fiction",]);
    # TEST
    test-e "$d/test2/.travis.yml", "exe";
}

{
    run-gen(['--basedir', "$d/test3", "--param", "subdirs=foo", '--theme', "dzil",]);
    # TEST
    test-e "$d/test3/.travis.yml", "exe";
}

{
    run-gen(['--basedir', "$d/test-latemp", "--param", "subdirs=foo", '--theme', "latemp",]);
    # TEST
    test-e "$d/test-latemp/.travis.yml", "exe";
}

{
    my $w = Dir-wrapper.new(sub => "test-dzil-1");
    CI::Gen::CI-Gen.new(
        basedir => $w.dir(),
        params=>
        {
            subdirs => 'Test-Count',
        },
        theme => "dzil",
    ).generate('foo');

    # TEST
    $w.test-travis-yml( "basedir");
    # TEST
    $w.contains-travis-yml( 'eval "$(perl -I ~/perl_modules/lib/perl5 -Mlocal::lib=$HOME/perl_modules)"' );

    my $needle = "\nperl:\n";
    for qqw/ blead 5.22 5.24 5.26 5.28 5.30 / -> $v {
        $needle ~= "    - '$v'\n";
    }
    # TEST
    $w.contains-travis-yml( $needle )
}

{
    my $w = Dir-wrapper.new(sub => "test-vered");
    CI::Gen::CI-Gen.new(
        basedir => $w.dir(),
        params=>
        {
            subdirs => 'c-begin',
        },
        theme => "XML-Grammar-Vered",
    ).generate('foo');

    # TEST
    $w.test-travis-yml( "basedir");
    # TEST
    $w.like-travis-yml( /^^ cache\: /);
}

{
    my $w = Dir-wrapper.new(sub => "test-latemp-ini");
    IO::Path.new($w.dir).mkdir;
    $w.spew-ini( "theme = latemp\n[param]\n\nsubdirs = .\n");
    run-gen(['--basedir', "$d/test-latemp-ini"]);

    # TEST
    $w.test-travis-yml("exe");
    # TEST
    test-e "{$w.dir}/.travis.bash", "exists";
    # TEST
    $w.unlike-travis-bash( /\"install\"/);
    # TEST
    $w.like-travis-bash( /cpanm' '\-v' '\-\-notest' 'IO\:\:Async/);


}
done-testing;

# vim:ft=perl6
