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
use Crypt::SSLeay;
use MIME::Base64;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Cookies;
use HTTP::Request::Common;
use XML::Simple;
use XML::SAX::Expat;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Porkchop::Gallery ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	error
);

our $VERSION = '0.03';

# Preloaded methods go here.
my $dbh;
my $verbose;
my $debug = 0;
my $session;
my $last_error = '';
my $last_error_time = 0;

my $url;
my $modbus;

# Initiate User Agent
use HTTP::Cookies::Netscape;
my $cookie_jar = HTTP::Cookies::Netscape->new(
   file => "cookies.txt",
   autosave => 1,
);
my $ua = LWP::UserAgent->new();
$ua->cookie_jar( $cookie_jar );

# Preloaded methods go here.
sub new
{
	my $package = shift;
    $session = shift;

	my $self = bless({}, $package);

	# Set User Agent Header
	my $agent = $session->{agent};
	$session->{agent} = "r7_client_libs/0.1" unless ($agent);
	$ua->agent($session->{agent});
	foreach my $header (sort keys $session->{headers}) {
		$ua->default_header($header => $session->{headers}->{$header});
	}

	if ($session->{portal_url} =~ /^https?\:\/\/\w[\w\-\.]+/)
	{
		$url = $session->{portal_url}."/_monitor/api";
	}
	else
	{
		unless ($session->{protocol} =~ /^http/)
		{
			$self->{error} = "Session protocol must be 'http' or 'https'";
			return $self;
		}
		if ($session->{server})
		{
			$url = "$session->{protocol}://$session->{server}/_monitor/api";
		}
		elsif ($session->{domain} =~ /^([\w\-\.]+)\.([\w\-]+)$/)
		{
			$url = "$session->{protocol}://www.$session->{domain}/_monitor/api";
		}
		else
		{
			$self->{error} = 'Invalid Session Domain Name';
			return $self;
		}
	}

	# Ping Site To Make Sure We're Ready
	my $response = $ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[   login           => $session->{user},
            password        => $session->{pass},
			method			=> 'ping',
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		if ($response->content() =~ /Requirements\snot\sMet/)
		{
			$self->{error} = "Invalid Username or Password";
			return $self;
		}
		$self->{error} = "Failed to communicate with server: ".$response->status_line;
		print "Portal URL: $url\n";
		print "Portal Response:\n";
		print $response->status_line."\n";
		print $response->content();
		return $self;
	}

	my $result = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => []);
    };
	if ($@)
	{
		$self->{error} = "Error pinging service: Cannot parse response: $@\n".$response->content();
		return $self;
	}
	unless ($result->{success} == 1)
	{
		$self->{error} = "Error pinging service: $result->{message}";
		return $self;
	}
	# Return Package
	return $self;
}
sub ping
{
	my $self = shift;
	$self->{error} = "";

	# Ping Site To Make Sure We're Ready
	my $response = $ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[   login           => $session->{user},
            password        => $session->{pass},
			method			=> 'ping',
		]
    );
	
	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to ping portal: ".$response->status_line();
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => []);
    };
	if ($@)
	{
		$self->{error} = "Error pinging portal: Cannot parse response: $@\n".$response->content();
		return 0;
	}
	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error pinging portal: $xml->{message}";
		return 0;
	}
	return $xml;
}
sub getHub
{
	my ($self,$hub) = @_;
	
	my $response = $ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[	method			=> 'getHubs',
			code			=> $hub,
		]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to retrieve hub info from server";
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => ['event','monitor','zone']);
    };
	if ($@)
	{
		$self->{error} = "Error getting hub info: Cannot parse response: $@\n".$response->content();
		return 0;
	}
	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error getting hub info: $xml->{message}";
		return 0;
	}
	return $xml;
}
sub addMessage
{
	my ($self,$message,$type,$event) = @_;

	$type = 'info' unless ($type);

	my $response = $ua->request(
    	POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   method			=> 'addMessage',
			event			=> $event,
			hub				=> $session->{remote},
			time			=> time,
			message_type	=> $type,
			message			=> $message,
		]
    );
}
sub getHubEvents
{
	my ($self,$hub) = @_;
	$self->{error} = '';

	unless ($hub)
	{
		$self->{error} = "No serial number configured";
		return 0;
	}
	my $parameters = {
		"hub"	=> $hub
	};

	return $self->getEvents($parameters);
}
sub getEvents
{
	my ($self,$parameters) = @_;
	$self->{error} = '';

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   method		=> 'getEvents',
			hub			=> $parameters->{hub},
			event		=> $parameters->{event},
			name		=> $parameters->{name},
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to retrieve events from server";
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => ['event','monitor','zone']);
    };
	if ($@)
	{
		$self->{error} = "Error getting events: Cannot parse response: $@\n".$response->content();
		return 0;
	}

	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error getting events: $xml->{message}";
		return 0;
	}
	return $xml;
}
sub syncEvents
{
	my ($self,$parameters) = @_;
	$self->{error} = '';

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   method		=> 'syncEvents',
			hub			=> $parameters->{hub},
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to retrieve events from server: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => ['event','monitor','zone']);
    };
	if ($@)
	{
		$self->{error} = "Error getting events: Cannot parse response: $@\n".$response->content();
		return 0;
	}

	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error getting events: $xml->{message}";
		return 0;
	}
	return $xml;
}
sub updateEvent
{
	my ($self,$event_id,$parameters) = @_;
	$self->{error} = '';

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   method		=> 'updateEvent',
			hub			=> $parameters->{hub},
			code		=> $event_id,
			active		=> $parameters->{active},
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to retrieve events from server: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => ['event','monitor','zone']);
    };
	if ($@)
	{
		$self->{error} = "Error getting events: Cannot parse response: $@\n".$response->content();
		return 0;
	}

	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error getting events: $xml->{message}";
		return 0;
	}
	return $xml;
}
sub confirmSync
{
	my ($self,$hub,$event) = @_;

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   method		=> 'confirmSync',
			hub			=> $hub,
			event		=> $event,
		]
    );

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Failed to communicate with server to confirm sync";
		return 0;
	}

	my $xml = eval{
        XMLin($response->content(),KeyAttr => [],"ForceArray" => ['event','monitor','zone']);
    };
	if ($@)
	{
		$self->{error} = "Error confirming sync: Cannot parse response: $@\n".$response->content();
		return 0;
	}

	unless ($xml->{success} == 1)
	{
		$self->{error} = "Error confirming sync: $xml->{message}";
		print STDOUT $xml->{message}."\n";
		return 0;
	}
}
sub getHubTasks
{
	my ($self,$hub) = @_;
	$self->{error} = '';

	my $response = eval {
		$ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[
			login			=> $session->{user},
			password		=> $session->{pass},
			session_code 	=> $session->{code},
			method			=> 'getHubTasks',
			hub				=> $hub,
		]
		);
	};
	if ($@)
	{
		#print "Failed to connect to server: $@\n";
	}
	#print "Content: ".$response->content()."\n";
	my $xml = eval {
		XMLin($response->content(),"ForceArray" => ['task']);
	};
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content();
		return 0;
	}
	return $xml;
}
sub getEventZones
{
	my ($self,$event_id) = @_;
	$self->{error} = '';

	if (! $event_id)
	{
		$self->{error} = "Event ID is required as first scalar parameter";
		return 0;
	}

	my $response = eval {
		$ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[
			login			=> $session->{user},
			password		=> $session->{pass},
			session_code 	=> $session->{code},
			method			=> 'getEventZones',
			event			=> $event_id,
		]
		);
	};
	if ($@)
	{
		#print "Failed to connect to server: $@\n";
	}
	unless ($response)
	{
		$self->{error} = "No response from monitor in getEventZones\n";
		return 0;
	}

	#print "Content: ".$response->content()."\n";
	my $xml = eval {
		XMLin($response->content(),"ForceArray" => ['zone']);
	};
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content();
		return 0;
	}
	return $xml;
}
sub addData
{
	my ($self,$hub,$event,$monitor,$zone,$time_offset,$value) = @_;
	$self->{error};

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   login			=> $session->{user},
			password		=> $session->{pass},
			hub				=> $hub,
			session_code 	=> $session->{code},
			method			=> 'addData',
			event			=> $event,
			monitor			=> $monitor,
			time			=> $time_offset,
			zone			=> $zone,
			value			=> $value,
		]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Error returned: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content());
    };
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content()."\n";
		return 0;
	}
    $session->{code} = $xml->{header}->{session};

	if ($xml->{success})
	{
		#print "Post Successful\n";
		return 1;
	}
	else
	{
		$self->{error} = "Posting Data Failed: $xml->{message}";
		return 0;
	}
	return 1;
}
sub addEvent
{
	my ($self,$label,$location,$status_id,$date_start,$custom_1,$custom_2,$custom_3,$custom_4) = @_;

	$self->{error};

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   login			=> $session->{user},
			password		=> $session->{pass},
			session_code 	=> $session->{code},
			method			=> 'addEvent',
			label			=> $label,
			location		=> $location,
			status_id		=> $status_id,
			date_start		=> $date_start,
			custom_1		=> $custom_1,
			custom_2		=> $custom_2,
			custom_3		=> $custom_3,
			custom_4		=> $custom_4,
		]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Error returned: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content());
    };
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content()."\n";
		return 0;
	}
    $session->{code} = $xml->{header}->{session};

	if ($xml->{success})
	{
		#print "Post Successful\n";
		return $xml;
	}
	else
	{
		$self->{error} = "Posting Data Failed: $xml->{message}";
		return 0;
	}
	return 1;
}
sub addSensor
{
	my ($self,$asset,$sensor) = @_;
	$self->{error} = '';

	my $response= $ua->request(
		POST $url,
		Content_Type	=> 'form-data',
		Content			=>
		[	login			=> $session->{user},
			password		=> $session->{pass},
			session_code 	=> $session->{code},
			method			=> 'addSensor',
			asset_code		=> $asset,
			code			=> $sensor,
		]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Error returned: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content());
    };
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content()."\n";
		return 0;
	}
    $session->{code} = $xml->{header}->{session};

	if ($xml->{success})
	{
		#print "Post Successful\n";
		return 1;
	}
	else
	{
		$self->{error} = "Adding Sensor Failed: $xml->{message}";
		return 0;
	}
	return 1;
}
sub addReading
{
	my ($self,$asset,$sensor,$value,$time) = @_;
	$self->{error} = '';

	my $response = $ua->request(
		POST $url,
		Content_Type    => 'form-data',
		Content         =>
		[   login			=> $session->{user},
			password		=> $session->{pass},
			session_code 	=> $session->{code},
			method			=> 'addReading',
			asset_code		=> $asset,
			sensor_code		=> $sensor,
			date_reading	=> $time,
			value			=> $value,
		]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$self->{error} = "Error returned: ".$response->status_line;
		return 0;
	}

	my $xml = eval{
        XMLin($response->content());
    };
	if ($@)
	{
		$self->{error} = "Cannot parse response: $@\n".$response->content()."\n";
		return 0;
	}
    $session->{code} = $xml->{header}->{session};

	if ($xml->{success})
	{
		#print "Post Successful\n";
		return 1;
	}
	else
	{
		$self->{error} = "Posting Data Failed: $xml->{message}";
		return 0;
	}
	return 1;
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
