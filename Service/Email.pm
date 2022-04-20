package Porkchop::Service::Email;

# Load Modules
use strict;
use vars '$AUTOLOAD';
use Data::Dumper;

# Extend Service Base
use parent "Porkchop::Service";

sub new {
	my $package = shift;
	my $options = shift;

	$options->{uri} = '/_email/api';
	my $self = $package->SUPER::new($options);

	$self->{service} = 'Email';
	return $self;
}

sub AUTOLOAD {
	my ($self,$params) = @_;

	my $method = $AUTOLOAD;
	$method =~ s/.*\://;
	unless ($self->_connected()) {
		$self->{_error} = "Not connected";
		return undef;
	}
	$self->println("Calling $method from ".$self->{service});

	$params->{'method'} = $method;

	my @objects = $self->_requestArray($params);
	my $count = @objects;
	if ($self->{_error}) {
		$self->println("Error in $method: ".$self->{_error});
		return undef;
	}
	elsif (@objects < 1) {
		$self->println("No objects returned");
	}
	else {
		$self->println("Found $count objects");
		print Dumper @objects;
	}
	return @objects;
}

1
