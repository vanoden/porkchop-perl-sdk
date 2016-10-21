###############################################
### Porkchop::Monitor						###
### Communicate with the Root Seven Monitor	###
### module interface.						###
###############################################
package Porkchop::Monitor;

# Load Modules
use 5.010000;
use strict;
no warnings;
use XML::Simple;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use BostonMetrics::HTTP::Response;
use Data::Dumper;

our $VERSION = '0.03';

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
		print Dumper $payload;
		return 1;
	}
	return undef;
}
sub getHub {
	my ($self,$hub) = @_;
	delete $self->{error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","getHubs");
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
sub addMessage {
	my ($self,$message) = @_;
	delete $self->{error};
print Dumper $message;

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addMessage");
	$request->add_param("asset_code",$message->{asset_code});
	$request->add_param("message",$message->{message});
	$request->add_param("level",$message->{level});
	$request->add_param("date_recorded",$message->{timestamp});
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
			if ($payload->{message}) {
				$self->{error} = "Application error: ".$payload->{message};
			}
			else {
				$self->{error} = "Application error: ".$payload->{error};
			}
		}
		return 1;
	}
	return undef;
}

sub addReading {
	my ($self,$reading) = @_;
	$self->{error} = '';
	
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->{verbose});
	$request->method("post");
	$request->url($self->endpoint);
	$request->add_param("method","addReading");
	$request->add_param("asset_code",$reading->{asset_code});
	$request->add_param("sensor_code",$reading->{sensor_code});
	$request->add_param("value",$reading->{value});
	$request->add_param("date_reading",$reading->{timestamp});

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
		if (! $payload->{success}) {
			if ($payload->{message}) {
				$self->{error} = "Application error: ".$payload->{message};
			}
			else {
				$self->{error} = "Application error: ".$payload->{error};
			}
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
