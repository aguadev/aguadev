package Agua::Common::SGE;
use Moose::Role;

=head2

	PACKAGE		Agua::Common::SGE
	
	PURPOSE
	
		CLUSTER METHODS FOR Agua::Common
		
=cut
#our $LOG = 0;
##$LOG = 1;

# STRINGS
has 'project'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'workflow'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'qmasterport'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'execdport'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'sgeroot'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);
has 'masterip'	=> ( is  => 'rw', 'isa' => 'Str|Undef', required	=>	0	);

# OBJECTS
has 'json'		=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'envars'	=> ( isa => 'HashRef|Undef', is => 'rw', required => 0 );

use Data::Dumper;
use File::Path;

sub getEnvars {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	
	$username 		=	$self->username() if not defined $username;
	$cluster 		=	$self->cluster() if not defined $cluster;

	return $self->envars() if $self->can('envars') and $self->envars();
	my $qmasterport;
	my $execdport;
	my $sgeroot;
	my $queue;
	my $project		=	$self->project();
	my $workflow	=	$self->workflow();
	my $sgecell 	= 	$cluster if defined $cluster;
	$sgecell = '' if not defined $sgecell;

	#### IF THE INITIAL (PARENT) WORKFLOW JOB WAS RUN LOCALLY MUST PICK UP THE SGE 
	#### ENVIRONMENT VARIABLES FROM THE SHELL IN ORDER TO IDENTIFY WHERE TO SUBMIT JOBS TO
	$self->logDebug("Retrieving environment variables from shell");
	$username 		= 	$ENV{'USERNAME'} if defined $ENV{'USERNAME'} and not defined $username;
	$cluster 		= 	$ENV{'CLUSTER'} if defined $ENV{'CLUSTER'};
	$qmasterport 	= 	$ENV{'SGE_QMASTER_PORT'};
	$execdport 		= 	$ENV{'SGE_EXECD_PORT'};
	$sgecell 		= 	$ENV{'SGE_CELL'} if not defined $sgecell;
	$sgeroot 		= 	$ENV{'SGE_ROOT'};
	$queue 			= 	$ENV{'QUEUE'};
	$project 		= 	$ENV{'PROJECT'} if not defined $project;
	$workflow 		= 	$ENV{'WORKFLOW'} if not defined $workflow;
	$sgeroot 		=	$self->conf()->getKey("cluster", 'SGEROOT') if not defined $sgeroot;

	#### SET USERNAME AND CLUSTER IF NOT DEFINED
	$self->username($username) if not $self->username();
	$self->cluster($sgecell) if not $self->cluster();
	$self->queue($queue) if not $self->queue();

	#### THIS JOB IS THE INITIAL (PARENT) WORKFLOW JOB LAUNCHED BY THE SYSTEM.
	#### IT RETRIEVES THE SGE PORT VARIABLES FROM THE DB
	if ( defined $username and $username
		and defined $sgecell and $sgecell
		and defined $self->db()->dbh() )
	{
		$self->logDebug("Retrieving environment variables from database");
		my $query = qq{SELECT qmasterport
FROM clustervars
WHERE username = '$username'
AND cluster = '$sgecell'};
		$self->logDebug("$query");
		$qmasterport 	= 	$self->db()->query($query);
		$execdport 		= 	$qmasterport + 1 if defined $qmasterport;
	}

	#### IF project AND workflow ARE NOT DEFINED, USE SLOTS IF FILLED
	$project = $self->project() if $self->can('project') and $self->project();
	$workflow = $self->workflow() if $self->can('workflow') and $self->workflow();

	$self->logDebug("BEFORE queue = self->queueName(username, project, workflow)");
	$self->logDebug("project", $project)  if defined $project;
	$self->logDebug("workflow", $workflow)  if defined $workflow;
	$queue = $self->queueName($username, $project, $workflow) if defined $project and defined $workflow;
	$self->queue($queue) if defined $queue and not $self->queue();

	$self->logDebug("queue", $queue) if defined $queue;
	$self->logDebug("username", $username) if defined $username;
	$self->logDebug("qmasterport", $qmasterport) if defined $qmasterport;
	$self->logDebug("execdport", $execdport) if defined $execdport;
	$self->logDebug("sgeroot", $sgeroot) if defined $sgeroot;
	$self->logDebug("queue", $queue) if defined $queue;
	$self->logDebug("queue not defined") if not defined $queue;
	
	my $envars = {};
	$envars->{qmasterport} 	= $qmasterport;
	$envars->{execdport} 	= $execdport;
	$envars->{sgeroot} 		= $sgeroot;
	$envars->{sgecell} 		= $sgecell;
	$envars->{username} 	= $username;	
	$envars->{queue} 		= $queue;	
	$envars->{project} 		= $project;	
	$envars->{workflow} 	= $workflow;	
	$envars->{tostring} 	= "export SGE_QMASTER_PORT=$qmasterport; " if defined $qmasterport;
	$envars->{tostring} 	.= "export SGE_EXECD_PORT=$execdport; " if defined $execdport;
	$envars->{tostring} 	.= "export SGE_ROOT=$sgeroot; " if defined $sgeroot;
	$envars->{tostring} 	.= "export SGE_CELL=$sgecell; " if defined $sgecell;
	$envars->{tostring} 	.= "export USERNAME=$username; " if defined $username;
	$envars->{tostring} 	.= "export QUEUE=$queue; " if defined $queue;
	$envars->{tostring} 	.= "export PROJECT=$project; " if defined $project;
	$envars->{tostring} 	.= "export WORKFLOW=$workflow; " if defined $workflow;
	$self->logDebug("envars->{tostring}", $envars->{tostring});

	$self->envars($envars);

	return $envars;
}

sub createQueuefile {
	my $self		=	shift;
	my ($queue, $queuefile, $parameters) = @_;

	my ($queuefiledir) = $queuefile =~ /^(.+?)\/([^\/]+)$/;
	$self->logDebug("queuefiledir", $queuefiledir);
	File::Path::mkpath($queuefiledir) if not -d $queuefiledir;
	$self->logError("Can't create queuefiledir: $queuefiledir") and exit if not -d $queuefiledir;

	my $contents = $self->setQueuefileContents($queue, $parameters);
	open(OUT, ">$queuefile") or die "Agua::Common::SGE::createQueuefile    Can't open queuefile: $queuefile\n";
	print OUT $contents;
	close(OUT) or die "Agua::Common::SGE::createQueuefile    Can't close queuefile: $queuefile\n";

	return $queuefile;
}


sub getQueueConf {
	my $self		=	shift;
	my $queue		=	shift;

	$queue = '' if not defined $queue;
	my $sgebin	=	$self->sgebinCommand();
	my $envars 	=	$self->getEnvars($self->username(), $self->cluster()); 
	my $qconf = "$envars->{tostring} $sgebin/qconf -sq $queue";
	$self->logDebug("$qconf");
	my $contents = `$qconf`;

	return if not defined $contents or not $contents;
	return $contents;
}

