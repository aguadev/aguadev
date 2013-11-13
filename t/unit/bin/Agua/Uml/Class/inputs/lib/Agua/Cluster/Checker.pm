package Agua::Cluster::Checker;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Data::Dumper;

##########################    CHECK OUTPUT METHODS     #########################

#### METHODS checkStatus, batchCheckfile AND printChecklog REQUIRE Jobs::getIndex

has 'min'		=> ( isa => 'Num|Undef', is => 'rw', default => 0 );
has 'max'		=> ( isa => 'Num|Undef', is => 'rw', default => 0 );
has 'maxchecks'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
sub rerun {
	my $self		=	shift;
	$self->logDebug("ELAND::rerun()");

	#### INPUTS
	my $referencedir 	=	$self->referencedir();
	my $outputdir 		=	$self->outputdir();
	my $replicates		=	$self->replicates();
	my $label 			=	$self->label();
	my $min 			=	$self->min();
	my $max 			=	$self->max();

	#### CHECK INPUTS
	die "Agua::Cluster::Checker::rerun    min not defined\n" if not defined $min;
	die "Agua::Cluster::Checker::rerun    max not defined\n" if not defined $max;
	die "Agua::Cluster::Checker::rerun    outputdir not defined\n" if not defined $outputdir;
	die "Agua::Cluster::Checker::rerun    replicates not defined\n" if not defined $replicates;
	die "Agua::Cluster::Checker::rerun    referencedir not defined\n" if not defined $referencedir;
	die "Agua::Cluster::Checker::rerun    label not defined\n" if not defined $label;

	my $dirnumbers = $self->stringToArray($replicates);

	#### GET REFERENCES -- LATER CHANGE THIS: USES chr*.vld FILES TO GET NAMES OF chr* DIRS
	my $referencefiles = $self->listReferenceFiles($referencedir, "\*\.vld");
	my $references = $self->getReferences($referencedir);
	my $overall_status = "completed";
	my $total_sublabels = '';
	my $missingfiles = [];	
	my $dubiousfiles = [];	
	foreach my $dirnumber ( @$dirnumbers )
	{
		next if $dirnumber == 1;
		
		#### SET SPLITFILE
		my $splitfile = "$outputdir/$dirnumber/splitfile.txt";
		$self->logDebug("Can't find splitfile", $splitfile)
 and exit if not -f $splitfile;
		$self->logDebug("splitfile", $splitfile);

		#### GET SPLITFILES
		my $splitfiles = $self->splitfiles($splitfile, $label);

		#### COLLECT ALL JOBS FOR THIS INPUT FILE AGAINST ALL REFERENCE FILES
		my $jobs = $self->generateBatchJobs("$outputdir/$dirnumber", $referencefiles, $splitfiles, $label);

		#### PRINT CHECKFILES
		my $outdir = $$jobs[0]->{outputdir};
		my $checkdir = "$outdir/check/$label";
		my $logfile = "$checkdir/check.log";
		$self->printCheckLog($logfile, $jobs, "$label-rerun", $outdir);

		#### PARSE THROUGH CHECK LOG FILE AND RUN ANY incomplete JOBS
		#### OPTIONS: ALL(:DEFAULT),MIN,MAX,EMPTY
		open(FILE,$logfile) or die "Agua::Cluster::Checker::rerun    Can't open logfile: $logfile\n";
		my @lines = <FILE>;
		close(FILE) or die "Agua::Cluster::Checker::rerun    Can't close logfile: $logfile\n";
		foreach my $line ( @lines )
		{
			$self->logDebug("line", $line);			
		}
	}
	$total_sublabels =~ s/,$//;
	return ($overall_status, $label, $total_sublabels, $missingfiles, $dubiousfiles);
}


sub printStatus {
	my $self		=	shift;
	my $jobs		=	shift;
	my $label		=	shift;

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

	$self->logCritical("\n------------------------------------------------------------");

	$self->logCritical("---[status $label: $status $sublabels]---");

	$self->logCritical("\n------------------------------------------------------------");

}
=head2

	SUBROUTINE		generateBatchJobs
	
	PURPOSE
	
		GENERATE LIST OF BATCH JOBS TO RUN ELAND AGAINST ALL REFERENCES
		
		USING SUBFILES OF INPUT FILES
		
