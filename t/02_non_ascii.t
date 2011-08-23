use strict;
use warnings;
use Algorithm::MyNaiveBayes;
use Test::More;

my $nb = Algorithm::MyNaiveBayes->new;

$nb->init;

$nb->add_instance( label => 'プラス',   attributes => { 'イイ'           => 3, '悪い'           => 1                        } );
$nb->add_instance( label => 'プラス',   attributes => { 'エキサイティン' => 2                                               } );
$nb->add_instance( label => 'プラス',   attributes => { 'イイ'           => 2, 'エキサイティン' => 1, '退屈'           => 1 } );
$nb->add_instance( label => 'マイナス', attributes => { '悪い'           => 1, '退屈'           => 3, 'ホビロン'       => 1 } );
$nb->add_instance( label => 'マイナス', attributes => { '悪い'           => 2, 'イイ'           => 1                        } );
$nb->add_instance( label => 'マイナス', attributes => { '悪い'           => 2, '退屈'           => 1, 'エキサイティン' => 1 } );

$nb->train;

my $result = $nb->classify( attributes => { 'イイ' => 2, '悪い' => 1, 'ぼんぼる' => 1 } );
ok($result->{'プラス'} > $result->{'マイナス'}, "non ascii classification 1");

$result = $nb->classify( attributes => { '悪い' => 1, 'ホビロン' => 3, 'イイ' => 1, 'なこち' => 10 } );
ok($result->{'プラス'} < $result->{'マイナス'}, "non ascii classification 2");

$nb->init;

done_testing;
