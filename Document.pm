package RootSeven::Document;

use 5.010000;
use strict;
no warnings;
use LWP::UserAgent;
use LWP::Simple;
use HTTP::Request::Common;
use XML::Simple;
use XML::SAX::Expat;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use RootSeven::Document ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

my $error;
my $ua;
my $session;

# Preloaded methods go here.
sub new
{
	my $package = shift;
    $session = shift;

	$error = '';

    # Initialize UserAgent
    $ua = LWP::UserAgent->new;
    
	# Return Package
	return bless({}, $package);
}
sub err
{
	$error = shift;
	return $error;
}
sub error
{
    return $error;
}
# Check For Latest Software Version
sub latest_version
{
    my $document = shift;
    $document = shift if ($document =~ /&RootSeven\:\:Document/);

	my $response = $ua->request(
			POST "$session->{protocol}://www.$session->{domain}/_document/api",
			Content_Type    => 'form-data',
			Content         =>
			[   login			=> $session->{user},
				password		=> $session->{pass},
				session_code 	=> $session->{code},
				action			=> 'GET LATEST',
				id				=> $document,
			]
	);
	
	# Move on if no connection available
	unless ($response->is_success)
	{
		$error = "Document Module Error: Failed request for latest version: ".$response->status_line."\n";
		return 0;
	}

	# Parse Response
	my $xml = eval{
        XMLin($response->content());
    };
	if ($@)
	{
		$error = "Cannot parse response: $@\n".$response->content()."\n";
		return 0;
	}
    return $xml->{latest}->{version};
}

sub upgrade_required
{
	$error = '';
	my $document = shift;
    $document = shift if ($document =~ /^RootSeven\:\:Document/);
    my $version = shift;

    my $latest = latest_version($document);
	if ($latest == 0)
	{
		return 0;
	}
	
	# Parse Versions
	my ($n1,$n2,$n3) = split(/\./,$latest);
	my ($v1,$v2,$v3) = split(/\./,$version);

	print "Comparing $latest to $version\n";
	if (($n1 > $v1) ||
		(($n1 == $v1) && ($n2 > $v2)) ||
		(($n1 == $v1) && ($n2 == $v2) && ($n3 > $v3))
	   )
	{
		# Upgrade required
		return 1;
	}
	return 0;
}

sub content
{
    my $package_id = shift;
    $package_id = shift if ($package_id =~ /^RootSeven\:\:Document/);
	my $new_file = shift;

	my $response = $ua->request(
			POST "$session->{protocol}://www.$session->{domain}/_document/show/$package_id",
			Content_Type    => 'form-data',
			Content         =>
			[   login			=> $session->{user},
				password		=> $session->{pass},
				session_code 	=> $session->{code},
				action			=> 'GET LATEST',
				id				=> $package_id,
			]
	);

	# Move on if no connection available
	unless ($response->is_success)
	{
		$error = "Document Module Error: Failed request for latest version\n";
		return 0;
	}

	if ($new_file)
	{
		# They want content saved to a given location
		unless (open (TMP,">$new_file"))
		{
			$error = "Document Module Error: Could not open $new_file for writing: $!";
			return 0;
		}

		unless (print TMP $response->content)
		{
			$error = "Document Module Error: Could not save content to $new_file: $!";
			close TMP;
			return 0;
		}

		close TMP;
		return 1;
	}

	# Return Content to caller
    return $response->content;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

RootSeven::Document - Perl extension for blah blah blah

=head1 SYNOPSIS

  use RootSeven::Document;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for RootSeven::Document, created by h2xs. It looks like the
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
