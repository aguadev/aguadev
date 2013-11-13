package Agua::Cluster::Jobs;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Cluster::Jobs
	
	PURPOSE
	
		RUN, MONITOR AND AUDIT CLUSTER JOBS
			
=cut

# INTS
has 'submit'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'starttime' => ( isa => 'Int|Undef', is => 'rw', default => sub { time() });
# STRINGS
#has 'clustertype'=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'queue'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'walltime'	=> ( isa => 'Str|Undef', is => 'rw', default => 24 );
has 'cpus'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qstat'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'qsub'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'maxjobs'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'sleep'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cleanup'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'dot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'verbose'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
# 	OBJECTS
has 'batchstats'=> ( isa => 'ArrayRef|Undef', is => 'rw', default => sub { [] });
has 'command'	=> ( isa => 'ArrayRef|Undef', is => 'rw' );
has 'conf'		=> ( isa => 'Conf::Agua|Undef', is => 'rw' );
has 'monitor'	=> 	( isa => 'Maybe|Undef', is => 'rw', required => 0 );

use strict;
use warnings;
use Carp;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;

sub getIndex {
=head2

	SUBROUTINE		getIndex
	
	PURPOSE
	
		RETURN THE PSEUDO-ENVIRONMENT VARIABLE USED BY THE CLUSTER
		
		TO REPRESENT THE ARRAY JOB ID

=cut

	my $self		=	shift;

	return '\$TASKNUM';

#	my $cluster = $self->cluster();	
#	return '\$LSB_JOBINDEX' if $cluster eq "LSF";
#	return '\$PBS_TASKNUM' if $cluster eq "PBS";
#    return '\$SGE_TASK_ID' if $cluster eq "SGE";
#	return;
}

sub moveToDir {
=head2

	SUBROUTINE		moveToDir
	
	PURPOSE
	
		1. MOVE THE CONTENTS OF A DIRECTORY TO ANOTHER DIRECTORY
		
		2. RUN ON THE MASTER NODE IF 'cluster' NOT SPECIFIED
			
			(E.G., BECAUSE TARGET DIRECTORY IS INVISIBLE TO
			
			CLUSTER EXECUTION HOSTS)
			
	INPUTS
	
		1. SOURCE DIRECTORY (MUST EXIST AND CANNOT BE A FILE)
		
		2. TARGET DIRECTORY (WILL BE CREATED IF DOES NOT EXIST)
		
		3. LABEL (IF SPECIFIED, JOB WILL BE SUBMITTED TO QUEUE)
		
	OUTPUTS
	
		1. ALL FILES IN SOURCE DIRECTORY WILL BE MOVED TO A
		
			NEWLY-CREATED TARGET DIRECTORY
			
=cut

	my $self		=	shift;
	my $sourcedir	=	shift;
	my $targetdir	=	shift;
	my $label		=	shift;
	$self->logDebug("Agua::Cluster::Jobs::moveToDir(sourcedir, targetdir, usage)");
	$self->logDebug("sourcedir", $sourcedir);

	$self->logDebug("targetdir", $targetdir);
	$self->logDebug("label", $label)  if defined $label;

	#### CHECK FOR SOURCE DIR
	$self->logDebug("sourcedir is a file", $sourcedir) and return if -f $sourcedir;
	$self->logDebug("targetdir is a file", $targetdir) and return if -f $targetdir;
	$self->logDebug("Can't find sourcedir", $sourcedir) and return if not -d $sourcedir;

	#### CREATE TARGET DIR IF NOT EXISTS
	File::Path::mkpath($targetdir) if not -d $targetdir;
	$self->logDebug("Skipping move because can't create targetdir", $targetdir) if not -d $targetdir;

	my $command = "mv $sourcedir/* $targetdir";
	
	if ( not defined $label )
	{
		$self->logDebug("command", $command);
		print `$command`;
	}
	else
	{
		#### SET JOB
		my $job = $self->setJob( [$command], $label, $targetdir);
		$self->runJobs( [$job], $label);
	}
}



sub setMonitor {
	my $self		=	shift;
	$self->logDebug("Agua::Cluster::Jobs::setMonitor()");
	
	return $self->monitor() if $self->monitor();

	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	my $classfile = "Agua/Monitor/" . uc($clustertype) . ".pm";
	my $module = "Agua::Monitor::$clustertype";
	$self->logDebug("clustertype", $clustertype);
	$self->logDebug("classfile", $classfile);
	$self->logDebug("module", $module);

	$self->logDebug("Doing require $classfile");
	require $classfile;

	$self->logDebug("username: " . $self->username());
	$self->logDebug("cluster: " . $self->cluster());
	my $monitor = $module->new(
		{
			'pid'		=>	$$,
			'conf' 		=>	$self->conf(),
			username	=>	$self->username(),
			cluster		=>	$self->cluster()
			#,
			#'db'		=>	$self->db()
		}
	);
	$self->monitor($monitor);

	return $monitor;
}




