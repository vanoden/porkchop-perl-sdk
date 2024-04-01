package Porkchop::Service;
#######################################################
### Porkchop/Service.pm								###
### Base class for Porkchop API Services			###
### A. Caravello 12/17/2019							###
#######################################################

# Load Modules
use strict;
use Data::Dumper;
use BostonMetrics::HTTP::Client;
use BostonMetrics::HTTP::Request;
use XML::Simple;
use vars '$AUTOLOAD';

use parent "Embedded::BaseClass";

my $VERSION = '0.9.2';
my $RELEASE = '20231211';

sub new {
	my ($package, $options) = @_;

	my $self = bless({}, $package);

	$self->_init($options);

	return $self;
}

sub _init {
	my ($self,$options) = @_;

	$self->client(BostonMetrics::HTTP::Client->new());

	$self->protocol('https') unless ($self->protocol());
	$self->host('127.0.0.1') unless ($self->host());

	$self->SUPER::_init($options);

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
	push(@parameters,{'host' => $self->host(),'protocol' => $self->protocol(),'client' => $self->client(),'verbose' => $self->verbose()});
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
	$self->clearError();

	$self->log("Calling shared authenticate from register api");
	my $remember_uri = $self->uri();
	$self->log("URI WAS ".$remember_uri);
	$self->uri('/_register/api');

	my $result = $self->_requestSuccess({'method' => 'authenticateSession', 'login' => $login, 'password' => $password});
	$self->uri($remember_uri);
	return $result;
}

sub account {
	my ($self) = @_;
	$self->clearError();
	
	$self->log("Calling shared account from register api");
	my $remember_uri = $self->uri();
	$self->uri('/_register/api');
	my $result = $self->_requestObject({'method' => 'me'},'customer');
	$self->uri($remember_uri);
	return $result;
}

sub ping {
	my ($self) = @_;
	$self->clearError();
	
	$self->log("Calling shared ping");
	my $result = $self->_requestSuccess({'method' => 'ping'});
	return $result;
}

