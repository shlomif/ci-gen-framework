use v6.c;
use Test;
use File::Temp;
use CI::Gen;

plan 5;
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

run('perl6', '-I.', 'bin/ci-generate', '--basedir', "$d/test2", "--param", "screenplay_subdir=foo", '--theme', "XML-Grammar-Fiction",);
# TEST
ok IO::Path.new("$d/test2/.travis.yml").e, "exe";

run('perl6', '-I.', 'bin/ci-generate', '--basedir', "$d/test3", "--param", "subdirs=foo", '--theme', "dzil",);
# TEST
ok IO::Path.new("$d/test3/.travis.yml").e, "exe";
done-testing;
