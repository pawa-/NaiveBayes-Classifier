package Algorithm::MyNaiveBayes;
use 5.008_001;
use Any::Moose;

our $VERSION = '0.01';

use Class::Inspector;
use Storable       qw/nstore retrieve/;
use List::AllUtils qw/uniq/;
use bignum;
use Carp;


has instances_path  => ( is => 'ro', isa => 'Str', builder => '_default_instances_path'  );
has classifier_path => ( is => 'ro', isa => 'Str', builder => '_default_classifier_path' );
has _instances      => ( is => 'rw', isa => 'ArrayRef' );
has _vocabulary     => ( is => 'rw', isa => 'ArrayRef' );
has _classifier     => ( is => 'rw', isa => 'ArrayRef' );


# clean up
no Any::Moose;
__PACKAGE__->meta->make_immutable;


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
    {
        my $instances_and_vocabulary = retrieve $self->instances_path;
        $self->_instances($instances_and_vocabulary->{instances});
        $self->_vocabulary($instances_and_vocabulary->{vocabulary});
    }
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
    my @vocabulary;

    croak 'label is not set'          if (!length $label);
    croak 'attributes is not HashRef' if (ref $attributes_ref ne 'HASH');
    croak 'attributes are not set'    if (!scalar keys %{$attributes_ref});

    $param{freq} = 1; # if a new category is made, its freq is one

    # add vocabulary
    for my $word (keys %{$attributes_ref}) { push(@vocabulary, $word); }

    if ($self->_vocabulary) { push(@{$self->_vocabulary}, @vocabulary); }
    else                    { $self->_vocabulary(\@vocabulary); }

    @{$self->_vocabulary} = uniq @{$self->_vocabulary};


    if ($self->_instances)
    {
        my $category_exists;

        # add instance
        for my $category (@{$self->_instances})
        {
            if ($category->{label} eq $label)
            {
                $category->{freq}++;

                for my $word ( @{$self->_vocabulary} )
                {
                    if (!length $attributes_ref->{$word}) { $attributes_ref->{$word} = 0; }
                    $category->{attributes}->{$word} += $attributes_ref->{$word};
                }

                $category_exists = 1;

                last;
            }
        }

        if (!$category_exists) { push(@{$self->_instances}, \%param); }
    }
    else { $self->_instances([\%param]); } # set first instance

    nstore(
        {
            instances  => $self->_instances,
            vocabulary => $self->_vocabulary,
        },
        $self->instances_path
    );
}

sub train
{
    my ($self) = @_;

    my (%class_probability, %word_probability);
    my ($num_of_train_data, %num_of_word_in_each_class);

    if ($self->_instances)
    {
        if (!$self->_vocabulary) { croak 'unexpected error: vocabulary returns false'; }

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

            $class_probability{$class}
                = ($category->{freq} + 1) / ($num_of_train_data + scalar @{$self->_instances});

            for my $word (@{$self->_vocabulary})
            {
                $word_probability{"${word}|$class"}
                    = ($category->{attributes}->{$word} + 1)
                    / ($num_of_word_in_each_class{$class} + scalar @{$self->_vocabulary});
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
    my ($class_probability, $word_probability) = @{$self->_classifier};

    for my $category (keys %{$class_probability})
    {
        my $probability = $class_probability->{$category};

        for my $word (keys %{$attributes_ref})
        {
            if ($attributes_ref->{$word} < 1)
            { croak 'attribute value must be bigger or eaqual to 1'; }

            if (!length $word_probability->{"${word}|$category"})
            { $word_probability->{"${word}|$category"} = 1; }

            $probability *=
                $word_probability->{"${word}|$category"} ** $attributes_ref->{$word};
        }

        $result{$category} = $probability;
    }

    return \%result;
}

sub init
{
    my $self = shift;

    if (-e $self->instances_path)
    { unlink $self->instances_path  or croak "failed to init"; }

    if (-e $self->classifier_path)
    { unlink $self->classifier_path or croak "failed to init"; }

    undef @{$self->_instances}  if $self->_instances;
    undef @{$self->_classifier} if $self->_classifier;
}

1;


__END__

=head1 NAME

Algorithm::MyNaiveBayes - Oreore NaiveBayes Classifier

=head1 SYNOPSIS

  use Algorithm::MyNaiveBayes;
  my $nb = Algorithm::MyNaiveBayes->new;

  #$nb->init; # delete previous data

  $nb->add_instance(
      label      => 'plus',
      attributes => { good => 3, bad => 1 },
  );

  $nb->add_instance(
      label      => 'minus',
      attributes => { bad => 1, boring => 3 },
  );

  # ...

  $nb->train;

  my $result = $nb->classify(
      attributes => { good => 2, bad => 1, boring => 1 }
  );


=head1 DESCRIPTION

Algorithm::MyNaiveBayes is Oreore NaiveBayes Classifier.
This uses multinominal model.
In smoothing, maximum a posteriori estimation is used.
I think Algorithm::NaiveBayes on CPAN is better than this module.

=head1 AUTHOR

pawa- E<lt>pawa[at]dojikko.comE<gt>

=head1 SEE ALSO

Algorithm::NaiveBayes

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
