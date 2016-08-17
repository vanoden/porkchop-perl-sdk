package Porkchop::Session;

use strict;
use HTTP::Request;
use HTTP::Cookies::Netscape;

sub new {
	my $package = shift;

	my $self = { };
	bless $self,$package;

	return $self;
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

sub init {
}

sub communicate {
	my $self = shift;
	my $request = shift;

	# Initiate User Agent
	my $cookie_jar = HTTP::Cookies::Netscape->new(
		file => "cookies.txt",
		autosave => 1,
	);
	$self->{ua} = LWP::UserAgent->new();
	$self->{ua}->cookie_jar( $cookie_jar );

	# Set User Agent Header
	$self->{ua}->{agent} = $self->{agent};

	my $url = $self->{protocol}."://".$self->{host}."/".$self->{uri};

	# Send Request
	my $response = $self->{ua}->request($request);

	# Move on if no connection available
	unless ($response->is_success)
	{
		if ($response->content() =~ /Requirements\snot\sMet/)
		{
			$self->{error} = "Invalid Username or Password";
			return $self;
		}
		$self->{error} = "Failed to communicate with server: ".$response->status_line;
		return 0;
	}
}
sub ping {
	my $self = shift;
	my $url = shift;

	my $request = HTTP::Request->new('POST');
	my $content = "login=".$self->{login}."&password=".$self->{password}."&method=ping";
	$request->content($content);

	my $response = $self->communicate($request);
	if ($response->code != 200) {
		$self->{error} = "Error pinging service: Cannot parse response: $@\n".$response->content();
		return $self;
	}
	unless ($response->{success} == 1)
	{
		$self->{error} = "Error pinging service: $response->{message}";
		return undef;
	}
	# Return Package
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
