package Agua::Monitor::PBS;
=head2

	PACKAGE		Agua::Monitor::PBS
	
    VERSION:        0.02

    PURPOSE
  
        1. MONITOR JOBS RUN ON A PBS (PORTABLE BATCH SCHEDULER) SYSTEM

	HISTORY
	
		0.02	Added monitor_jobs failback on 'ERROR' qstat output
		0.01	Basic version

=cut 

use strict;
use warnings;
use Carp;

use FindBin qw($Bin);
use lib "$Bin/../..";

#### INTERNAL MODULES
#use Agua::DBaseFactory;

#### EXTERNAL MODULES
use POSIX;
use Data::Dumper;
use DBI;

#### EXPORTER
require Exporter;
our @ISA = 'Agua::Monitor';
our @EXPORT_OK = qw();
our $AUTOLOAD;

#### DEFAULT PARAMETERS
our @DATA = qw(
	DBTYPE
	DBFILE
    SQLFILE
    DBOBJECT
    SLEEP

	CPUS
	QSUB
	QSTAT
	CHECKJOB
	CANCELJOB
	TEMPDIR
	
	PID
    COMMAND
    OUTPUTDIR
    DATETIME
	CONF
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}

our $SLEEP = 5;
our $QSTAT = "qstat";
our $ERROR_REGEX = "^ERROR";
our $JOBID_REGEX = "^\\s*(\\d+)";
our $CHECKJOB = "/usr/local/bin/checkjob";

=head2

	SUBROUTINE		submitJob
	
	PURPOSE
	
		SUBMIT A JOB TO THE CLUSTER AND RETURN THE JOB ID
		
	NOTES
	
		GET LIST OF PROCESS IDS BEFORE AND AFTER SUBMISSION AS BACKUP
		
		TO MITIGATE RISK OF UNDEFINED JOB ID WHEN READING ERROR MESSAGE
		
		DUE TO ERROR WITH STATUS REQUEST (qstat) TO SCHEDULER, E.G.:

			ERROR:    communication error kronos.ccs.miami.edu:42559 (client timed out)

=cut

sub submitJob
{
	my $self		=	shift;
	my $args 		=	shift;
	$self->logDebug("Agua::Monitor::PBS::submitJob(command)");
	$self->logDebug("args", $args);
	
	my $queue = $args->{queue};
	$self->logDebug("queue not defined. Returning") and return if not defined $queue;
	my $batch = $args->{batch};
	$batch = '' if not defined $batch;
	
	my $scriptfile = $args->{scriptfile};
	my $stderrfile = $args->{stderrfile};
	my $stdoutfile = $args->{stdoutfile};
	$stdoutfile = "/dev/null" if not defined $stdoutfile;
	$stderrfile = "/dev/null" if not defined $stderrfile;

	$self->logDebug("Scriptfile not defined. Returning null") and return if not defined $args->{scriptfile};

	my $qsub 		=	$self->get_qsub();
	my $qstat		=	$self->get_qstat();
	my $sleep		=	$self->get_sleep();
	$self->logDebug("qsub not defined. Returning") and return if not defined $qsub;

	#### QSUB
	my $command = "$qsub $batch -q $queue $scriptfile";
	$command .= " -o $stdoutfile " if defined $stdoutfile and $stdoutfile and not defined $batch;
	$command .= " -e $stderrfile " if defined $stderrfile and $stderrfile and not defined $batch;
	$self->logDebug("command", $command);

	#### GET CURRENT IDS BEFORE SUBMIT
	my $all_ids = $self->jobIds();
	#### GET THE PID
	my $output = `$command`;
	use re 'eval';	# EVALUATE AS REGEX
	my ($job_id) = $output =~ /$JOBID_REGEX/;
	use re 'eval';	# EVALUATE AS REGEX
	$self->logDebug("job_id after submit", $job_id)  if defined $job_id;
	$self->logDebug("job_id not defined after submit")  if not defined $job_id;	;


	#### THERE WAS A PROBLEM RETURNING A JOB ID, GET IT AS THE
	#### FIRST NEW JOB PRESENT IN THE JOBS LIST
	if ( not defined $job_id )
	{
		my $tries = 10;
		$self->logDebug("job_id not defined. Checking for $tries tries");

		#### GET CURRENT IDS IMMEDIATELY AFTER SUBMIT
		#### NB: THIS HACK ASSUMES NO OTHER PROCESSES ARE SUBMITTING
		#### 	WHICH MIGHT NOT BE THE CASE. REDO LATER.
		my $new_ids = $self->jobIds();
		$self->logDebug("new_ids", $new_ids);
		
		while ( $$new_ids[scalar(@$new_ids - 1)] == $$all_ids[scalar(@$all_ids - 1)]
			   and $tries )
		{
			$self->logDebug("new_ids");
			$new_ids = $self->jobIds();

			if ( not defined $$new_ids
				or $$new_ids[scalar(@$new_ids - 1)] != $$all_ids[scalar(@$all_ids - 1)]	)
			{
				$tries = 0;
			}
			else
			{
				$tries--;
				$self->logDebug("$tries left.");
				$self->logDebug("Qstat sleeping $sleep seconds");
				sleep($sleep);
			}
		}

		$job_id = $$new_ids[scalar(@$new_ids - 1)];
	}
	
	return $job_id;	
}


