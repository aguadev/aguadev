package Agua::Cluster::Usage;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;
##########################        USAGE METHODS        #########################

#### METHODS usageStats AND printUsage REQUIRE Jobs::getIndex


=head2

	SUBROUTINE		lastDuration
	
	PURPOSE
	
		RETURN THE DURATION FOR THE LAST BATCH OF JOBS RUN USING
		
		runJobs SUBROUTINE
		
=cut

sub lastDuration {
	my $self		=	shift;
	$self->logDebug("Agua::Cluster::lastDuration()");

	#### SET LABEL IF NOT DEFINED
	my $batchstats = $self->batchstats();
	$self->logDebug("batchstats", $batchstats);

	return if not defined $batchstats or scalar(@$batchstats) == 0;

	my $last_index = scalar(@$batchstats) - 1;
	my $batch = $$batchstats[$last_index];
	$self->logDebug("batch", $batch);

	return $batch->{duration};
}




=head2

	SUBROUTINE		usageStats
	
	PURPOSE
	
		PARSE USAGE STATS FROM STDOUT FILES FOR EACH JOB IN SUPPLIED
		
		ARRAY OF JOBS AND RETURN AS AN ARRAY OF USAGE STATS

		Started at Mon Mar  8 18:14:03 2010
		Results reported at Mon Mar  8 18:14:23 2010
		
		Your job looked like:
		
		------------------------------------------------------------
		# LSBATCH: User input
		/nethome/syoung/base/pipeline/benchmark/maq/maq3/1/chrY-1.sh
		------------------------------------------------------------
		
		Successfully completed.
		
		Resource usage summary:
		
			CPU time   :     18.25 sec.
			Max Memory :         3 MB
			Max Swap   :       155 MB
		
			Max Processes  :         4
			Max Threads    :         5
		
=cut

sub usageStats {
	my $self		=	shift;	
	my $jobs		=	shift;
	my $label		=	shift;
	my $duration	=	shift;
	$self->logDebug("Agua::Cluster::usageStats(jobs)");
	$self->logDebug("no. jobs: " . scalar(@$jobs));
	$self->logDebug("label", $label);
	$self->logDebug("duration", $duration);
	
	#### CHECK FOR NON-BATCH STDOUT FILES
	if ( not defined $$jobs[0]->{batch} )
	{
		$self->logDebug("Checking non-batch stdout file");
		my $usage = [];
		foreach my $job ( @$jobs )
		{
			#### GET CONTENTS OF STDOUT FILE
			my $stdoutfile = $job->{stdoutfile};
			$self->logDebug("stdoutfile", $stdoutfile);
			my $hash = $self->parseUsagefile($stdoutfile);
			next if not defined $hash;
	
			#### PUSH TO STATS ARRAY
			push @$usage, $hash;
		}
		
		#### SET LABEL IF NOT DEFINED
		my $batchstats = $self->batchstats();
		$batchstats = [] if not defined $batchstats;
		$label = "BATCH " . (scalar(@$batchstats) + 1) if not defined $label;
	
		#### PUSH ONTO GLOBAL USAGE STATS
		$self->addUsageStatistic($label, $duration, $usage);
	}
	
	#### CHECK FOR BATCH JOB STDOUT FILES
	#### NB: SUBSTITUTE TASK NUMBER FOR JOB INDEX
	#### (I.E., '$LSB_JOBINDEX' OR '$PBS_TASKNUM')
	else
	{
		$self->logDebug("Checking batch stdout files");
		foreach my $job ( @$jobs )
		{
			my $tasks = $job->{tasks};
			return if not defined $tasks or not $tasks;
			#### SET LABEL IF NOT DEFINED
			my $batchstats = $self->batchstats();
			$batchstats = [] if not defined $batchstats;
			$label = "BATCH " . (scalar(@$batchstats) + 1) if not defined $label;

			#### GET CONTENTS OF STDOUT FILE
			my $stdoutfile = $job->{stdoutfile};
			$self->logDebug("stdoutfile", $stdoutfile);

			my $index = $self->getIndex();
			my $usage = [];
			for my $task ( 1..$tasks )
			{
				my $file = $stdoutfile;
				$file =~ s/\\$index/$task/g;
				my $hash = $self->parseUsagefile($file);
		
				#### PUSH TO STATS ARRAY
				push @$usage, $hash;
			}
		
			#### PUSH ONTO GLOBAL USAGE STATS
			$self->addUsageStatistic($label, $duration, $usage);
		}
	}
	
	
	
}