sub getQueuefileTemplate {
	return qq{	
	qname                 default
	hostlist              \@allhosts
	seq_no                0
	load_thresholds       np_load_avg=20
	suspend_thresholds    NONE
	nsuspend              1
	suspend_interval      00:05:00
	priority              0
	min_cpu_interval      00:05:00
	processors            UNDEFINED
	qtype                 BATCH INTERACTIVE
	ckpt_list             NONE
	pe_list               make
	rerun                 FALSE
	slots                 1
	tmpdir                /tmp
	shell                 /bin/bash
	prolog                NONE
	epilog                NONE
	shell_start_mode      posix_compliant
	starter_method        NONE
	suspend_method        NONE
	resume_method         NONE
	terminate_method      NONE
	notify                00:00:60
	owner_list            NONE
	user_lists            NONE
	xuser_lists           NONE
	subordinate_list      NONE
	complex_values        NONE
	projects              NONE
	xprojects             NONE
	calendar              NONE
	initial_state         default
	s_rt                  INFINITY
	h_rt                  INFINITY
	s_cpu                 INFINITY
	h_cpu                 INFINITY
	s_fsize               INFINITY
	h_fsize               INFINITY
	s_data                INFINITY
	h_data                INFINITY
	s_stack               INFINITY
	h_stack               INFINITY
	s_core                INFINITY
	h_core                INFINITY
	s_rss                 INFINITY
	h_rss                 INFINITY
	s_vmem                INFINITY
	h_vmem                INFINITY
};

}

sub setQueuefileContents {
	my $self		=	shift;
	my $queue		=	shift;
	my $parameters	=	shift;

	$self->logDebug("queue", $queue);
	$self->logDebug("parameters", $parameters);
	
	#### GET THE EXISTING TEMPLATE FOR THIS QUEUE IF EXISTS
	my $template = $self->getQueuefileTemplate($queue);

	#### SET PARAMETERS
	foreach my $key ( keys %$parameters )
	{
		my $value = $parameters->{$key};
		$self->logDebug("key->value: $key -> $value");
		$template =~ s/$key(\s+)(\S+)/$key$1$value/ms;
	}
	return $template;
}

sub getQueue {
	my $self		=	shift;
	my $queue		=	shift;
	$self->logError("queue not defined") and exit if not defined $queue;

	my $envars = $self->getEnvars($self->username(), $self->cluster());
	my $sgebin = $self->sgebinCommand();
	my $qconf = "$envars->{tostring} $sgebin/qconf -sq $queue";
	$self->logDebug("$qconf");
	return `$qconf`;
}

sub _addQueue  {
	my $self		=	shift;
	my ($queue, $queuefile, $parameters) = @_;
	
	$self->createQueuefile($queue, $queuefile, $parameters);
	
	my $envars = $self->getEnvars($self->username(), $self->cluster());
	my $sgebin = $self->sgebinCommand();

	#### ADD THE QUEUE
	my $addqueue = "$envars->{tostring}";
	$addqueue .= "$sgebin/qconf -Aq $queuefile";
	$self->logDebug("addqueue", $addqueue);
	print `$addqueue`;
}


sub modifyQueue  {
	my $self		=	shift;
	my ($queue, $queuefile) = @_;
	
	$self->logError("Can't find queuefile: $queuefile") and exit if not -f $queuefile;

	#### ADD THE QUEUE
	my $modify = "qconf -Mq $queuefile";
	$self->logDebug("modify", $modify);
	print `$modify`;
}



sub _removeQueue {
	my $self		=	shift;
	my $queue		=	shift;
	my $queuefile	=	shift;
	my $running		=	shift;
	$self->logDebug("Agua::Common::SGE::_removeQueue(queue, queuefile, running)");
	$self->logDebug("queue", $queue);
	$self->logDebug("queuefile", $queuefile);
	$self->logDebug("running", $running);
	
	#### REMOVE queuefile
	my $remove = "rm -fr $queuefile";
	$self->logDebug("$remove");
	print `$remove`;	
	$self->logDebug("Can't remove queuefile", $queuefile) if -f $queuefile;
	
	#### RETURN IF NOT FUNNING
	return if not $running;
	
	my $sgebin = $self->sgebinCommand();
	$self->logDebug("sgebin", $sgebin);

	#### DELETE ANY JOBS RUNNING IN THE QUEUE
	$self->deleteQueueJobs($sgebin, $queue);

	#### DELETE THE QUEUE USING qconf
	my $delete = "$sgebin/qconf -dq $queue";
	$self->logDebug("$delete");
	print `$delete`;
}