sub jobIds
{
	my $self		=	shift;
	$self->logDebug("Agua::Monitor::PBS::jobIds()");	;

	#### GET LIST OF JOBS IN QSTAT
	my $lines = $self->jobLines();

	#### PARSE OUT IDS FROM LIST
	my $job_ids = [];
	foreach my $line ( @$lines )
	{
		use re 'eval';# EVALUATE AS REGEX
		$line =~ /$JOBID_REGEX/;
		push @$job_ids, $1 if defined $1 and $1;
		no re 'eval';# STOP EVALUATING AS REGEX
	}

	return $job_ids;
}


=head2

	SUBROUTINE		jobLines
	
	PURPOSE
		
		RETURN THE LINES FROM A QSTAT CALL:

			EXEC QSTAT COMMAND AND COLLECT RESULT LINES AS THEY <STREAM> OUT
	
=cut

sub jobLines
{
	my $self		=	shift;
	$self->logDebug("Agua::Monitor::PBS::jobLines()");

	#### TRY REPEATEDLY TO GET A CLEAN QSTAT REPORT
	my $qstat		=	$self->get_qstat();
	my $sleep		=	$self->get_sleep();	

	#### GET ERROR MESSAGES ALSO
	my $command = "$qstat 2>&1 |";
	$self->logDebug("$command");

	#### MAXIMUM TRIES BEFORE GIVING UP
	my $tries = 20;

	#### REPEATEDLY TRY SYSTEM CALL UNTIL A NON-ERROR RESPONSE IS RECEIVED
	my $result = $self->repeatTries($command, $ERROR_REGEX, $sleep, $tries);
	$self->logDebug("repeatTries result", $result);

	my @lines = split "\n", $result;
	my $jobs_list = [];
	foreach my $line ( @lines )
	{
		use re 'eval';# EVALUATE AS REGEX
		push @$jobs_list, $line if $line =~ /$JOBID_REGEX/;
		no re 'eval';# EVALUATE AS REGEX
	}
	
	return \@lines;
}


=head2

	SUBROUTINE		repeatTries
	
	PURPOSE
		
		REPEATEDLY TRY SYSTEM CALL UNTIL A NON-ERROR RESPONSE IS RECEIVED

=cut

sub repeatTries
{
	my $self		=	shift;
	my $command		=	shift;
	my $error_regex	=	shift;
	my $sleep		=	shift;
	my $tries		=	shift;
	$self->logDebug("Agua::Monitor::PBS::repeatTries(command, error_regex, sleep, tries)");
	$self->logDebug("error_regex", $error_regex);
	$self->logDebug("sleep", $sleep);
	$self->logDebug("tries", $tries);
	

	my $result = '';	
	my $error_message = 1;
	while ( $error_message and $tries )
	{
		open(COMMAND, $command) or die "Can't exec command: $command\n";
		while(<COMMAND>) {
			$result .= $_;
		}
		close (COMMAND);
		$self->logDebug("Qstat result", $result);

		use re 'eval';	# EVALUATE AS REGEX
		$error_message = $result =~ /$ERROR_REGEX/;
		$self->logDebug("error_message", $error_message)  if not $result;
		no re 'eval';# STOP EVALUATING AS REGEX

		#### DECREMENT TRIES AND SLEEP
		$tries--;
		$self->logDebug("$tries left.")  if not $result;
		$self->logDebug("Qstat sleeping $sleep seconds") if $error_message;

		$self->logDebug("printing date:");
		$self->logDebug(`date`);

		sleep($sleep) if $error_message;
	}
	
	return $result;
}


