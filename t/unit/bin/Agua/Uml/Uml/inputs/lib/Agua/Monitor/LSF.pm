package Agua::Monitor::LSF;
=head2

	PACKAGE		Agua::Monitor::LSF
	
    VERSION:        0.01

    PURPOSE
  
        1. MONITOR JOBS RUN ON A LSF (PORTABLE BATCH SCHEDULER) SYSTEM

	HISTORY
	
		0.01	Basic version
		
use LSF::Job;

use LSF::Job RaiseError => 0, PrintError => 1, PrintOutput => 0;

$job = LSF::Job->new(123456);

$job = LSF::Job->submit(-q => 'default' ,-o => '/dev/null' ,"echo hello");

$job2 = LSF::Job->submit(-q => 'default' ,-o => '/home/logs/output.txt' ,"echo world!");

@jobs = LSF::Job->jobs( -J => "/mygroup/*" );

$job2->modify(-w => "done($job)" );

$job2->del(-n => 1);

$job->top();

$job->bottom();

$exit = $job->history->exit_status;



=cut 

use strict;
use warnings;
use Carp;

use FindBin qw($Bin);
use lib "$Bin/..";

#### INTERNAL MODULES
use DBaseFactory;
#use DBase::SQLite;
use Monitor;

#### EXTERNAL MODULES
use POSIX;
use Data::Dumper;
use DBI;

#### USE LSF
use LSF::Job;
use LSF::Job RaiseError => 0, PrintError => 1, PrintOutput => 0;

#### EXPORTER
require Exporter;
our @ISA = 'Monitor';
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
our $QUEUE = "normal";
our $ERROR_REGEX = "^ERROR";
our $JOBID_REGEX = "^\\s*(\\d+)";


=head2

	SUBROUTINE		summary
	
	PURPOSE
	
		RETURN A SUMMARY OF ALL JOBS SO FAR SUBMITTED BY THE USER

[syoung@m1 ~]$ bacct
Line <114534>: Bad event format: JOB_FINISH 1267037765 offset[534:1]: lsfRusage 19 fields: utime stime maxrss ixrss ismrss idrss isrss minflt majflt nswap inblock oublock ioch msgsnd msgrcv nsignals nvcsw nivcsw exutime

Accounting information about jobs that are: 
  - submitted by users syoung, 
  - accounted on all projects.
  - completed normally or exited
  - executed on all hosts.
  - submitted to all queues.
  - accounted on all service classes.
------------------------------------------------------------------------------

SUMMARY:      ( time unit: second ) 
 Total number of done jobs:      61      Total number of exited jobs:   212
 Total CPU time consumed:     145.1      Average CPU time consumed:     0.5
 Maximum CPU time of a job:    14.9      Minimum CPU time of a job:     0.0
 Total wait time in queues:  1137.0
 Average wait time in queue:    4.2
 Maximum wait time in queue:   11.0      Minimum wait time in queue:    2.0
 Average turnaround time:         9 (seconds/job)
 Maximum turnaround time:       102      Minimum turnaround time:         2
 Average hog factor of a job:  0.01 ( cpu time / turnaround time )
 Maximum hog factor of a job:  0.20      Minimum hog factor of a job:  0.00
 Total throughput:             6.91 (jobs/hour)  during   39.49 hours
 Beginning time:       Mar  2 20:33      Ending time:          Mar  4 12:03

=cut

sub _summary
{
	my $self		=	shift;
	my $args		=	shift;
	$self->logDebug("Agua::Monitor::LSF::_summary(command)");

	my $command = "bacct";
	$self->logDebug("command", $command);
	my $summary = `bacct`;

	$self->{_summary} = $summary;
	
	return $summary;
}

=head2

	SUBROUTINE		summary
	
	PURPOSE
	
		RETURN A SUMMARY OF THE USER'S CLUSTER USAGE TO DATE

=cut

sub get_summary
{
	my $self		=	shift;
	my $refresh	=	shift;

	return $self->{_summary} if defined $self->{_summary} and not $refresh;

	return $self->_summary();	
}



=head2

	SUBROUTINE		get_jobid
	
	PURPOSE
	
		RETURN THE JOB ID OF A SUBMITTED JOB
		
