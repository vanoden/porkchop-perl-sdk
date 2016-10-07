package Porkchop::Session;

use strict;
use BostonMetrics::HTTP::Request;
use BostonMetrics::HTTP::Response;
use Data::Dumper;

my $client;

sub new {
	my $package = shift;
	my $parameters = shift;

	my $self = { };
	bless $self,$package;

	if (defined($parameters->{login})) {
		$self->{login} = $parameters->{login};
	}
	if (defined($parameters->{password})) {
		$self->{password} = $parameters->{password};
	}
	if (defined($parameters->{portal_url})) {
		$self->{poral_url} = $parameters->{portal_url};
	}

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

sub login {
	my $self = shift;
	my $login = shift;

	if ($login) {
		$self->{login} = $login;
	}
	return $self->{login};
}

sub password {
	my $self = shift;
	my $password = shift;

	if ($password) {
		$self->{password} = $password;
	}
	return $self->{password};
}

sub host {
	my $self = shift;
	my $host = shift;

	if ($host) {
		$self->{host} = $host;
	}
	return $self->{host};
}

sub port {
	my $self = shift;
	my $port = shift;

	if ($port) {
		$self->{port} = $port;
	}
	return $self->{port};
}

sub protocol {
	my $self = shift;
	my $protocol = shift;

	if ($protocol) {
		$self->{protocol} = $protocol;
	}
	return $self->{protocol};
}

sub code {
	my $self = shift;
	my $code = shift;

	if ($code) {
		$self->{code} = $code;
	}
	return $self->{code};
}

sub error {
	my $self = shift;
	return $self->{error};
}
sub verbose {
	my $self = shift;
	my $verbose = shift;
	$self->{verbose} = $verbose if (defined($verbose));
	return $self->{verbose};
}
sub communicate {
	my $self = shift;
	my $request = shift;

	# Initiate User Agent
	my $cookie_jar = HTTP::Cookies::Netscape->new(
		file => "cookies.txt",
		autosave => 1,
	);

	my $conduit = LWP::UserAgent->new();
	#$self->{ua}->cookie_jar( $cookie_jar );

	# Set User Agent Header
	#$self->{ua}->{agent} = $self->{agent};

	#my $url = $self->{protocol}."://".$self->{host}."/".$self->{uri};

	# Send Request
	#return $self->{ua}->request($request);
}
sub ping {
	my $self = shift;

	my $request = HTTP::Request->new();
	$request->uri($self->{portal_url}."/_session/ping");
	$request->header("X-Test" => "mytest");
	$request->method("POST");
	my @parameters = (
		"method=ping"
	);
	$request->content(join(",",@parameters));

	my $ua = LWP::UserAgent->new;
	$ua->agent("PorkchopClient");

	my $response = $ua->request($request);
print Dumper $response;

	return 1;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Porkchop::Register - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Porkchop::Register;
  blah blah blah

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