=head2

	SUBROUTINE		parseUsagefile
	
	PURPOSE
	
		PARSE THE DURATION, MEMORY, SWAP, ETC. INFORMATION FROM
		
		A USAGE OUTPUT FILE

qacct -j 21
==============================================================
qname        Project1-Workflow1  
hostname     master              
group        root                
owner        root                
project      NONE                
department   defaultdepartment   
jobname      Project1-1-Workflow1-1
jobnumber    21                  
taskid       undefined
account      sge                 
priority     0                   
qsub_time    Mon May 16 05:08:59 2011
start_time   Mon May 16 05:09:02 2011
end_time     Mon May 16 05:09:41 2011
granted_pe   NONE                
slots        1                   
failed       100 : assumedly after job
exit_status  137                 
ru_wallclock 39           
ru_utime     0.000        
ru_stime     0.000        
ru_maxrss    1340                
ru_ixrss     0                   
ru_ismrss    0                   
ru_idrss     0                   
ru_isrss     0                   
ru_minflt    1780                
ru_majflt    0                   
ru_nswap     0                   
ru_inblock   0                   
ru_oublock   40                  
ru_msgsnd    0                   
ru_msgrcv    0                   
ru_nsignals  0                   
ru_nvcsw     38                  
ru_nivcsw    4                   
cpu          3.480        
mem          0.157             
io           0.002             
iow          0.000             
maxvmem      79.340M
arid         undefined
		
=cut
sub parseUsagefile {
	my $self		=	shift;
	my $file		=	shift;
	$self->logDebug("Agua::Cluster::parseUsagefile(file)");
	$self->logDebug("usage file not defined. Returning") and return if not defined $file;
	$self->logDebug("file", $file);

	#### PAUSE FOR $fh TO BE PRINTED AND CLOSED
	#### (DELAY OCCURS WITH BATCH JOBS)
	my $fh;
	my $tries = 20;
	my $counter = 0;
	my $success = 0;
	my $sleep = $self->sleep();
	$sleep = 10 if not defined $sleep;
	my $temp = $/;
	while ( not $success and $counter < $tries )
	{
		$counter++;

		$success = 1 if open($fh, $file);
		last if $success;
		my $date = `date`;
		$self->logDebug("Try number $counter looking for usage file", $file);

		sleep($sleep);
	}
	#### WARN AND RETURN NULL IF CAN'T OPEN FILE
	$self->logDebug("Can't open output file", $file) and return if not $success;	
	$/ = "END OF FILE";
	my $output = <$fh>;
	close($fh);
	$/ = $temp;

	my $hash = {};
	if ( defined $output )
	{
		($hash->{completed}) = $output =~ /Started at ([^\n]+)/msi;
		($hash->{reported}) = $output =~ /Results reported at ([^\n]+)/msi;
		($hash->{cputime}) = $output =~ /CPU time\s+:\s+([^\n]+)/msi;
		($hash->{maxmemory}) = $output =~ /Max Memory\s+:\s+([^\n]+)/msi;
		($hash->{maxswap}) = $output =~ /Max Swap\s+:\s+([^\n]+)/msi;
		($hash->{maxprocesses}) = $output =~ /Max Processes\s+:\s+(\d+)/msi;
		($hash->{maxthreads}) = $output =~ /Max Threads\s+:\s+(\d+)/msi;
		($hash->{status}) = $output =~ /([^\n]+)\s*\n\s*\n\s*Resource usage summary:/msi;	
		($hash->{shellscript}) = $output =~ /# LSBATCH: User input\s*\n\s*([^\n]+)/msi;
	}

	return $hash;
}

