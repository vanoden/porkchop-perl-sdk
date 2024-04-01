package Porkchop::Service::Register;

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

	$options->{uri} = '/_register/api';
	$self->{service} = 'Register';

	$self->SUPER::_init($options);
}

1