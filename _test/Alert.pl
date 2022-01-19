#!/usr/bin/perl

###############################################
### Porkchop::Service::Alert test			###
### Test the Porkchop Alert module.			###
### A. Caravello 1/10/2022					###
###############################################

# Load Modules
use strict;
use Data::Dumper;
use Term::ReadKey;
use lib "../../";
use BostonMetrics::HTTP::Client;
use Porkchop::Service::Alert;
use Porkchop::Service::Monitor;

###############################################
### User Configurable Parameters			###
###############################################
my %config = (
	'conduit'		=> 'TCP',
	'log_level'		=> 6,
	'timeout'		=> 10,
	'portal_url'	=> 'http://test.spectrosinstruments.com',
	'agent'			=> 'portal_sync_service/0.1'
);

foreach my $arg (@ARGV) {
	chomp $arg;

	if ($arg =~ /^\-\-(\w[\w\-\.\_]*)\=(.*)$/) {
		my $key = $1;
		my $val = $2;
		$key =~ s/\-/\_/g;
		$config{$key} = $val
	}
}

###############################################
### Get Portal Credentials                  ###
###############################################
my ($login,$password);
if (defined($config{login})) {
	$login = $config{login};
	print "Please Provide Your Portal Password\n";
}
else {
	print "Please Provide Your Portal Credentials\n";
	print "Login: ";
	$login = ReadLine(0);
	chomp $login;
	print "Password: ";
}
ReadMode('noecho');
$password = ReadLine(0);
ReadMode('normal');
chomp $password;
print "\n";

###############################################
### Main Procedure							###
###############################################
# Initialize HTTP Client
my $client = BostonMetrics::HTTP::Client->new({'conduit' => $config{conduit},'proxy_host' => $config{proxy_host},'proxy_port' => $config{proxy_port}});
$client->agent($config{'agent'});
$client->verbose($config{'log_level'});
$client->timeout($config{'timeout'});
if ($config{conduit} =~ /proxy/) {
	$client->proxy($config{proxy_host},$config{proxy_port});
}
elsif ($config{conduit}) {
	$client->conduit($config{conduit});
}
die "Error: ".$client->error()."\n" unless($client->connect());

# Initialize Service
my $alert_service = Porkchop::Service::Alert->new({
	'ssl'		=> 0,
	'client'	=> $client,
	'verbose'	=> $config{'log_level'},
	'endpoint'	=> $config{'portal_url'}
});

my $monitor_service = Porkchop::Service::Monitor->new({
	'ssl'		=> 0,
	'client'	=> $client,
	'verbose'	=> $config{'log_level'},
	'endpoint'	=> $config{'portal_url'}
});

die "Authentication failed: ".$alert_service->error()."\n" unless ($alert_service->authenticate($login,$password));

print "Authenticated\n";

my $collections = $monitor_service->findCollections({'status' => 'ACTIVE'},'collection');
print Dumper $collections->[0];