sub runJobs {
=head2

	SUBROUTINE		runJobs
	
	PURPOSE
	
		RUN A LIST OF JOBS CONCURRENTLY UP TO A MAX NUMBER
		
		OF CONCURRENT JOBS

=cut

	my $self		=	shift;
	my $jobs		=	shift;
	my $label 		=	shift;

	#### SET SLEEP
	my $sleep	= $self->sleep();
	$sleep = 5 if not defined $sleep;

	#### GET OUTPUTDIR
	my $outputdir = $self->outputdir();
	$self->logDebug("Agua::Cluster::Jobs::runJobs(jobs, label)");
	$self->logCritical("jobs not defined") and exit if not defined $jobs;
	$self->logCritical("label not defined") and exit if not defined $label;
	$self->logDebug("XXXXX no. jobs: " . scalar(@$jobs));
	my $jobids = [];
	my $scriptfiles = [];

	#### SET CURRENT TIME (START TIMER)
	my $current_time =  time();

	### EXECUTE JOBS	
	$self->execute($jobs, $label);
	
	#### CHECK JOBS HAVE COMPLETED
	my $status = "completed";
	my $sublabels 	= '';
	#my $maxchecks = maxchecks();
	#$maxchecks = 3 if not defined $maxchecks;
	my $counter = 0;
	#while ( not $status and $counter < $maxchecks )
	#{
		$self->logDebug("doing check $counter with checkStatus(jobs, label)");
		$counter++;
		($status, $sublabels) = $self->checkStatus($jobs, $label);
		$self->logDebug("status", $status);
		$self->logDebug("Sleeping for 10 seconds") if not $status;
	#	sleep(10) if not $status;
	#}
	$self->logDebug("Final value of status", $status);

	#### SEND JOB COMPLETION SIGNAL
	$self->logWarning("\n------------------------------------------------------------");
	$self->logWarning("---[status $label: $status $sublabels]---");
	$self->logWarning("\n------------------------------------------------------------");
	print "\n------------------------------------------------------------";
	print "---[status $label: $status $sublabels]---";
	print "\n------------------------------------------------------------";

	
	#### PRINT CHECKFILES
	my $checkfiles = $self->printCheckLog($jobs, $label, $outputdir);


	#### GET DURATION (STOP TIMER)
	my $duration = Timer::runtime( $current_time, time() );

	#### PRINT DURATION
	my $datetime = Timer::current_datetime();
	$self->logDebug("Completed ", $label);
	$self->logDebug("duration", $duration);


	#### SET USAGE STATS FOR SINGLE OR BATCH JOB
	if ( defined $self->cluster()
		and $self->cluster() eq "LSF" )
	{
		$self->usageStats($jobs, $label, $duration);
		
		#### PRINT USAGE STATS TO usagefile
		$self->logDebug("Doing printUsage       " . Timer::current_datetime());
		$self->printUsage($jobs, $label);
		$self->logDebug("After printUsage       " . Timer::current_datetime());
	}

	##### CLEAN UP CLUSTER STDOUT AND STDERR FILES
	my $cleanup = $self->cleanup();
	if ( defined $cleanup and $cleanup )
	{
		$self->logDebug("Cleaning up scriptfiles.");
		foreach my $scriptfile ( @$scriptfiles )
		{
			$self->logDebug("Removing scriptfile", $scriptfile);
			`rm -fr $scriptfile*`;
		}
	}
	else
	{
		$self->logDebug("cleanup not defined. Leaving scriptfiles.");
	}
	
	$self->logDebug("END OF Agua::Cluster::Jobs::runJobs");
	
	return ($status, $sublabels);
}

sub execute {
=head2

	SUBROUTINE		execute
	
	PURPOSE
	
		execute A LIST OF JOBS CONCURRENTLY UP TO A MAX NUMBER
		
		OF CONCURRENT JOBS

=cut

	my $self		=	shift;
	my $jobs		=	shift;
	my $label 		=	shift;

	$self->logDebug("execute(jobs, label)");

	my $username = $self->username();
	my $cluster = $self->cluster();
	my $submit = $self->submit();
	my $envars = $self->getEnvars($username, $cluster);

	#### execute COMMANDS IN SERIES LOCALLY IF cluster NOT DEFINED
	if ( not defined $envars or not $submit or not $cluster )
	{
		$self->logDebug("Doing executeLocal(jobs, label)");
		$self->executeLocal($jobs, $label);
	}
	else
	{
		$self->logDebug("Doing executeCluster(jobs, label)");
		$self->executeCluster($jobs, $label);
	}
}

