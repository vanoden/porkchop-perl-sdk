package Porkchop::Service::Register;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_register/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Register';
	return $self;
}

1