package Porkchop::Service::Monitor;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_monitor/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Monitor';
	return $self;
}

1