sub queueExists {
	my $self		=	shift;
	my $queue		=	shift;

	$self->logDebug("Agua::Common::SGE::queueExists(queue, queuefile)");
	$self->logDebug("queue", $queue);

	my $sgebin = $self->sgebinCommand();
	$self->logDebug("sgebin", $sgebin);
	my $queuelist = `$sgebin/qconf -sql`;
	my @queues = split "\n", $queuelist;
	for ( my $i = 0; $i < $#queues + 1; $i++ )
	{
		$self->logDebug("queues[$i]", $queues[$i]);
		$self->logDebug("Returning 1 because queues[$i] eq $queue");
		return 1 and last if $queues[$i] eq $queue;
	}
	
	return 0;
}

sub queueName {
	my $self		=	shift;
	my $username	=	shift;
	my $project		=	shift;
	my $workflow	=	shift;

	return if not defined $username or not defined $project or not defined $workflow;
	return "$username-$project-$workflow";	
	#my $queue;
	#my $json	=	$self->json();
	#if ( defined $json and	$json )	{
	#	$queue 	= $json->{username} . "-" . $json->{project} . "-" . $json->{workflow}; 
	#}
	#else {
	#	$queue 	= $self->username() . "-" . $self->project() . "-" . $self->workflow(); 
	#}
	#
	#return $queue;
}



sub deleteQueueJobs {
	my $self		=	shift;
	my $sgebin		=	shift;
	my $queue		=	shift;
	
	my $qstat = "$sgebin/qstat -q $queue";
	$self->logDebug("$qstat");
	my @jobs = `$qstat`;
	foreach my $job ( @jobs )
	{
		next if not $job =~ /^\s+(\d+)\s+/;
		my $jobid = $1;
		my $delete = "$sgebin/qdel $jobid";
		$self->logDebug("$delete");
		print `$delete`;
	}
}

sub getHostlist {
	my $self	=	shift;
	
	$self->logDebug("Agua::Common::SGE::getHostlist()");

	my $command = "qconf -sel";
	my $hosts = `$command`;
	$self->logDebug("hosts: @$hosts");
	
	my $hostlist = join ",", @$hosts;
	$self->logDebug("hostlist", $hostlist);
	
	return $hostlist;
}

sub addPE {
	my $self		=	shift;
	my ($pe, $pefile, $slots) = @_;
	$self->logDebug("pefile", $pefile); 

	my ($pefiledir) = $pefile =~ /^(.+?)\/([^\/]+)$/;
	$self->logDebug("pefiledir", $pefiledir);
	File::Path::mkpath($pefiledir) if not -d $pefiledir;
	$self->logError("Can't create pefiledir: $pefiledir") and exit if not -d $pefiledir;
	
	#### BACKUP IF EXISTS
	$self->backupFile($pefile) if -f $pefile;
	
	open(OUT, ">$pefile") or die "Agua::Common::SGE::addPE    Can't open pefile: $pefile\n";
	my $contents = $self->setPEFileContents($pe, $slots);
	$self->logDebug("contents", $contents);
	print OUT $contents;
	close(OUT) or die "Agua::Common::SGE::addPE    Can't close pefile: $pefile\n";
	$self->logDebug("pefile", $pefile);
	
	#### ADD THE QUEUE
	my $add = "qconf -Ap $pefile";
	$self->logDebug("add", $add);
	print `$add`;	

} ####	addPE

sub setPEFileContents {
	my $self		=	shift;
	my $pe			=	shift;
	my $slots		=	shift;
	
	# OPTIONAL ENTRIES:
    # slots              AUTO

	return qq{	
    pe_name            $pe
    user_lists         arusers
    slots              $slots
    xuser_lists        NONE
    start_proc_args    /bin/true
    stop_proc_args     /bin/true
    allocation_rule    \$pe_slots
    control_slaves     TRUE
    job_is_first_task  FALSE
    urgency_slots      min
    accounting_summary TRUE\n};
}

sub addPEToQueue {
	my $self		=	shift;
	my ($pe, $queue, $queuefile) = @_;
	$self->logDebug("pe", $pe);
	$self->logDebug("queue", $queue);
	$self->logDebug("queuefile", $queuefile);

	#### ADD threaded PE TO default QUEUE'S pe_list:
	my $contents = $self->addPEQueuefileContents($pe, $queue, $queuefile);
	
	#### PRINT MODIFIED CONTENT TO QUEUE CONF FILE
	open(OUT, ">$queuefile") or die "Monitor::SGE::addPEToQueue    Can't write to queuefile: $queuefile\n";
	print OUT $contents;
	close(OUT) or die "Monitor::SGE::addPEToQueue    Can't close queuefile: $queuefile\n";
	
	$self->modifyQueue($queue, $queuefile);
}

sub addPEQueuefileContents {
	my $self		=	shift;
	my ($pe, $queue, $queuefile) = @_;
	$self->logDebug("pe", $pe);
	$self->logDebug("queuefile", $queuefile);

	my $contents;
	$contents = $self->getFileContents($queuefile) if -f $queuefile and not -z $queuefile;
	$contents = $self->setQueuefileContents($queue)
		if not -f $queuefile or -z $queuefile or $contents =~ /^\s*$/;

	#### BACKUP QUEUEFILE IF ITS PRESENT AND NON-EMPTY
	$self->backupFile($queuefile) if -f $queuefile and not -z $queuefile and $contents !~ /^\s*$/;
	$self->logDebug("contents", $contents);

	if ( $contents =~ /^(.+)\n(\s*pe_list\s+)([^\n]+)\n(.+)$/ms )
	{
		$contents = $1 . "\n". $2 . $3 . " " . $pe . "\n" . $4 ;
	}	
	$self->logDebug("contents", $contents);

	return $contents;	
}

sub removePE {
	my $self		=	shift;
	my ($pe, $pefile) = @_;

	$self->logDebug("Agua::Common::SGE::removePE(pe, pefile)");
	$self->logDebug("pe", $pe);
	$self->logDebug("pefile", $pefile);

	#### DELETE THE QUEUE USING qconf
	my $delete = "qconf -dq $pe";
	$self->logDebug("delete", $delete);
	print `$delete`;	

	#### REMOVE THE QUEUEFILE
	my $remove = "rm -fr $pefile";
	$self->logDebug("remove", $remove);
	print `$remove`;	
}

sub backupFile {
	my $self		=	shift;
	my $filename 	=	shift;
	
	#### BACKUP FILE
	my $counter = 1;
	my $backupfile = "$filename.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$filename.$counter";
	}
	$self->logDebug("backupfile", $backupfile);
	`cp $filename $backupfile`;
	
	$self->logError("backupfile not created") and exit if not -f $backupfile;
}

sub getQueuefile {
	my $self		=	shift;
	my $queue		=	shift;
	$self->logDebug("queue", $queue);

	my $adminuser = $self->conf()->getKey("agua", 'ADMINUSER');
	$adminuser = $self->conf()->getKey('agua', "ADMINUSER") if not defined $adminuser;
	$self->logError("sgeroot not defined") and exit if not defined $adminuser;
	$self->logDebug("admin", $adminuser);
	my $fileroot = $self->getFileroot($adminuser);
	my $queuefile = "$fileroot/.sge/conf/$queue.conf";
	$self->logDebug("queuefile", $queuefile);

	return $queuefile;
}

sub sgebinCommand {
	my $self		=	shift;
	my $username 	=	$self->username();
	my $cluster 	=	$self->cluster();
	#### SET COMMAND WITH ENVIRONMENT VARIABLES
 	my $envars = $self->getEnvars($username, $cluster);
	my $sgebin = $self->conf()->getKey("cluster", 'SGEBIN');
    my $command;	
	$command .= "$envars->{tostring}" if defined $envars and defined $envars->{tostring};
	$command .= "$sgebin";
	
	return $command;
}

sub queueStatus {
	my $self		=	shift;
	$self->logDebug("Agua::Common::SGE::queueStatus()");
	my $username 	=	$self->username();
	my $cluster 	=	$self->cluster();
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);
	
    my $qstat = $self->sgebinCommand($username, $cluster);
	$self->logDebug("qstat", $qstat);
	my ($bindir) = $qstat =~ /(\S+)$/;
	$self->logDebug("bindir", $bindir);
	$qstat .= "/qstat -f";

	return "CAN'T FIND QSTAT EXECUTABLE: $bindir" if not -d $bindir;

    my $output = `$qstat`;
	$self->logDebug("output", $output);

	
	my $summary = $self->qstatSummary($output);
	
	return $summary;
}

sub qstatSummary {
#### PARSE qstat OUTPUT INTO FORMATTED STRING
	my $self		=	shift;
	my $output		=	shift;	
    my ($nodes, $jobs);
    if ( $output =~ /PENDING JOBS/ )
    {
        ($nodes, $jobs) = $output =~ /^(.+)\n#{10,}\n.+?PENDING JOBS.+?\n#{10,}\n(.+)?$/ms;
    }
    else {
        $nodes = $output;
    }
    my $summary = "=================================================================================\n";
    $summary .= $nodes;
    return $summary if not defined $jobs;
    
    my @lines = split "\n", $jobs;
    my $jobcounts = {};
    foreach my $line ( @lines )
    {
        my ($jobname) = $line =~ /^\s*\S+\s+\S+\s+(\S+)/;
        if ( exists $jobcounts->{$jobname} )
        {
            $jobcounts->{$jobname}++;
        }
        else
        {
            $jobcounts->{$jobname} = 1;
        }
    }
    
    foreach my $key ( sort keys %$jobcounts )
    {
        $summary .= "$key: $jobcounts->{$key}\n";
    }
	
	return $summary;
}

sub qstatFailure {
#### RETURN 1 IF qstat RETURNS AN ERROR, 0 OTHERWISE
	my $self		=	shift;
	$self->logDebug("Agua::Common::SGE::qstatFailure()");
	my $sgebinCommand = $self->sgebinCommand();
	my $qstat = "$sgebinCommand/qstat";
	$self->logDebug("qstat", $qstat);
	
	my $output = $self->captureStderr($qstat);
	return 0 if not defined $output;	
	$self->logDebug("output", $output);
	$self->logDebug("Returning 1")  if $output =~ /error:/;

	return 1 if $output =~ /error:/;
	return 0;
}