=head2

	SUBROUTINE		statValue
	
	PURPOSE
	
		RETURN THE FORMATTED VALUE OF A USAGE STATISTIC
		
=cut

sub statValue {	
	my $self		=	shift;
	my $stats		=	shift;
	my $field		=	shift;
	my $operation 	=	shift;
	$self->logDebug("statValue(stats,field)");
	$self->logDebug("no. stats: " . scalar(@$stats));
	$self->logDebug("field", $field);
	$self->logDebug("operation", $operation);
	
	return if not defined $stats or not @$stats;
	return if not defined $field;
	my $suffix = '';
	if ( defined $field and defined $stats and defined $$stats[0]->{$field} )
	{
		($suffix) = $$stats[0]->{$field} =~ /^\s*[\d\.]+\s+(\S+)$/;
	}
	$self->logDebug("suffix", $suffix);

	my $value = 0;
	$value = 99999999 if $operation eq "min";
	
	foreach my $stat ( @$stats )
	{
		next if not defined $stat->{$field};
		$stat->{$field} =~ /^([\.\d]+)/;

		if ( $operation eq "max" )
		{
			if ( $1 > $value )	{	$value = $1;	}
		}
		if ( $operation eq "min" )
		{
			if ( $1 < $value )	{	$value = $1;	}
		}
		if ( $operation eq "total" )
		{
			$value += $1;
		}
	}
	$self->logDebug("Returning value, suffix: $value $suffix");

	return ($value, $suffix);	
}


=head2

	SUBROUTINE		printUsage
	
	PURPOSE
	
		PRINT THE USAGE STATISTICS FOR ALL BATCHES OF JOBS
		
		(EITHER ON CLUSTER USING runJobs OR LOCALLY) LOADED
		
		INTO self->batchstats ARRAY
		
=cut