=head2

    SUBROUTINE      remainingJobs
    
    PURPOSE
    
        KEEP TRACK OF PIDS OF CURRENTLY RUNNING JOBS
        
	CALLER
	
		fastaInfos, printFiles
	
=cut

sub remainingJobs
{    
	my $self		=	shift;
	my $job_ids    	=	shift;
	$self->logDebug("Agua::Monitor::PBS::remainingJobs(job_ids)");
	$self->logDebug("job_ids: @$job_ids");

    my $qstat   =   $self->get_qstat();
    
	#### GET LIST OF JOBS IN QSTAT
	my $lines = $self->jobLines();
	
	for ( my $i = 0; $i < @$job_ids; $i++ )
    {
		my $job_id = $$job_ids[$i];
		my $jobstatus = $self->jobStatus($job_id);
		if ( defined $jobstatus and defined $jobstatus->{status} and $jobstatus->{status} eq "Completed" )
		{
			$self->logDebug("JOB completed", $job_id);
			splice @$job_ids, $i, 1;
		}
    }
	$self->logDebug("Returning job_ids: @$job_ids");

    return $job_ids;
}



=head2

    SUBROUTINE      jobLineStatus
    
    PURPOSE
    
        RETURN THE STATUS OF A PARTICULAR JOB IDENTIFIED BY JOB ID
        
	NOTES
	
		CALLED IN Sampler.pm BY fastaInfos AND printFiles SUBROUTINES
	
=cut

sub jobLineStatus
{    
	my $self		=	shift;
	my $job_id    	=	shift;
    my $job_lines	=   shift;
	$self->logDebug("Agua::Monitor::PBS::jobLineStatus(pids, qstat, sleep)");
	$self->logDebug("job_id", $job_id)  if defined $job_id;
	$self->logDebug("pids: @$job_lines");
	
	#### GET LIST OF JOBS IN QSTAT
	my $lines = $self->jobLines();

	my $status;
    foreach my $line ( @$lines )
    {
		my $job_id_match = $line =~ /^$job_id\./;
		if ( $job_id_match )
		{
			$status = $self->lineStatus($line);
			last;
        }
    }

	$self->logDebug("Returning status", $status)  if defined $status;
    return $status;
}


=head2

    SUBROUTINE      jobStatus
    
    PURPOSE
    
        RETURN THE STATUS OF A PARTICULAR JOB IDENTIFIED BY JOB ID
        
	NOTES
	
		CALLED IN Sampler.pm BY fastaInfos AND printFiles SUBROUTINES
	
=cut

sub jobStatus
{    
	my $self		=	shift;
	my $job_id    	=	shift;
	$self->logDebug("Agua::Monitor::PBS::jobStatus(pids, qstat, sleep)");
	$self->logDebug("job_id", $job_id)  if defined $job_id;
	
#	#### GET LIST OF JOBS IN QSTAT
#	my $lines = $self->jobLines();
#
#	my $status;
#    foreach my $line ( @$lines )
#    {
#		my $job_id_match = $line =~ /^$job_id\./;
#		if ( $job_id_match )
#		{
#			$status = $self->lineStatus($line);
#			last;
#        }
#    }

	my $jobcheck = $self->checkJob($job_id);	
	$self->logDebug("jobcheck", $jobcheck);

	my $status = $self->checkToStatus($jobcheck);

	$self->logDebug("Returning status", $status)  if defined $status;
    return $status;
}




=head2

	SUBROUTINE		checkJob
	
	PURPOSE
	
		GET RESPONSE FROM checkJob CALL
		
		
echo '{"username":"syoung","sessionId":"1228791394.7868.158","project":"Project1","workflow":"Workflow1","mode":"executeWorkflow","number":1}' | perl -U workflow.cgi

