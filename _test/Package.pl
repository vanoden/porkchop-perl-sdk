#!/usr/bin/perl

use strict;
use lib "../../";
use Porkchop::Register;
use Porkchop::Package;
use Data::Dumper;

my %config = (
	'conduit'	=> 'TCP',
	'log_level'	=> 9,
	'timeout'	=> 10,
	'login'		=> 'acaravello',
	'password'	=> 'Concentr8!',
	'portal_url'	=> "http://dev.office.spectrosinstruments.com"
);

my $client = BostonMetrics::HTTP::Client->new({'conduit' => $config{conduit},'verbose' => $config{log_level}});
$client->agent("Package.pl/0.1");
$client->verbose($config{'log_level'});
$client->timeout($config{'timeout'});

die "Cannot connect: ".$client->error()."\n" unless($client->connect());

# Start Session
print "Authenticating to portal\n";
my $register = Porkchop::Register->new();
$register->client($client);
$register->verbose($config{'log_level'});
$register->endpoint($config{portal_url}."/_register/api");
$register->authenticate($config{login},$config{password});
die "Cannot login: ".$register->error()."\n" if ($register->error);

my $_package = Porkchop::Package->new({
	'verbose'	=> 9,
	'endpoint'	=> $config{portal_url}."/_package/api",
	'client'	=> $client,
});

print "Pinging Package Endpoint\n";
unless ($_package->ping()) {
	die "Error pinging endpoint: ".$_package->error()."\n";
}

my $last;
my @packages = $_package->find_packages();
foreach my $package(@packages) {
	print "Package: ".$package->{code}."\n";
	my $version = $_package->latest_version($package->{code});
	if ($_package->error()) {
		print "Error: ".$_package->error()."\n";
	}
	else {
		print "Version: ";
		printf("%0d.%0d.%0d\n",$version->{major},$version->{minor},$version->{build});
		$last->{build} = $version->{build};
		$last->{major} = $version->{major};
		$last->{minor} = $version->{minor};
	}
}

if ($_package->add_version('web-dl',$last->{major},$last->{minor},$last->{build} + 1,'PUBLISHED','/tmp/test.txt')) {
	print "Success\n";
}
else {
	print "Error: ".$_package->error();
}