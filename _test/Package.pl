#!/usr/bin/perl
###############################################
### Package.pl								###
### Package Module Tests					###
### A. Caravello 4/18/2019					###
###############################################

# Load Modules
use strict;
use Term::ReadKey;
use Data::Dumper;
use lib "../../";
use Porkchop::Register;
use Porkchop::Package;

###############################################
### User Configurable Parameters			###
###############################################
my %config = (
	'conduit'	=> 'TCP',
	'log_level'	=> 9,
	'timeout'	=> 10,
	'portal_url'	=> "http://test.spectrosinstruments.com"
);

foreach my $option(@ARGV) {
	chomp $option;

	if ($option =~ /^\-\-(upload\-file|log\-level|product\-code|major\-number|minor\-number|build\-number)\=(.*)/) {
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

if ($config{settings}) {
    foreach my $setting(sort keys %config) {
        print "$setting: ".$config{$setting}."\n";
    }
    exit;
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
$register->authenticate($login,$password);
die "Cannot login: ".$register->error()."\n" if ($register->error);

# Initialize Package Module
my $_package = Porkchop::Package->new({
	'verbose'	=> 9,
	'endpoint'	=> $config{portal_url}."/_package/api",
	'client'	=> $client,
});

print "Pinging Package Endpoint\n";
unless ($_package->ping()) {
	die "Error pinging endpoint: ".$_package->error()."\n";
}

my ($build_number,$minor_number,$major_number);
my @packages = $_package->find_packages();
foreach my $package(@packages) {
	next unless $package->{code};
	print "Package: ".$package->{code}."\n";
	my $version = $_package->latest_version($package->{code});
	if ($_package->error()) {
		print "Error: ".$_package->error()."\n";
	}
	else {
		print "Version: ";
		printf("%0d.%0d.%0d\n",$version->{major},$version->{minor},$version->{build});
		$build_number = $version->{build};
		$major_number = $version->{major};
		$minor_number = $version->{minor};
        exit;
	}
    $build_number ++;
}

if (defined($config{build_number})) {
	$build_number = $config{build_number};
}
if (defined($config{minor_number})) {
	$minor_number = $config{minor_number};
}
if (defined($config{major_number})) {
	$major_number = $config{major_number};
}

print "Major: $major_number\n";
if ($config{product_code} && length($config{product_code})) {
	die "major number required\n" unless(defined($major_number));
	if ($_package->add_version($config{product_code},$major_number,$minor_number,$build_number,'PUBLISHED',$config{upload_file})) {
		print "Success\n";
	}
	else {
		print "Error: ".$_package->error();
	}
}