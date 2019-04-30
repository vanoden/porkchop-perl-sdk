###############################################
### Porkchop::Engineering					###
### Communicate with Porkchop				###
### Engineering module interface.			###
###############################################
package Porkchop::Engineering;

# Load Modules
use 5.010000;
use strict;
no warnings;
use XML::Simple;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use BostonMetrics::HTTP::Response;
use Data::Dumper;

our $VERSION = '0.01';

my $client;

# Preloaded methods go here.
sub new {
	my $package = shift;
	my $options = shift;

	my $self = bless({}, $package);

	if ($options->{verbose}) {
		$self->verbose($options->{verbose});
	}
	if (defined($options->{endpoint})) {
		$self->endpoint($options->{endpoint});
	}
	if (defined($options->{client})) {
		$self->client($options->{client});
	}

	# Return Package
	return $self;
}

sub client {
	my $self = shift;
	my $newclient = shift;
	
	$client = $newclient if (defined($newclient));
	return $client;
}

sub endpoint {
	my $self = shift;
	my $endpoint = shift;

	$self->{endpoint} = $endpoint if (defined($endpoint));

	return $self->{endpoint};
}

sub ping {
	my $self = shift;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","ping");
	my $response = $client->load($request);

	if ($client->error) {
		$self->{error} = "Client error: ".$client->error;
	}	
	elsif (! $response) {
		$self->{error} = "No response from server";
	}
	elsif ($response->code != 200) {
		$self->{error} = "Server error [".$response->code."] ".$response->reason;
	}
	elsif ($response->error) {
		$self->{error} = "Server error: ".$response->error;
	}
	elsif ($response->content_type() ne "application/xml") {
		$self->{error} = "Non object from server";
	}
	else {
		my $payload = XMLin($response->body,KeyAttr => []);
		if (! $payload->{success}) {
			if ($payload->{error}) {
				$self->{error} = "Application error: ".$payload->{error};
			}
			elsif ($payload->{message}) {
				$self->{error} = "Application error: ".$payload->{message};
			}
			else {
				$self->{error} = "Unhandled service error";
				print $response->body;
			}
			return 0;
		}
		return 1;
	}
	return undef;
}

sub verbose {
	my $self = shift;
	my $verbose = shift;
	$self->{verbose} = $verbose if (defined($verbose));
	return $self->{verbose};
}

sub error {
	my $self = shift;
	return $self->{error};
}
1;
__END__

=head1 NAME

Porkchop::Register - Perl wrapper for Porkchop Register API

=head1 SYNOPSIS

  use Porkchop::Register;
  $register = Porkchop::Register->new({'verbose' => 9,'endpoint' => 'http://testurl.com/_register/api'});
  if ($register->authenticate('login','password')) {
	$customer = $register->me();
  }
  else {
    die $register->error."\n";
  } 

=head1 DESCRIPTION

Stub documentation for Porkchop::Register, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Anthony Caravello, E<lt>tony@caravello.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2099 by Boston Metrics, Inc

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
