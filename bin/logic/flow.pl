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



# create workflow



perl flow.pl work create --wkfile /workflows/workflowOne.wk --name workflowOne



# create application from command file



perl flow.pl app loadCmd --cmdfile /workflows/applicationOne.cmd --appfile /workflows/applicationOne.app --name applicationOne



# add application to workflow



perl flow.pl work addApp --wkfile /workflows/workflowOne.wk --appfile /workflows/applicationOne.app --name applicationOne



# run single application



perl flow.pl work app run --wkfile /workflows/workflowOne.wk --name applicationOne



# run all applications in workflow



perl flow.pl work run --wkfile /workflows/workflowOne.wk 



=cut



use strict;

#use diagnostics;



#### USE LIBRARY

use Scalar::Util qw(weaken);

use FindBin qw($Bin);

use lib "$Bin/../../lib";

#BEGIN {

#    unshift @INC, "/nethome/syoung/base/pipeline/moose/tmp/lib64/perl5/site_perl/5.8.8/x86_64-linux-thread-multi";

#    unshift @INC, "/nethome/syoung/0.5/lib/external/perl5-32/site_perl/5.8.8";

#    unshift @INC, "/nethome/syoung/0.5/lib/external/perl5-64/site_perl/5.8.8/x86_64-linux-thread-multi";

#    unshift @INC, "/nethome/syoung/0.5/lib/external/perl5-32/5.8.8";    

#}



#### EXTERNAL MODULES

use Term::ANSIColor qw(:constants);

use Data::Dumper;

#use Getopt::Long qw(GetOptionsFromString);

#use Getopt::Simple;

use Agua::CLI::Parameter;

use Agua::CLI::App;

use Agua::CLI::Workflow;



#### INTERNAL MODULES

use Timer;



#### GET MODE AND ARGUMENTS

my @arguments = @ARGV;

usage() if not @arguments;

print "flow.pl    arguments: @arguments\n";



#### GET FILE

my $file = shift @ARGV;

print "flow.pl    file: $file\n";

#print "flow.pl    Can't find file: $file\n" and exit if not -f $file;



#### GET SWITCH

#my $switch = shift @ARGV;

##print "Argument '$switch' not supported. Please use 'param', 'app' or 'work'\n"

#    and exit if $switch !~ /^(param|app|work)$/;



#### GET MODE

my $mode = shift @ARGV;

print "No mode provided (try --help)\n" and exit if not defined $mode;

usage() if $mode =~ /^-h$/ or $mode =~ /^--help$/;

#print "mode: $mode\n";



#### MANAGE INDIVIDUAL OR NESTED WORKFLOW FILES

if ( $file =~ /\.param$/ ) {

    my $parameter = Agua::CLI::Parameter->new(

        paramfile => $file

    );

    $parameter->getopts();

    $parameter->$mode();    

}

elsif ( $file =~ /\.app$/ ) {

    my $app = Agua::CLI::App->new(

        appfile => $file

    );

    $app->getopts();

    $app->$mode();    

}

elsif ( $file =~ /\.wk$/ )

{

    my $workflow = Agua::CLI::Workflow->new(

        wkfile => $file

    );

    $workflow->getopts();

    my $success = $workflow->$mode();

    print "flow.pl    mode '$mode' not recognised\n" and exit if $success != 1;

}

else

{

    print "flow.pl    file type '$file' not recognised (must be .wk, .app or .param)\n";

}



##### PRINT RUN TIME

#my $runtime = Timer::runtime( $time, time() );

#print "flow.pl    \n";

#print "flow.pl    Run time: $runtime\n";

#print "flow.pl    Date: ";

#print Timer::datetime(), "\n";

#print "flow.pl    Command: \n";

#print "flow.pl    $0 @arguments\n";

#print "flow.pl    \n";

#print "flow.pl    ****************************************\n\n\n";

#exit;





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