sub checkSge {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	$self->logDebug("Checking SGE and will restart if stopped.");
	$self->logDebug("username", $username);
	$self->logDebug("cluster", $cluster);

	#### SET SGE PORTS
	$self->setSgePorts();
	my $qmasterport = $self->qmasterport();
	my $execdport = $self->execdport();
	
	#### GET MASTER DNSNAME
	my $masterinfo = $self->getHeadnodeMasterInfo($cluster);
	$self->logDebug("masterinfo", $masterinfo);
	return 0 if not defined $masterinfo;
	
	my $mastername = $masterinfo->{fqdn};
	$self->logDebug("mastername", $mastername);

	#### SET MASTER OPS Agua::Ssh OBJECT
	$self->setMasterOpsSsh($mastername);	

	##### CHECK SGE IS RUNNING ON MASTER THEN HEADNODE
	$self->checkMasterSge($qmasterport, $execdport);
	$self->checkHeadnodeSge($execdport);
	
	return 1;
}

sub checkHeadnodeSge {
=head2

SUBRO8UTINE 	checkHeadnodeSge

PURPOSE

	IF SGE STOPPED OR QSTAT FAILS, RESTART SGE ON HEADNODE:
	
	1. KILL EXECD ON HEADNODE
	
	2. START EXECD ON HEADNODE

=cut
	my $self		=	shift;
	my $execdport	=	shift;
	$self->logDebug("Agua::Workflow::checkHeadnodeSge(cluster, execdport)");
	$self->logDebug("execdport", $execdport);

	#### RETURN IF EXEC DAEMON IS RUNNING
	my $execd_running = $self->head()->ops()->execdRunning($execdport);
	$self->logDebug("BEFORE execd_running", $execd_running);

	#### CHECK IF QSTAT FAILS
	my $qstat_failure = $self->qstatFailure();
	$self->logDebug("qstat_failure", $qstat_failure);

	#### RETURN IF ALL OKAY
	$self->logDebug("Returning because execd is running and there is no qstat failure")  if $execd_running and not $qstat_failure;
	return if $execd_running and not $qstat_failure;

	#### KILL EXECD IF QSTAT FAILS
	$self->stopHeadnodeSge($execd_running) if $execd_running and $qstat_failure;
	
	#### START EXEC DAEMON
	$self->startHeadnodeSge($execdport) if ($execd_running and $qstat_failure) or not $execd_running;

	#### CONFIRM HAS RESTARTED
	$execd_running = $self->head()->ops()->execdRunning($execdport);
	$self->logDebug("AFTER execd_running", $execd_running);
	$self->logError("Could not restart execd") and exit if not $execd_running;
}

sub setHeadnodeActQmaster {
#### PRINT MASTER INTERNAL DNS_NAME TO SGE_ROOT/SGE_CELL/common/act_qmaster
	my $self		=	shift;
	my $cluster		=	shift;
	my $masterip	=	shift;
	$self->logDebug("cluster", $cluster);
	$self->logDebug("masterip", $masterip);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $act_qmaster =  "$sgeroot/$cluster/common/act_qmaster";
	$self->head()->ops()->toFile($act_qmaster, $masterip);
}

sub restartHeadnodeSge {
=head2

SUBRO8UTINE 	restartHeadnodeSge

PURPOSE

	1. KILL EXECD ON HEADNODE
	
	2. START EXECD ON HEADNODE

=cut
	my $self			=	shift;
	my $execdport		=	shift;
	$self->logDebug("Agua::Workflow::restartHeadnodeSge(execdport)");
	$self->logDebug("execdport", $execdport);

	#### KILL EXECD 
	$self->stopHeadnodeSge($execdport);

	#### START EXECD
	$self->startHeadnodeSge($execdport);
}

sub stopHeadnodeSge {
	my $self		=	shift;
	my $execdport	=	shift;

	$self->head()->ops()->stopSgeProcess($execdport);
}

sub startHeadnodeSge {
	my $self		=	shift;
	my $execdport	=	shift;
	$self->logDebug("Common::SGE::startHeadnodeSge()");
	my $sgebinCommand = $self->sgebinCommand();
	my $command = "$sgebinCommand/sge_execd";
	$self->logDebug("command", $command)  if defined $command;
	$self->head()->ops()->runCommand($command);

	#### CONFIRM HAS RESTARTED
	my $execd_running = $self->head()->ops()->execdRunning($execdport);
	$self->logDebug("AFTER execd_running", $execd_running);
	$self->logError("Could not restart execd") and exit if not $execd_running;
}

sub setHeadnodeSubmit {
#### Add new master IP (long dns name) to submit hosts and admin hosts lists
	my $self		=	shift;
	my $cluster		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	my $oldname	=	shift;
	my $newname	=	shift;
    $self->logDebug("Agua::Common::SGE::setHeadnodeSubmit(cluster, oldname, newname)");
	$self->logDebug("cluster : $cluster ");
	$self->logDebug("qmasterport : $qmasterport ");
	$self->logDebug("execdport : $execdport ");
	$self->logDebug("oldname : $oldname ");
	$self->logDebug("newname : $newname ");
	
	#### SET ENVARS 
	my $envars = $self->sgeEnvars($cluster, $qmasterport, $execdport);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');

	#### REMOVE OLD IP FROM ADMIN/SUBMIT HOSTS LIST
	my $removemodes = [ '-ds', '-dh' ];
	foreach my $removemode ( @$removemodes )
	{
		my $command = "$envars $sgeroot/bin/lx24-amd64/qconf $removemode $oldname";
		$self->logDebug("command", $command);
		my $output = $self->head()->ops()->runCommand($command);
		$self->logDebug("output", $output);
	}

	#### ADD NEW IP TO ADMIN/SUBMIT HOSTS LIST
	my $addmodes = [ '-as', '-ah' ];
	foreach my $addmode ( @$addmodes )
	{
		my $command = "$envars $sgeroot/bin/lx24-amd64/qconf $addmode $newname";
		$self->logDebug("command", $command);
		my $output = $self->head()->ops()->runCommand($command);
		$self->logDebug("output", $output);
	}
}

sub sgeEnvars {
#### Add new master IP (long dns name) to submit hosts and admin hosts lists
	my $self		=	shift;
	my $cluster		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;

	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $envars = qq{export SGE_ROOT=$sgeroot; };
	$envars .= qq{export SGE_CELL=$cluster; };
	$envars .= qq{export SGE_QMASTER_PORT=$qmasterport; };
	$envars .= qq{export SGE_EXECD_PORT=$execdport; };	
	$self->logDebug("envars", $envars);
	
	return $envars;
}

sub getActQmaster {
#### PRINT MASTER INTERNAL DNS_NAME TO SGE_ROOT/SGE_CELL/common/act_qmaster
	my $self		=	shift;
	my $cluster		=	shift;
	$self->logDebug("cluster", $cluster);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $act_qmaster =  "$sgeroot/$cluster/common/act_qmaster";
	my $command = "cat $act_qmaster";
	my $masterip = `$command`;
	$masterip =~ s/\s+$//g;
	
	return $masterip;
}

