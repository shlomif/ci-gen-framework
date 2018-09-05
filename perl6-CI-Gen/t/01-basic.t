use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 10;
# TEST
pass "replace me";
my $d = tempdir;
CI::Gen::CI-Gen.new(basedir=>"$d/test1",params=>{
        screenplay_subdir => 'selina-mandrake/screenplay',
    },
    theme => "XML-Grammar-Fiction",
).generate('foo');

# TEST
ok IO::Path.new("$d/test1/.travis.yml").e, "basedir";
# TEST
pass "working";

sub run-gen(@args) {
    return run('perl6', '-I.', 'bin/ci-generate', @args);
}
run-gen(['--basedir', "$d/test2", "--param", "screenplay_subdir=foo", '--theme', "XML-Grammar-Fiction",]);
# TEST
ok IO::Path.new("$d/test2/.travis.yml").e, "exe";

run-gen(['--basedir', "$d/test3", "--param", "subdirs=foo", '--theme', "dzil",]);
# TEST
ok IO::Path.new("$d/test3/.travis.yml").e, "exe";

run-gen(['--basedir', "$d/test-latemp", "--param", "subdirs=foo", '--theme', "latemp",]);
# TEST
ok IO::Path.new("$d/test-latemp/.travis.yml").e, "exe";
CI::Gen::CI-Gen.new(basedir=>"$d/test-vered",params=>{
        subdirs => 'c-begin',
    },
    theme => "XML-Grammar-Vered",
).generate('foo');

# TEST
ok IO::Path.new("$d/test-vered/.travis.yml").e, "basedir";
# TEST
like(slurp("$d/test-vered/.travis.yml"), /^ cache\: /);

{
    IO::Path.new("$d/test-latemp-ini").mkdir;
    spurt "$d/test-latemp-ini/.ci-gen.ini", "theme = latemp\n[param]\n\nsubdirs = .\n";
    run-gen(['--basedir', "$d/test-latemp-ini"]);

    # TEST
    ok IO::Path.new("$d/test-latemp-ini/.travis.yml").e, "exe";
    # TEST
    ok IO::Path.new("$d/test-latemp-ini/.travis.bash").e, "exists";

}
done-testing;

# vim:ft=perl6
