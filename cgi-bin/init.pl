#!/usr/bin/perl -w

=head2

	APPLICATION 	init.pl
	
	PURPOSE
	
		EXECUTE INITIALISATION TASKS FOR AGUA:
		
			LOAD USER DATA INTO AGUA DATABASE
			
			PRINT X.509 KEY FILES FOR HTTPS AND AWS
			
			MOUNT AGUA DATA VOLUMES
			
			MOUNT USER VOLUMES	
			
=cut

use strict;

use FindBin qw($Bin);

#### DISABLE BUFFERING OF STDOUT
$| = 1;

#### DEBUG HEADER
print "Content-type: text/html\n\n";

use CGI::Carp qw(fatalsToBrowser);

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   2;
my $logfile     = "$Bin/log/agua-init.log";

#### GET CONF
use FindBin qw($Bin);
use lib "$Bin/lib/";
use Conf::Yaml;
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1,
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  4
);

#### USE LIBS
use lib "lib";

#### INTERNAL MODULES
use Agua::Init;
use Util;

#### EXTERNAL MODULES
use Data::Dumper;

#### GET INPUT
my $input = $ARGV[0];
print "No JSON input<br>Exiting<br>\n" and exit if not defined $input or not $input;
$input =~ s/\s+$//;

#### CONVERT JSON TEXT TO OBJECT
use JSON;
my $jsonParser = JSON->new();
my $json = $jsonParser->allow_nonref->decode($input);

#### ADD CONF TO JSON OBJECT
$json->{data}->{conf} = $conf;

#### CREATE INIT OBJECT
my $init = Agua::Init->new($json->{data});

#### PRINT KEY FILE
$init->printKeyFiles();

####### GET ELASTIC IP
my $publicip = $init->getPublicIp() || "localhost";
#print "{error: 'Can't get public IP address'}" and exit if not defined $publicip or not $publicip;

print "{status: 'Printing init log'}\n";

#### PRINT REDIRECT WINDOW
my $htmldir = $conf->getKey('agua', 'HTMLDIR');
my $urlprefix = $conf->getKey('agua', 'URLPREFIX');
my $filename = "log/initlog.html";
my $url = "$urlprefix/$filename";
my $htmlfile = "$htmldir/$urlprefix/$filename";
my $datetime = `date`;

open(STDOUT, ">$htmlfile") or die "Can't open htmlfile: $htmlfile\n" if defined $htmlfile;
print qq{<html>
<head>
	<title>Init Progress Log</title>

	<link href="../plugins/init/css/progress.css" rel="stylesheet" type="text/css">

</head>
<script>
var waitSeconds = 10;
function beginrefresh(){
	if (waitSeconds==1) {
		window.location.reload()
	}
	else { 
		waitSeconds-=1
		document.getElementById('cursec').innerHTML = waitSeconds + " seconds left until page refresh"
	}
	setTimeout("beginrefresh()",1000)
}
window.onload=beginrefresh
</script>
<body>
<center>
	<table class="header">
		<tr>
			<td class="logo"> </td>
			<td class="title"> Progress Log </td>
			<td>
				<table class="clock">
					<tr>
						<td class="date">Started: $datetime</td>
					<tr>
					</tr>
						<td class="countdown" id="cursec"></td>
					</tr>
				</table>
			</td>
		</tr>
	</table>
	</div>
	<div class="message"> Please make a note of this instance's Public IP address:</div>
	<div class="address">$publicip</div>
	<div class="message"> Click here to open Agua:</div>
	<div class="url" onclick="window.open('$publicip/agua/agua.html')">$publicip/agua/agua.html</div>
	<br>
</center>
<hr>
<div class="progress">

};


#### EXECUTE INITIALISATION
$init->init();

EXITLABEL: { warn "Doing EXITLABEL\n"; };