{"username":"syoung","sessionId":"9999999999.9999.999","project":"Project1","workflow":"Workflow1","mode":"executeWorkflow","number":1}


	EXAMPLE
	
	checkjob 2355875

		job 235875
		
		AName: STDIN
		State: Idle 
		Creds:  user:agua  group:agua  account:agua  class:default
		WallTime:   00:00:00 of 4:00:00
		SubmitTime: Mon Feb 22 07:27:05
		  (Time Queued  Total: 00:00:54  Eligible: 00:00:00)
		
		Total Requested Tasks: 1
		
		Req[0]  TaskCount: 1  Partition: ALL  
		Memory >= 0  Disk >= 0  Swap >= 0
		
		
		
		IWD:            $HOME/home/admin/Project1/Workflow1
		Executable:     /opt/moab/spool/moab.job.2ch7mO
		
		Partition List: ALL,base
		Flags:          GLOBALQUEUE
		Attr:           checkpoint
		StartPriority:  1
		NOTE:  job violates constraints for partition base (job 235875 violates active HARD MAXJOB limit of 2 for user agua  (Req: 1  InUse: 2)
		)
		
		BLOCK MSG: job 235875 violates active HARD MAXJOB limit of 2 for user agua  (Req: 1  InUse: 2)
		 (recorded at last scheduling iteration)


=cut

sub checkJob
{
	my $self		=	shift;
	my $job_id		=	shift;
	$self->logDebug("Agua::Monitor::PBS::checkJob(job_id)");
	$self->logDebug("job_id", $job_id);
	my $checkjob = $self->get_checkjob();
	$self->logDebug("job_id", $job_id);

	$checkjob = $CHECKJOB if not defined $checkjob;
	die "Agua::Monitor::PBS::job_id    job_id not defined. Exiting.\n" if not defined $job_id;

	#### SET COMMAND
	my $command = "$checkjob $job_id 2>&1 |";
	$self->logDebug("$command");

	#### SLEEP BETWEEN TRIES
	my $sleep		=	$self->get_sleep();	
	$sleep = $SLEEP if not defined $sleep;
	$self->logDebug("sleep", $sleep);

	#### MAXIMUM TRIES BEFORE GIVING UP
	my $tries = 20;
	
	#### ERROR REGEX
	my $error_regex = "^ERROR";

	#### REPEATEDLY TRY SYSTEM CALL UNTIL A NON-ERROR RESPONSE IS RECEIVED
	my $result = $self->repeatTries($command, $error_regex, $sleep, $tries);
	$self->logDebug(":checkJob    result", $result);
	
	return $result;	
}

=head2

job 235878

AName: STDIN
State: Running 
Creds:  user:syoung  group:bioinfo  account:bioinfo  class:default
WallTime:   00:00:00 of 4:00:00
SubmitTime: Mon Feb 22 07:48:44
  (Time Queued  Total: 00:00:01  Eligible: 00:00:00)

StartTime: Mon Feb 22 07:48:45
Total Requested Tasks: 1

Req[0]  TaskCount: 1  Partition: base  
Memory >= 0  Disk >= 0  Swap >= 0

Allocated Nodes:
[n29:1]



IWD:            $HOME/.agua/Project1/Workflow1
Executable:     /opt/moab/spool/moab.job.wdAlxx

StartCount:     1
Partition List: ALL,base
Flags:          BACKFILL,GLOBALQUEUE
Attr:           BACKFILL,checkpoint
StartPriority:  1
Reservation '235878' (00:00:00 -> 4:00:00  Duration: 4:00:00)




job 235888

AName: STDIN
State: Completed 
Complete Time:  Mon Feb 22 08:20:40
  Completion Code: 271
Creds:  user:syoung  group:bioinfo  account:bioinfo  class:default
WallTime:   00:10:57 of 4:00:00
SubmitTime: Mon Feb 22 08:09:42
  (Time Queued  Total: 00:16:11  Eligible: 00:00:00)

Total Requested Tasks: 1

Req[0]  TaskCount: 1  Partition: base  
Memory >= 0  Disk >= 0  Swap >= 0
NodeCount:  1

Allocated Nodes:
[n28:1]



IWD:            $HOME/.agua/Project1/Workflow1
Executable:     /opt/moab/spool/moab.job.GZrYhE

Execution Partition:  base
StartPriority:  0






	SUBROUTINE		checkToStatus
	
	PURPOSE
	
		GET JOB STATUS FROM checkJob CALL


		job 234836
		
		AName: sleep-10000
		State: Running 
		Creds:  user:agua  group:agua  account:agua  class:default
		WallTime:   1:32:36 of 4:00:00
		SubmitTime: Thu Feb 18 12:23:20
