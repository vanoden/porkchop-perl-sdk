###############################################
### Porkchop::Package						###
### Communicate with Porkchop				###
### Package module interface.				###
###############################################
package Porkchop::Package;

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

	if (defined($options->{verbose})) {
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

	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->verbose($self->verbose());
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","ping");

	return $self->_send($request);
}

sub find_packages {
	my $self = shift;

	$debug->println("called");
	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->verbose($self->verbose());
	$request->method("post");
	$request->url($self->endpoint());
	$request->add_param("method","findPackages");

	my @results;
	my $payload = $self->_send($request,'package');
	if (ref($payload) eq "ARRAY") {
		return @{$payload};
	}
	elsif ($payload) {
		$results[0] = $payload;
	}
	return @results;
}

sub add_version {
	my ($self,$package_code,$major,$minor,$build,$status,$file,$mime_type) = @_;

	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->method("post");
	$request->url($self->endpoint());
	$request->add_param("method","addVersion");
	$request->add_param("package_code",$package_code);
	$request->add_param("major",$major);
	$request->add_param("minor",$minor);
	$request->add_param("build",$build);
	$request->add_param("status",$status);
	$request->add_file($file,{'mime_type' => $mime_type});
	if ($request->error) {
		$self->{_error} = $request->error();
		return 0;
	}

	return $self->_send($request);
}

sub latest_version {
	my $self = shift;
	my $package_code = shift;

	$debug->println("called for package_code $package_code");
	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->verbose($self->verbose());
	$request->method("post");
	$request->url($self->endpoint());
	$request->add_param("method","latestVersion");
	$request->add_param("package_code",$package_code);

	my $version = $self->_send($request,'version');
	return $version;
}

sub _send {
	my ($self,$request,$object_name) = @_;

	my $response = $client->load($request);
	if ($client->error) {
		$self->{_error} = "Client error: ".$client->error;
	}
	elsif (! $response) {
		$self->{_error} = "No response from server";
	}
	elsif ($response->code != 200) {
		$self->{_error} = "Server error [".$response->code."] ".$response->reason;
	}
	elsif ($response->error) {
		$self->{_error} = "Server error: ".$response->error;
	}
	elsif ($response->content_type() ne "application/xml") {
		$self->{_error} = "Non object from server: ".$response->content_type();
	}
	else {
		my $payload = XMLin($response->body,KeyAttr => []);
		if (! $payload->{success}) {
			if ($payload->{error}) {
				$self->{_error} = "Application error: ".$payload->{error};
			}
			elsif ($payload->{message}) {
				$self->{_error} = "Application error: ".$payload->{message};
			}
			else {
				$self->{_error} = "Unhandled service error";
				print $response->body;
			}
			return undef;
		}
		if (defined($object_name)) {
			return $payload->{$object_name};
		}
		else {
			return 1;
		}
	}
	return undef;
}

sub verbose {
	my $self = shift;
	my $verbose = shift;

	if (defined($verbose)) {
		$self->{_verbose} = $verbose;
		$debug->level($verbose);
	}
	return $self->{_verbose};
}

sub error {
	my $self = shift;
	return $self->{_error};
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Porkchop::Package - Perl extension for interfacing with the Porkchop CMS Package Module

=head1 SYNOPSIS

  use Porkchop::Package;
  my $package = Porkchop::Package->new

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