sub executeLocal {
=head2

	SUBROUTINE		executeLocal
	
	PURPOSE
	
		EXECUTE A LIST OF JOBS LOCALLY IN SERIES OR IN PARALLEL 

=cut

	my $self		=	shift;
	my $jobs		=	shift;
	my $label 		=	shift;
	$self->logDebug("Agua::Cluster::Jobs::executeLocal(jobs, label)");
	$self->logCritical("jobs not defined") and exit if not defined $jobs;
	$self->logCritical("label not defined") and exit if not defined $label;
	$self->logDebug("XXXX no. jobs: " . scalar(@$jobs));

$self->logDebug("HERE");
	#### INPUTS
	my $monitor = $self->monitor() if defined $self->db();		#### ACCESSOR IS IMPLEMENTED
	my $cluster = $self->cluster();
	my $maxjobs = $self->maxjobs();
	my $qsub 	= $self->qsub();
	my $qstat 	= $self->qstat();
	my $sleep	= $self->sleep();
	my $queue 	= $self->queue();	
ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZzz
	#### SET DEFAULT SLEEP
	$sleep = 3 if not defined $sleep;
	
	#### QUIT IF maxjobs NOT DEFINED
	$self->logCritical("maxjobs not defined. Exiting") and exit if not defined $maxjobs;

	my $jobids = [];
	my $scriptfiles = [];

	my $counter = 0;
	$self->logDebug("executing " . scalar(@$jobs) . " jobs\n");
	foreach my $job ( @$jobs )
	{	
		$counter++;
		$self->logDebug("counter", $counter);
		#### CREATE OUTPUT DIRECTORY
		my $outputdir = $job->{outputdir};
		File::Path::mkpath($outputdir) if not -d $outputdir;
		$self->logDebug("Can't create outputdir", $outputdir) and die if not -d $outputdir;
	
		#### MOVE TO OUTPUT DIRECTORY
		$self->logDebug("Doing chdir($outputdir)");
		chdir($outputdir) or die "Can't move to output subdir: $outputdir/$counter\n";	
		
		my $commands = $job->{commands};

		#### REDIRECT STDOUT AND STDERR IF stdoutfile DEFINED
		my $stdoutfile = $job->{stdoutfile};
		my $stderrfile = $job->{stderrfile};
		my $lockfile = $job->{lockfile};
		my $oldout;
		my $olderr;

		#if ( defined $stdoutfile )
		#{
		#	$self->logDebug("diverting STDOUT to", $stdoutfile);
		#	open my $oldout, ">&STDOUT"  or die "Can't duplicate STDOUT: $!";
		#	open my $olderr, ">&STDERR"  or die "Can't duplicate STDERR: $!";
		#	#open OLDERR,     ">&", \*STDERR or die "Can't dup STDERR: $!";
		#	
		#	#### REMOVE OLD FILES
		#	`rm -fr $stdoutfile` if defined $stdoutfile;
		#	`rm -fr $stderrfile` if defined $stderrfile;
		#	
		#	#### REDIRECT OUTPUT/ERROR
		#	open(STDOUT, ">$stdoutfile") or die "Can't redirect STDOUT to file: $stdoutfile" if defined $stdoutfile;
		#	open(STDERR, ">$stderrfile") or die "Can't redirect STDOUT to file: $stderrfile" if defined $stderrfile;
		#	open(STDERR, ">$stdoutfile") or die "Can't redirect STDERR to file: $stdoutfile\n" if defined $stdoutfile and not defined $stderrfile;
		#	
		#	#### ALTERNATELY, DO THIS
		#	##push @system_call, "1> $stdoutfile" if defined $stdoutfile;
		#	##push @system_call, "2> $stderrfile" if defined $stderrfile;
		#	##push @system_call, "2> $stdoutfile" if not defined $stderrfile and defined $stdoutfile;
		#}

		#### execute COMMANDS
		print `date > $lockfile`;
		foreach my $command ( @$commands )
		{
			$self->logDebug("command", $command);
			print `$command`;
			$self->logDebug("Completed command");
		}
		print `unlink $lockfile`;
		
		my $whoami = `whoami`;
		$self->logDebug("whoami", $whoami);

		##### END REDIRECTION OF STDOUT AND STDERR
		#if ( defined $stdoutfile )
		#{
		#	open STDOUT, ">&", $oldout if defined $stdoutfile;
		#	open STDERR, ">&", $olderr if defined $stderrfile;
		#}
	}
	

	$self->logDebug("Completed");

	return $scriptfiles;
}

