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
	'conduit'		=> 'TCP',
	'log_level'		=> 3,
	'timeout'		=> 10,
	'environment'	=> "development"
);

foreach my $option(@ARGV) {
	chomp $option;

	if ($option =~ /^\-\-(upload\-file|upload\-name|log\-level|environment|repository|login)\=(.*)/) {
		my $key = $1;
		my $value = $2;
		$key =~ s/\-/_/g;
		$config{$key} = $value;
	}
    elsif ($option =~ /^\-\-(settings)$/) {
        my $key = $1;
        $key =~ s/\-/_/g;
        $config{$key} = 1;
    }
}

if ($config{environment} eq 'development') {
	$config{portal_url} = 'http://dev.office.spectrosinstruments.com';
}
elsif ($config{environment} eq 'test') {
	$config{portal_url} = 'http://test.spectrosinstruments.com';
}
elsif ($config{environment} eq 'production') {
	$config{portal_url} = 'https://www.spectrosinstruments.com';
}
else {
	die "Valid environment required\n";
}

if ($config{settings}) {
    foreach my $setting(sort keys %config) {
        print "$setting: ".$config{$setting}."\n";
    }
    exit;
}

###############################################
### Get Portal Credentials					###
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

if ($config{upload_name}) {
	die "File not found\n" unless (-e $config{upload_file});
    die "Repository required\n" unless (defined($config{repository}));
	if ($storage->add_file($config{repository},$config{upload_name},'files','ACTIVE',$config{upload_file})) {
		print "Success\n";
	}
	else {
		print "Error: ".$storage->error()."\n";
	}
}
