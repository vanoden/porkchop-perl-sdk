###############################################
### Porkchop::Geopgraphy					###
### Communicate with the Root Seven 		###
### geography module.						###
###############################################
package Porkchop::Geography;

# Load Modules
use 5.010000;
use strict;
no warnings;
use XML::Simple;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use BostonMetrics::HTTP::Response;
use Data::Dumper;
use Embedded::Debug;
use Porkchop::Geography::Country;
use Porkchop::Geography::Province;

our $VERSION = '0.01';

my $debug = Embedded::Debug->new();
my $client;

# Preloaded methods go here.
sub new {
	my $package = shift;
	my $options = shift;

	my $self = { };
	bless $self, $package;

	if (defined($options->{verbose})) {
		$self->verbose($options->{verbose});
	}
	if (defined($options->{client})) {
		$self->client($options->{client});
	}
	if (defined($options->{endpoint})) {
		$self->endpoint($options->{endpoint});
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

	my $params = {
		'method'	=> 'ping'
	};

	my $request = $self->_request($params);
	return $self->_send($request);
}

sub getCountry {
	my $self = shift;
	my $name = shift;

	my $params = {
		'method'	=> 'getCountry',
		'name'		=> $name
	};

	$debug->println("Getting country '$name'");
	my $object = $self->_send($self->_request($params),'country');
	if ($object->{id} =~ /^\d+$/) {
		$debug->print("Found country '".$object->{name}."'");
		my $country = Porkchop::Geography::Country->new();
		$country->{id} = $object->{id};
		$country->{name} = $object->{name};
		$country->{abbreviation} = $object->{abbreviation};
		return $country;
	}
	else {
		return undef;
	}
}

sub addCountry {
	my ($self,$name,$abbreviation) = @_;

	my $params = {
		'method'		=> 'addCountry',
		'name'			=> $name,
		'abbreviation'	=> $abbreviation
	};

	my $object = $self->_send($self->_request($params),'country');
	if ($object->{id} =~ /^\d+$/) {
		$debug->print("Added country '".$object->{name}."'");
		my $country = Porkchop::Geography::Country->new();
		$country->{id} = $object->{id};
		$country->{name} = $object->{name};
		$country->{abbreviation} = $object->{abbreviation};
		return $country;
	}
	else {
		return undef;
	}
}

sub getProvince {
	my ($self,$name,$country_id) = @_;
	my $params = {
		'method'		=> 'getProvince',
		'country_id'	=> $country_id,
		'name'			=> $name
	};
	my $object = $self->_send($self->_request($params),'province');
	if ($object->{code} =~ /^\w+$/) {
		$debug->print("Found province ".$object->{name});
		my $province = Porkchop::Geography::Province->new();
		$province->{code} = $object->{code};
		$province->{name} = $object->{name};
		$province->{abbreviation} = $object->{abbreviation};
		$province->{country_id} = $object->{country_id};
		return $province;
	}
	else {
		return undef;
	}
}

sub addProvince {
	my ($self,$name,$country_id,$abbreviation) = @_;

	my $params = {
		'method'		=> 'addProvince',
		'name'			=> $name,
		'abbreviation'	=> $abbreviation,
		'country_id'	=> $country_id
	};

	my $object = $self->_send($self->_request($params),'province');
	if ($object->{code} =~ /^\w+$/) {
		$debug->print("Found province ".$object->{name});
		my $province = Porkchop::Geography::Province->new();
		$province->{code} = $object->{code};
		$province->{name} = $object->{name};
		$province->{abbreviation} = $object->{abbreviation};
		$province->{country_id} = $object->{country_id};
		return $province;
	}
	else {
		return undef;
	}
}

sub _request {
	my ($self,$params) = @_;
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->method("post");
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}
	return $request;
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
		print "Verbose: ".$verbose."\n";
		$debug->level($verbose);
		$self->{verbose} = $verbose;
	}
	return $self->{verbose};
}

sub error {
	my $self = shift;
	return $self->{_error};
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
