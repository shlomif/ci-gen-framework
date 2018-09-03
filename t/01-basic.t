use v6.c;
use Test;
use CI::Gen;

plan 2;
# TEST
pass "replace me";
mkdir "foo";
chdir "foo";
CI::Gen::CI-Gen.new(basedir=>'.').generate('foo');
# TEST
pass "working";
done-testing;
