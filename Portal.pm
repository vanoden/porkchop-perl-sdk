package Porkchop::Portal;

use strict;
use Porkchop::Session;
use Porkchop::Monitor;

# Constructor
sub new {
	my $package = shift;
	my $parameters = shift;

	my $self = { };
	bless $self,$package;

	$self->{session} = Porkchop::Session->new({
		'login'		=> $parameters->{login},
		'password'	=> $parameters->{password},
	});

	$self->{url}		= $parameters->{url};
	$self->{agent}		= $parameters->{agent};
	$self->{system}		= $parameters->{system};

	return $self;
}

# Start Session
sub connect {
	
}

sub ping {
	
}

sub sendReading {
	
}

sub sendMessage {
	
}

sub error {
	my $self = shift;
	return $self->{error};
}

1