sub checkMasterSge {
#### RESTART SGE ON MASTER IF STOPPED
	my $self		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	$self->logDebug("Agua::Workflow::checkMasterSge(qmasterport, execdport)");

	$self->logDebug("DOING qmaster_running = self->master()->ops()->qmasterRunning($qmasterport)");
	my $qmaster_running = $self->master()->ops()->qmasterRunning($qmasterport);
	$self->logDebug("BEFORE qmaster_running", $qmaster_running);
	my $execd_running = $self->master()->ops()->execdRunning($execdport);
	$self->logDebug("BEFORE execd_running", $execd_running);
	
	return if $qmaster_running and $execd_running;

	#### RESTART
	$self->restartMasterSge($qmasterport, $execdport);

	#### VERIFY RESTARTED
	$qmaster_running = $self->master()->ops()->qmasterRunning($qmasterport);
	$self->logDebug("AFTER qmaster_running", $qmaster_running);
	$execd_running = $self->master()->ops()->execdRunning($execdport);
	$self->logDebug("AFTER execd_running", $execd_running);
	$self->logError("Could not restart qmaster") and exit if not $qmaster_running;
	$self->logError("Could not restart execd") and exit if not $execd_running;
}

sub getPorts {
	my $self	=	shift;
	$self->logDebug("");
	
	#### SELECT UNUSED PORTS FOR SGE_QMASTER_PORT AND SGE_EXECD_PORT
	#### NB: MAX 100 CLUSTERS, QMASTER PORT RANGE: 36241-37231
	my $minmaster = 36231;
	my $maxmaster = 37231;
	my $qmasterport;
	my $execdport;
	
	#### GET THE PORTS FOR THE CLUSTER IF WE ARE SIMPLY
	#### REINITIALISING ITS 
	my $username = $self->username();
	my $cluster = $self->cluster();
	my $sgeroot =	$self->conf()->getKey("cluster", 'SGEROOT');
	
	my $query = qq{SELECT qmasterport
FROM clustervars
WHERE username = '$username'
AND cluster = '$cluster'};
	$self->logDebug("query", $query);	
	$qmasterport = $self->db()->query($query);
	$execdport = $qmasterport + 1 if defined $qmasterport;

	if ( not defined $qmasterport )
	{
		$query = qq{SELECT MAX(qmasterport)
FROM clustervars
WHERE qmasterport > $minmaster};
		$self->logDebug("$query");
	
		$qmasterport = $self->db()->query($query);
		$self->logDebug("qmasterport", $qmasterport)  if defined $qmasterport;
		$qmasterport += 10 if defined $qmasterport;
		$execdport = $qmasterport + 1 if defined $qmasterport;
	
		#### IF WE HAVE REACHED MAX PORT NUMBER, qmasterport IS UNDEFINED.
		#### IN THIS CASE, RECYCLE UNUSED PORTS IN ALLOWED RANGE
		if ( not defined $qmasterport )
		{
			my $query = qq{SELECT COUNT(qmasterport) FROM clustervars};
			my $count = $self->db()->query($query);
			if ( $count == 0 )
			{
				$qmasterport = $minmaster + 10;
			}
			else
			{
				my $query = qq{SELECT qmasterport FROM clustervars};
				$self->logDebug("$query");
				my $ports = $self->db()->queryarray($query);
				for ( my $i = 0; $i < @$ports - 1; $i++ )
				{
					if ( ($$ports[$i + 1] - $$ports[$i]) > 10 )
					{
						$qmasterport = $$ports[$i] + 10;
					}
				}
			}
			
			$execdport = $qmasterport + 1 if defined $qmasterport;
		}
	
		#### ADD NEW PORTS TO DATABASE TABLE
		$query = qq{INSERT INTO clustervars
VALUES ('$username', '$cluster', '$qmasterport', '$execdport', '$sgeroot', '$cluster')};
		$self->logDebug("$query");
		my $success = $self->db()->do($query);
		$self->logDebug("insert success", $success);
	}

	$self->logDebug("qmasterport", $qmasterport);
	$self->logDebug("execdport", $execdport);

	return $qmasterport, $execdport;	
}

sub setSgePorts {
	my $self		=	shift;
	$self->logDebug();
	
	my ($qmasterport, $execdport) = $self->getPorts();
	$self->logDebug("qmasterport", $qmasterport);
	$self->logDebug("execdport", $execdport);
	$self->qmasterport($qmasterport);
	$self->execdport($execdport);
}

#### UPDATE HEADNODE AND MASTERS IF CHANGED
sub updateHostname {
	my $self		=	shift;
	
	##### GET CURRENT HOSTNAME
	my ($oldname) = $self->head()->ops()->runCommand("hostname");	
	$self->logDebug("oldname", $oldname);

	##### GET ACTUAL LONG INTERNAL IP
	my $instanceid = $self->head()->ops()->runCommand("curl -s http://169.254.169.254/latest/meta-data/instance-id");
	$self->head()->init({
		instanceid	=>	$instanceid,
		privatekey	=>	$self->privatekey(),
		publiccert	=>	$self->publiccert()
	});

	$self->head()->getInfo();
	my $newname = $self->head()->internalfqdn();
	$self->logDebug("newname", $newname);
	return if $oldname eq $newname;

	#### SET HEADNODE HOSTNAME TEMPORARILY
	$self->setHeadnodeHostname($newname);

	#### UPDATE HEADNODE INFO IN SGE ON MASTERS
	$self->updateHeadnodeInSge($oldname, $newname);	

	#### SET HEADNODE HOSTNAME PERMANENTLY
	$self->setHeadnodeHostnamefile($newname);

}

sub updateHeadnodeInSge {
#### Add head node to submit hosts and admin hosts lists
	my $self		=	shift;
	my $oldheadname	=	shift;
	my $newheadname	=	shift;
	#### GET PORTS FOR ALL CLUSTERS
	$self->setDbh() if not defined $self->db();
	my $query = qq{SELECT * from clustervars ORDER BY username};
	my $clusterhashes = $self->db()->queryhasharray($query);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	foreach my $clusterhash ( @$clusterhashes )
	{
		my $cluster 	= $clusterhash->{cluster};
		my $username 	= $clusterhash->{username};
		my $qmasterport = $clusterhash->{qmasterport};
		my $execdport 	= $clusterhash->{execdport};

		#### GET OLD MASTER INFO STORED IN qmaster_info FILE
		my $masterinfo = $self->getHeadnodeMasterInfo($cluster);
		next if not defined $masterinfo;
		my $oldmastername 	=	$masterinfo->{fqdn};
		$self->logDebug("oldmastername", $oldmastername);

		#### GET NEW (CURRENT) MASTER INFO FROM AWS
		my $masterid = $masterinfo->{instanceid};
		$self->master()->init({
			instanceid	=>	$masterid,
			privatekey	=>	$self->privatekey(),
			publiccert	=>	$self->publiccert()
		});
		$self->master()->getInfo();
#		$self->master()->load({
#                 'status' => 'running',
#                 'reservationid' => 'r-56c97c38',
#                 'externalip' => '50.16.168.90',
#                 'blockdevices' => [
#                                     {
#                                       'volume' => 'vol-d1b798bb',
#                                       'attached' => '2011-10-24T01:35:42.000Z',
#                                       'device' => '/dev/sda1'
#                                     }
#                                   ],
#                 'privatekey' => '/nethome/admin/.keypairs/private.pem',
#                 'externalfqdn' => 'ec2-50-16-168-90.compute-1.amazonaws.com',
#                 'imageid' => 'ami-78837d11',
#                 'internalip' => '10.220.38.156',
#                 'instanceid' => 'i-98b09ef8',
#                 'availzone' => 'us-east-1a',
#                 'instancetype' => 't1.micro',
#                 'kernelid' => 'aki-0b4aa462',
#                 'internalfqdn' => 'domU-12-31-38-04-25-6E.compute-1.internal',
#                 'publiccert' => '/nethome/admin/.keypairs/public.pem',
#                 'launched' => '2011-10-24T01:35:20+0000',
#                 'securitygroup' => '@sc-syoung-microcluster',
#                 'keyname' => 'id_rsa-admin-key',
#                 'amazonuserid' => '728213020069'
#               });

		
		my $masterstatus = $self->master()->status();
		my $newmastername = $self->master()->internalfqdn();
		my $newmasterip = $self->master()->internalip();
		next if not defined $newmastername or not $newmastername;
		next if not defined $newmasterip or not $newmasterip;
		

		$self->update($username, $cluster, $qmasterport, $execdport, $oldheadname, $newheadname, $oldmastername, $newmastername, $newmasterip);	
	
	}
}

