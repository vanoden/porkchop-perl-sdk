package Porkchop::Service::Package;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_package/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Package';
	return $self;
}

1