sub executeCluster {
=head2

	SUBROUTINE		executeCluster
	
	PURPOSE
	
		executeCluster A LIST OF JOBS CONCURRENTLY UP TO A MAX NUMBER
		
		OF CONCURRENT JOBS

=cut

	my $self		=	shift;
	my $jobs		=	shift;
	my $label 		=	shift;
	$self->logDebug("Agua::Cluster::Jobs::executeCluster(jobs, label)");
	$self->logCritical("jobs not defined") and exit if not defined $jobs;
	$self->logCritical("label not defined") and exit if not defined $label;
	$self->logDebug("no. jobs: " . scalar(@$jobs));

	#### INSTANTIATE CLUSTER JOB MONITOR
	my $monitor = $self->setMonitor();
	
	#### INPUTS
	my $cluster = $self->cluster();
	my $maxjobs = $self->maxjobs();
	my $qsub 	= $self->qsub();
	my $qstat 	= $self->qstat();
	my $sleep	= $self->sleep();
	my $queue 	= $self->queue();	

	#### SET DEFAULT SLEEP
	$sleep = 3 if not defined $sleep;
	
	#### QUIT IF maxjobs NOT DEFINED
	$self->logCritical("maxjobs not defined. Exiting") and exit if not defined $maxjobs;

	my $jobids = [];
	my $scriptfiles = [];

	#### DEBUG USAGE
	my $execute = 1;
	#$execute = 0;
	if ( $execute )
	{
		#### execute EVERY JOB
		my $counter = 0;
		$self->logDebug("executing " . scalar(@$jobs) . " jobs\n");
		foreach my $job ( @$jobs )
		{	
			$counter++;
			
			#### CREATE OUTPUT DIRECTORY
			my $outputdir = $job->{outputdir};
			File::Path::mkpath($outputdir) if not -d $outputdir;
			$self->logDebug("Can't create outputdir", $outputdir) and die if not -d $outputdir;
		
			#### MOVE TO OUTPUT DIRECTORY
			chdir($outputdir) or die "Can't move to output subdir: $outputdir/$counter\n";	
			
			##### execute COMMANDS IN SERIES LOCALLY IF cluster NOT DEFINED
			#if ( not defined $cluster )
			#{
			#	$self->logDebug("cluster not defined. executening commands locally");
			#	my $commands = $job->{commands};
			#
			#	#### REDIRECT STDOUT AND STDERR IF stdoutfile DEFINED
			#	my $stdoutfile = $job->{stdoutfile};
			#	my $stderrfile = $job->{stderrfile};
			#	my $lockfile = $job->{lockfile};
			#	my $oldout;
			#	my $olderr;
			#	if ( defined $stdoutfile )
			#	{
			#		$self->logDebug("diverting STDOUT to", $stdoutfile);
			#		open my $oldout, ">&STDOUT"  or die "Can't duplicate STDOUT: $!";
			#		open my $olderr, ">&STDERR"  or die "Can't duplicate STDERR: $!";
			#		#open OLDERR,     ">&", \*STDERR or die "Can't dup STDERR: $!";					
			#		open(STDOUT, ">$stdoutfile") or die "Can't redirect STDOUT to file: $stdoutfile" if defined $stdoutfile;
			#		open(STDERR, ">$stderrfile") or die "Can't redirect STDOUT to file: $stderrfile" if defined $stderrfile;
			#		open(STDERR, ">>$stdoutfile") or die "Can't redirect STDERR to file: $stdoutfile\n" if defined $stdoutfile and not defined $stderrfile;
			#		
			#		#### ALTERNATELY, DO THIS
			#		##push @system_call, "1> $stdoutfile" if defined $stdoutfile;
			#		##push @system_call, "2> $stderrfile" if defined $stderrfile;
			#		##push @system_call, "2> $stdoutfile" if not defined $stderrfile and defined $stdoutfile;
			#	}
			#
			#	#### execute COMMANDS
			#	print `date > $lockfile`;
			#	foreach my $command ( @$commands )
			#	{
			#		$self->logDebug("command", $command);
			#		print `$command`;
			#		$self->logDebug("Completed command");
			#	}
			#	print `unlink $lockfile`;
			#
			#	#### END REDIRECTION OF STDOUT AND STDERR
			#	if ( defined $stdoutfile )
			#	{
			#		open STDOUT, ">&", $oldout if defined $stdoutfile;
			#		open STDERR, ">&", $olderr if defined $stderrfile;
			#	}
			#}
			#
			##### IF cluster IS DEFINED, execute JOBS CONCURRENTLY ON CLUSTER
			#else
			#{
				#### GET FILES
				my $label = $job->{label};
				my $batch = $job->{batch};
				my $tasks = $job->{tasks};
				my $commands = $job->{commands};
				my $scriptfile = $job->{scriptfile};
				my $stdoutfile = $job->{stdoutfile};
				my $stderrfile = $job->{stderrfile};
				my $lockfile = $job->{lockfile};
				
				#### PRINT SHELL SCRIPT	
				$self->printScriptfile($scriptfile, $commands, $label, $stdoutfile, $stderrfile, $lockfile);
#				$self->logDebug("scriptfile", $scriptfile);
				
				#### SUBMIT AND GET THE JOB ID 
				$self->logDebug("Doing scriptfile", $scriptfile);
				$self->logDebug("Doing monitor->submitJob()");
				my $jobid = $monitor->submitJob(
					{
						scriptfile  => $scriptfile,
						queue       => $queue,
						qsub       	=> $qsub,
						qstat		=> $qstat,
						stdoutfile  => $stdoutfile,
						stderrfile  => $stderrfile,
						batch		=> $batch,
						tasks		=> $tasks
					}
				);
				$self->logCritical("jobid not defined. Exiting") and exit if not defined $jobid;
				$self->logDebug("jobid", $jobid);

				#### SAVE PID FOR CHECKING 
				push @$jobids, $jobid;
				$self->logDebug("Added jobid to list", $jobid );
				$self->logDebug("jobids ", scalar(@$jobids));
				$self->logDebug("maxjobs", $maxjobs);
			
				my $date = `date`;
				$date =~ s/\s+$//;
				$self->logDebug("date", $date);
				$self->logDebug("No. jobs: ", scalar(@$jobids));
				$self->logDebug("maxjobs", $maxjobs);
				
				#### CHECK TO MAKE SURE WE HAVEN'T REACHED
				#### THE LIMIT OF MAX CONCURRENT JOBS
				while ( scalar(@$jobids) >= $maxjobs )
				{
					$self->logDebug("Sleeping $sleep seconds...");
					sleep($sleep);
					
					
					$jobids = $monitor->remainingJobs($jobids);
				}
				
				#### CLEAN UP
				#`rm -fr $scriptfile`;
				push @$scriptfiles, $scriptfile;
			}	
		
		#}
		
		
		#### WAIT TIL ALL JOBS ARE FINISHED
		$self->logDebug("Waiting until the last jobs are finished (", scalar(@$jobids), " left)...");
		while ( defined $jobids and scalar(@$jobids) > 0 )
		{
			sleep($sleep);
			$jobids = $self->monitor()->remainingJobs($jobids);   
			$self->logDebug("", scalar(@$jobids), " jobs remaining: @$jobids");
		}
	}
	else
	{
		sleep(1);
	}
	$self->logDebug("Completed");

	return $scriptfiles;
}