sub update {
	my $self		=	shift;
	my $username	=	shift;
	my $cluster		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	my $oldheadname 	= 	shift;
	my $newheadname 	= 	shift;
	my $oldmastername 	= 	shift;
	my $newmastername 	= 	shift;
	my $newmasterip		=	shift;
	
	#### SET ENVIRONMENT VARIABLES
	$self->getEnvars($username, $cluster);

	#### SET SSH IN MASTER Ops OBJECT
	$self->setMasterOpsSsh($newmastername);
	
	#### TURN ON FILE BACKUP IN MASTER Ops OBJECT
	$self->master()->ops()->backup(1);

	my $keypairfile = $self->setKeypairfile($username);
	#################################################
	#### UPDATE MASTER SGE IF OLD AND NEW INFO DIFFER
	if ( $newmastername ne $oldmastername )
	{
		#### UPDATE MASTER SGE
		$self->updateMasterInSge($cluster, $qmasterport, $execdport, $oldmastername, $newmastername, $newmasterip);
		
	}
	#################################################
	#### OTHERWISE, RESTART SGE ON MASTER AND HEADNODE
	else
	#elsif ( not $self->head()->ops()->execdRunning($execdport) )
	{
		#### KILL THEN START MASTER SGE DAEMONS
		$self->restartMasterSge($qmasterport, $execdport);
		
		#### KILL THEN START HEADNODE SGE EXECD
		$self->restartHeadnodeSge($execdport);
	}
	
	
	#################################################
	#### UPDATE HEADNODE IN ADMIN HOSTS LIST
	my $newname = $self->head()->internalfqdn();
	$self->setSgeSubmitHosts($cluster, $qmasterport, $execdport, $oldheadname, $newheadname);
	
	############################################
	##### UPDATE EXPORTS FROM HEADNODE TO MASTER
	
	#### UPDATE HEADNODE /etc/exports
	$self->updateHeadnodeEtcExports($oldmastername, $newmastername);
	
	### UPDATE MASTER /etc/fstab 
	$self->updateMasterEtcFstab($oldheadname, $newheadname);

	#### ENSURE CORRECT LINKS FROM MOUNTPOINTS TO '/' DIRS
	$self->setMasterMountPoints();

	#### RESTART HEADNODE NFS DAEMONS
	$self->head()->ops()->restartNfs();
	$self->master()->ops()->restartNfs();

	#### MOUNT HEADNODE SHARES ON MASTER
	$self->mountOnMaster();
}


sub updateMasterInSge {
=head

1. UPDATE HOSTNAME WITH NEW DNS_NAME ON MASTER
2. UPDATE IP AND DNS NAME IN /etc/hosts ON MASTER
3. UPDATE act_qmaster ON MASTER
4. REPLACE OLD DNS_NAME IN ADMIN HOSTS LIST ON MASTER

=cut
	my $self		=	shift;
	my $cluster		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	my $oldname 	= 	shift;
	my $newname 	= 	shift;
	my $newip		=	shift;
	$self->logDebug("cluster", $cluster);
	$self->logDebug("qmasterport", $qmasterport);
	$self->logDebug("execdport", $execdport);
	$self->logDebug("oldname", $oldname);
	$self->logDebug("newname", $newname);
	$self->logDebug("newip", $newip);
	
	#### UPDATE MASTER HOSTNAME 
	$self->setMasterHostname($newname);
	
	#### UPDATE MASTER /etc/hostname
	$self->setMasterHostnamefile($newname);
	
	### UPDATE MASTER /etc/hosts
	$self->setMasterEtcHosts();
	
	#### UPDATE MASTER act_qmaster 
	$self->setMasterActQmaster($cluster, $newname);
	
	#### UPDATE HEADNODE act_qmaster 
	$self->setHeadnodeActQmaster($cluster, $newname);
	
	#### KILL THEN START MASTER SGE DAEMONS
	$self->restartMasterSge($qmasterport, $execdport);
	
	#### UPDATE MASTER IN ADMIN HOSTS LIST
	$self->setSgeSubmitHosts($cluster, $qmasterport, $execdport, $oldname, $newname);
	
	#### RESTART HEADNODE SGE EXECD
	$self->restartHeadnodeSge($execdport);

	#### SET HEADNODE qmaster_info
	$self->setHeadnodeMasterInfo($cluster);
}

sub setMasterOpsSsh {
	my $self		=	shift;
	my $mastername	=	shift;
	$self->logDebug("mastername", $mastername);
	
	my $adminuser = $self->conf()->getKey('agua', 'ADMINUSER');
	my $keypairfile	=	$self->setKeypairfile($adminuser);
	$self->logDebug("keypairfile", $keypairfile);

	#### SET SSH
	if ( not defined $self->ssh() ) {
		$self->master()->ops()->_setSsh("root", $mastername, $keypairfile);	
	}
	else {
		$self->master()->ops()->ssh()->keyfile($keypairfile);
		$self->master()->ops()->ssh()->remotehost($mastername);
		$self->master()->ops()->ssh()->remoteuser("root");
	}
}

sub setMasterHostname {
#### PERMANENTLY SET MASTER HOSTNAME
	my $self		=	shift;
	my $hostname	=	shift;

	#### SET CURRENT HOSTNAME
	my $command = "hostname $hostname";
	$self->logDebug("command : $command ");
	$self->master()->ops()->runCommand($command);
	
	#### VERIFY HOSTNAME
	my $verify = "hostname";
	my $result = $self->master()->ops()->runCommand($verify);
	chomp($result);
	$self->logDebug("result : $result ");
	$self->logError("Could not set hostname to hostname: $hostname") and exit if not defined $result or $result ne $hostname;	
}

sub setMasterHostnamefile {
#### PERMANENTLY SET MASTER HOSTNAME
	my $self		=	shift;
	my $hostname	=	shift;

	my $hostnamefile = "/etc/hostname";
	$self->master()->ops()->toFile($hostnamefile, $hostname);	
}

