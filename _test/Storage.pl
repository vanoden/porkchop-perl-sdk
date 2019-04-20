#!/usr/bin/perl
###############################################
### Storage.pl								###
### Test Porkchop Portal Uploads.			###
### A. Caravello 4/19/2019					###
###############################################

# Load Modules
use strict;
use Term::ReadKey;
use Data::Dumper;
use lib "../../";
use Porkchop::Register;
use Porkchop::Storage;

###############################################
### User Configurable Parameters			###
###############################################
my %config = (
	'conduit'	=> 'TCP',
	'log_level'	=> 3,
	'timeout'	=> 10,
	'portal_url'	=> "http://test.spectrosinstruments.com"
);

foreach my $option(@ARGV) {
	chomp $option;

	if ($option =~ /^\-\-(upload\-file|upload\-name|log\-level)\=(.*)/) {
		my $key = $1;
		my $value = $2;
		$key =~ s/\-/_/g;
		$config{$key} = $value;
	}
}

###############################################
### Get Portal Credentials					###
###############################################
print "Please Provide Your Portal Credentials\n";
print "Login: ";
my $login = ReadLine(0);
chomp $login;
print "Password: ";
ReadMode('noecho');
my $password = ReadLine(0);
ReadMode('normal');
chomp $password;
print "\n";

###############################################
### Main Procedure							###
###############################################
# Initialize Web Client
my $client = BostonMetrics::HTTP::Client->new({'conduit' => $config{conduit},'verbose' => $config{log_level}});
$client->agent("Storage.pl/0.1");
$client->verbose($config{'log_level'});
$client->timeout($config{'timeout'});

die "Cannot connect: ".$client->error()."\n" unless($client->connect());

# Start Session
print "Authenticating to portal\n";
my $register = Porkchop::Register->new();
$register->client($client);
$register->verbose($config{'log_level'});
$register->endpoint($config{portal_url}."/_register/api");
$register->authenticate($login,$password);
die "Cannot login: ".$register->error()."\n" if ($register->error);

# Initialize Storage Module
my $storage = Porkchop::Storage->new({
	'verbose'	=> 9,
	'endpoint'	=> $config{portal_url}."/_storage/api",
	'client'	=> $client,
});

print "Pinging Storage Endpoint\n";
unless ($storage->ping()) {
	die "Error pinging endpoint: ".$storage->error()."\n";
}

if (0) {
	$storage->add_repository({
		'code'		=> 'repo1',
		'name'		=> 'Test Repository',
		'type'		=> 'Local',
		'status'	=> 'ACTIVE',
		'path'		=> "/var/porkchop/storage/repo1"
	});
	die $storage->error()."\n" if ($storage->error());
}
my @repositories = $storage->find_repositories();
foreach my $repository(@repositories) {
	print "Repo: ".$repository->{code}."\n";
}

if ($storage->add_file('repo1',$config{upload_name},'files','ACTIVE',$config{upload_file})) {
	print "Success\n";
}
else {
	print "Error: ".$storage->error()."\n";
}