=cut

sub get_jobid
{
	my $self		=	shift;

	$self->logDebug("Agua::Monitor::LSF::get_jobid(command)");
	$self->logDebug("self: ");
	my $job = $self->get_job();
	my $job_id = $job->id();
	$self->logDebug("job_id", $job_id);
	
	return $job_id;	
}





=head2

	SUBROUTINE		submitJob
	
	PURPOSE
	
		SUBMIT A JOB TO AN LSF CLUSTER AND RETURN ITS JOB ID
		
=cut

sub submitJob
{
	my $self		=	shift;
	my $args		=	shift;
	$self->logDebug("Agua::Monitor::LSF::submitJob(command)");
	$self->logDebug("args", $args);

	my $queue = $args->{queue};
	my $scriptfile = $args->{scriptfile};
	$self->logDebug("Scriptfile not defined. Returning null") and return if not defined $args->{scriptfile};
	$args->{stdoutfile} = "/dev/null" if not defined $args->{stdoutfile};
	$args->{stderrfile} = "/dev/null" if not defined $args->{stderrfile};

	my $job = $self->submit($args);
	
	my $job_id = $job->id();
	$self->set_jobid($job_id);
	$self->logDebug("job_id", $job_id);
	
	return $job_id;	
}


=head2

	SUBROUTINE		submit
	
	PURPOSE
	
		SUBMIT A JOB TO AN LSF CLUSTER EITHER AS A SINGLE JOB,
		
		OR AS AN ARRAY JOB IF THE batch ARGUMENT IS NON-EMPTY

=cut

sub submit
{
	my $self		=	shift;
	my $args		=	shift;
	$self->logDebug("Agua::Monitor::LSF::submit(command)");
	$self->logDebug("args", $args);

	my $queue = $args->{queue};
	my $batch = $args->{batch};
	my $tasks = $args->{tasks};

	my $scriptfile = $args->{scriptfile};
	my $stdoutfile = $args->{stdoutfile};
	my $stderrfile = $args->{stderrfile};
	$stdoutfile = "/dev/null" if not defined $stdoutfile;
	$stderrfile = "/dev/null" if not defined $stderrfile;

	#### GET CPUS
	my $cpus = $self->get_cpus();
	$cpus = 1 if not defined $cpus;
	$self->logDebug("cpus", $cpus);

	#### CREATE JOB
	my $job;
	my $tries = 20;
	my $sleep = $self->get_sleep();
	$sleep = 5 if not defined $sleep;
	$self->logDebug("sleep", $sleep);
	$self->logDebug("tries", $tries);
	
	#### SUBMIT NON-BATCH JOB
	if ( not defined $batch or not $batch )
	{
		$self->logDebug("submitting ordinary (NON-BATCH) job: ");

		#### REMOVE FILES IF EXIST
		`rm -fr $stdoutfile` if -f $stdoutfile;
		`rm -fr $stderrfile` if -f $stderrfile;	

		#### TRY REPEATEDLY UNTIL SUCCESSFUL
		my $counter = 0;
		while ( not defined $job and $counter < $tries )
		{
			$counter++;

			$self->logDebug("command: bsub -n $cpus -q $queue -o $stdoutfile $scriptfile");
			
			$job = LSF::Job->submit(
				-n => $cpus,
				-q => $queue,
				-o => $stdoutfile,
				$scriptfile
			);
		}
	}
	
	#### SUBMIT BATCH JOB
	else
	{
		$self->logDebug("submitting BATCH job: ");
		$self->logDebug("queue", $queue);
		$self->logDebug("stdoutfile", $stdoutfile);
		$self->logDebug("batch", $batch);
		$self->logDebug("scriptfile", $scriptfile);
		
		#### REMOVE STDOUT FILES IF EXIST
		for my $task ( 1..$tasks )
		{
			my $file = $stdoutfile;
			$file =~ s/\$LSB_JOBINDEX/$task/g;
			`rm -fr $file` if -f $file;
		}
		
		#### CREATE STDOUT DIRECTORY FOR EACH TASK
		for my $task ( 1..$tasks )
		{
			my ($outdir) = $stdoutfile =~ /^(.+?)\/[^\/]+$/;
			$outdir =~ s/\$LSB_JOBINDEX/$task/g;
			File::Path::mkpath($outdir) if not -d $outdir;
			$self->logError("Can't create outdir: $outdir") and exit if not -d $outdir;
		}

		#### TRY REPEATEDLY UNTIL SUCCESSFUL
		my $counter = 0;
		while ( not defined $job and $counter < $tries )
		{
			$counter++;

			$stdoutfile =~ s/\$LSB_JOBINDEX/%I/g;
			$self->logDebug("command: bsub -n $cpus -q $queue -o $stdoutfile -J $batch $scriptfile");

			#### CONVERT '$LSB_INDEX' TO '%I' IN STDOUTFILE FOR SUBMIT COMMAND
			#$stdoutfile =~ s/\$PBS_TASKNUM/$task/g;

			$job = LSF::Job->submit(
				-n => $cpus,
				-q => $queue,
				-o => $stdoutfile,
				-J => $batch,
				$scriptfile
			);
			
			sleep($sleep);
		}
	}
	
	#### SET self->JOB
	$self->{_job} = $job;

	$self->logDebug("job", $job);

	return $job;	
}

