package Porkchop::Service::Alert;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_alert/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Alert';
	return $self;
}

1
