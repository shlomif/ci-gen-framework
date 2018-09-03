use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 4;
# TEST
pass "replace me";
my $d = tempdir;
CI::Gen::CI-Gen.new(basedir=>"$d/test1",params=>{
        screenplay_subdir => 'selina-mandrake/screenplay',
    }).generate('foo');

# TEST
ok IO::Path.new("$d/test1/.travis.yml").e, "basedir";
# TEST
pass "working";

run('perl6', 'bin/ci-generate', '--basedir', "$d/test2", "--param", "screenplay_subdir=foo");
# TEST
ok IO::Path.new("$d/test2/.travis.yml").e, "exe";

done-testing;
