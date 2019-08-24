###############################################
### Porkchop::Support												###
### Communicate with the Root Seven 				###
### support interface.											###
###############################################
package Porkchop::Support;

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

	my $self = { };
	bless $self, $package;

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
	
	if (! $response) {
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
			$self->{error} = "Application error: ".$payload->{error};
		}
		return 1;
	}
	return undef;
}

sub addDomain {
	my ($self,$parameters) = @_;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addDomain");
	$request->add_param("name",$parameters->{name});
	my $response = $client->load($request);
	
	if (! $response) {
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
		if ($payload->{success} != 1) {
				$self->{error} = "Application error: ".$payload->{error};
		}
		return 1;
	}
	return undef;
}

sub getDomain {
	my ($self,$parameters) = @_;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getDomain");
	$request->add_param("name",$parameters->{name});
	my $response = $client->load($request);
	
	if (! $response) {
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
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return $payload->{domain};
	}
	return undef;
}

sub getHost {
	my ($self,$domain_name,$name) = @_;
	delete $self->{error};
	unless (defined($name)) {
		$name = $domain_name;
		$domain_name = undef;
	}

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getHost");
	$request->add_param("domain_name",$domain_name);
	$request->add_param("name",$name);
	my $response = $client->load($request);
	
	if (! $response) {
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
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return $payload->{host};
	}
	return undef;
}

sub addHost {
	my ($self,$parameters) = @_;
	delete $self->{error};
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addHost");
	$request->add_param("domain_name",$parameters->{domain_name});
	$request->add_param("name",$parameters->{name});
	$request->add_param("os_name",$parameters->{os_name});
	$request->add_param("os_version",$parameters->{os_version});

	my $response = $client->load($request);
	
	if (! $response) {
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
		if ($payload->{success} != 1) {
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return 1;
	}
	return undef;
}

sub getAddress {
	my ($self,$ip_address) = @_;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getAddress");
	$request->add_param("address",$ip_address);
	my $response = $client->load($request);
	
	if (! $response) {
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
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return $payload->{address};
	}
	return undef;
}

sub addAddress {
	my ($self,$parameters) = @_;
	$self->{error} = '';
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addAddress");
	$request->add_param("mac_address",$parameters->{mac_address});
	$request->add_param("address",$parameters->{address});
	$request->add_param("prefix",$parameters->{prefix});

	my $response = $client->load($request);
	
	if (! $response) {
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
		if ($payload->{success} != 1) {
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return 1;
	}
	return undef;
}

sub getAdapter {
	my ($self,$mac_address) = @_;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getAdapter");
	$request->add_param("mac_address",$mac_address);
	my $response = $client->load($request);
	
	if (! $response) {
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
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return $payload->{adapter};
	}
	return undef;
}

sub addAdapter {
	my ($self,$parameters) = @_;
	$self->{error} = '';
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addAdapter");
	$request->add_param("domain_name",$parameters->{domain_name});
	$request->add_param("host_name",$parameters->{host_name});
	$request->add_param("mac_address",$parameters->{mac_address});
	$request->add_param("name",$parameters->{default});
	$request->add_param("type",$parameters->{type});

	my $response = $client->load($request);
	
	if (! $response) {
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
		if ($payload->{success} != 1) {
			$self->{error} = "Application error: ".$payload->{error};
			return undef;
		}
		return 1;
	}
	return undef;
}

sub error {
	my $self = shift;
	return $self->{error};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Porkchop::Monitor - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Porkchop::Monitor;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Porkchop::Monitor, created by h2xs. It looks like the
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
