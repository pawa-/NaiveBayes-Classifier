use inc::Module::Install;
name 'Algorithm-MyNaiveBayes';
all_from 'lib/Algorithm/MyNaiveBayes.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
