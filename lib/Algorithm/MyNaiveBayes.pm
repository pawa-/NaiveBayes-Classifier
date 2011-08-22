package Algorithm::MyNaiveBayes;
use Any::Moose;
use Class::Inspector;
use Storable qw/nstore retrieve/;
use Carp;


has instances_path  => ( is => 'ro', isa => 'Str', builder => '_default_instances_path'  );
has classifier_path => ( is => 'ro', isa => 'Str', builder => '_default_classifier_path' );
has _instances      => ( is => 'rw', isa => 'ArrayRef' );
has _classifier     => ( is => 'rw', isa => 'ArrayRef' );


sub BUILD
{
    my $self = shift;
    $self->_load_instances;
    $self->_load_classifier;
}

sub _module_directory_path
{
    my $path = Class::Inspector->loaded_filename(__PACKAGE__);
    $path =~ s|\.pm|/|;
    return $path;
}

sub _default_instances_path
{
    my $self = shift;
    my $path = $self->_module_directory_path . 'instances';
    return $path;
}

sub _default_classifier_path
{
    my $self = shift;
    my $path = $self->_module_directory_path . 'classifier';
    return $path;
}

sub _load_instances
{
    my $self = shift;

    if (-s $self->instances_path)
    { $self->_instances(retrieve $self->instances_path); }
}

sub _load_classifier
{
    my $self = shift;

    if (-s $self->classifier_path)
    { $self->_classifier(retrieve $self->classifier_path); }
}

sub add_instance
{
    my ($self, %param) = @_;

    my $label          = $param{label};
    my $attributes_ref = $param{attributes};

    croak 'label is not set'          if (!length $label);
    croak 'attributes is not HashRef' if (ref $attributes_ref ne 'HASH');
    croak 'attributes are not set'    if (!scalar keys %{$attributes_ref});

    $param{freq} = 1; # if a new category is made, its freq is one

    if ($self->_instances)
    {
        my $category_exists;

        for my $category (@{$self->_instances})
        {
            if ($category->{label} eq $label)
            {
                $category->{freq}++;

                for my $word ( keys %{$attributes_ref} )
                {
                     $category->{attributes}->{$word} += $attributes_ref->{$word};
                }

                $category_exists = 1;

                last;
            }
        }

        if (!$category_exists) { push(@{$self->_instances}, \%param); }
    }
    else { $self->_instances([\%param]); } # set a first instance

    nstore($self->_instances, $self->instances_path);
}

sub train
{
    my ($self) = @_;

    my (%class_probability, %word_probability);
    my ($num_of_train_data, %num_of_word_in_each_class);

    if ($self->_instances)
    {
        # count num of train data and num of word
        for my $category (@{$self->_instances})
        {
            my $class = $category->{label};
            $num_of_train_data += $category->{freq};

            for my $word (keys %{$category->{attributes}})
            {
                $num_of_word_in_each_class{$class} += $category->{attributes}->{$word};
            }
        }

        # clac probability
        for my $category (@{$self->_instances})
        {
            my $class = $category->{label};
            $class_probability{$class} = $category->{freq} / $num_of_train_data;

            for my $word (keys %{$category->{attributes}})
            {
                $word_probability{"${word}|$class"}
                    = $category->{attributes}->{$word} / $num_of_word_in_each_class{$class};
            }
        }
    }
    else { croak 'classifier> give me some instances!'; }

    $self->_classifier( [\%class_probability, \%word_probability] );

    nstore($self->_classifier, $self->classifier_path);
}

sub classify
{
    my ($self, %param) = @_;

    my $attributes_ref = $param{attributes};

    croak 'attributes is not HashRef' if (ref $attributes_ref ne 'HASH');
    croak 'attributes are not set'    if (!scalar keys %{$attributes_ref});

    if (!$self->_classifier)
    {
        if (-s $self->classifier_path) { $self->_classifier(retrieve $self->classifier_path); }
        else                           { croak 'train is needed!'; }
    }

     #print Dumper $self->_classifier; # debug

    my %result;
    my ($class_possibility, $word_possibility) = @{$self->_classifier};

    for my $category (keys %{$class_possibility})
    {
        my $probability = $class_possibility->{$category};

        for my $word (keys %{$attributes_ref})
        {
            $probability *=
                $word_possibility->{"${word}|$category"} ** $attributes_ref->{$word};
        }

        $result{$category} = $probability;
    }

    return \%result;
}

1;