sub setJob {
=head2

	SUBROUTINE		setJob
	
	PURPOSE
	
		GENERATE COMMANDS TO ALIGN SEQUENCES AGAINST REFERENCE
		
=cut
	my $self			=	shift;
	my $commands		=	shift;
	my $label			=	shift;
	my $outputdir		=	shift;
	my $scriptfile		=	shift;
	my $usagefile		=	shift;
	my $stdoutfile		=	shift;
	my $stderrfile		=	shift;
	my $lockfile		=	shift;
	$self->logDebug("outputdir", $outputdir);

	#### SET DIRS
	my $scriptdir = "$outputdir/scripts";
	my $stdoutdir = "$outputdir/stdout";
	my $lockdir = "$outputdir/lock";

	#### CREATE DIRS	
	File::Path::mkpath($scriptdir) if not -d $scriptdir;
	File::Path::mkpath($stdoutdir) if not -d $stdoutdir;
	File::Path::mkpath($lockdir) if not -d $lockdir;
	$self->logError("Cannot create directory scriptdir: $scriptdir") and exit if not -d $scriptdir;
	$self->logError("Cannot create directory stdoutdir: $stdoutdir") and exit if not -d $stdoutdir;
	$self->logError("Cannot create directory lockdir: $lockdir") and exit if not -d $lockdir;	

	#### SET FILES IF NOT DEFINED
	$scriptfile = "$scriptdir/$label.sh" if not defined $scriptfile;
	$stdoutfile = "$stdoutdir/$label.out" if not defined $stdoutfile;
	$stderrfile = "$stdoutdir/$label.err" if not defined $stderrfile;
	$lockfile = "$lockdir/$label.lock" if not defined $lockfile;

	$self->logDebug("Agua::Cluster::Jobs::setJob(commands, $label, $outputdir)");
	$self->logDebug("commands: @$commands");
	$self->logDebug("label", $label);
	$self->logDebug("outputdir", $outputdir);
	
	#### SANITY CHECK
	$self->logCritical("commands not defined") and exit if not defined $commands;
	$self->logCritical("label not defined") and exit if not defined $label;
	$self->logCritical("outputdir not defined") and exit if not defined $outputdir;

	#### SET JOB LABEL, COMMANDS, ETC.
	my $job;
	$job->{label} = $label;
	$job->{commands} = $commands;
	$job->{outputdir} = $outputdir;
	$job->{scriptfile} = $scriptfile;
	$job->{stdoutfile} = $stdoutfile;
	$job->{stderrfile} = $stderrfile;
	$job->{lockfile} = $lockfile;

	return $job;
}


