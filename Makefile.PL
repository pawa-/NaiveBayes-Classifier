use inc::Module::Install;
name 'Algorithm-MyNaiveBayes';
all_from 'lib/Algorithm/MyNaiveBayes.pm';

requires 'Any::Moose';
requires 'Class::Inspector';
requires 'Storable';
requires 'List::AllUtils';
requires 'bignum';
requires 'Carp';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => 0.88; # done_testing
test_requires 'Test::File';

auto_set_repository;
auto_include;

readme_from 'lib/Algorithm/MyNaiveBayes.pm';
resources repository => 'https://github.com/pawa-/NaiveBayes-Classifier';

WriteAll;