=cut

sub generateBatchJobs {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $referencefiles 	=	shift;
	my $splitfiles		=	shift;
	my $label			=	shift;
	$self->logDebug("Agua::Cluster::generateBatchJobs(outputfile, referencefiles, splitfiles)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. referencefiles: " . scalar(@$referencefiles));
	$self->logDebug("No. splitfiles: " . scalar(@$splitfiles));

	#### CHECK INPUTS
	$self->logCritical("outputdir not defined or empty: $outputdir") and exit if not defined $outputdir or not $outputdir;
	$self->logCritical("referencefiles not defined or empty: $referencefiles") and exit if not defined $referencefiles or not $referencefiles;
	$self->logCritical("splitfiles not defined or empty: $splitfiles") and exit if not defined $splitfiles or not $splitfiles;
	$self->logCritical("label not defined or empty: $label") and exit if not defined $label or not $label;

	#### COLLECT ALL JOBS FOR EACH INPUT FILE AGAINST ALL REFERENCE FILES
	my $jobs = [];
	my $number_splitfiles = scalar(@$splitfiles);
	
	my $reference_counter = 0;
	foreach my $referencefile ( @$referencefiles )
	{
		$self->logDebug("referencefile", $referencefile);
		$reference_counter++;
		$self->logDebug("reference_counter", $reference_counter);
		
		#### GET REFERENCE NAME (E.G., 'chr22')
		my ($reference) = $referencefile =~ /^.+?\/([^\/]+)$/;
		$reference =~ s/\.[^\.]{2,6}$//;
		$self->logDebug("reference", $reference);

		#### SET OUTPUT DIR
		my $outdir = "$outputdir/$reference";
		File::Path::mkpath($outdir) if not -d $outdir;
		$self->logDebug("outdir", $outdir);

		#### CREATE BATCH COMMAND
		my $batch_command = $self->batchCommand($outdir, $referencefile, $splitfiles);
		$self->logDebug("batch_command: \n\n$batch_command\n\n")  if defined $batch_command;

		#### SET LABEL
		my $joblabel = "$label-$reference";
		$self->logDebug("joblabel", $joblabel);

		#### SET BATCH JOB 
		my $job = $self->setBatchJob([$batch_command], $joblabel, $outdir, $number_splitfiles);

		push @$jobs, $job;
	}
	$self->logDebug("No. jobs: " . scalar(@$jobs));

	return $jobs;
}

=head

	SUBROUTINE		check
	
	PURPOSE
	
		CHECK THAT ALL OUTPUT FILES ARE PRESENT
		
=cut