sub setMasterEtcHosts {
#### UPDATE /etc/hosts, REMOVING OLD ENTRY IF EXISTS
	my $self		=	shift;
	
	my $ip = $self->master()->internalip();
	$self->logDebug("ip ", $ip);
	my $dnsname = $self->master()->internalfqdn();
	$self->logDebug("dnsname ", $dnsname);

	# EXAMPLE: 10.126.43.231 ip-10-126-43-231.ec2.internal master
	my $inserts = [ "$ip\t$dnsname\tmaster"];
	$self->logDebug("inserts : @$inserts");
	my $removes = [ "^\\S+\t\\S+\tmaster"];
	$self->logDebug("removes : @$removes");
	
	my $lines = $self->master()->ops()->removeInsertFile("/etc/hosts", $removes, $inserts);
}

sub setMasterActQmaster {
	my $self		=	shift;
	my $cluster		=	shift;
	my $dnsname		=	shift;

	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $act_qmaster = "$sgeroot/$cluster/common/act_qmaster";
	$self->logDebug("act_qmaster : $act_qmaster ");
	$self->master()->ops()->toFile($act_qmaster, $dnsname);
}


sub restartMasterSge {
	my $self			=	shift;
	my $qmasterport		=	shift;
	my $execdport		=	shift;
	$self->logDebug("DOING self->stopMasterSge($qmasterport, $execdport)");
	$self->stopMasterSge($qmasterport, $execdport);
	$self->logDebug("DOING self->startMasterSge($qmasterport, $execdport)");
	$self->startMasterSge($qmasterport, $execdport);
}
sub stopMasterSge {
	my $self		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	
	$self->master()->ops()->stopSgeProcess($qmasterport);
	$self->master()->ops()->stopSgeProcess($execdport);
}

sub startMasterSge {
	my $self		=	shift;
	my $sgebinCommand = $self->sgebinCommand();
	my $command = "$sgebinCommand/sge_qmaster";
	$self->logDebug("command", $command);
	$self->master()->ops()->runCommand($command);
	
	$command = "$sgebinCommand/sge_execd";
	$self->master()->ops()->runCommand($command);
}

sub setSgeSubmitHosts {
#### Add new master IP (long dns name) to submit hosts and admin hosts lists
	my $self		=	shift;
	my $cluster		=	shift;
	my $qmasterport	=	shift;
	my $execdport	=	shift;
	my $oldname	=	shift;
	my $newname	=	shift;
    $self->logDebug("Agua::Common::SGE::setSgeSubmitHosts(cluster, oldname, newname)");
	$self->logDebug("cluster : $cluster ");
	$self->logDebug("qmasterport : $qmasterport ");
	$self->logDebug("execdport : $execdport ");
	$self->logDebug("oldname : $oldname ");
	$self->logDebug("newname : $newname ");
		
	#### SET ENVARS 
	my $envars = $self->sgeEnvars($cluster, $qmasterport, $execdport);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	#### REMOVE OLD IP FROM ADMIN/SUBMIT HOSTS LIST
	my $removemodes = [ '-ds', '-dh' ];
	foreach my $removemode ( @$removemodes )
	{
		my $command = "$envars $sgeroot/bin/lx24-amd64/qconf $removemode $oldname";
		$self->logDebug("command", $command);
		my $output = $self->master()->ops()->runCommand($command);
		$self->logDebug("output", $output);
	}

	#### ADD NEW IP TO ADMIN/SUBMIT HOSTS LIST
	my $addmodes = [ '-as', '-ah' ];
	foreach my $addmode ( @$addmodes )
	{
		my $command = "$envars $sgeroot/bin/lx24-amd64/qconf $addmode $newname";
		$self->logDebug("command", $command);
		my $output = $self->master()->ops()->runCommand($command);
		$self->logDebug("output", $output);
	}
}

sub getHeadnodeMasterInfo {
#### PRINT MASTER INTERNAL DNS_NAME TO SGE_ROOT/SGE_CELL/common/act_qmaster
	my $self		=	shift;
	my $cluster		=	shift;
	$self->logDebug("cluster", $cluster);
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $qmaster_info =  "$sgeroot/$cluster/qmaster_info";
	$self->logDebug("qmaster_info ", $qmaster_info);

	my $contents = $self->head()->ops()->getFileContents($qmaster_info);
	$self->logDebug("contents ", $contents);

	#### qmaster_info FORMAT:	
	# ip-10-126-35-168.ec2.internal	ip-10-126-35-168	10.126.35.168	i-98b09ef8
	return if not defined $contents or not $contents =~ /^(\S+)\s+(\S+)\s+(\S+)\s*$/;
	return {
		ip			=>	$1,
		fqdn		=>	$2,
		instanceid	=>	$3
	};
}

sub setHeadnodeMasterInfo {
	my $self		=	shift;
	my $cluster		=	shift;
	$self->logError("cluster is not defined") and exit if not defined $cluster;
	$self->logError("self->master() is not defined") and exit if not defined $self->master();
	
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	my $qmaster_infofile = "$sgeroot/$cluster/qmaster_info";
	$self->logDebug("qmaster_infofile ", $qmaster_infofile);
	my $fqdn = $self->master()->internalfqdn();
	my $ip = $self->master()->internalip();
	my $instanceid = $self->master()->instanceid();
	$self->logError("fqdn is empty") and exit if not $fqdn;
	$self->logError("ip is empty") and exit if not $ip;
	$self->logError("instanceid is empty") and exit if not $instanceid;
	
	my $content = "$fqdn\t$ip\t$instanceid\n";
	$self->head()->ops()->writeFile($qmaster_infofile, $content);	
}

sub updateHeadnodeEtcExports {
	my $self			=	shift;
	my $oldmasterip		=	shift;
	my $newmasterip		=	shift;
	my $exportsfile = "/etc/exports";
	my $sourcedirs = $self->conf()->getKey('starcluster:mounts', 'SOURCEDIRS');
	$self->logDebug("sourcedirs", $sourcedirs);
	my @sources = split ",", $sourcedirs;
	my $removes = [];
	my $inserts = [];
	foreach my $sourcedir ( @sources )
	{
		push @$removes, "$sourcedir\\s+\\S+\\(async,no_root_squash,no_subtree_check,rw\\)";
		push @$inserts, "$sourcedir\t$newmasterip(async,no_root_squash,no_subtree_check,rw)";
	}

	$self->logDebug("removes", $removes);
	$self->logDebug("inserts", $inserts);

	$self->head()->ops()->replaceInFile($exportsfile, $removes, $inserts);
}

