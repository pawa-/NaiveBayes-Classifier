package Algorithm::MyNaiveBayes;
use Any::Moose;
use Storable;
use YAML         qw/Dump/;
use Data::Dumper qw/Dumper/;

has foo => ( is => 'ro' );

sub BUILD
{
    my $self = shift;
    $self->_load_model;
}

sub _load_model
{
    my $self = shift;
    print "test\n";
    #print $self->foo;
}

sub add_instance
{
    my ($self, %params) = @_;
    print Dumper %params;
    print Dumper $params{label};
}

1;