can		  (Time Queued  Total: 00:00:01  Eligible: 00:00:00)
		
		StartTime: Thu Feb 18 12:23:21
		Total Requested Tasks: 1
		
		Req[0]  TaskCount: 1  Partition: base  
		Memory >= 0  Disk >= 0  Swap >= 0
		NodeCount:  1
		
		Allocated Nodes:
		[n28:1]
		
		
		
		IWD:            /tmp
		Executable:     /opt/moab/spool/moab.job.tcA9DY
		
		StartCount:     1
		Partition List: ALL,base
		Flags:          GLOBALQUEUE
		Attr:           checkpoint
		StartPriority:  1
		Reservation '234836' (-1:33:20 -> 2:26:40  Duration: 4:00:00)

=cut

sub checkToStatus
{
	my $self		=	shift;
	my $jobcheck	=	shift;
	$self->logDebug("Agua::Monitor::PBS::checkToStatus()");

	my $statusHash;
	($statusHash->{status}) = $jobcheck =~ /State:\s*(\S+)/ms;
	($statusHash->{submittime}) = $jobcheck =~ /SubmitTime:\s*([^\n]+)/ms;
	($statusHash->{starttime}) = $jobcheck =~ /StartTime:\s*([^\n]+)/ms;
	($statusHash->{nodes}) = $jobcheck =~ /Allocated Nodes:\s*\n\s*(\S+?)/ms;
	($statusHash->{nodecount}) = $jobcheck =~ /NodeCount:\s*(\d+)/ms;

	$self->logDebug("statusHash", $statusHash);

	return $statusHash;	
}


=head2

    SUBROUTINE      status    

    PURPOSE
    
		HASH JOBID AGAINST STATUS

=cut

sub statusHash
{
	my $self		=	shift;
	$self->logDebug("Agua::Monitor::PBS::statusHash()");

	my $joblines = $self->jobLines();
	$self->logDebug("joblines: @$joblines");

	my $statusHash;
	foreach my $line ( @$joblines )
	{
		if ( $line =~ /^(\d+)/ )
		{
			$statusHash->{$1} = $self->lineStatus($line);
		}
	}
	
	$self->logDebug("statusHash", $statusHash);
	
	return $statusHash;
}


=head2

sub

	SUBROUTINE		lineStatus
	
	PURPOSE
	
		RETURN THE STATUS ENTRY FOR A JOB LINE

=cut

sub lineStatus
{
	my $self		=	shift;
	my $line		=	shift;
	
	my ($status) = $line =~ /^.{68}(\S+)/;
	
	return "running" if $status eq "R";
	return "queued" if $status eq "Q";
	return "error" if $status eq "E";
}


=head2

    SUBROUTINE      status    

    PURPOSE
    
		REPORT THE STATUS OF A JOB

=cut

sub status
{
	my $self		=	shift;
	my $args        =	shift;
    my $type = $args->{type};
    my $value = $args->{value};
    my $limit = $args->{limit};

    $self->logDebug("args", $args);
    $self->logDebug("value", $value);
    $self->logDebug("limit", $limit);

    my $dbfile = $self->dbfile() if $self->get_db() and $self->get_db eq "SQLite";
    $self->logDebug("dbfile", $dbfile) if $self->get_db eq "SQLite";

	#### GET DB OBJECT
	my $db = $self->get_db();
	
    #### FIRST, GET TOTAL ENTRIES IN TABLE
    my $query;
    $query = qq{SELECT COUNT(*) FROM monitor};
    my $total = $self->db()->query($query);
    $self->logDebug("total", $total);
    
    #### THEN, SET UP THE QUERY DEPENDING ON THE ARGS
    #### IF type IS DEFINED, SEARCH DB ACCORDINGLY    
    if ( defined $type )
    {
        if ( $type =~ /^job$/ )
        {
            $query = qq{SELECT * FROM monitor ORDER BY datetime DESC LIMIT $value, $limit};
        }
        elsif ( $type =~ /^pid$/ )
        {
            $query = qq{SELECT * FROM monitor WHERE processid='$value' ORDER BY datetime DESC};
        }
    }
    #### OTHERWISE, GET THE limit LAST ENTRIES IN THE DATABASE
    else
    {
        $query = qq{SELECT * FROM monitor ORDER BY datetime DESC LIMIT $limit};
    }
    $self->logDebug("query", $query);
    
    #### GET FIELDS
    my $fields = $self->db()->fields('monitor');
    $self->logDebug("Fields: @$fields");

    #### RUN QUERY
    my $jobs = $self->db()->querytwoDarray($query);
    return if not defined $jobs;
    
    #### PRINT JOBS
    foreach my $job ( @$jobs )
    {
        $self->logDebug("*************************************************************");
        for ( my $index = 0; $index < @$job; $index++ )
        {
            my $key = $$fields[$index];
            my $value = $$job[$index];
            my $gap = " " x ( 20 - length($key));
            $self->logDebug("$key$gap$value");
        }
    }
}


