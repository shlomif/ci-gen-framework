use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 8;

my $d = tempdir;

sub test-e(Str $var, Str $blurb) {
    return ok IO::Path.new($var).e, $blurb;
}

{
    CI::Gen::CI-Gen.new(basedir=>"$d/test1",params=>{
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
    CI::Gen::CI-Gen.new(basedir=>"$d/test-vered",params=>{
        subdirs => 'c-begin',
    },
    theme => "XML-Grammar-Vered",
    ).generate('foo');

    # TEST
    test-e "$d/test-vered/.travis.yml", "basedir";
    # TEST
    like(slurp("$d/test-vered/.travis.yml"), /^ cache\: /);
}

{
    IO::Path.new("$d/test-latemp-ini").mkdir;
    spurt "$d/test-latemp-ini/.ci-gen.ini", "theme = latemp\n[param]\n\nsubdirs = .\n";
    run-gen(['--basedir', "$d/test-latemp-ini"]);

    # TEST
    test-e "$d/test-latemp-ini/.travis.yml", "exe";
    # TEST
    test-e "$d/test-latemp-ini/.travis.bash", "exists";

}
done-testing;

# vim:ft=perl6
