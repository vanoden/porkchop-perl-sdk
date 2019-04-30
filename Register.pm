###############################################
### Porkchop::Register						###
### Communicate with Porkchop				###
### Register module interface.				###
###############################################
package Porkchop::Register;

# Load Modules
use 5.010000;
use strict;
no warnings;
use XML::Simple;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use BostonMetrics::HTTP::Response;
use Embedded::Debug;
use Data::Dumper;

our $VERSION = '0.03';

my $client;
my $debug = Embedded::Debug->new();

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
	if ($request->error()) {
		$self->{error} = $request->error;
		return 0;
	}
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
			$debug->log($self->{error},'error');
			return 0;
		}
		return 1;
	}
	return undef;
}

sub me {
	my $self = shift;
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->url($self->endpoint);
	$request->add_param("method","me");
	my $response = $client->post($request);
	
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
		$self->{error} = "Non object from server: ".$response->content_type();
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
			return undef;
		}
		return $payload->{customer};
	}
	return undef;
}

sub authenticate {
	my ($self,$login,$password) = @_;
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","authenticateSession");
	$request->add_param("login",$login);
	$request->add_param("password",$password);
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
		$self->{error} = "Non object from server: ".$response->content_type();
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

sub getCustomer {
	my ($self,$login) = @_;
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getCustomer");
	$request->add_param("login",$login);
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
		$self->{error} = "Non object from server: ".$response->content_type();
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
			return undef;
		}
		return $payload->{customer};
	}
	return undef;
}

sub addCustomer {
	my $self = shift;
	my $parameters = shift;

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addCustomer");
	$request->add_param("login",$parameters->{login});
	$request->add_param("password",$parameters->{password});
	$request->add_param("organization",$parameters->{organization});
	$request->add_param("first_name",$parameters->{first_name});
	$request->add_param("last_name",$parameters->{last_name});
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
		$self->{error} = "Non object from server: ".$response->content_type();
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
			return undef;
		}
		return $payload->{customer};
	}
	return undef;
}

sub updateCustomer {
	my $self = shift;
	my $parameters = shift;

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","updateCustomer");
	$request->add_param("code",$parameters->{login});
	$request->add_param("password",$parameters->{password}) if (defined($parameters->{password}));
	$request->add_param("organization",$parameters->{organization}) if (defined($parameters->{organization}));
	$request->add_param("first_name",$parameters->{first_name}) if (defined($parameters->{first_name}));
	$request->add_param("last_name",$parameters->{last_name}) if (defined($parameters->{last_name}));
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
		$self->{error} = "Non object from server: ".$response->content_type();
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
			return undef;
		}
		return $payload->{customer};
	}
	return undef;
}

sub verbose {
	my $self = shift;
	my $verbose = shift;
	if (defined($verbose)) {
		$debug->level($verbose);
		$self->{verbose} = $verbose;
	}
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

root, E<lt>root@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
