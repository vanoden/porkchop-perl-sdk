package Porkchop::Service;
#######################################################
### Porkchop/Service.pm								###
### Base class for Porkchop API Services			###
### A. Caravello 12/17/2019							###
#######################################################

# Load Modules
use strict;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use Embedded::Debug;
use Data::Dumper;
use XML::Simple;

my $client = BostonMetrics::HTTP::Client->new();
my $debug = Embedded::Debug->new();
$debug->level(9);

sub new {
	my $package = shift;
	my $options = shift;

	my $self = bless({}, $package);

	$self->protocol('https') unless (defined($self->{protocol}));
	$self->host('127.0.0.1') unless (defined($self->{host}));

    my @available_options = qw (verbose protocol host uri endpoint client);
    foreach my $option(@available_options) {
        if (defined($options->{$option})) {
            $self->$option($options->{$option});
        }
    }

	# Return Package
	return $self;
}

sub api {
	my $self           = shift;
	my $requested_type = shift;
	my $location       = "Porkchop/Service/$requested_type.pm";
	my $class          = "Porkchop::Service::$requested_type";

	require $location;
	my @parameters = @_;
	push(@parameters,{'host' => $self->{host},'protocol' => $self->{protocol},'client' => $client});
	my $object = $class->new(@parameters);
	return $object;
}

sub connect {
	my ($self,$host) = @_;
	$self->{host} = $host;
}

sub _connected {
	my $self = shift;
	return 1;
}
sub authenticate {
	my ($self,$login,$password) = @_;

}

sub _send {
	my ($self,$request,$array) = @_;
	$debug->println("Sending request to ".$self->endpoint());

	my $response = $client->post($request);
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
		my $payload = XMLin($response->body,KeyAttr => [],ForceArray => $array);
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
		else {
			return $payload;
		}
	}
	return undef;
}

sub _request {
	my ($self,$params) = @_;
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}
	return $request;
}

sub _requestSuccess {
	my ($self,$params) = @_;
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->{_error}) {
		return undef;
	}
	elsif ($envelope) {
		return $envelope->{success};
	}
	else {
		$self->{_error} = "No response";
		return undef;
	}
}

sub _requestObject {
	my ($self,$params,$object_name) = @_;
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->{_error}) {
		return undef;
	}
	elsif ($envelope) {
		return $envelope->{$object_name};
	}
	else {
		$self->{_error} = "No response";
		return undef;
	}
}

sub _requestArray {
	my ($self,$params) = @_;
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->{_error}) {
		return undef;
	}
	elsif ($envelope) {
		my $element_name;
		# Get Name of first non-'success' element
		foreach my $element(sort keys $envelope) {
			if ($element ne 'success' && $element ne 'header') {
				$element_name = $element;
			}
		}
		return undef unless($element_name);
		my @elements;
		if (ref($envelope->{$element_name} eq 'ARRAY')) {
			foreach my $element(@{$envelope->{$element_name}}) {
				push(@elements,$element);
			}
		}
		else {
			print Dumper $envelope;
			$elements[0] = $envelope->{$element_name};
		}
		return @elements;
	}
	else {
		$self->{_error} = "No response";
		return undef;
	}
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

sub protocol {
	my ($self,$protocol) = @_;
	if (defined($protocol)) {
		$self->{protocol} = $protocol;
		if (defined($self->{uri}) && defined($self->{protocol})) {
			$self->{endpoint} = $self->{protocol}.'://'.$self->{host}.$self->{uri};
		}
	}
	return $self->{host};
}

sub host {
	my ($self,$host) = @_;
	if (defined($host)) {
		$self->{host} = $host;
		$self->println("Setting host to $host",'notice');
		if (defined($self->{uri}) && defined($self->{protocol})) {
			$self->println("Setting endpoint to ".$self->{protocol}.'://'.$self->{host}.$self->{uri});
			$self->{endpoint} = $self->{protocol}.'://'.$self->{host}.$self->{uri};
		}
	}
	return $self->{host};
}

sub uri {
	my ($self,$uri) = @_;
	if (defined($uri)) {
		$self->{uri} = $uri;
		if (defined($self->{host}) && defined($self->{protocol})) {
			$self->{endpoint} = $self->{protocol}.'://'.$self->{host}.$self->{uri};
		}
	}
	return $self->{host};
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

sub println {
	my ($self,$message,$level) = @_;
	$level = 'debug' unless (defined($level));
	my ($package,$filename,$line,$subroutine,$hasargs) = caller(1);
	$debug->println($message,$level,$package,$filename,$line,$subroutine,$hasargs);
}

sub error {
	my $self = shift;
	return $self->{_error};
}

1;