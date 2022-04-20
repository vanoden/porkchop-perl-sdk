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
use XML::Simple;
use vars '$AUTOLOAD';

my $client = BostonMetrics::HTTP::Client->new();
my $debug;

sub new {
	my $package = shift;
	my $options = shift;

	my $self = bless({}, $package);

	$debug = Embedded::Debug->new();

	$self->protocol('https');
	$self->host('127.0.0.1');
	$self->port(443);

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
	push(@parameters,{'host' => $self->{host},'protocol' => $self->{protocol},'client' => $client,'verbose' => $self->verbose()});
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
	delete $self->{_error};

	$debug->println("Calling shared authenticate from register api");
	my $remember_uri = $self->uri();
	$debug->println("URI WAS ".$remember_uri);
	$self->uri('/_register/api');
	my $result = $self->_requestSuccess({'method' => 'authenticateSession', 'login' => $login, 'password' => $password});
	$self->uri($remember_uri);
	return $result;
}
sub account {
	my ($self) = @_;
	delete $self->{_error};
	
	$debug->println("Calling shared account from register api");
	my $remember_uri = $self->uri();
	$self->uri('/_register/api');
	my $result = $self->_requestObject({'method' => 'me'},'customer');
	$self->uri($remember_uri);
	return $result;
}
sub ping {
	my ($self) = @_;
	delete $self->{_error};
	
	$debug->println("Calling shared ping");
	my $result = $self->_requestSuccess({'method' => 'ping'});
	return $result;
}

sub _send {
	my ($self,$request,$array) = @_;
	delete $self->{_error};

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
	elsif ($response->{headers}->{'Content-Disposition'} =~ /^filename\=(.*)/) {
		my $payload;
		$self->{filename} = $1;
		$self->{tmpfile} = "/tmp/porkchopServiceDownload.".$$;
		$self->{filesize} = length($response->body());
		open(OUT,">".$self->{tmpfile});
		if ($! && $! !~ /Inappropriate\sioctl/) {
			$self->{_error} = "Server error: Cannot save download: $!";
		}
		else {
			print OUT $response->body();
			return 1;
		}
	}
	elsif ($response->content_type() ne "application/xml") {
		$self->{_error} = "Non object from server: ".$response->content_type();
	}
	else {
		my $payload;
		eval {
			$payload = XMLin($response->body,KeyAttr => [],ForceArray => $array);
		};
		if ($@) {
			$self->{_error} = "Unparseable response: $@";
			$debug->println("Unparseable response: $@",'error');
			$debug->println($response->body(),'debug');
			return undef;
		}
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
	delete $self->{_error};

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
	delete $self->{_error};

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
	delete $self->{_error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	$debug->println("Requesting $object_name",'trace');
	foreach my $key (sort keys %{$params}) {
		$debug->println("Adding param $key => ".$params->{$key});
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
	delete $self->{_error};

	$debug->println("Request ".$params->{method}." from ".$self->{service}." API",'trace');
	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint());
	
	#$request->proxy_mode(1);
	#if ($client->{conduit}->type() eq 'Proxy') {
	#	$debug->println("Proxy Mode",'notice');
	#	$request->proxy_mode(1);
	#}
	#else {
	#	$debug->println("Not proxy",'notice');
	#}

	foreach my $key (sort keys %{$params}) {
		$debug->println("Adding param $key => ".$params->{$key});
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->{_error}) {
		return undef;
	}
	elsif ($envelope) {
		my $element_name;
		# Get Name of first non-'success' element
		foreach my $element(sort keys %{$envelope}) {
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
			$elements[0] = $envelope->{$element_name};
		}
		return @elements;
	}
	else {
		$self->{_error} = "No response";
		return undef;
	}
}

sub _requestFile {
	my ($self,$params,$path) = @_;
	delete $self->{_error};

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$debug->println("Adding param $key => ".$params->{$key});
		$request->add_param($key,$params->{$key});
	}

	if ($self->_send($request)) {
		return {
			'tmpfile'	=> $self->{tmpfile},
			'filename'	=> $self->{filename},
			'filesize'	=> $self->{filesize}
		};
	}
	else {
		return undef;
	}
}

sub client {
	my $self = shift;
	my $newclient = shift;

	if (defined($newclient)) {
		$client = $newclient;
	}
	return $client;
}

sub endpoint {
	my $self = shift;
	my $endpoint = shift;

	if (defined($endpoint)) {
		$debug->println("Updating endpoint with $endpoint",'trace');
		if ($endpoint =~ /(https?)\:\/\/([^\/]+)(\/.*)/ || $endpoint =~ /(https?)\:\/\/([^\/]+)/) {
			my $protocol = $1;
			my $host = $2;
			my $uri = $3;
			$self->protocol($protocol);
			$self->host($host);
			#$self->uri($uri);
			if ($protocol eq 'https') {
				$self->port(443);
			}
			else {
				$self->port(80);
			}
			
			$debug->println("Endpoint parsed");
		}
		else {
			$debug->println("Endpoint $endpoint didnt match",'trace');
			$self->uri($endpoint);
		}
		$debug->println("Set uri to ".$self->uri(),'trace');
	}
	if ($self->protocol() eq 'https' && $self->port() != 443) {
		return $self->protocol()."://".$self->host().":".$self->port().$self->uri();
	}
	elsif ($self->protocol() eq 'http' && $self->port() != 80) {
		return $self->protocol()."://".$self->host().":".$self->port().$self->uri();
	}

	return $self->protocol()."://".$self->host().$self->uri();
}

sub protocol {
	my ($self,$protocol) = @_;
	if (defined($protocol)) {
		$self->{protocol} = $protocol;
	}
	return $self->{protocol};
}

sub host {
	my ($self,$host) = @_;
	if (defined($host)) {
		$self->{host} = $host;
		$debug->println("Setting host to $host",'trace');
	}
	return $self->{host};
}

sub port {
	my ($self,$port) = @_;
	if (defined($port)) {
		$self->{port} = $port;
	}
	return $self->{port};
}
sub uri {
	my ($self,$uri) = @_;
	if (defined($uri)) {
		$self->{uri} = $uri;
	}
	return $self->{uri};
}

sub verbose {
	my $self = shift;
	my $verbose = shift;
	if (defined($verbose)) {
		$debug->level($verbose);
	}
	return $debug->level();
}

sub error {
	my $self = shift;
	return $self->{_error};
}

sub debug {
	my ($self,$message,$level) = @_;
	$level = $debug->level() unless (defined($level));
	$debug->println("called with level $level",'trace');
	$debug->println($message,$level);
}

sub AUTOLOAD {
	my ($self,$params,$res_object) = @_;

	my $method = $AUTOLOAD;
	$method =~ s/.*\://;
	unless ($self->_connected()) {
		$self->{_error} = "Not connected";
		return undef;
	}
	$debug->println("Calling $method from ".$self->{service});

	$params->{'method'} = $method;

	if ($self->{service} eq 'Package' && $method =~ /^download/) {
		return $self->_requestFile($params,$res_object);
	}
	if (defined($res_object)) {
		my $object = $self->_requestObject($params,$res_object);
		return $object;
	}
	
	my @objects = $self->_requestArray($params);
	my $count = @objects;
	if ($self->{_error}) {
		$debug->println("Error in $method: ".$self->{_error});
		return undef;
	}
	elsif (@objects < 1) {
		$debug->println("No objects returned");
	}
	else {
		$debug->println("Found $count objects");
	}
	return @objects;
}

sub DESTROY {
	my $self = shift;
}
1;