=head2

	SUBROUTINE		get_db
	
	PURPOSE

		RETURN THE _db OR CREATE ONE
		
=cut

sub get_db
{
	my $self		=	shift;
	
	my $conf = $self->get_conf();	
	
	#### CREATE DB OBJECT USING DBASE FACTORY
	my $db = 	DBaseFactory->new( $conf->getKey("database", "DBTYPE"),
	{
		'DBFILE'	=>	$conf->getKey("database", "DBFILE"),
		'DATABASE'	=>	$conf->getKey("database", "DATABASE"),
		'USER'      =>  $conf->getKey("database", "USER"),
		'PASSWORD'  =>  $conf->getKey("database", "PASSWORD")
	}
) or die "Can't create database object to create database: $conf->getKey('database', 'DATABASE'). $!\n";

    #my $db = DBaseFactory->new( "SQLite", { 'DBFILE' => $dbfile } ) or die "Can't open DB file '$dbfile': $!\n";
    #if ( not defined $db )
    #{
    #    die "Database object not defined. Tried to access sqlite DB file: $dbfile\n";
    #}    

	return $db;	
}
    




=head2

    SUBROUTINE      update
    
    PURPOSE
    
		UPDATE THE STATUS OF ALL running JOBS IN THE DATABASE

=cut

sub update
{
	my $self		=	shift;

    #### GET DBOBJECT
    my $db 	= $self->{_db};

    #### GET QSTAT
    my $qstat 		= $self->{_qstat};

	#### DEPRECATED: REMOVE IN NEXT VERSION. SEPARATED DB FROM MONITOR.
	#### 
    ##### CONNECT TO SQLITE DATABASE
	#### 
	#my $dbfile      =	$self->dbfile();
    #my $dbh = DBI->connect( "dbi:SQLite:$dbfile" ) || die "Cannot connect: $DBI::errstr";
    #
    ##### CREATE DBase::SQLite OBJECT
    #my $db = DBase::SQLite->new(    {   'DBH' => $dbh   }   );
    
    my $query = qq{SELECT processid FROM monitor WHERE status = 'running'};
    my $pids = $self->db()->queryarray($query);
    foreach my $pid ( @$pids )
    {        
        my $qstat_result = '';
        my $qstat_command = "$qstat $pid 2>&1 |";
        $self->logDebug("$qstat_command");
        open(COMMAND, $qstat_command) or die "Can't exec command: $qstat_command\n";
        while(<COMMAND>) {
            $qstat_result .= $_;
        }
        close (COMMAND);

        if ( $qstat_result =~ /^qstat: Unknown Job Id/i )
        {
            my $query = qq{UPDATE monitor SET status = 'completed' WHERE processid = '$pid'};
            $self->logDebug("query", $query);
            $self->db()->do($query);
            next;
        }
        
        my @lines = split "\n", $qstat_result;
        shift @lines; shift @lines;
        my $completed = 0;
        my $line;
        while ( ( $line = shift @lines ) and defined $line and not $completed )
        {
            next if $line =~ /^\s*$/;
            my $pid_match = $line =~ /^$pid\./;
            if ( $pid_match )
            {
                my $status;
                ($status) = $line =~ /^.{68}(\S+)/;
                if ( $status eq "C" )
                {
                    my $query = qq{UPDATE monitor SET status = 'completed' WHERE processid = '$pid'};
                    $self->logDebug("query", $query);
                    my $success = $self->db()->do($query);
                    $self->logDebug("success", $success);
                    $completed = 1;
                }
                elsif ( $status eq "E" )
                {
                    my $query = qq{UPDATE monitor SET status = 'error' WHERE processid = '$pid'};
                    $self->logDebug("query", $query);
                    $self->db()->do($query);
                    
                    $completed = 1;
                }
            }
        }
        
    } # foreach my $pid ( @$pids )

}