sub check {
	my $self		=	shift;
	$self->logDebug("ELAND::check()");

	#### INPUTS
	my $referencedir 	=	$self->referencedir();
	my $outputdir 		=	$self->outputdir();
	my $replicates		=	$self->replicates();
	my $label 			=	$self->label();
	my $min 			=	$self->min();
	my $max 			=	$self->max();

	#### CHECK INPUTS
	die "ELAND::check    min not defined\n" if not defined $min;
	die "ELAND::check    max not defined\n" if not defined $max;
	die "ELAND::check    outputdir not defined\n" if not defined $outputdir;
	die "ELAND::check    replicates not defined\n" if not defined $replicates;
	die "ELAND::check    referencedir not defined\n" if not defined $referencedir;
	die "ELAND::check    label not defined\n" if not defined $label;

	my $dirnumbers = $self->stringToArray($replicates);

	#### GET REFERENCES -- LATER CHANGE THIS: USES chr*.vld FILES TO GET NAMES OF chr* DIRS
	my $referencefiles = $self->listReferenceFiles($referencedir, "\*\.vld");
	my $references = $self->getReferences($referencedir);
	my $overall_status = "completed";
	my $total_sublabels = '';
	my $missingfiles = [];	
	my $dubiousfiles = [];	
	foreach my $dirnumber ( @$dirnumbers )
	{
		next if $dirnumber == 1;
		
		#### SET SPLITFILE
		my $splitfile = "$outputdir/$dirnumber/splitfile.txt";
		$self->logDebug("Can't find splitfile", $splitfile)
 and exit if not -f $splitfile;
		$self->logDebug("splitfile", $splitfile);

		#### GET SPLITFILES
		my $splitfiles = $self->splitfiles($splitfile, $label);

		#### COLLECT ALL JOBS FOR THIS INPUT FILE AGAINST ALL REFERENCE FILES
		my $jobs = $self->generateBatchJobs("$outputdir/$dirnumber", $referencefiles, $splitfiles, $label);
	
		#### CHECK IF ALL THE JOBS COMPLETED
		my ($status, $sublabels) = $self->checkStatus($jobs, $label);
		#### PRINT CHECKFILES
		my $outdir = $$jobs[0]->{outputdir};
		my $checkdir = "$outdir/check/$label";
		my $logfile = "$checkdir/check.log";
		$self->printCheckLog($logfile, $jobs, "$label-rerun", $outdir);

		#### CHECK FOR DUBIOUS FILE SIZES
		my ($missfiles, $doubtfiles) = $self->checkFilesizes($logfile, $min, $max);
		@$missingfiles = (@$missingfiles, @$missfiles);
		@$dubiousfiles = (@$dubiousfiles, @$doubtfiles);
		
		$overall_status = $status if $status ne "completed";
		$total_sublabels .= $sublabels . "," if $sublabels and $status ne "completed";
	}
	$total_sublabels =~ s/,$//;
	return ($overall_status, $label, $total_sublabels, $missingfiles, $dubiousfiles);
}



=head

	SUBROUTINE		checkFilesizes
	
	PURPOSE
	
		LOOK FOR OUTLIER FILE SIZES - TOO SMALL OR TOO BIG
		
=cut