sub updateMasterEtcFstab {
#### SET /etc/fstab ENTRIES FOR STATIC MOUNTS
	my $self			=	shift;
	my $oldheaddnsname	=	shift;
	my $newheaddnsname	=	shift;
	my $file = "/etc/fstab";
	my $inserts = [];
	my $removes = [];
	my $mounts = $self->conf()->getKey('starcluster:mounts', 'MOUNTPOINTS');
	my $devicenames = $self->conf()->getKey('starcluster:mounts', 'DEVICES');
	$self->logDebug("mounts", $mounts);
	my @mountpoints = split ",", $mounts;
	my @devices = split ",", $devicenames;
	for ( my $i = 0; $i < $#mountpoints + 1; $i++ )
	{
		my $mountpoint = $mountpoints[$i];
		my $device = $devices[$i];
		#push @$inserts, "$newheaddnsname:$device  $mountpoint    nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0";
		push @$inserts, "$newheaddnsname:$device  $mountpoint    nfs     nfsvers=3,defaults 0 0";
		push @$removes, "\\s+$mountpoint\\s+nfs";
	}
	
	$self->logDebug("removes", $removes);
	$self->logDebug("inserts", $inserts);

	$self->master()->ops()->replaceInFile($file, $removes, $inserts);
}
	

sub setMasterMountPoints {
#### CREATE MOUNTPOINT DIRECTORIES AND LINKS ON MASTER
	my $self			=	shift;

	my $mounts = $self->conf()->getKey('starcluster:mounts', 'MOUNTPOINTS');
	my $mountbase = $self->conf()->getKey('starcluster:mounts', 'MOUNTBASE');
	$self->logDebug("mounts", $mounts);
	$self->logDebug("mountbase", $mountbase);
	my @mountpoints = split ",", $mounts;
	foreach my $mountpoint ( @mountpoints )
	{
		#### CREATE MOUNTPOINT DIRECTORY
		$self->master()->ops()->unmount($mountpoint, "-f");

		#### CREATE MOUNTPOINT DIRECTORY
		$self->master()->ops()->createDirectory($mountpoint);
	
		#### REMOVE LINK TARGET IF PRESENT
		my ($target) = $mountpoint =~ /^$mountbase(.+)$/;
		$self->logDebug("target", $target);
		$self->master()->ops()->removeLink($target);

		#### CREATE LINK
		$self->master()->ops()->addLink($mountpoint, $target);
	}
}

sub mountOnMaster {
	my $self			=	shift;

	my $sourceip = $self->head()->internalfqdn();	
	my $sourcedirs = $self->conf()->getKey('starcluster:mounts', 'SOURCEDIRS');
	my $mounts = $self->conf()->getKey('starcluster:mounts', 'MOUNTPOINTS');
	$self->logDebug("sourcedirs", $sourcedirs);
	my @sources = split ",", $sourcedirs;
	my @mountpoints = split ",", $mounts;
	for ( my $i = 0; $i < $#sources + 1; $i++ )
	{
		my $sourcedir = $sources[$i];
		my $mountpoint = $mountpoints[$i];
		$self->master()->ops()->mountNfs($sourcedir, $sourceip, $mountpoint);
	}
}

sub getHostname {
#### GET CURRENT HOSTNAME
	my $self		=	shift;
	my $remote		=	shift;
	my $command = "hostname";
	$command = "$remote '$command'";
	$self->logDebug("command : $command ");
	my $hostname = `$command`;
	chomp($hostname);
	$self->logDebug("hostname : $hostname ");

	return $hostname;
}

sub setHeadnodeHostname {
#### SET HOSTNAME (TEMPORARY - RESOLVED FROM /etc/hostname AT REBOOT)
	my $self		=	shift;
	my $hostname	=	shift;

	#### SET HOSTNAME
	$self->head()->ops()->runCommand("hostname $hostname");
	
	#### VERIFY HOSTNAME
	my $result = $self->head()->ops()->runCommand("hostname");
	chomp($result);
	$self->logDebug("result : $result ");
	$self->logError("Could not set hostname ($hostname), got result: $result") and exit if not defined $result or $result ne $hostname;	
}

sub setHeadnodeHostnamefile {
#### PERMANENTLY SET MASTER HOSTNAME
	my $self		=	shift;
	my $hostname	=	shift;

	my $hostnamefile = "/etc/hostname";
	$self->head()->ops()->toFile($hostnamefile, $hostname);	
}

sub rebootInstance {
	my $self		=	shift;
	my $instance	=	shift;
	
	my $instanceid = $instance->instanceid();
	$self->head()->ops()->runCommand("ec2-reboot-instanceS $instanceid");
}

#### UPDATE MASTER AND HEADNODE
sub resetMaster {
=head

	SUBROUTINE:		resetMaster.pl

	PURPOSE:
	
		CALLED BY REBOOTED MASTER NODE TO CHECK IF ITS IP HAS CHANGED
		
		OR IF THE HEADNODE'S IP HAS CHANGED, AND IF SO:
	
			1. UPDATE MASTER AND/OR HEADNODE HOSTNAMES
	
			2. UPDATE SGE ON MASTER AND HEADNODE
	
			3. UPDATE MOUNTS FROM HEADNODE ON MASTER

	INPUTS:
	
		1. MASTER CLUSTER/CELL NAME
	
		2. MASTER INSTANCE ID
		
=cut
	my $self		=	shift;
	
	##### GET HEADNODE OLD DNS NAME
	my $oldheadname = $self->head()->ops()->runCommand("hostname");
	$self->logDebug("oldheadname", $oldheadname);

	#### GET USERNAME AND PORTS
	$self->setDbh() if not defined $self->db();
	my $cluster = $self->cell();
	my $query = qq{SELECT * from clustervars WHERE cluster='$cluster'};
	$self->logDebug("query ", $query);
	my $clusterhash = $self->db()->queryhash($query);
	my $username 	= $clusterhash->{username};
	my $qmasterport = $clusterhash->{qmasterport};
	my $execdport 	= $clusterhash->{execdport};
	$self->logError("username not defined") and exit if not defined $username;
	$self->username($username);

	my $adminkey = $self->getAdminKey($username);
	$self->logDebug("adminkey", $adminkey);
	return if not defined $adminkey;
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");

	my ($privatekey, $publiccert);
	$privatekey = $self->getEc2PrivateFile($username) if not $adminkey;
	$privatekey = $self->getEc2PrivateFile($adminuser) if $adminkey;
	$publiccert = $self->getEc2PublicFile($username);

	##### GET HEADNODE NEW DNS NAME
	my $headid = $self->head()->ops()->runCommand("curl -s http://169.254.169.254/latest/meta-data/instance-id");
	$self->head()->init({
		instanceid	=>	$headid,
		privatekey	=>	$privatekey,
		publiccert	=>	$publiccert
	});
	$self->head()->getInfo();
	my $newheadname = $self->head()->internalfqdn();
	$self->logDebug("newheadname", $newheadname);
	
	#### GET MASTER OLD DNS NAME
	my $masterinfo = $self->getHeadnodeMasterInfo($cluster);
	my $oldmastername = $masterinfo->{fqdn};	
	
	#### GET MASTER NEW DNS NAME
	my $masterid = $self->masterid();
	$self->master()->init({
		instanceid	=>	$masterid,
		privatekey	=>	$self->privatekey(),
		publiccert	=>	$self->publiccert()
	});
	$self->master()->getInfo();
		
	my $masterstatus = $self->master()->status();
	$self->logDebug("masterstatus", $masterstatus) if defined $masterstatus;
	$self->logDebug("Skipping because master is not running") and return if not defined $masterstatus or $masterstatus ne "running";
	
	my $newmastername = $self->master()->internalfqdn();
	my $newmasterip = $self->master()->internalip();
	$self->logDebug("oldmastername", $oldmastername);
	$self->logDebug("newmastername", $newmastername);

	$self->update($username, $cluster, $qmasterport, $execdport, $oldheadname, $newheadname, $oldmastername, $newmastername, $newmasterip);	
}

1;