sub setBatchJob {
=head2

	SUBROUTINE		setBatchJob
	
	PURPOSE
	
		GENERATE COMMANDS TO ALIGN SEQUENCES AGAINST REFERENCE
		
=cut

	
	my $self			=	shift;
	my $commands		=	shift;
	my $label			=	shift;
	my $outputdir		=	shift;
	my $number			=	shift;
$self->logDebug("Agua::Cluster::Jobs::setBatchJob(commands, label, outputdir, number)");

	$self->logCritical("commands not defined. Exiting...") and exit if not defined $commands;
	$self->logCritical("label not defined. Exiting...") and exit if not defined $label;
	$self->logCritical("outputdir not defined. Exiting...") and exit if not defined $outputdir;
	$self->logCritical("number not defined. Exiting...") and exit if not defined $number;
	
	#### GET CLUSTER
	my $clustertype = $self->clustertype();
	$self->logDebug("outputdir", $outputdir);

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index = $self->getIndex();
	$index =~ s/^\\//;

	#### CREATE TASK-RELATED DIRS
	my $scriptdir = "$outputdir/scripts";
	my $stdoutdir = "$outputdir/stdout/$index";
	my $lockdir = "$outputdir/lock/$index";
	my $taskdir = "$outputdir/$index";

	$self->createTaskDirs($taskdir, $number);
	$self->createTaskDirs($scriptdir, $number);
	$self->createTaskDirs($stdoutdir, $number);
	$self->createTaskDirs($lockdir, $number);	
	
	#### SET FILES IF NOT DEFINED
	my $scriptfile = "$scriptdir/$label.sh";
	my $stdoutfile = "$stdoutdir/$label-stdout.txt";
	my $stderrfile = "$stdoutdir/$label-stderr.txt";
	my $lockfile = "$lockdir/$label-lock.txt";

	#### SET FILE TO BE CHECKED TO FLAG COMPLETION
	#### NB: batchCheckfile CAN BE OVERRIDDEN BY THE INHERITING
	#### CLASS (E.G., Bowtie.pm) FOR NON-'out.sam' FILES
	my $checkfile = $self->batchCheckfile($label, $outputdir);

	#### SET JOB LABEL, COMMANDS, ETC.
	#### NB: FOR POSSIBLE FUTURE USE - ADD JOB ID TO FILENAME
	#$job->{usagefile} = "$outputdir/%I/$label-usage.%J.txt";
	#$job->{usagefile} = "$outputdir/\$PBS_TASKNUM/$label-usage.\$PBS_JOBID.txt";
	my $job;
	$job->{label} = $label;
	$job->{commands} = $commands;
	$job->{outputdir} = $outputdir;
	$job->{scriptfile} = $scriptfile;
	$job->{checkfile} = $checkfile;
	$job->{stdoutfile} = $stdoutfile;
	$job->{stderrfile} = $stderrfile;
	$job->{lockfile} = $lockfile;
	$job->{tasks} = $number;
	
	#### SET BATCH
	$job->{batch} = "$label\[1-$number\]" if $clustertype eq "LSF";
	$job->{batch} = "-t $number" if $clustertype eq "PBS";
	$job->{batch} = "-t 1-$number" if $clustertype eq "SGE";
	
	$self->logDebug("job", $job);

	return $job;
}


sub createTaskDirs {
	my $self		=	shift;
	my $directory	=	shift;
	my $number		=	shift;
	$self->logDebug("Agua::Cluster::Jobs::createTaskDirs(directory, number)");
	$self->logDebug("directory: $directory ");
	$self->logDebug("number: $number ");

	my $index = $self->getIndex();
	$self->logDebug("index", $index);

	#### CREATE DIRS	
	my $dirs;
	for my $task ( 1..$number )
	{
		my $dir = $directory;
		$self->logDebug("BEFORE dir", $dir);
		
		use re 'eval';
		$dir =~ s/\\$index/$task/g;
		no re 'eval';
		$self->logDebug("AFTER dir", $dir);

		push @$dirs, $dir;
		File::Path::mkpath($dir) if not -d $dir;
	}

	return $dirs;
}

sub printScriptfile {
=head2

	SUBROUTINE		printScriptfile
	
	PURPOSE
	
		PRINT SHELL SCRIPT CONFORMING TO CLUSTER TYPE
		
=cut

	my $self		=	shift;

	$self->logDebug("Agua::Cluster::Jobs::printScriptfile(splitfiles)");

	my $clustertype =  $self->conf()->getKey('agua', 'CLUSTERTYPE');
	$self->logDebug("clustertype", $clustertype);
	return $self->printPbsScriptfile(@_) if $clustertype eq "PBS";
	return $self->printLsfScriptfile(@_) if $clustertype eq "LSF";
	return $self->printSgeScriptfile(@_) if $clustertype eq "SGE";
}

