use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 3;
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

done-testing;