sub printUsage {
	my $self		=	shift;
	my $jobs		=	shift;
	my $label		=	shift;
	$self->logDebug("printUsage(jobs, label)");

	my $outputdir	=	$self->outputdir();
	$self->logDebug("BEFORE outputdir", $outputdir)  if defined $outputdir;
	$outputdir = $$jobs[0]->{outputdir}
		if defined $$jobs[0]->{outputdir}
		and $$jobs[0]->{outputdir};
	
	
	my $index = $self->getIndex();
	$outputdir =~ s/\\$index//;
	$self->logDebug("AFTER outputdir", $outputdir);
	
	my $usagedir = "$outputdir/usage";
	File::Path::mkpath($usagedir) if not -d $usagedir;
	my $usagefile = "$usagedir/$label-usage.txt";
	$self->logDebug("usagefile", $usagefile);


	#### REMOVE FILE IF EXISTS
	`rm -fr $usagefile` if -f $usagefile;
	$self->logDebug("previous usagefile PRESENT!") if -f $usagefile;

	#### RETRIEVE INITIAL COMMAND USED BY THE USER
	my $command		=	$self->command();
	#### GET BATCH STATS
	my $batchstats 	=	$self->batchstats();
	$self->logDebug("No. batchstats: " . scalar(@$batchstats));

#	$self->logDebug("batchstats[0]: ");
	#### RETURN IF BATCH STATS NOT DEFINED
	$self->logDebug("batchstats not defined. Returning") and return if not defined $batchstats;	
	$self->logDebug("Printing USAGE file", $usagefile);


	#### CALCULATE TOTAL USAGE
	my $total_cputime = 0;

	#### GET DURATION (STOP TIMER)
	my $starttime = $self->starttime();
	$self->logDebug("starttime", $starttime);
	my $duration;
	if ( defined $starttime )
	{
		$duration = Timer::runtime( $starttime, time() );
	}

	#### OPEN OUTPUT FILE	
	open(OUT, ">>$usagefile") or die "Can't open usage file: $usagefile\n";	

	#### PRINT SCRIPT NAME AND command
	print OUT "[$label]\n";
	print OUT "Completed: $0\n";
	print OUT "Date:      ";
	print OUT Timer::current_datetime(), "\n";
	print OUT "Duration:  $duration\n" if defined $duration;
	print OUT "Command:   $command\n" if defined $command and ref($command) ne "ARRAY";
	print OUT "Command:   @$command\n" if defined $command and ref($command) eq "ARRAY";
	print OUT "\nUSAGE STATISTICS\n\n";

	#### HEADINGS FOR USAGE STATS TABLE FOR EACH BATCH
	my $headings = ['completed', 'reported', 'cputime', 'maxmemory', 'maxswap', 'maxprocesses', 'maxthreads', 'status', 'shellscript'];
	
	#### PRINT USAGE FOR EACH TYPE
	my $title_width = 15;
	foreach my $batchstat ( @$batchstats )
	{
		print OUT $self->formatTitle("BATCH", $title_width);
		print OUT $batchstat->{label};
		print OUT "\n";

		print OUT $self->formatTitle("DURATION", $title_width);
		print OUT $batchstat->{duration} if defined $batchstat->{duration};
		print OUT "\n";

		my $stats = $batchstat->{usage};
		
		if ( not defined $stats or not @$stats )
		{
			print OUT "\n";
			next;
		}

		#### PRINT MIN AND MAX VALUES FOR MEMORY, SWAP AND CPUTIME (ALSO TOTAL)
		my $fields = ['cputime', 'maxmemory', 'maxswap'];
		foreach my $field ( @$fields )
		{
			my ($min, $max, $suffix);
			($min, $suffix) = $self->statValue($stats, $field, 'min');
			print OUT $self->formatTitle(uc($field) . " MIN", $title_width);
			print OUT "$min\t$suffix\n";
	
			($max, $suffix) = $self->statValue($stats, $field, 'max');
			print OUT $self->formatTitle(uc($field) . " MAX", $title_width);
			print OUT "$max\t$suffix\n";
	
			if ( $field eq "cputime" )
			{
				my ($total, $suffix) = $self->statValue($stats, $field, 'total');
				print OUT $self->formatTitle(uc($field) . " TOTAL", $title_width);
				print OUT "$total\t$suffix\n";

				$total_cputime += $total;
			}
		}

		#### PRINT HEADERS
		foreach my $heading ( @$headings )	{	print OUT "$heading\t";	}
		print OUT "\n";

		foreach my $stat ( @$stats )
		{
			foreach my $heading ( @$headings )
			{
				$self->logDebug("heading '$heading' not defined in stat:")  if not defined $stat->{$heading};
				$self->logDebug("stat", $stat) if not defined $stat->{$heading};
				$stat->{$heading} = 0 if not defined $stat->{$heading};
				
				print OUT "$stat->{$heading}\t";	
			}
			print OUT "\n";
		}
		print OUT "\n";
	}
	close(OUT) or die "Can't close usage file: $usagefile\n";

	#### RESET BATCHSTATS	
	$self->{_batchstats} = [];
}

=head2

	SUBROUTINE		addUsageStatistic
	
	PURPOSE
	
		ADD A USAGE STATISTIC FOR A LOCAL OR CLUSTER RUN OF ONE
		
		OR MORE JOBS TO self->batchstats
		
=cut

sub addUsageStatistic {
	my $self		=	shift;
	my $label		=	shift;
	my $duration	=	shift;
	my $usage		=	shift;
	$self->logDebug("Agua::Cluster::addUsageStatistic(label, duration, usage)");
	$self->logDebug("label", $label);
	$self->logDebug("duration", $duration);
	$usage = [] if not defined $usage; 	

	my $batch_stat;
	$batch_stat->{label} = $label;
	$batch_stat->{duration} = $duration;
	$batch_stat->{usage} = $usage;

	my $batchstats = $self->batchstats();
	push @$batchstats, $batch_stat;

	$self->{_batchstats} = $batchstats;
}




=head2

	SUBROUTINE		formatTitle
	
	PURPOSE

		FORMAT TITLE TO PREDEFINED WIDTH

=cut
sub formatTitle {
	my $self		=	shift;
	my $title		=	shift;
	my $width		=	shift;
	
	return $title if length($title) >= $width;
	my $margin = $width - length($title);
	$title .= " " x $margin;
	
	return $title;
}





1;