=head2

	SUBROUTINE		jobIds
	
	PURPOSE
	
		RETURN THE LIST OF ALL JOB IDS CURRENTLY AVAILABLE THROUGH
		
		THE bhist COMMAND
		
=cut

sub jobIds
{
	my $self		=	shift;
	$self->logDebug("Agua::Monitor::LSF::jobIds()");	;

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
	$self->logDebug("Agua::Monitor::LSF::jobStatus(pids, qstat, sleep)");
	$self->logDebug("job_id", $job_id)  if defined $job_id;
	
	#### GET LIST OF JOBS IN QSTAT
	my $lines = $self->jobLines();
	#### METHOD 1
	my $status;
    foreach my $line ( @$lines )
    {
		$self->logDebug("CHECKING job_id $job_id against line", $line);
		my $job_id_match = $line =~ /^$job_id/;
		if ( $job_id_match )
		{
			
			$self->logDebug("MATCHED line", $line);
	
			$status = $self->lineStatus($line);
			$self->logDebug("status", $status);
			
			last;
        }
    }

	#### METHOD 2
	#my $jobcheck = $self->checkJob($job_id);	
	$self->logDebug("Returning status", $status)  if defined $status;
    return $status;
}


=head2

	SUBROUTINE		lineStatus
	
	PURPOSE
	
		RETURN THE STATUS ENTRY FOR A bjobs LINE

		JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
		5031    syoung  RUN   priority   m1          n0143       test1      Mar  5 14:19

=cut

sub lineStatus
{
	my $self		=	shift;
	my $line		=	shift;
	$self->logDebug("Agua::Monitor::LSF::lineStatus()");
	$self->logDebug("line", $line);
	
	my ($status) = $line =~ /^\s*\S+\s+\S+\s+(\S+)/;
	$self->logDebug("status", $status);
	
	return "running" if $status eq "RUN";
	return "queued" if $status eq "PEND";
	return "completed" if $status eq "EXIT";
	return "error" if $status eq "ERROR";
}



=head2

    SUBROUTINE      statusHash    

    PURPOSE
    
		HASH JOBID AGAINST STATUS

=cut

sub statusHash
{
	my $self		=	shift;
	$self->logDebug("Agua::Monitor::LSF::statusHash()");

	my $joblines = $self->jobLines();
	$self->logDebug("joblines: @$joblines");

	my $statusHash;
	foreach my $line ( @$joblines )
	{
		if ( $line =~ /^(\d+)/ )
		{
			$self->logDebug("DOING line", $line);
			$statusHash->{$1} = $self->lineStatus($line);
		}
	}
	
	$self->logDebug("statusHash", $statusHash);
	
	return $statusHash;
}