sub printSgeScriptfile {
=head2

	SUBROUTINE		printSgeScriptfile
	
	PURPOSE
	
		PRINT SHELL SCRIPT CONFORMING TO PBS FORMAT

	EXAMPLES
	
		#$ -pe mvapich 4 
		#$ -M [my email] 
		#$ -m ea 
		#$ -l h_rt=8:00:00 
		#$ -R y 
		#$ -j y 
		#$ -notify 
		#$ -cwd 

=cut

	my $self		=	shift;
	my $scriptfile	=	shift;
	my $commands	=	shift;
	my $label		=	shift;
	my $stdoutfile	=	shift;
	my $stderrfile	=	shift;
	my $lockfile	=	shift;

	my $queue = $self->queue();
	my $cpus = $self->cpus();
	$cpus = 1 if not defined $cpus or not $cpus;
	$self->logDebug("Agua::Cluster::Jobs::printLsfScriptfile(scriptfile, commands, label, stdoutfile, stderrfile)");
	$self->logDebug("stdoutfile", $stdoutfile);
	$self->logDebug("stderrfile", $stderrfile);
	$self->logDebug("cpus", $cpus);

	open(SHFILE, ">$scriptfile") or die "Can't open script file: $scriptfile\n";
	print SHFILE qq{#!/bin/bash\n\n};
	
	#### ! IMPORTANT !
	#### NEEDED BECAUSE EXEC NODES NOT FINDING $SGE_TASK_ID
	#### ADD LABEL
	print SHFILE qq{#\$ -N $label\n};
	
	#### ADD CPUs
	print SHFILE qq{#\$ -pe threaded $cpus\n} if defined $cpus and $cpus > 1;

	#### STDOUT AND STDERR
	print SHFILE qq{#\$ -j y\n} if not defined $stderrfile;
	print SHFILE qq{#\$ -o $stdoutfile\n} if defined $stdoutfile;
	print SHFILE qq{#\$ -e $stderrfile\n} if defined $stderrfile;
	
	#### ADD QUEUE
	print SHFILE qq{#\$ -q $queue\n};

	#### ADD WALLTIME IF DEFINED
	my $walltime = $self->walltime();
	print SHFILE qq{#\$ -l h_rt=$walltime:00:00\n} if defined $walltime and $walltime;

#### ADDITIONAL ENVARS
#echo COMMD_PORT: 	\$COMMD_PORT
#echo SGE_O_LOGNAME: \$SGE_O_LOGNAME
#echo SGE_O_MAIL: 	\$SGE_O_MAIL
#echo SGE_O_TZ: 		\$SGE_O_TZ
#echo SGE_CKPT_ENV: 	\$SGE_CKPT_ENV
#echo SGE_CKPT_DIR: 	\$SGE_CKPT_DIR

	print SHFILE qq{
echo "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*"
echo SGE_JOB_SPOOL_DIR: \$SGE_JOB_SPOOL_DIR
echo SGE_O_HOME: 		\$SGE_O_HOME
echo SGE_O_HOST: 		\$SGE_O_HOST
echo SGE_O_PATH: 		\$SGE_O_PATH
echo SGE_O_SHELL: 		\$SGE_O_SHELL
echo SGE_O_WORKDIR: 	\$SGE_O_WORKDIR
echo SGE_STDERR_PATH:	\$SGE_STDERR_PATH
echo SGE_STDOUT_PATH:	\$SGE_STDOUT_PATH
echo SGE_TASK_ID: 		\$SGE_TASK_ID
echo HOME: 				\$HOME
echo HOSTNAME: 			\$HOSTNAME
echo JOB_ID: 			\$JOB_ID
echo JOB_NAME: 			\$JOB_NAME
echo NQUEUES: 			\$NQUEUES
echo NSLOTS: 			\$NSLOTS

echo SGE_ROOT: 			\$SGE_ROOT
echo SGE_CELL: 			\$SGE_CELL
echo SGE_QMASTER_PORT: 	\$SGE_QMASTER_PORT
echo SGE_EXECD_PORT: 	\$SGE_EXECD_PORT

echo USERNAME: 	     	\$USERNAME
echo PROJECT:  	       	\$PROJECT
echo WORKFLOW: 	       	\$WORKFLOW
echo QUEUE:    	       	\$QUEUE

};

	#### ADD HOSTNAME
	print SHFILE qq{hostname -f\n};

	#### PRINT LOCK FILE
	print SHFILE qq{date > $lockfile\n};

	my $command = join "\n", @$commands;
	print SHFILE "$command\n";

	#### REMOVE LOCK FILE
	print SHFILE qq{unlink $lockfile;\n\nexit\n};

	close(SHFILE);
	chmod(0777, $scriptfile);
	#or die "Can't chmod 0777 script file: $scriptfile\n";
	$self->logDebug("scriptfile printed", $scriptfile);
}



sub printPbsScriptfile {
=head2

	SUBROUTINE		printPbsScriptfile
	
	PURPOSE
	
		PRINT SHELL SCRIPT CONFORMING TO PBS FORMAT
		
=cut

	my $self		=	shift;
	my $scriptfile	=	shift;
	my $commands	=	shift;
	my $label		=	shift;
	my $stdoutfile	=	shift;
	my $stderrfile	=	shift;
	my $lockfile	=	shift;
	$self->logDebug("Agua::Cluster::Jobs::printLsfScriptfile(scriptfile, commands, label, stdoutfile, stderrfile)");

	open(SHFILE, ">$scriptfile") or die "Can't open script file: $scriptfile\n";
	print SHFILE qq{#!/bin/bash\n\n};

	#### ! IMPORTANT !
	#### NEEDED BECAUSE EXEC NODES NOT FINDING $SGE_TASK_ID
	print SHFILE qq{export TASKNUM=\$(expr \$PBS_TASKNUM)\n\n};
	
	#### ADD LABEL
	print SHFILE qq{#PBS -N $label	                # The name of the job
};

	#### STDOUT AND STDERR
	print SHFILE qq{#PBS -j oe\n} if not defined $stderrfile;
	print SHFILE qq{#PBS -o $stdoutfile\n} if defined $stdoutfile;
	print SHFILE qq{#PBS -e $stderrfile\n} if defined $stderrfile;

	#### ADD WALLTIME IF DEFINED
	my $walltime = $self->walltime();
	print SHFILE qq{#PBS -W $walltime:00\n} if defined $walltime;

	print SHFILE qq{
echo running on PBS_O_HOST: 			\$PBS_O_HOST
echo originating queue is PBS_O_QUEUE: 	\$PBS_O_QUEUE
echo executing queue is PBS_QUEUE: 		\$PBS_QUEUE
echo working directory is PBS_O_WORKDIR:\$PBS_O_WORKDIR
echo execution mode is PBS_ENVIRONMENT: \$PBS_ENVIRONMENT
echo job identifier is PBS_JOBID: 		\$PBS_JOBID
echo job name is PBS_JOBNAME: 			\$PBS_JOBNAME
echo node file is PBS_NODEFILE: 		\$PBS_NODEFILE
echo current home directory PBS_O_HOME: \$PBS_O_HOME
echo PBS_O_PATH: 						\$PBS_O_PATH
echo PBS_JOBID: 						\$PBS_JOBID
};

	#### ADD HOSTNAME
	print SHFILE qq{hostname -f\n};

	#### PRINT LOCK FILE
	print SHFILE qq{date > $lockfile\n};

	#### PRINT ALL COMMANDS TO SHELL SCRIPT FILE
	foreach my $command ( @$commands )
	{
		print SHFILE "$command\n";
	}

	#### REMOVE LOCK FILE
	print SHFILE qq{unlink $lockfile;\n\nexit\n};

	close(SHFILE);
	chmod(0777, $scriptfile);
	#or die "Can't chmod 0777 script file: $scriptfile\n";
	$self->logDebug("scriptfile printed", $scriptfile);
}


sub printLsfScriptfile {
=head2

	SUBROUTINE		printLsfScriptfile
	
	PURPOSE
	
		PRINT SHELL SCRIPT CONFORMING TO LSF FORMAT
		
#BSUB -J jobname	# assigns a name to job
#BSUB -B	        # Send email at job start
#BSUB -N	        # Send email at job end
#BSUB -e errfile	# redirect stderr to specified file
#BSUB -o out_file	# redirect stdout to specified file
#BSUB -a application	# specify serial/parallel options
#BSUB -P project_name	# charge job to specified project
#BSUB -W runtime	# set wallclock time limit
#BSUB -q queue_name	# specify queue to be used
#BSUB -n num_procs	# specify number of processors
#BSUB -R    "span[ptile=num_procs_per_node]"	# specify MPI resource requirements

=cut

	my $self		=	shift;
	my $scriptfile	=	shift;
	my $commands	=	shift;
	my $label		=	shift;
	my $stdoutfile 	=	shift;
	my $stderrfile	=	shift;
	my $lockfile	=	shift;
	$self->logDebug("Agua::Cluster::Jobs::printLsfScriptfile(scriptfile, commands, label, stdoutfile, stderrfile)");

	#### SANITY CHECK
	$self->logCritical("scriptfile not defined") and exit if not defined $scriptfile;
	$self->logCritical("commands not defined") and exit if not defined $commands;
	$self->logCritical("label not defined") and exit if not defined $label;

	open(SHFILE, ">$scriptfile") or die "Can't open script file: $scriptfile\n";
	print SHFILE qq{#!/bin/bash
	
#BSUB -J $label             	# The name of the job
};

	#### ADD WALLTIME IF DEFINED
	my $walltime = $self->walltime();
	print SHFILE qq{#BSUB -W $walltime:00\n} if defined $walltime;

	print SHFILE qq{#BSUB -o $stdoutfile 			# print STDOUT to this file\n} if defined $stdoutfile;
	print SHFILE qq{#BSUB -e $stderrfile 			# print STDERR to this file\n} if defined $stderrfile;
	print SHFILE qq{

echo "LS_JOBID: " \$LS_JOBID
echo "LS_JOBPID: " \$LS_JOBPID
echo "LSB_JOBINDEX: " \$LSB_JOBINDEX
echo "LSB_JOBNAME: " \$LSB_JOBNAME
echo "LSB_QUEUE: " \$LSB_QUEUE
echo "LSFUSER: " \$LSFUSER
echo "LSB_JOB_EXECUSER: " \$LSB_JOB_EXECUSER
echo "HOSTNAME: " \$HOSTNAME
echo "LSB_HOSTS: " \$LSB_HOSTS
echo "LSB_ERRORFILE: " \$LSB_ERRORFILE
echo "LSB_JOBFILENAME: " \$LSB_JOBFILENAME
echo "LD_LIBRARY_PATH: " \$LD_LIBRARY_PATH

date > $lockfile

};

	#### PRINT ALL COMMANDS TO SHELL SCRIPT FILE
	foreach my $command ( @$commands )
	{
		print SHFILE "$command\n";
	}

	print SHFILE qq{
unlink $lockfile;

exit;
};

	close(SHFILE);
	chmod(0777, $scriptfile) or die "Can't chmod 0777 script file: $scriptfile\n";
	$self->logDebug("scriptfile printed", $scriptfile);

}








no Moose;


1;