sub _send {
	my ($self,$request,$array) = @_;
	$self->clearError();

	$self->log("Sending request to ".$self->endpoint());
	my $response = $self->client()->post($request);
	if ($self->client()->error()) {
		$self->error("Client error: ".$self->client()->error());
	}
	elsif (! $response) {
		$self->error("No response from server");
	}
	elsif ($response->code != 200) {
		$self->error("Server error [".$response->code."] ".$response->reason());
	}
	elsif ($response->error) {
		$self->error("Server error: ".$response->error());
	}
	elsif ($response->{headers}->{'Content-Disposition'} =~ /^filename\=(.*)/) {
		my $payload;
		$self->{filename} = $1;
		if ($array->[0] =~ /^\?\w[\w\.\_\-\/]*/) {
			$self->{tmpfile} = $array->[0];
		}
		else {
			$self->{tmpfile} = "/tmp/porkchopServiceDownload.".$$;
		}
		$self->{filesize} = length($response->body());
		open(OUT,">".$self->{tmpfile});
		if ($! && $! !~ /Inappropriate\sioctl/) {
			$self->error("Server error: Cannot save download: $!");
		}
		else {
			print OUT $response->body();
			return 1;
		}
	}
	elsif ($response->content_type() ne "application/xml") {
		$self->error("Non object from server: ".$response->content_type());
	}
	else {
		my $payload;
		eval {
			$payload = XMLin($response->body(),KeyAttr => [],ForceArray => $array);
		};
		if ($@) {
			$self->error("Unparseable response: $@");
			$self->log("Unparseable response: $@",'error');
			$self->log($response->body(),'debug');
			return undef;
		}
		if (! $payload) {
			$self->error("No response from server");
			return undef;
		}
		elsif (! $payload->{success}) {
			if ($payload->{error}) {
				$self->error("Error returned: ".$payload->{error});
			}
			elsif ($payload->{message}) {
				$self->error("Error returned: ".$payload->{message});
			}
			else {
				$self->error("Unhandled service error");
				print $response->body();
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
	$self->clearError();

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
	$self->clearError();

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	if ($request->validURL($self->endpoint())) {
		$request->url($self->endpoint());
		if ($request->error()) {
			$self->error($request->error());
			return undef;
		}
	}
	else {
		$self->error("Invalid URL: '".$self->endpoint()."'");
		return undef;
	}

	foreach my $key (sort keys %{$params}) {
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->error()) {
		return undef;
	}
	elsif ($envelope) {
		return $envelope->{success};
	}
	else {
		$self->error("No response");
		return undef;
	}
}

sub _requestObject {
	my ($self,$params,$object_name) = @_;
	$self->clearError();

	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->verbose($self->verbose());
	$request->url($self->endpoint());

	$self->log("Requesting $object_name",'notice');
	foreach my $key (sort keys %{$params}) {
		$self->log("Adding param $key => ".$params->{$key});
		$request->add_param($key,$params->{$key});
	}

	$self->log($request,'trace');
	my $envelope = $self->_send($request);
	$self->log($envelope,'trace');
	if ($self->error()) {
		return undef;
	}
	elsif ($envelope) {
		return $envelope->{$object_name};
	}
	else {
		$self->error("No response");
		return undef;
	}
}

sub _requestArray {
	my ($self,$params) = @_;
	$self->clearError();

	$self->log("Request ".$params->{method}." from ".$self->{service}." API",'trace');
	my $request = BostonMetrics::HTTP::Request->new({'verbose' => $self->verbose()});
	$request->verbose($self->verbose());
	$request->url($self->endpoint());

	foreach my $key (sort keys %{$params}) {
		$self->log("Adding param $key => ".$params->{$key});
		$request->add_param($key,$params->{$key});
	}

	my $envelope = $self->_send($request);
	if ($self->error()) {
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
		$self->error("No response");
		return undef;
	}
}

sub _requestFile {
	my ($self,$params,$path) = @_;
	$self->clearError();

	my $request = BostonMetrics::HTTP::Request->new();
	$request->verbose($self->verbose());
	$request->url($self->endpoint);

	foreach my $key (sort keys %{$params}) {
		$self->log("Adding param $key => ".$params->{$key});
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
	my $new_client = shift;
	$self->identifySub();

	if (defined($new_client)) {
		$self->{_client} = $new_client;
	}
	return $self->{_client};
}

sub endpoint {
	my $self = shift;
	my $endpoint = shift;
	$self->identifySub();

	if (defined($endpoint)) {
		$self->log("Updating endpoint with $endpoint",'notice');
		if ($endpoint =~ /(https?)\:\/\/([^\/]+)(\/.*)/ || $endpoint =~ /(https?)\:\/\/([^\/]+)/) {
			my $protocol = $1;
			my $host = $2;
			my $uri = $3;
			$self->protocol($protocol);
			$self->host($host);
			$self->uri($uri) if (defined($uri));
			
			$self->log("Endpoint parsed",'notice');
		}
		else {
			$self->log("Endpoint $endpoint didnt match",'trace');
			#$self->uri($endpoint);
		}
	}
	if ($self->protocol() eq 'https' && $self->port() != 443) {
		$self->log("Returning ssl endpoint ".$self->protocol()."://".$self->host().":".$self->port().$self->uri(),'notice');
		return $self->protocol()."://".$self->host().":".$self->port().$self->uri();
	}
	elsif ($self->protocol() eq 'http' && $self->port() != 80) {
		$self->log("Returning http endpoint ".$self->protocol()."://".$self->host().":".$self->port().$self->uri(),'notice');
		return $self->protocol()."://".$self->host().":".$self->port().$self->uri();
	}
	else {
		$self->log("Returning endpoint ".$self->protocol()."://".$self->host().$self->uri(),'notice');
		return $self->protocol()."://".$self->host().$self->uri();
	}
}

sub protocol {
	my ($self,$protocol) = @_;
	$self->identifySub();
	if (defined($protocol)) {
		$self->log("Setting protocol to $protocol",'trace');
		$self->client()->protocol($protocol);
	}
	return $self->client()->protocol();
}

sub host {
	my ($self,$host) = @_;
	$self->identifySub();
	if (defined($host)) {
		$self->log("Setting host to $host",'notice');
		$self->client()->host($host);
	}
	return $self->client()->host();
}

sub port {
	my ($self,$port) = @_;
	$self->identifySub();
	if (defined($port)) {
		$self->log("Setting port to $port",'notice');
		$self->client()->port($port);
	}
	return $self->client()->port();
}

sub uri {
	my ($self,$uri) = @_;
	$self->identifySub();
	$self->clearError();

	if ($uri =~ /^http\s\:\/\/[\w\.\:]+(\/\.*)/) {
		$self->{uri} = $1;
		$self->log("Set uri to ".$self->{uri},'trace');
	}
	elsif ($uri =~ /^(\/_\w[\w\.\-_\/]*)\??/) {
		$self->{uri} = $1;
		$self->log("Set uri to ".$self->{uri},'trace');
	}
	elsif ($uri =~ /^(_\w[\w\.\-_\/]*)\??/){
		$self->log("Set uri to ".$self->{uri},'trace');
		return $self->{uri} = "/".$1;
	}
	elsif (defined($uri)) {
		my ($package,$file,$line,$sub) = caller(1);
		$self->error("Invalid URI '$uri'");
		return undef;
	}
	return $self->{uri};
}

sub user_agent {
	my $self = shift;
	my $agent = shift;
	if (defined($agent)) {
		$self->client()->user_agent($agent);
	}
	return $self->client()->user_agent();
}

sub AUTOLOAD {
	my ($self,$params,$res_object) = @_;

	my $method = $AUTOLOAD;
	if ($method =~ /identifySub/) {
		$self->log("You don't belong here");
		my ($package,$file,$line,$subroutine) = caller(1);
		$self->log("Called $method");
		$self->log("Called by ".$package."::".$subroutine."()");
		return undef;
	}
	$method =~ s/.*\://;
	unless ($self->_connected()) {
		$self->error("Not connected");
		return undef;
	}
	$self->log("Calling $method from ".$self->{service});
	if (! ref($params)) {
		$params = {};
	}
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
	if ($self->error()) {
		$self->log("Error in $method: ".$self->error());
		return undef;
	}
	elsif (@objects < 1) {
		$self->log("No objects returned");
	}
	else {
		$self->log("Found $count objects");
	}
	return @objects;
}

sub DESTROY {
	my $self = shift;
}
1;
