#!/usr/bin/perl -w

#### DEBUG
my $DEBUG = 0;
$DEBUG = 01;

#### TIME
my $time = time();
my $duration = 0;
my $current_time = $time;

=head2

APPLICATION

    flow

PURPOSE

    Manage workflow files and run workflows

USAGE

    ./flow.pl mode [switch] [args] [--help]


 mode     :    Type of workflow object (work|app|param)
 switch   :    Nested object (e.g., work app, app param)
 args     :    Arguments for the selected mode
 --help   :    print help info

EXAMPLES

PROJECTS

# Add project to database
/agua/apps/bin/cli/flow.pl proj save --projfile ./Project1.proj

# Add workflows to project (and save to database)
/agua/apps/bin/cli/flow.pl proj saveWorkflow --project Project1 --wkfile ./workflowOne.work

WORKFLOWS

# Create a workflow file with a specified name
./flow.pl work create --wkfile /workflows/workflowOne.wk --name workflowOne

# Add an application to workflow file
./flow.pl work addApp --wkfile /workflows/workflowOne.wk --appfile /workflows/applicationOne.app --name applicationOne

# Run a single application in a workflow
./flow.pl work app run --wkfile /workflows/workflowOne.wk --name applicationOne

# Run all applications in workflow
./flow.pl work run --wkfile /workflows/workflowOne.wk 

APPLICATIONS

# Create an application file from a file containing the application run command
./flow.pl app loadCmd --cmdfile /workflows/applicationOne.cmd --appfile /workflows/applicationOne.app --name applicationOne

=cut

use strict;
#use diagnostics;

#### USE LIBRARY
use Scalar::Util qw(weaken);
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Term::ANSIColor qw(:constants);
use Data::Dumper;

#### INTERNAL MODULES
use Timer;
use Agua::CLI::Parameter;
use Agua::CLI::App;
use Agua::CLI::Workflow;
use Agua::CLI::Project;

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";
my $logfile  =   "$installdir/log/flow.log";
my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    log     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

#### GET MODE AND ARGUMENTS
my @arguments = @ARGV;
usage() if not @arguments;
#print "flow.pl    arguments: @arguments\n";

#### GET FILE
my $file = shift @ARGV;
usage() if $file =~ /^-h$/ or $file =~ /^--help$/;
#print "flow.pl    Can't find file: $file\n" and exit if not -f $file;
#print "flow.pl    file: $file\n";

#### GET MODE
my $mode = shift @ARGV;
#print "mode: $mode\n";
print "No mode provided (try --help)\n" and exit if not defined $mode;
usage() if $mode =~ /^-h$/ or $mode =~ /^--help$/;
#print "mode: $mode\n";

#### MANAGE INDIVIDUAL OR NESTED WORKFLOW FILES
if ( $file =~ /\.param$/ ) {
    my $parameter = Agua::CLI::Parameter->new(
        paramfile   =>  $file,
        conf        =>  $conf
    );
    $parameter->getopts();
    $parameter->$mode();    
}
elsif ( $file =~ /\.app$/ ) {
    my $app = Agua::CLI::App->new(
        appfile     =>  $file,
        conf        =>  $conf
    );
    $app->getopts();
    $app->$mode();    
}
elsif ( $file =~ /(\.wk|\.work)$/ )
{
    my $workflow = Agua::CLI::Workflow->new(
        inputfile      =>  $file,
        conf        =>  $conf
    );
    $workflow->getopts();
    my $success = $workflow->$mode();
    print "flow.pl    mode '$mode' not recognised\n" and exit if $success != 1;
}
elsif ( $file =~ /\.proj$/ )
{
    my $project = Agua::CLI::Project->new(
        inputfile   =>  $file,
        conf        =>  $conf
    );
    $project->getopts();
    $project->$mode();
}
else
{
    print "flow.pl    file type '$file' not recognised (must be .proj, .work, .wk, .app or .param)\n";
}


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


sub usage
{
    print GREEN;
    print `perldoc $0`;
    print RESET;
    exit;
}