sub checkFilesizes {
	my $self		=	shift;
	my $logfile		=	shift;
	my $min			=	shift;
	my $max			=	shift;
	my @checkfiles;
	my $counter = 0;
	my $fh;
	$/ = undef;

	open($fh, "<$logfile") or die "Can't open logfile: $logfile\n";
	my $contents = <$fh>;
	close($fh) or die "Can't close logfile: $logfile\n";
	$/ = "\n";	
	my @lines = split "\n", $contents;
	foreach my $line ( @lines )
	{
		$counter++;
		next if $line =~ /^\s*$/ or $line =~ /^#/;
		
		my ($filesize, $file) = $line =~ /^\S+\t\S+\t(\S+)\t[^\t]+\t[^\t]+\t([^\t]+)/;
		$self->logDebug("file is not defined in checklog line $counter: **$line**")
 and exit if not defined $file;
		$self->logDebug("filesize is not defined in checklog line $counter: **$line**")
 and exit if not defined $filesize;
		
		push @checkfiles, { file => $file, filesize => $filesize };
	}

	#### DETECT OUTLIERS
	my $avg = 0;
	foreach my $checkfile ( @checkfiles )
	{
		$avg += $checkfile->{filesize}
			if defined $checkfile->{filesize}
			and $checkfile->{filesize}
			and $checkfile->{filesize} ne "-";
	};

	$avg = $avg / $counter;
	my $variance = 0;
	foreach my $checkfile( @checkfiles )
	{
		$variance += ($checkfile->{filesize} - $avg)**2
			if $checkfile->{filesize} ne "-";
	}
	$variance = $variance / ($#checkfiles + 1);
	my $deviation = $variance**0.5;
	my $doubtfiles = [];
	my $missingfiles = [];
	my $lower = int($avg - ($deviation * $min));
	my $upper = int($avg + ($deviation * $max));
	my $intavg = int($avg);
	foreach my $checkfile ( @checkfiles )
	{
		push @$missingfiles, $checkfile->{file} . "\n" 
			and next if $checkfile->{filesize} eq "-";
			
		if ( $checkfile->{filesize} < $lower )
		{
			my $multiple = $checkfile->{filesize} / $avg;
			push @$doubtfiles, "$lower($min SDs)\t$upper($max SDs)\t$multiple\t$intavg\t$checkfile->{filesize}\t$checkfile->{file}\n";
		}
		if ( $checkfile->{filesize} > $upper )
		{
			my $multiple = $checkfile->{filesize} / $avg;
			push @$doubtfiles, "$lower($min SDs)\t$upper ($max SDs)\t$multiple\t$intavg\t$checkfile->{filesize}\t$checkfile->{file}\n";
		}
	}
	
	return ($missingfiles, $doubtfiles);
}

=head2

	SUBROUTINE		checkStatus
	
	PURPOSE
	
		1. CHECK THE LOCK FILES ARE NOT PRESENT TO CONFIRM THAT EACH JOB
		
			HAS COMPLETED
			
		2. USES THE HELPER FUNCTION correctOutput IN THIS MODULE OR
		
			OVERRIDDEN BY THE INHERITING CLASS
			
		3. IF THE OUTPUT FILES ARE ABSENT, MARK THE JOB AS 'MISSING'
	
	NOTES
	
		USES LOCK FILES INSTEAD OF THESE OTHER STRATEGIES:
		
			- lsof
					DOES NOT WORK OVER NFS, ETC.
			
			- stat
					FILE WRITER MAY BE IDLING SO LAST WRITE TIME
			
					DOES NOT GUARANTEE WRITING IS FINISHED
					
			- flock
					NOT GUARANTEED, STABLE OR EFFECTIVE
			
			- chmod
					WON'T WORK WITH SAME USER RUNNING PROCESSES
				
			- rename, unlink
					ATOMIC BUT REQUIRE APPLICATION-SPECIFIC INFORMATION
					
					REGARDING PARTICULAR OUTPUT FILES
					
			- copy TEMPFILES
					POSSIBLE ISSUES WITH GAP BETWEEN COPY 'COMPLETION' AND
					
					ACTUAL AVAILABILITY ON DISTRIBUTED FILE SYSTEM
	
=cut

sub checkStatus {
	my $self		=	shift;	
	my $jobs		=	shift;
	$self->logDebug("Agua::Cluster::Checker::checkStatus(jobs)");
	$self->logDebug("no. jobs: " . scalar(@$jobs));

	my $overall_status 	=	"completed";
	my $labels		=	'';

	#### NON-BATCH JOBS
	if ( not defined $$jobs[0]->{batch} )
	{
		foreach my $job ( @$jobs )
		{
			#### GET OUTPUTDIR
			my $outputdir = $job->{outputdir};
			#### GET LOCKFILE
			my $lockfile = $job->{lockfile};
			#### GET CHECKFILE
			my $checkfile = $job->{checkfile};
			$checkfile = '' if not defined $checkfile;
			my ($status, $presence, $size, $modified) = $self->checkOutput($lockfile, $checkfile);
			$overall_status = "incomplete" if not defined $status or $status eq "incomplete";
			#### ADD CHECKS TO JOB
			$job->{check} = {
				lockfile 	=>	$lockfile,
				checkfile 	=>	$checkfile,
				status     =>	$status,
				presence     =>	$presence,
				size		=>	$size,
				modified	=>	$modified
			};
		}		
	}
	
	#### FOR BATCH JOBS, USE TASK NUMBER, E.G., '%I' OR 'PBS_TASKNUM'
	else
	{
		foreach my $job ( @$jobs )
		{
			$self->logDebug("Checking batch job");
			#### GET OUTPUTDIR
			my $outputdir = $job->{outputdir};
			#### GET LOCKFILE
			my $lockfile = $job->{lockfile};
			$self->logDebug("lockfile", $lockfile);

			#### GET CHECKFILE
			my $checkfile = $job->{checkfile};
			$self->logDebug("checkfile", $checkfile);

			#### GET TASKS
			my $tasks = $job->{tasks};
			return if not defined $tasks or not $tasks;

			#### SET INDEX PATTERN FOR BATCH JOB
			my $index = $self->getIndex();

			#### COLLECT CHECK INFORMATION FOR ALL TASKS
			my $checks = [];
			for my $task ( 1..$tasks )
			{
				my $lock = $lockfile;
				$lock =~ s/\\$index/$task/;
				my $check = $checkfile;
				$check =~ s/\\$index/$task/;
				
				#### STATUS HIERARCHY: complete < incomplete < missing < failed
				my ($status, $presence, $size, $modified) = $self->checkOutput($lock, $check);
				$overall_status = "incomplete" if $status eq "incomplete"
					and $overall_status ne "missing"
					and $overall_status ne "failed";
				$overall_status = "missing" if $presence eq "missing"
					and $overall_status ne "failed";
				$overall_status = "failed" if $status eq "incomplete"
					and $presence eq "missing";
				$labels .= $job->{label} . "," if $status ne "complete";
				
				push( @$checks, {
						task 		=>	$task,
						lockfile 	=>	$lockfile,
						checkfile 	=>	$checkfile,
						status     =>	$status,
						presence     =>	$presence,
						size		=>	$size,
						modified	=>	$modified
					}
				);
			}

			#### ADD CHECKS TO JOB
			$job->{checks} = $checks;
		}
	}
	
	$labels =~ s/,$//;

	return $overall_status, $labels;
}
=head2

	SUBROUTINE		batchCheckfile
	
	PURPOSE
	
		CREATE DIRECTORY AND NOMINATE AN OUTPUT FILE AS THE 'FLAG'
		
		TO BE CHECKED FOR COMPLETION
		
=cut

sub batchCheckfile {
	my $self			=	shift;
	my $label			=	shift;
	my $outputdir		=	shift;
	
	$self->logCritical("label not defined. Exiting...") and exit if not defined $label;
	$self->logCritical("outputdir not defined. Exiting...") and exit if not defined $outputdir;
	
	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index = $self->getIndex();

	#### SET FILES IF NOT DEFINED
	my $checkfile = "$outputdir/$index/out.sam";

	return $checkfile;
}

=head2

	SUBROUTINE		checkOutput

	PURPOSE
	
		CREATE .sh FILE

=cut

sub checkOutput {
	my $self		=	shift;	
	my $lockfile	=	shift;
	my $checkfile	=	shift;

	return "lockfilenotdefined", "-", '-', '-'
		if not defined $lockfile or not $lockfile;
#	$self->logDebug("Agua::Cluster::)");
	my $status = "complete";
	my $presence = "-";
	my $size = "-";
	my $modified = "-";
	
	### SET STATUS TO 'incomplete' IF LOCKFILE PRESENT
	$status = "incomplete" if -f $lockfile;
	$size = -s $checkfile if $checkfile and -f $checkfile;
	#### SET STATUS TO INCOMPLETE IF CHECKFILE IS DEFINED AND NOT PRESENT
	$presence = "present" if defined $checkfile and -f $checkfile;
	$presence = "missing" if defined $checkfile and not -f $checkfile;

	my $timestamp =  (stat($checkfile))[9] if $checkfile and -f $checkfile;
	$modified = localtime($timestamp) if $checkfile and -f $checkfile;
#	$self->logDebug("Returning status", $status);
#	$self->logDebug("Returning size", $size);
#	$self->logDebug("Returning modified", $modified);

	return $status, $presence, $size, $modified;
}

=head2

	SUBROUTINE		printCheckfile
	
	PURPOSE
	
		1. PRINT RESULTS OF checkOutput IF AVAILABLE
		
		2. PRINT TSV IN THIS ORDER: 'missing', 'empty', 'incomplete', 'complete'
		
=cut

sub printCheckLog {
	my $self		=	shift;	
	my $logfile		=	shift;
	my $jobs		=	shift;
	my $label		=	shift;
	my $outdir		=	shift;
#	$self->logDebug("Agua::Cluster::printCheckLog(jobs, label, outputdir)");
#	$self->logDebug("no. jobs: " . scalar(@$jobs));
#	$self->logDebug("label", $label);
#	$self->logDebug("outputdir", $outputdir)  if defined $outputdir;
	

	#### CHECK INPUTS	
	$self->logDebug("jobs not defined. Returning...") and return if not defined $jobs;
	$self->logDebug("label not defined. Returning...") and return if not defined $label;
	$self->logDebug("outdir not defined. Returning...") and return if not defined $outdir;

	my $index = $self->getIndex();
	$outdir =~ s/\/\\$index//g;
	
	my $checkdir = "$outdir/check/$label";
	File::Path::mkpath($checkdir) if not -d $checkdir;
	$self->logCritical("Can't create checkdir: $checkdir") and exit if not -d $checkdir;

	$self->logDebug("Opening logfile", $logfile);
	open(LOG, ">$logfile") or die "Can't open logfile: $logfile\n";

	#### NON-BATCH JOBS
	if ( not defined $$jobs[0]->{batch} )
	{
		my $counter = 0;
		foreach my $job ( @$jobs )
		{
			$counter++;
			
			$self->logDebug("ordinary job");
			my $check = $job->{check};
			$self->logDebug("check", $check) if not defined $check->{size};

			print LOG $check->{status} . "\t";
			print LOG $check->{presence} . "\t";
			print LOG $check->{size} . "\t";
			print LOG $check->{modified} . "\t";
			print LOG $check->{lockfile} . "\t";
			print LOG $check->{checkfile} . "\n"
				if defined $check->{checkfile} and $check->{checkfile};
			print LOG ".\n"
				if not defined $check->{checkfile} or not $check->{checkfile};
			
			require JSON;
			my $jsonParser = JSON->new();

			#### PRINT SCRIPTFILE AND 
			if ( $check->{status} eq "incomplete"
				or $check->{presence} eq "missing" 
			)
			{
				#### PRINT SHELL SCRIPT	
				my $scriptfile = "$checkdir/$label-$counter.sh";
				$self->printScriptfile($scriptfile,
					$job->{commands},
					$job->{label},
					$job->{stdoutfile},
					$job->{stderrfile},
					$job->{lockfile}
				);
				
				#### PRINT JOB JSON FILE
				my $jobfile = "$checkdir/$label-$counter.job";
				my $json = $jsonParser->encode($job);
				open(OUT, ">$jobfile") or die "Can't open jobfile: $jobfile\n";
				print OUT $json;
				close(OUT) or die "Can't close jobfile: $jobfile\n";
			}
		}		
	}
	else
	{
		
		my $counter = 0;
		foreach my $job ( @$jobs )
		{
			$counter++;
			
			$self->logDebug("batch job");
			my $task = 0;
			foreach my $check ( @{$job->{checks}} )
			{
				$task++;
				$check->{lockfile} =~ s/\\$index/$task/g;
				$check->{checkfile} =~ s/\\$index/$task/g;	

				print LOG $check->{status} . "\t";
				print LOG $check->{presence} . "\t";
				print LOG $check->{size} . "\t";
				print LOG $check->{modified} . "\t";
				print LOG $check->{lockfile} . "\t";
				print LOG $check->{checkfile} . "\n";
				
				require JSON;
				my $jsonParser = JSON->new();
				
				if ( $check->{status} eq "incomplete"
					or $check->{size} eq "-" )
				{
					#### PRINT SCRIPT FILE
					my $scriptfile = "$checkdir/$label-$counter-$task.sh";
	
					my $label = $job->{label};
					my $commands = $job->{commands};
					my $stdoutfile = $job->{stdoutfile};
					my $stderrfile = $job->{stderrfile};
					my $lockfile = $job->{lockfile};
					
					#### PRINT SHELL SCRIPT	
					$self->printScriptfile($scriptfile, $commands, $label, $stdoutfile, $stderrfile, $lockfile);
					
					#### PRINT JOB JSON FILE
					my $jobfile = "$checkdir/$label-$counter-$task.job";
					my $json = $jsonParser->encode($job);
					open(OUT, ">$jobfile") or die "Can't open jobfile: $jobfile\n";
					print OUT $json;
					close(OUT) or die "Can't close jobfile: $jobfile\n";
				}
			}
		}		
	}
	close(LOG) or die "Can't close logfile: $logfile\n";
	
	return $logfile;
}


sub timestamp {
    my $self		=	shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp = printf { $self->logfh() } "%4d-%02d-%02d %02d:%02d:%02d\n",
		$year+1900,$mon+1,$mday,$hour,$min,$sec;
		
	return $timestamp;
}

1;
