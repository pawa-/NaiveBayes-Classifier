use inc::Module::Install;
name 'Algorithm-MyNaiveBayes';
all_from 'lib/Algorithm/MyNaiveBayes.pm';

requires 'Any::Moose'
requires 'Class::Inspector'
requires 'Storable'
requires 'List::AllUtils'
requires 'Carp'

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
