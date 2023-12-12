#!/usr/bin/perl

###############################################
### Porkchop::Service::Alert test			###
### Test the Porkchop Alert module.			###
### A. Caravello 1/10/2022					###
###############################################

# Load Modules
use strict;
use Data::Dumper;
use lib "../../";
use BostonMetrics::Hub;
use Porkchop::Service::Alert;
use Porkchop::Service::Monitor;
use parent "Embedded::TestScript";

my $script = Embedded::Utility->new();

###############################################
### Usage									###
###############################################
my $usage = $script->usage();
$usage->description('Show the latest readings for each sensor');
$usage->example($script->name()." [arguments]");

###############################################
### Configuration							###
###############################################
# Load Config From File if Available
my $hub = BostonMetrics::Hub->new({'config_file' => $script->locateConfigFile(),'verbose' => $script->parameter('log_level')});
$script->configure($hub->config());

$script->defaultParameter('conduit','TCP');
$script->defaultParameter('timeout',10);
$script->defaultParameter('agent','portal_sync_service/0.1');
$script->defaultParameter('endpoint','https://test.spectrosinstruments.com');

# Display Parameters and Exit
if ($script->test_mode()) {
    $script->displayAllParameters();
    exit;
}
$script->show_version();
$script->show_usage();

###############################################
### Get Portal Credentials					###
###############################################
$script->getCredentials();

###############################################
### Main Procedure							###
###############################################
# Initialize HTTP Client
$script->initClient();

# Initialize Service
my $alert_service = Porkchop::Service::Alert->new({
	'ssl'		=> 0,
	'client'	=> $script->httpClient(),
	'verbose'	=> $script->parameter('log_level'),
	'endpoint'	=> $script->parameter('portal_url')
});

my $monitor_service = Porkchop::Service::Monitor->new({
	'ssl'		=> 0,
	'client'	=> $script->httpClient(),
	'verbose'	=> $script->parameter('log_level'),
	'endpoint'	=> $script->parameter('portal_url')
});

die "Authentication failed: ".$alert_service->error()."\n" unless ($alert_service->authenticate($script->parameter('login'),$script->parameter('password')));

print "Authenticated\n";

my $collections = $monitor_service->findCollections({'status' => 'ACTIVE'},'collection');
die $monitor_service->error() if ($monitor_service->error());
print Dumper $collections->[0];