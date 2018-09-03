use v6.c;
use Test;
use CI::Gen;

pass "replace me";
mkdir "foo";
chdir "foo";
CI::Gen::CI-Gen.new(basedir=>'.').generate('foo');
pass "working";
done-testing;
