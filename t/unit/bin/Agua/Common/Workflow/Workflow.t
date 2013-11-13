#!/usr/bin/perl -w

use Test::More	tests => 18;

use FindBin qw($Bin);
use lib "$Bin/../../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;


BEGIN {
    use_ok('Conf::Yaml');
    use_ok('Test::Agua::Common::Workflow');
}
require_ok('Conf::Yaml');
require_ok('Test::Agua::Common::Workflow');

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

my $logfile = "$Bin/outputs/aguatest.workflow.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;

my $conf = Conf::Yaml->new(
    inputfile	=>	$configfile,
    backup	    =>	1,
    separator	=>	"\t",
    spacer	    =>	"\\s\+",
    logfile     =>  $logfile,
	SHOWLOG     =>  2,
	PRINTLOG    =>  2    
);
isa_ok($conf, "Conf::Yaml", "conf");

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../../dump/create.dump";

my $username = $conf->getKey("database", "TESTUSER");

my $workflow = new Test::Agua::Common::Workflow(
    conf        =>  $conf,
    dumpfile    =>  $dumpfile,
    logfile     =>  $logfile,
	SHOWLOG     =>  $SHOWLOG,
	PRINTLOG    =>  $PRINTLOG,
	username	=>	$username
);
isa_ok($workflow, "Test::Agua::Common::Workflow", "workflow");

#### ADD WORKFLOW
my $json = {
    "username"	=>	$username,
    "project"	=>	"Project1",
    "name"		=>	"Workflow1",
    "number"	=>	"1",
    "description"=>	"Workflow description",
    "notes"	    =>	"Notes",
};
$workflow->testAddWorkflow($json);


__END__

echo '{"project":"Project1","name":"Workflow3","number":"3","newnumber":2,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi

echo '{"project":"Project1","name":"Workflow3","number":"2","newnumber":3,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi

echo '{"project":"Project1","name":"Workflow3","number":"3","newnumber":2,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi
Content-type: text/html

echo '{"project":"Project1","name":"Workflow3","number":"2","newnumber":5,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi

echo '{"project":"Project1","name":"Workflow3","number":"5","newnumber":1,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi

echo '{"project":"Project1","name":"Workflow3","number":"1","newnumber":3,"mode":"moveWorkflow","username":"syoung","sessionId":"1234567890.1234.123"}' | /var/www/cgi-bin/agua/0.6/workflow.cgi

