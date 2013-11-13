#!/usr/bin/perl

use FCGI; # Imports the library; required line

# Initialization code

$cnt = 0;

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "/agua/lib";
use lib "/agua/lib";

#### INTERNAL MODULES
use Agua::Workflow;
use Agua::DBaseFactory;
use Conf::Yaml;

#### EXTERNAL MODULES
use DBI;
use DBD::SQLite;
use Data::Dumper;

    #### TIME BEFORE    
	use Devel::Peek;
	use Time::HiRes qw[gettimeofday tv_interval];
	my $time = [gettimeofday()];	

#### SET LOG
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;

#### GET CONF
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1,
    SHOWLOG     =>  2,
    PRINTLOG    =>  4
);

my $object = Agua::Workflow->new({
    conf        =>  $conf,
    #SHOWLOG     =>  4,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
});


# Response loop
while (FCGI::accept >= 0) {


my $begintime;

BEGIN {
$begintime = time();
warn "begintime: $begintime\n";
    
}

print "Content-type: text/html\r\n\r\n";

#print "<h2>fcgi.pl, processid: $$</h2>\n";
#print "<head>\n<title>FastCGI Demo Page (perl)</title>\n</head>\n";
#print  "<h1>FastCGI Demo Page (perl)</h1>\n";
#print "This is coming from a FastCGI server.\n<BR>\n";
#print "Running on <EM>$ENV{SERVER_NAME}</EM> to <EM>$ENV{REMOTE_HOST}</EM>\n<BR>\n";

$cnt++;
warn "This is connection number $cnt\n";
  
my $whoami = `whoami`;
chomp($whoami);
warn " XXX: $whoami<br>\n";

#print "conf:\n";
#print Dumper $conf;

### GET PUTDATA
my $input	= <STDIN>;
#my $input	= $ARGV[0];
#print "input: $input\n";

print "{ error: 'workflow.pl    input not defined' }" and exit if not defined $input or not $input or $input =~ /^\s*$/;

#### GET JSON
use JSON;
my $jsonParser = JSON->new();
my $json = $jsonParser->allow_nonref->decode($input);
print "{ 'error' : 'workflow.pl   JSON not defined' }" and exit if not defined $json;

warn "JSON Parser: ", tv_interval($time), "\n";


#### GET MODE
my $mode = $json->{mode};
print "{ error: 'workflow.pl    mode not defined' }" and exit if not defined $mode;

#### GET USERNAME
my $username = $json->{username};
#print "{ error: 'view.cgi    username not defined' }" and exit if not defined $username;

warn "Instantiate Conf::Yaml: ", tv_interval($time), "\n";

my $logfile     =   "$Bin/log/$username.workflow.log";
$conf->logfile($logfile);
$object->logfile($logfile);
$object->initialise($json);


warn "Instantiate Agua::Workflow: ", tv_interval($time), "\n";

#### RUN QUERY
no strict;
$object->$mode();
use strict;



warn "workflow->$mode(): ", tv_interval($time), "\n";

my $endtime = time();
warn "total: " . ($endtime - $begintime) . "\n";




}   # while (FCGI::accept >= 0) {









