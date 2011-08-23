use strict;
use warnings;
use Algorithm::MyNaiveBayes;
use Test::More;
use Test::File;

my $nb = Algorithm::MyNaiveBayes->new;

file_exists_ok($nb->_default_instances_path)  or diag('instances file not exists');
file_exists_ok($nb->_default_classifier_path) or diag('classifier file not exists');


$nb->init;

file_not_exists_ok($nb->_default_instances_path)  or diag('faild to init');
file_not_exists_ok($nb->_default_classifier_path) or diag('faild to init');


$nb->add_instance( label => 'plus',  attributes => { good     => 3, bad      => 1                } );
$nb->add_instance( label => 'plus',  attributes => { exciting => 2                               } );
$nb->add_instance( label => 'plus',  attributes => { good     => 2, exciting => 1, boring   => 1 } );
$nb->add_instance( label => 'minus', attributes => { bad      => 1, boring   => 3, hobiron  => 1 } );
$nb->add_instance( label => 'minus', attributes => { bad      => 2, good     => 1                } );
$nb->add_instance( label => 'minus', attributes => { bad      => 2, boring   => 1, exciting => 1 } );

file_exists_ok($nb->_default_instances_path)    or diag('faild to make instances file');
file_not_empty_ok($nb->_default_instances_path) or diag('faild to write instances file');


$nb->train;

file_exists_ok($nb->_default_classifier_path)    or diag('faild to make classifier file');
file_not_empty_ok($nb->_default_classifier_path) or diag('faild to write classifier file');


my $result = $nb->classify( attributes => { good => 2, bad => 1, great => 1 } );
ok($result->{plus} > $result->{minus}, "classification 1");

$result = $nb->classify( attributes => { bad => 1, hobiron => 3, good => 1, happy => 10 } );
ok($result->{plus} < $result->{minus}, "classification 2");

$result = $nb->classify( attributes => { good => 1000, bad => 1, great => 1 } );
ok($result->{plus} > $result->{minus}, "classification 3");

$result = $nb->classify( attributes => { bad => 1000, hobiron => 3, good => 1, happy => 10 } );
ok($result->{plus} < $result->{minus}, "classification 4");


$nb->add_instance( label => 'plus',  attributes => { good => 3, bad => 1 } ) for (1 .. 1000);

$result = $nb->classify( attributes => { good => 2, bad => 1, great => 1 } );
ok($result->{plus} > $result->{minus}, "classification 5");

$result = $nb->classify( attributes => { bad => 1, hobiron => 3, good => 1, happy => 10 } );
ok($result->{plus} < $result->{minus}, "classification 6");

done_testing;
