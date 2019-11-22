package Porkchop::Portal;

use strict;
use Data::Dumper;
use Porkchop::Session;
use Porkchop::Monitor;
use XML::Simple;
use HTTP::Cookies;

# Constructor
sub new {
	my $package = shift;
	my $parameters = shift;

	my $self = { };
	bless $self,$package;

	$self->{url}		= $parameters->{url};
	$self->{system}		= $parameters->{system};
	$self->{login}		= $parameters->{login};
	$self->{password}	= $parameters->{password};
	
	my $cookie_jar = HTTP::Cookies->new(
		file => "$ENV{'HOME'}/lwp_cookies.dat",
		autosave => 1,
	);
  
	my $agent = $parameters->{agent};
	$agent = "Porkchop_Portal/0.1" unless ($agent);
	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->agent($agent);
	$self->{ua}->cookie_jar( {});

	return $self;
}

sub url {
	my ($self,$url) = @_;

	if (defined($url)) {
		$self->{url} = $url;
	}
	return $self->{url};
}

# Start Session
sub startSession {
	my $self = shift;
	$self->{error} = undef;
	my $login = shift;
	my $password = shift;

	if (defined($login)) {
		$self->{login} = $login;
	}
	if (defined($password)) {
		$self->{password} = $password;
	}

	my $response = $self->requestSuccess(
		"/_register/api",
		{
			"login"		=> $self->{login},
			"password"	=> $self->{password},
			"method"	=> "authenticateSession"
		}
	);
	return 1 if ($response);
	return 0;
}

sub ping {
	my $self = shift;
	$self->{error} = undef;

	my $response = $self->requestSuccess(
		"/_register/api",
		{
			"method"	=> "me"
		}
	);
	if ($response && $response->{success}) {
		print Dumper $response;
		return 1;
	}
	return 0;
}

sub sendReading {
	my $self = shift;
	my $reading = shift;
	$self->{error} = undef;

	my $response = $self->requestSuccess(
		"/_monitor/api",
		{
			"asset_code"	=> $reading->{asset_code},
			"sensor_code"	=> $reading->{sensor_code},
			"value"			=> $reading->{value},
			"date_read"		=> $reading->{date_read},
			"method"		=> "addReading"
		}
	);
	if ($response) {
		return 1;
	}
	else {
		return 0;
	}
}

sub sendMessage {
	
}

sub requestSuccess {
	my ($self,$uri,$parameters) = @_;
	$self->{error} = undef;
	
	my $object = $self->requestObject($uri,$parameters);
	return undef if ($self->error);
	if (ref($object) eq 'HASH') {
		if ($object->{success}) {
			return 1;
		}
		else {
			if ($object->{message}) {
				$self->{error} = $object->{message};
			}
			elsif ($object->{error}) {
				$self->{error} = $object->{error};
			}
			else {
				$self->{error} = "No error returned";
			}
			return 0;
		}
	}
	return 0;
}
sub requestObject {
	my ($self,$uri,$parameters) = @_;
	$self->{error} = undef;

	my $xml = $self->requestXML($uri,$parameters);
	return undef if ($self->error);
	my $object = eval{
		XMLin($xml,KeyAttr => []);
	};
	if ($@) {
		$self->{error} = "Response not parseable: ".$@;
		return 0;
	}
	return $object;
}
sub requestXML {
	my ($self,$uri,$parameters) = @_;
	$self->{error} = undef;

	my $response = $self->request($uri,$parameters);
	return undef if ($self->error);
	if ($response->code != 200) {
		$self->{error} = "Server returned ".$response->code." ".$response->status_line."\n";
		return 0;
	}
	if ($response->header("Content-Type") eq 'application/xml') {
		return $response->content;
	}
	$self->{error} = "Response not XML: ".$response->content;
	return 0;
}
sub request {
	my ($self,$uri,$parameters) = @_;
	$self->{error} = undef;

	my $request = HTTP::Request->new();
	$request->uri($self->{url}.$uri);
	$request->header("Content-Type" => "application/x-www-form-urlencoded");
	$request->method("POST");

	my $content = '';
	foreach my $parameter(sort keys %{$parameters}) {
		$content .= '&' if (length($content));
		$content .= $parameter."=".$parameters->{$parameter};
	}
	$request->content($content);
	my $response = $self->{ua}->request($request);
	$self->{content} = $response->content;
	$self->{code} = $response->code;
	return $response;
}
sub error {
	my $self = shift;
	return $self->{error};
}

1
