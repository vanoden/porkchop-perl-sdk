###############################################
### RootSeven::MetaData						###
### Communicate with the Root Seven Meta	###
### module interface.						###
###############################################
package RootSeven::MetaData;

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

# This allows declaration	use RootSeven-MetaData ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	error
);

our $VERSION = '0.01';

# Preloaded methods go here.
my $session;
my $url;
my $ua = LWP::UserAgent->new();

sub new
{
	my $package = shift;
    $session = shift;

	my $self = bless({}, $package);

	# Set User Agent Header
	my $agent = $session->{agent};
	$session->{agent} = "r7_client_libs/0.1" unless ($agent);
	$ua->agent($session->{agent});
	
	unless ($session->{protocol} =~ /^http/)
	{
		$self->{error} = "Session protocol must be 'http' or 'https'";
		return $self;
	}
	unless ($session->{domain} =~ /^([\w\-\.]+)\.([\w\-]+)$/)
	{
		$self->{error} = 'Invalid Session Domain Name';
		return $self;
	}
    $url = "$session->{protocol}://www.$session->{domain}/_monitor/api";

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
		$self->{error} = "Failed to ping portal";
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
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

RootSeven-MetaData - Perl extension for blah blah blah

=head1 SYNOPSIS

  use RootSeven-MetaData;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for RootSeven-MetaData, created by h2xs. It looks like the
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

root, E<lt>root@office.dmandc.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
