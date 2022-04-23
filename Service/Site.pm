package Porkchop::Service::Site;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_site/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Site';
	return $self;
}

1
