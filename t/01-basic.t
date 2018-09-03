use v6.c;
use Test;
use CI::Gen;

plan 3;
# TEST
pass "replace me";
mkdir "foo";
chdir "foo";
CI::Gen::CI-Gen.new(basedir=>'.',params=>{
        screenplay_subdir => 'selina-mandrake/screenplay',
    }).generate('foo');
# TEST
pass "working";
chdir "..";
CI::Gen::CI-Gen.new(basedir=>'test1',params=>{
        screenplay_subdir => 'selina-mandrake/screenplay',
    }).generate('foo');

# TEST
ok IO::Path.new("test1/.travis.yml").e, "basedir";

done-testing;