=head2

    SUBROUTINE      create_db    

    PURPOSE
    
		CREATE THE DATABASE AND THE monitor TABLE

=cut

sub create_db
{
	my $self		=	shift;

	my $dbfile    =	$self->{_dbfile};

    #### CREATE DB OBJECT USING DBASE FACTORY
    my $db = DBaseFactory->new( "SQLite", { 'DBFILE' => $dbfile } ) or die "Can't open DB file '$dbfile': $!\n";
    if ( not defined $db )
    {
        die "Database object not defined. Tried to access sqlite DB file: $dbfile\n";
    }
    
    #### CREATE SQLFILE IF DOESN'T EXIST
    my $sqlfile = $self->sqlfile();
    
    #### SET TABLE
    my $table = $sqlfile =~ /([^\/^\\]+)\.sql/;
        
    #### CREATE PROJECTS TABLE
    $self->logDebug("Creating table", $table);
    $self->logDebug("Using sqlfile", $sqlfile);
    my $success = $self->db()->create_table($table, $sqlfile);
    
    return $success;
}


=head2

    SUBROUTINE      dbfile    
    PURPOSE
    
		RETURN THE DBFILE LOCATION AND CREATE DBFILE IF NOT PRESENT

=cut

sub dbfile
{
	my $self		=	shift;

	my $dbfile    =	$self->{_dbfile};

    #### SET DEFAULT DBFILE
    if ( not defined $dbfile or not $dbfile )
    {
        my $username = `whoami`;
        $username =~ s/\s+$//;
        my $dbdir = "/home/$username/.sqlite"; 
        if ( not -d $dbdir )
        {
            mkdir($dbdir) or die "Can't make dbfile directory: $dbdir\n";
        }
        $dbfile = "$dbdir/monitor.dbl";
        $self->{_dbfile} = $dbfile;    
    }
    $self->logDebug("Dbfile", $dbfile);
    $self->create_db();
    
    return $dbfile;
}



=head2

    SUBROUTINE      sqlfile    

    PURPOSE
    
		RETURN THE sqlfile LOCATION

=cut

sub sqlfile
{
	my $self		=	shift;

	my $sqlfile    =	$self->{_sqlfile};

    my $sql = qq{CREATE TABLE IF NOT EXISTS monitor
(
	processid	VARCHAR(20) NOT NULL,
	command     TEXT,
	outputdir   TEXT,
	datetime	DATETIME NOT NULL,
	status		TEXT,
	PRIMARY KEY (processid, datetime)
)};

	my $fileroot = $self->{_conf}->{FILEROOT};
	
    if ( not defined $sqlfile or not $sqlfile )
    {
        my $username = `whoami`;
        $username =~ s/\s+$//;
        my $sqldir = "/home/$username/.sqlite"; 
        if ( not -d $sqldir )
        {
            mkdir($sqldir) or die "Can't make sqlfile directory: $sqldir\n";
        }
        $sqlfile = "$sqldir/monitor.sql";
        $self->{_sqlfile} = $sqlfile;    
    }
    $self->logDebug("sqlfile", $sqlfile);
 
    open(SQLFILE, ">$sqlfile") or die "Can't open sql file for writing: $sqlfile\n";
    print SQLFILE $sql;
    close(SQLFILE);
    
    return $sqlfile;
}

=head2

	SUBROUTINE 		tempdir
	
	PURPOSE
	
		GET A WORLD-WRITABLE TEMP DIR
		
=cut


sub tmpdir
{
	my $self		=	shift;
	
	my $tmpdir = $self->{_tmpdir};
	return $tmpdir if defined $tmpdir;
	
    #### PRINT SQLFILE TO /tmp AND LOAD
	my $tmpdirs = [ "/tmp", "/var/tmp", "/usr/tmp"];
    foreach my $dir ( @$tmpdirs )
	{
		if ( -d $dir and -w $dir )
		{
			$self->{_tmpdir} = $dir;
			return $dir;
		}
	}
	
	return undef;
}


=head2

    SUBROUTINE      register
    
    PURPOSE
    
		REGISTER A CLUSTER JOB IN THE SQLITE DATABASE
        
=cut

