package Porkchop::Service::Monitor;

# Load Modules
use strict;
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	my $self = { };
	bless $self, $package;

	$self->_init($options);
}

sub _init {
	my ($self,$options) = @_;

	$options->{uri} = '/_monitor/api';
	$self->{service} = 'Monitor';

	$self->SUPER::_init($options);
}

1
