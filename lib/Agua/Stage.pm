use MooseX::Declare;
our $VERSION = 0.1;

=head2

	PACKAGE		Stage
	
	PURPOSE:
	
		A Stage IS ONE STEP IN A WORKFLOW. IT HAS THE FOLLOWING
		
		CHARACTERISTICS:
		
		1. EACH Stage RUNS ITSELF AND LOGS ITS STATUS TO THE stage
		
			DATABASE TABLE.
		
		2. A Stage WILL RUN LOCALLY BY DEFAULT. IF THE submit VARIABLE IS NOT
		
			ZERO AND cluster VARIABLE IS NOT EMPTY, IT WILL RUN ON A
			
			CLUSTER.
	
		3. EACH Stage DYNAMICALLY SETS ITS STDOUT, STDERR, INPUT AND OUTPUT
		
			FILES.
		
=cut 

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";

class Agua::Stage with (Agua::Common::Base, Agua::Common::Logger, Agua::Common::Util, Agua::Common::Timer, Agua::Cluster::Jobs) {

#### INTERNAL MODULES

#### EXTERNAL MODULES
use IO::Pipe;
use Data::Dumper;
#use overload '==' => 'identical';
#use overload 'eq' => 'equal';

use FindBin qw($Bin);

# Booleans
has 'log'			=>  ( isa => 'Int', is => 'rw', default => 0 );  
has 'printlog'			=>  ( isa => 'Int', is => 'rw', default => 0 );

# Ints
has 'workflowpid'	=>	( isa => 'Int|Undef', is => 'rw' );
has 'stagepid'		=>	( isa => 'Int|Undef', is => 'rw' );
has 'stagejobid'	=>	( isa => 'Int|Undef', is => 'rw' );
has 'number'		=>  ( isa => 'Str', is => 'rw');
has 'workflownumber'=>  ( isa => 'Str', is => 'rw');
has 'start'     	=>  ( isa => 'Int', is => 'rw' );
has 'submit'     	=>  ( isa => 'Int|Undef', is => 'rw' );
has 'slots'     	=>  ( isa => 'Int|Undef', is => 'rw' );
has 'maxjobs'     	=>  ( isa => 'Int|Undef', is => 'rw' );

# Strings
has 'username'  	=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'project'   	=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'name'   		=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'queue'			=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'outputdir'		=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'scriptfile'	=>  ( isa => 'Str', is => 'rw', required => 1 );
has 'installdir'   	=>  ( isa => 'Str', is => 'rw', required => 1  );
has 'version'   	=>  ( isa => 'Str', is => 'rw', required => 1  );

has 'clustertype'	=>  ( isa => 'Str|Undef', is => 'rw', default => "SGE" );
has 'fileroot'		=> 	( isa => 'Str|Undef', is => 'rw', default => '' );
has 'executor'		=> 	( isa => 'Str|Undef', is => 'rw', default => undef );
has 'envarfile'		=> 	( isa => 'Str|Undef', is => 'rw', default => undef );
has 'location'		=> 	( isa => 'Str|Undef', is => 'rw', default => '' );

has 'setuid'		=>  ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue_options'	=>  ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'requestor'		=> 	( isa => 'Str', is => 'rw', required	=>	0	);
has 'stdoutfile'	=>  ( isa => 'Str', is => 'rw' );
has 'stderrfile'	=>  ( isa => 'Str', is => 'rw' );
has 'cluster'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'qsub'			=>  ( isa => 'Str', is => 'rw' );
has 'qstat'			=>  ( isa => 'Str', is => 'rw' );
has 'resultfile'	=>  ( isa => 'Str', is => 'ro', default => sub { "/tmp/result-$$" });
has 'queued'		=>  ( isa => 'Str', is => 'rw' );
has 'started'		=>  ( isa => 'Str', is => 'rw' );
has 'completed'		=>  ( isa => 'Str', is => 'rw' );

# OBJECTS
has 'envars'		=> ( isa => 'HashRef', is => 'rw', required => 1 );
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', required => 1 );

has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'monitor'		=> 	( isa => 'Maybe', is => 'rw', required => 0 );
has 'stageparameters'=> ( isa => 'ArrayRef', is => 'rw', required => 1 );
has 'samplehash'   	=>  ( isa => 'HashRef|Undef', is => 'rw', required => 0  );

####////}

method BUILD ($args) {
	#$self->logDebug("$$ Stage::BUILD    args:");
	#$self->logDebug("$$ args", $args);
}

method run {
=head2

	SUBROUTINE		run
	
	PURPOSE

		1. RUN THE STAGE APPLICATION AND UPDATE STATUS TO 'running'
		
		2. UPDATE THE PROGRESS FIELD PERIODICALLY (CHECKPROGRESS OR DEFAULT = 10 SECS)

		3. UPDATE STATUS TO 'complete' WHEN EXECUTED APPLICATION HAS FINISHED RUNNING
		
=cut

	$self->logDebug("$$ Stage::run()");
	
	#### TO DO: START PROGRESS UPDATER

	#### EXECUTE APPLICATION
	my $exitcode;
	my $error;
	
	$self->logDebug("$$ self->cluster", $self->cluster())  if defined $self->cluster();
	
	my $submit = $self->submit();
	my $cluster = $self->cluster(); 
	$self->logDebug("$$ submit", $submit);
	$self->logDebug("$$ cluster", $cluster);

	#### SET STATUS TO running
	$self->setStatus('running');
 
	#### RUN ON CLUSTER
	if ( defined $cluster and $cluster and defined $submit and $submit ) {
		$self->logDebug("$$ Doing self->runOnCluster()");
		($exitcode, $error) = $self->runOnCluster();
		$self->logDebug("$$ self->runOnCluster() stage run exitcode", $exitcode);
	}
	#### RUN LOCALLY	
	else {
		$self->logDebug("$$ Doing self->runLocally()");
		($exitcode, $error) = $self->runLocally();
		$self->logDebug("$$ self->runLocally stage run exitcode (0 means OK)", $exitcode)  if defined $exitcode;
	}
	
	#### REGISTER PROCESS IDS SO WE CAN MONITOR THEIR PROGRESS
	$self->registerRunInfo();

	#### SET EMPTY IF UNDEFINED
	$error = "" if not defined $error;
	$exitcode = "" if not defined $exitcode;
	
	return ($exitcode, $error);
}

method runLocally {
#### EXECUTE THE APPLICATION LOCALLY
	$self->logDebug("$$ Stage::runLocally()");
    my $stageparameters =	$self->stageparameters();
	$self->logError("stageparemeters not defined") and exit if not defined $stageparameters;
	
	#### GET FILE ROOT
	my $username = $self->username();
	my $fileroot = $self->fileroot();
	$self->logDebug("$$ fileroot", $fileroot);

	#### CONVERT ARGUMENTS INTO AN ARRAY IF ITS A NON-EMPTY STRING
	my $arguments = $self->setArguments($stageparameters);
	$self->logDebug("$$ arguments: @$arguments");

	#### ADD USAGE COMMAND
	my $usagefile	=	$self->stdoutfile();
	$usagefile		=~	s/stdout$/usage/;
	my $usage		=	qq{/usr/bin/time \\
-o $usagefile \\
-f "%Uuser %Ssystem %Eelapsed %PCPU (%Xtext+%Ddata %Mmax)k " \\
};

	#### SET LIBS
	#### ADD PERL5LIB FOR EXTERNAL SCRIPTS TO FIND Agua MODULES
	my $aguadir = $self->conf()->getKey("agua", 'INSTALLDIR');
	my $perl5lib = "$aguadir/lib";

	#### GET ENVARS
	my $envars 			= $self->getEnvars();
	my $exports 		= $envars->{tostring};
	$self->logDebug("$$ exports", $exports);
	my $libs			=	"export PERL5LIB=$perl5lib; $exports";
	my $envarfile		=	$self->envarfile();
	$self->logDebug("envarfile", $envarfile);
	if ( defined $envarfile and $envarfile ne "" ) {
		my $fileexports	=	$self->getFileExports($envarfile);
		$libs .= $fileexports if defined $fileexports;
	}
	
	#### SET EXECUTOR 
	my $executor = $self->executor();
	$self->logDebug("executor", $executor);
	
	#### PREFIX APPLICATION PATH WITH PACKAGE INSTALLATION DIRECTORY
	my $application = $self->installdir() . "/" . $self->location();	
	#$self->logDebug("$$ application", $application);
	
	#### SET SYSTEM CALL
	my @systemcall = ();
	push @systemcall, $libs;
	push @systemcall, $usage;
	push @systemcall, $executor if defined $executor and $executor ne "";
	push @systemcall, $application;
	push @systemcall, @$arguments;
	$self->logDebug("SYSTEMCALL", \@systemcall);
	
	#### REDIRECTION IS 1 IF SYSTEM CALL CONTAINS A ">"
	my $redirection	=	$self->containsRedirection(\@systemcall);
	
	#### SET STDOUT AND STDERR FILES
	my $stdoutfile = $self->stdoutfile();
	my $stderrfile = $self->stderrfile();
	push @systemcall, " \\\n1> $stdoutfile" if defined $stdoutfile and not $redirection;
	push @systemcall, " \\\n2> $stderrfile" if defined $stderrfile;
	$self->logDebug("$$ systemcall: @systemcall");

	#### CLEAN UP BEFOREHAND
	`rm $stdoutfile` if -f $stdoutfile;
	`rm $stderrfile` if -f $stderrfile;
	
    #### SET CHANGE DIR TO APPLICATION DIRECTORY, JUST IN CASE
    $self->logDebug("$$ application", $application);
    my ($changedir) = $application =~ /^(.+?)\/[^\/]+$/;
	$self->logDebug("$$ changedir", $changedir);
	
	#### NO BUFFERING
	$| = 1;

	#### COMMAND
	my $command = join " ", @systemcall;
	$self->logDebug("command", $command);

	#### CREATE stdout DIR
	$self->logDebug("stdoutfile", $stdoutfile);
	my ($outputdir, $label)	=	$stdoutfile	=~	/^(.+?)\/[^\/]+\/([^\/]+)\.stdout$/;
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("label", $label);

	my $scriptfile	=	"$outputdir/script/$label.sh";
	my $exitfile	=	"$outputdir/stdout/$label.exit";
	my $lockfile	=	"$outputdir/stdout/$label.lock";
	$self->logDebug("scriptfile", $scriptfile);
	$self->logDebug("exitfile", $exitfile);
	$self->logDebug("lockfile", $lockfile);

	$self->printScriptFile($scriptfile, $command, $exitfile, $lockfile);
	$self->logDebug("$$ BEFORE SUBMIT command");
	`$scriptfile`;
	$self->logDebug("$$ AFTER SUBMIT command");
	
	#### DISABLE STDOUT BUFFERING ON PARENT
	$| = 1;
	
	#### UPDATE STATUS TO 'running'
	my $now = $self->db()->now();
	$self->logDebug("now", $now);
	my $set = qq{
	status='running',
started=$now,
queued=$now,
completed=''};
	$self->setFields($set);

	#### WAIT FOR JOB TO FINISH
	$self->logDebug("$$ Doing wait for command to complete");
	#wait;

	#### PAUSE FOR RESULT FILE TO BE WRITTEN 
	sleep(3);
	$self->logDebug("$$ Finished wait for command to complete");
	open(RESULT, $exitfile);
	my $exitcode = <RESULT>;
	close(RESULT);
	$self->logDebug("$$ exitfile", $exitfile);
	$self->logDebug("$$ exitcode", $exitcode);
	
	#### SET STATUS TO 'error' IF exitcode IS NOT ZERO
	if ( defined $exitcode and $exitcode == 0 ) {
		$self->setStatus('completed') ;
	}
	else {
		$self->setStatus('error');
	}
	$exitcode	=~ 	s/\s+$// if defined $exitcode;
	
	return $exitcode;
}

method containsRedirection ($arguments) {
	return if not defined $arguments or not @$arguments;
	
	foreach my $argument ( @$arguments ) {
		return 1 if $argument eq ">";
	}
	
	return 0;
}

method getFileExports ($file) {
    open(FILE, $file) or die "Can't open file: $file: $!";

	my $exports	=	"";
    while ( <FILE> ) {
		next if $_	=~ /^#/ or $_ =~ /^\s*$/;
		chomp;
		$exports .= "$_; ";
    }

	return $exports;
}

method setStageJob {

=head2

	SUBROUTINE		setStageJob
	
	PURPOSE
	
		RETURN THE JOB HASH FOR THIS STAGE:
		
			command		:	Command line system call,
			label		:	Unique name for job (e.g., to be used by SGE)
			outputfile	:	Location of outputfile

=cut

	#$self->logCaller("");

	#### CLUSTER MONITOR
	my $monitor		=	$self->monitor();	
	#### GET MAIN PARAMS
	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflownumber 	= $self->workflownumber();
	my $workflow 	= $self->workflow();
	my $number 		= $self->number();
	my $queue 		= $self->queue();
	my $cluster		= $self->cluster();
	my $qstat		= $self->qstat();
	my $qsub		= $self->qsub();
	my $workflowpid = $self->workflowpid();
    #$self->logDebug("$$ cluster", $cluster);

	#### SET DEFAULTS
	$queue = '' if not defined $queue;

	#### GET AGUA DIRECTORY FOR CREATING STDOUTFILE LATER
	my $aguadir 	= $self->conf()->getKey("agua", 'AGUADIR');

	#### GET FILE ROOT
	my $fileroot = $self->getFileroot($username);

	#### GET ARGUMENTS ARRAY
    my $stageparameters =	$self->stageparameters();
    #$self->logDebug("$$ Arguments", $stageparameters);
    $stageparameters =~ s/\'/"/g;
	my $arguments = $self->setArguments($stageparameters);    

	#### GET PERL5LIB FOR EXTERNAL SCRIPTS TO FIND Agua MODULES
	my $installdir = $self->conf()->getKey("agua", 'INSTALLDIR');
	my $perl5lib = "$installdir/lib";
	
	#### SET EXECUTOR
	my $executor	.=	"export PERL5LIB=$perl5lib; ";
	$executor 		.= 	$self->executor() if defined $self->executor();
	#$self->logDebug("$$ self->executor(): " . $self->executor());

	#### SET APPLICATION
	my $application = $self->installdir() . "/" . $self->location();	
	#$self->logDebug("$$ application", $application);

	#### ADD THE INSTALLDIR IF THE LOCATION IS NOT AN ABSOLUTE PATH
	#$self->logDebug("$$ installdir", $installdir);
	if ( $application !~ /^\// and $application !~ /^[A-Z]:/i ) {
		$application = "$installdir/bin/$application";
		#$self->logDebug("$$ Added installdir to stage_arguments->{location}: " . $application);
	}

	#### SET SYSTEM CALL
	my @systemcall = ($application, @$arguments);
	my $command = "$executor @systemcall";
	
    #### GET OUTPUT DIR
    my $outputdir = $self->outputdir();
    #$self->logDebug("$$ outputdir", $outputdir);

	#### SET JOB NAME AS project-workflow-number
	my $label =	$project;
	$label .= "-" . $workflownumber;
	$label .= "-" . $workflow;
	$label .= "-" . $number;
    #$self->logDebug("$$ label", $label);
	
	my $samplehash	=	$self->samplehash();
	$self->logNote("samplehash", $samplehash);
	if ( defined $samplehash ) {
		my $id		=	$samplehash->{sample};
		$label		=	"$id.$label";
	}

	#### SET JOB 
	return $self->setJob([$command], $label, $outputdir);
}

method runOnCluster {
=head2

	SUBROUTINE		runOnCluster
	
	PURPOSE
	
		SUBMIT THE SHELLSCRIPT FOR EXECUTION ON A CLUSTER

=cut
	$self->logDebug("$$ Stage::runOnCluster()");	;

	#### CLUSTER MONITOR
	my $monitor		=	$self->monitor();	
	#### GET MAIN PARAMS
	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflownumber 	= $self->workflownumber();
	my $workflow 	= $self->workflow();
	my $number 		= $self->number();
	my $queue 		= $self->queue();
	my $cluster		= $self->cluster();
	my $qstat		= $self->qstat();
	my $qsub		= $self->qsub();
	my $workflowpid = $self->workflowpid();
    $self->logDebug("$$ cluster", $cluster);

	#### SET DEFAULTS
	$queue = '' if not defined $queue;

	#### GET AGUA DIRECTORY FOR CREATING STDOUTFILE LATER
	my $aguadir 	= $self->conf()->getKey("agua", 'AGUADIR');

	#### GET FILE ROOT
	my $fileroot = $self->getFileroot($username);

	#### GET ARGUMENTS ARRAY
    my $stageparameters =	$self->stageparameters();
    #$self->logDebug("$$ Arguments", $stageparameters);
    $stageparameters =~ s/\'/"/g;
	my $arguments = $self->setArguments($stageparameters);    

	#### GET PERL5LIB FOR EXTERNAL SCRIPTS TO FIND Agua MODULES
	my $installdir = $self->conf()->getKey("agua", 'INSTALLDIR');
	my $perl5lib = "$installdir/lib";
	
	#### SET EXECUTOR
	my $executor	.=	"export PERL5LIB=$perl5lib; ";
	$executor 		.= 	$self->executor() if $self->executor();
	$self->logDebug("$$ self->executor(): " . $self->executor());

	#### SET APPLICATION
	my $application = $self->installdir() . "/" . $self->location();	
	$self->logDebug("$$ application", $application);

	#### ADD THE INSTALLDIR IF THE LOCATION IS NOT AN ABSOLUTE PATH
	$self->logDebug("$$ installdir", $installdir);
	if ( $application !~ /^\// and $application !~ /^[A-Z]:/i ) {
		$application = "$installdir/bin/$application";
		$self->logDebug("$$ Added installdir to stage_arguments->{location}: " . $application);
	}

	#### SET SYSTEM CALL
	my @systemcall = ($application, @$arguments);
	my $command = "$executor @systemcall";
	
    #### GET OUTPUT DIR
    my $outputdir = $self->outputdir();
    $self->logDebug("$$ outputdir", $outputdir);

	#### SET JOB NAME AS project-workflow-number
	my $label =	$project;
	$label .= "-" . $workflownumber;
	$label .= "-" . $workflow;
	$label .= "-" . $number;
    $self->logDebug("$$ label", $label);

	#### SET *** BATCH *** JOB 
	my $job = $self->setJob([$command], $label, $outputdir);
	
	#### GET FILES
	my $commands = $job->{commands};
	my $scriptfile = $job->{scriptfile};
	my $stdoutfile = $job->{stdoutfile};
	my $stderrfile = $job->{stderrfile};
	my $lockfile = $job->{lockfile};
	
	#### PRINT SHELL SCRIPT	
	$self->printSgeScriptfile($scriptfile, $commands, $label, $stdoutfile, $stderrfile, $lockfile);
	$self->logDebug("$$ scriptfile", $scriptfile);

	#### SET QUEUE
	$self->logDebug("$$ queue", $queue);
	$job->{queue} = $self->queue();
	
	#### SET QSUB
	$self->logDebug("$$ qsub", $qsub);
	$job->{qsub} = $self->qsub();

	#### SET SGE ENVIRONMENT VARIABLES
	$job->{envars} = $self->envars() if $self->envars();

	#### SUBMIT TO CLUSTER AND GET THE JOB ID 
	my ($jobid, $error)  = $monitor->submitJob($job);
	$self->logDebug("$$ jobid", $jobid);
	$self->logDebug("$$ error", $error);

	return (undef, $error) if not defined $jobid or $jobid =~ /^\s*$/;

	#### SET STAGE PID
	$self->setStagePid($jobid);
	
	#### SET QUEUED
	$self->setQueued();

	#### GET JOB STATUS
	$self->logDebug("$$ Monitoring job...");
	my $jobstatus = $monitor->jobStatus($jobid);
	$self->logDebug("$$ jobstatus", $jobstatus);

	#### SET SLEEP
	my $sleep = $self->conf()->getKey("cluster", 'SLEEP');
	$sleep = 5 if not defined $sleep;
	$self->logDebug("$$ sleep", $sleep);
	
	my $set_running = 0;
	while ( $jobstatus ne "completed" and $jobstatus ne "error" ) {
		sleep($sleep);
		$jobstatus = $monitor->jobStatus($jobid);
		$self->setRunning() if $jobstatus eq "running" and not $set_running;
		$set_running = 1 if $jobstatus eq "running";

		$self->setStatus('completed') if $jobstatus eq "completed";
		$self->setStatus('error') if $jobstatus eq "error";
	}
	$self->logDebug("$$ jobstatus", $jobstatus);

	#### 20 SECONDS SEEMS LONG ENOUGH FOR qacct INFO TO BE READY
	my $PAUSE = 2;
	$self->logDebug("$$ Sleeping $PAUSE before self->setRunTimes(jobid)");
	sleep($PAUSE);
	$self->setRunTimes($jobid);


	$self->logDebug("$$ Completed");

	return 0;
}	#	runOnCluster

method updateStatus ($set, $username, $project, $workflow) {
	
	my $query = qq{UPDATE stage
SET $set
WHERE username = '$username'
AND project = '$project'
AND workflow = '$workflow'
};
	$self->logDebug("$$ $query");
	my $success = $self->db()->do($query);
	if ( not $success )
	{
		$self->logError("Can't update stage table for username $username, project $project, workflow $workflow with set clause: $set");
		exit;
	}
}

method printScriptFile ($scriptfile, $command, $exitfile, $lockfile) {
	$self->logNote("scriptfile", $scriptfile);

	#### CREATE DIR COMMANDS
	$self->mkdirCommand($scriptfile);
	$self->mkdirCommand($exitfile);
	$self->mkdirCommand($lockfile);

	my $contents	=	qq{#!/bin/bash

echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
echo USERNAME: 	     	\$USERNAME
echo PROJECT:  	       	\$PROJECT
echo WORKFLOW: 	       	\$WORKFLOW
echo QUEUE:    	       	\$QUEUE
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"

hostname -f
date

# OPEN LOCKFILE
date > $lockfile

$command

#### REMOVE LOCKFILE
echo \$? > $exitfile

# REMOVE LOCKFILE
unlink $lockfile;

exit 0;

};
	$self->logDebug("contents", $contents);

	open(OUT, ">$scriptfile") or die "Can't open script file: $scriptfile\n";
	print OUT $contents;
	close(OUT);
	chmod(0777, $scriptfile);
	$self->logNote("scriptfile printed", $scriptfile);
}

method mkdirCommand ($file) {
	my ($dir)	=	$file	=~	/^(.+?)\/[^\/]+$/;
	my $command	=	"mkdir -p $dir";
	$self->logDebug("command", $command);
	
	`$command`;
}

method setArguments ($stageparameters) {
#### SET ARGUMENTS AND GET VALUES FOR ALL PARAMETERS
	$self->logNote("stageparameters", $stageparameters);
	$self->logNote("no. stageparameters: " . scalar(@$stageparameters));

	#### SANITY CHECK
	return if not defined $stageparameters;
	return if ref($stageparameters) eq '';

	#### GET FILEROOT
	my $username 	= $self->username();
	my $cluster 	= $self->cluster();
	my $version 	= $self->version();
	my $fileroot 	= $self->getFileroot($username);
	$self->logNote("username", $username);
	$self->logNote("cluster", $cluster);
	$self->logNote("fileroot", $fileroot);
	$self->logNote("version", $version);
	
	#### SORT BY ORDINALS
	@$stageparameters = sort { $a->{ordinal} <=> $b->{ordinal} } @$stageparameters;
	#$self->logNote("SORTED stageparameters", $stageparameters);
	
	#### GENERATE ARGUMENTS ARRAY
	#$self->logNote("Generating arguments array...");
	my $clustertype;
	my $arguments = [];
	foreach my $stageparameter (@$stageparameters)
	{
		my $name	 	=	$stageparameter->{name};
		my $argument 	=	$stageparameter->{argument};
		my $value 		=	$stageparameter->{value};
		my $valuetype 	=	$stageparameter->{valuetype};
		my $discretion 	=	$stageparameter->{discretion};

		my $samplehash	=	$self->samplehash();
		#$self->logNote("samplehash", $samplehash);

		$value	=~	s/<VERSION>/$version/g if defined $version;

		if ( defined $samplehash ) {
			foreach my $key ( keys %$samplehash ) {
				my $match	=	uc($key);
				my $mate	=	$samplehash->{$key};
				#$self->logNote("key", $key);
				#$self->logNote("match", $match);
				#$self->logNote("mate", $mate);
				#$self->logNote("DOING MATCH $match / $mate");
				$value	=~	s/<$match>/$mate/g;
				#$self->logNote("AFTER MATCH value: $value");
			}
		}
	
		$clustertype = 1 if $name eq "clustertype";

		$self->logNote("name", $name);
		$self->logNote("argument", $argument);
		$self->logNote("value", $value);
		$self->logNote("valuetype", $valuetype);
		$self->logNote("discretion", $discretion);

		#### SKIP EMPTY FLAG OR ADD 'checked' FLAG
		if ( $valuetype eq "flag" )
		{
			if (not defined $value or not $value)
			{
				$self->logNote("Skipping empty flag", $argument);
				next;
			}

			push @$arguments, $argument;
			next;
		}
		
		if ( $value =~ /^\s*$/ and $discretion ne "required" )
		{
			$self->logNote("Skipping empty argument", $argument);
			next;
		}
		
		if ( defined $value )
		{
			$self->logNote("BEFORE value", $value);

			#### ADD THE FILE ROOT FOR THIS USER TO FILE/DIRECTORY PATHS
			#### IF IT DOES NOT BEGIN WITH A '/', I.E., AN ABSOLUTE PATH
			if ( $valuetype =~ /^(file|directory)$/ and $value =~ /^[^\/]/ )
			{	
				$self->logNote("Adding fileroot to $valuetype", $value);
				$value =~ s/^\///;
				$value = "$fileroot/$value";
			}


			#### ADD THE FILE ROOT FOR THIS USER TO FILE/DIRECTORY PATHS
			#### IF IT DOES NOT BEGIN WITH A '/', I.E., AN ABSOLUTE PATH
			if ( $valuetype =~ /^(files|directories)$/ and $value =~ /^[^\/]/ )
			{	
				$self->logNote("Adding fileroot to $valuetype", $value);
				my @subvalues = split ",", $value;
				foreach my $subvalue ( @subvalues )
				{
					$subvalue =~ s/^\///;
					$subvalue = "$fileroot/$subvalue";
				}
				
				$value = join ",", @subvalues;
			}

			#### 'X=' OPTIONS
			if ( $argument =~ /=$/ ) {
				push @$arguments, qq{$argument$value};
			}

			#### '-' OPTIONS (E.G., -i)
			elsif ( $argument =~ /^\-[^\-]/ ) {
				push @$arguments, qq{$argument $value};
			}
			
			#### DOUBLE '-' OPTIONS (E.G., --inputfile)
			else
			{
				push @$arguments, $argument;
				push @$arguments, $value;
			}

			$self->logNote("AFTER value", $value);
		}
	}

	if ( defined $clustertype ){
		if ( defined $username and $username )
		{
			push @$arguments, "--username";
			push @$arguments, $username;
		}
	
		if ( defined $cluster and $cluster )
		{
			push @$arguments, "--cluster";
			push @$arguments, $cluster;
		}
	}

	$self->logNote("arguments", $arguments);

	return $arguments;
}

method registerRunInfo {
=head2

	SUBROUTINE		registerRunInfo
	
	PURPOSE
	
		SET THE PROCESS IDS FOR:
		
			- THE STAGE ITSELF
			
			- THE PARENT OF THE STAGE'S APPLICATION (SAME AS STAGE)
		
			- THE CHILD OF THE STAGE'S APPLICATION
		
=cut
	$self->logDebug("$$ Agua::Stage::registerRunInfo()");

    	my $workflowpid = $self->workflowpid();
	my $stagepid 	= $self->stagepid() || '';
	my $stagejobid = $self->stagejobid() || '';
	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflow 	= $self->workflow();
	my $workflownumber = $self->workflownumber();
	my $number		 = $self->number();
	my $stdoutfile		 = $self->stdoutfile();
	my $stderrfile		 = $self->stderrfile();
	#### UPDATE status TO waiting IN TABLE stage
    my $query = qq{UPDATE stage
    SET
	stdoutfile='$stdoutfile',
	stderrfile='$stderrfile'
	WHERE username = '$username'
    AND project = '$project'
    AND workflow = '$workflow'
    AND workflownumber = '$workflownumber'
    AND number = '$number'};
    my $success = $self->db()->do($query);
	if ( not $success )
	{
		$self->logDebug("$$ Could not insert entry for stage $self->stagenumber() into 'stage' table");
        return 0;
    }

	return 1;
}


method register {
#### SET STATUS TO waiting FOR A STAGE IN THE stage TABLE
	my $status	=	shift;

	$self->logDebug("$$ Stage::register()");

    
	#### SET SELF _status TO waiting
	$self->status('waiting');

	my $username = $self->username();
	my $project = $self->project();
	my $workflow = $self->workflow();
	my $workflownumber = $self->workflownumber();
	my $number = $self->number();

	#### UPDATE status TO waiting IN TABLE stage
    my $query = qq{UPDATE stage
    SET status='waiting'
	WHERE username = '$username'
    AND project = '$project'
    AND workflow = '$workflow'
    AND workflownumber = '$workflownumber'
    AND number = '$number'};
    $self->logDebug("$$ $query");
    my $success = $self->db()->do($query);
	$self->logDebug("$$ insert success", $success);
	if ( not $success )
	{
		warn "Stage::register    Could not insert entry for stage $self->stagenumber() into 'stage' table\n";
        return 0;
    }

	$self->logDebug("$$ Successful insert!");
	return 1;
}

method isComplete {
=head2

	SUBROUTINE		isComplete
	
	PURPOSE

		CHECK IF THIS STAGE HAS STATUS 'complete' IN THE stage
		
	INPUT
	
		WORKFLOW NAME (workflow) AND STAGE NAME (name)
	
	OUTPUT
	
		RETURNS 1 IF COMPLETE, 0 IF NOT COMPLETE
	
=cut

    
	my $project = $self->project();
	my $workflow = $self->workflow();
	my $number = $self->number();

	my $query = qq{SELECT status
	FROM stage
	WHERE project='$project'
	AND workflow = '$workflow'
	AND number = '$number'
	AND status='completed'};
	$self->logDebug("$$ $query");
	my $complete = $self->db()->query($query);
	$self->logDebug("$$ complete", $complete);
	
	return 0 if not defined $complete or not $complete;
	return 1;
}

method setRunTimes ($jobid) {
	$self->logDebug("$$ Stage::setRunTimes(jobid)");
	$self->logDebug("$$ jobid", $jobid);
	my $username = $self->username();
	my $cluster = $self->cluster();
	my $qacct = $self->monitor()->qacct($username, $cluster, $jobid);
	$self->logDebug("$$ qacct", $qacct);

	return if not defined $qacct or not $qacct;
	return if $qacct =~ /^error: job id \d+ not found/;

	#### QACCT OUTPUT FORMAT:
	#	qsub_time    Sat Sep 24 01:05:17 2011
	#	start_time   Sat Sep 24 01:05:24 2011
	#	end_time     Sat Sep 24 01:05:24 2011

	my ($queued) = $qacct =~ /qsub_time\s+([^\n]+)/ms;
	my ($started) = $qacct =~ /start_time\s+([^\n]+)/ms;
	my ($completed) = $qacct =~ /end_time\s+([^\n]+)/ms;
	$queued = $self->datetimeToMysql($queued);
	$started = $self->datetimeToMysql($started);
	$completed = $self->datetimeToMysql($completed);
	
	my $set = qq{
queued = '$queued',
started = '$started',
completed = '$completed'};
	$self->logDebug("$$ set", $set);

	$self->setFields($set);
}
method setStatus ($status) {	
#### SET THE status FIELD IN THE stage TABLE FOR THIS STAGE
    $self->logDebug("$$ status", $status);

	#### GET TABLE KEYS
	my $username = $self->username();
	my $project = $self->project();
	my $workflow = $self->workflow();
	my $number = $self->number();

	my $query = qq{UPDATE stage
SET
status = '$status',
completed = NOW()
WHERE username = '$username'
AND project = '$project'
AND workflow = '$workflow'
AND number = '$number'};
	$self->logNote("$query");
	my $success = $self->db()->do($query);
	if ( not $success )
	{
		$self->logError("Can't update stage (project: $project, workflow: $workflow, number: $number) with status: $status");
		exit;
	}
}


method setQueued {
	$self->logDebug("$$ Stage::setQueued(set)");
	my $now = $self->db()->now();
	my $set = qq{
status		=	'queued',
started 	= 	'',
queued 		= 	$now,
completed 	= 	''};
	$self->setFields($set);
}

method setRunning {
	$self->logDebug("$$ Stage::setRunning(set)");
	my $now = $self->db()->now();
	my $set = qq{
status		=	'running',
started 	= 	$now,
completed 	= 	''};
	$self->setFields($set);
}

method setFields ($set) {
    #$self->logDebug("set", $set);

	#### GET TABLE KEYS
	my $username 	= 	$self->username();
	my $project 	= 	$self->project();
	my $workflow 	= 	$self->workflow();
	my $number 		= 	$self->number();
	my $now 		= 	$self->db()->now();

	my $query = qq{UPDATE stage
SET $set
WHERE username = '$username'
AND project = '$project'
AND workflow = '$workflow'
AND number = '$number'};	
	#$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logError("Could not set fields for stage (project: $project, workflow: $workflow, number: $number) set : '$set'") and exit if not $success;
}

method setStagePid ($stagepid) {
	$self->logDebug("stagepid", $stagepid);
	
	#### GET TABLE KEYS
	my $username 	= $self->username();
	my $project 	= $self->project();
	my $workflow 	= $self->workflow();
	my $number 		= $self->number();
	my $now 		= $self->db()->now();
	my $query = qq{UPDATE stage
SET
stagepid = '$stagepid'
WHERE username = '$username'
AND project = '$project'
AND workflow = '$workflow'
AND number = '$number'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logDebug("success", $success);
	$self->logError("Could not update stage table with stagepid: $stagepid") and exit if not $success;
}





method toString () {
	print $self->_toString();
}

method _toString () {
	my @keys = qw[ username project workflownumber workflow name number start executor location fileroot queue queue_options outputdir scriptfile stdoutfile stderrfile workflowpid stagepid stagejobid submit setuid installdir cluster qsub qstat resultfile];
	my $string = '';
	foreach my $key ( @keys )
	{
		my $filler = " " x (20 - length($key));
		$string .= "$key$filler:\t";
		$string .= $self->$key() || '';
		$string .= "\n";
	}
	$string .= "\n\n";
}


} #### Agua::Stage