sub register
{
	my $self		=	shift;

	my $pid          =	$self->{_pid};
	my $command     =	$self->{_command};
	my $outputdir   =	$self->{_outputdir};

    #### GET DB FILE
	my $dbfile      =	$self->dbfile();

    #### CONNECT TO SQLITE DATABASE
    my $dbh = DBI->connect( "dbi:SQLite:$dbfile" ) || die "Cannot connect: $DBI::errstr";
    
    #### CREATE DBase::SQLite OBJECT
    my $db = DBase::SQLite->new(    {   'DBH' => $dbh   }   );

	#### INSERT ENTRY INTO TABLE
	my $now = "DATETIME('NOW')";
	$now = "NOW()" if $self->get_conf()->getKey("database", 'DBTYPE') =~ /^MYSQL$/i;
    my $query = qq{INSERT INTO monitor VALUES ( '$pid', '$command', '$outputdir', $now), 'running' )};
    $self->logDebug("$query");
    my $success = $self->db()->do($query);
    $self->logDebug("Success", $success);

    return $success;
}



=head2

    SUBROUTINE      monitor
    
    PURPOSE
    
		MONITOR A PBS JOB AND RETURN 1 WHEN COMPLETED:

		Job id                    Name             User            Time Use S Queue
		------------------------- ---------------- --------------- -------- - -----
		14887.kronos              test.sh          syoung          00:00:00 R psmall  

=cut


sub monitor
{
	my $self		=	shift;

	my $pid    =	$self->{_pid};
    my $qstat = $self->{_qstat};
	my $sleep = $self->{_sleep};
	$self->logDebug(".monitor()");
	$self->logDebug("id", $pid);
	$self->logDebug("qstat", $qstat);
	$self->logDebug("sleep", $sleep);

    #### REGISTER THIS JOB
    $self->register();
	#Job id                    Name             User            Time Use S Queue
	#------------------------- ---------------- --------------- -------- - -----
	#14887.kronos              test.sh          syoung          00:00:00 R psmall  
	
	my $completed = 0;
    my $status;
	while ( ! $completed )
	{
        my $qstat_result = '';
        my $qstat_command = "$qstat $pid 2>&1 |";
        $self->logDebug("$qstat_command");
        open(COMMAND, $qstat_command) or die "Can't exec command: $qstat_command\n";
        while(<COMMAND>) {
            $qstat_result .= $_;
        }
        close (COMMAND);
        ### LATER:LOG pid IN /var/run OR DBFILE
        ##
        ##$pid = fork;
        #
        ##open (PID, ">/var/run/foo.pid");
        ##print PID $$;
        ##close (PID);

        #### THIS DOESN'T WORK
        ####$self->logDebug("Qstat command", $qstat_command);
        ####my $qstat_result = system "$qstat $pid";
        ####$self->logDebug("Qstat result", $qstat_result);
        
        if ( $qstat_result =~ /^qstat: Unknown Job Id/i )
        {
            $self->logDebug("Unknown Job Id: $pid. Returning undef");
            return;
        }
        
        my @lines = split "\n", $qstat_result;
        shift @lines; shift @lines;
        foreach my $line ( @lines )
        {
            next if $line =~ /^\s*$/;
            my $pid_match = $line =~ /^$pid\./;
            if ( $pid_match )
            {
                ($status) = $line =~ /^.{68}(\S+)/;
                if ( $status eq "C" )
                {
                    $completed = 1;
                }
            }
        }
        if ( not $completed )
        {
            $self->logDebug(".");
            sleep($sleep);
        }   
	}

    
#    #### GET DB FILE
#	my $dbfile      =	$self->dbfile();
#
#    #### CONNECT TO SQLITE DATABASE
#    my $dbh = DBI->connect( "dbi:SQLite:$dbfile" ) || die "Cannot connect: $DBI::errstr";
#    
#    #### CREATE DBase::SQLite OBJECT
#    my $db = DBase::SQLite->new(    {   'DBH' => $dbh   }   );
#    
#    my $query = qq{UPDATE monitor SET status = 'complete' WHERE processid = '$pid' AND datetime =  '$command', '$outputdir', 'running', $now )};
#    $self->logDebug("$query");
#    my $success = $self->db()->do($query);
#    $self->logDebug("Success", $success);
    return $status;
}




=head2

	SUBROUTINE		new
	
	PURPOSE

		CREATE A NEW self OBJECT

=cut

sub new
{
    my $class 		=	shift;
	my $arguments 	=	shift;
   
	my $self = {};
    bless $self, $class;
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);
    return $self;
}







1;