=head2

	SUBROUTINE		jobLines
	
	PURPOSE
		
		RETURN THE LINES FROM A bjobs CALL

		bjobs
		JOBID   USER    STAT  QUEUE      FROM_HOST   EXEC_HOST   JOB_NAME   SUBMIT_TIME
		5031    syoung  RUN   priority   m1          n0143       test1      Mar  5 14:19

		NB: bhist DOESN'T PROVIDE STATUS DIRECTLY - HAVE TO INFER FROM 'PEND' AND 'RUN'

		bhist 5031
		Summary of time in seconds spent in various states:
		JOBID   USER    JOB_NAME  PEND    PSUSP   RUN     USUSP   SSUSP   UNKWN   TOTAL
		5031    syoung  test1     2       0       8       0       0       0       10  
	
=cut

sub jobLines
{
	my $self		=	shift;
	my $args		=	shift;
	$self->logDebug("Agua::Monitor::LSF::jobLines()");

	$args = { '-a' => 1 } if not defined $args; 
	my $job = $self->get_job();
	$self->logDebug("No current job (i.e., self->{_job}. Returning null") and return if not defined $job;

	#### GET bjobs INFO
	my $command = "bjobs -a";
	my $result = `$command`;
	#### GET LINES	
	my @lines = split "\n", $result;
	my $jobs_list = [];
	foreach my $line ( @lines )
	{
		use re 'eval';# EVALUATE AS REGEX
		push @$jobs_list, $line if $line =~ /$JOBID_REGEX/;
		no re 'eval';# EVALUATE AS REGEX
	}
	return $jobs_list;
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
	$self->logDebug("Agua::Monitor::LSF::remainingJobs(job_ids)");
	$self->logDebug("job_ids: @$job_ids");

    my $qstat   =   $self->get_qstat();
    
	#### GET LIST OF JOBS IN QSTAT
	my $lines = $self->jobLines();
	
	for ( my $i = 0; $i < @$job_ids; $i++ )
    {
		my $job_id = $$job_ids[$i];
		$self->logDebug("Checking match job_id", $job_id);

		my $jobstatus = $self->jobStatus($job_id);
		$self->logDebug("jobstatus", $jobstatus);
		
		if ( not defined $jobstatus or not $jobstatus or $jobstatus eq "completed" )
		{
			$self->logDebug("JOB completed", $job_id);
			splice @$job_ids, $i, 1;
		}
    }

	$self->logDebug("remaining job_ids (", scalar(@$job_ids), " left): @$job_ids");

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
	$self->logDebug("Agua::Monitor::LSF::jobLineStatus(pids, qstat, sleep)");
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

	SUBROUTINE		checkJob
	
	PURPOSE
	
		RETURN A HASH OF THE JOB'S STATUS

=cut

sub checkJob
{
	my $self		=	shift;
	my $job_id		=	shift;

	$self->logDebug("Agua::Monitor::LSF::checkJob(job_id)");
	$self->logDebug("job_id", $job_id);
	my $job;
	if ( defined $job_id )
	{
		$job = LSF::Job->new($job_id);
	}
	else
	{
		$job = $self->get_job();
	}
	$self->logError("job not defined. Exiting.") and exit if not defined $job;

	return $job->history->exit_status;
}





################################################################################
################################################################################
###########################	       old monitor       ###########################
################################################################################
################################################################################


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

    $self->logDebug("(args)");
    $self->logDebug(": $");
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
) or die "Can't create database object to create database: $conf->getKey("database", "DATABASE"). $!\n";

    #my $db = DBaseFactory->new( "SQLite", { 'DBFILE' => $dbfile } ) or die "Can't open DB file '$dbfile': $!\n";
    #if ( not defined $db )
    #{
    #    die "Database object not defined. Tried to access sqlite DB file: $dbfile\n";
    #}    
	
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
    
		MONITOR A LSF JOB AND RETURN 1 WHEN COMPLETED:

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
	$self->logDebug("Monitor.monitor()");
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
   
	$self->logDebug("(self, arguments)");

	my $self = {};
    bless $self, $class;	

	if ( defined $arguments->{jobid} and $arguments->{jobid} )
	{
		$self->logDebug("arguments->jobid", $arguments->{jobid});
		$self->{_job} = LSF::Job->new($arguments->{jobid});
	}

	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);
    return $self;
}







1;




