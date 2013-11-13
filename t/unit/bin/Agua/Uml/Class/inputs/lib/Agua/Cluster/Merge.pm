package Agua::Cluster::Merge;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;
##########################       MERGE METHODS        ##########################

#### METHODS sortSubdirSam AND subdirSamHIts REQUIRE Jobs::getIndex


=head2

	SUBROUTINE		pyramidMergeBam
	
	PURPOSE
	
		1. MERGE ALL FILES PER REFERENCE IN A PYRAMID OF DECREASING
		
			(BY HALF) BATCHES OF MERGES UNTIL THE FINAL OUTPUT FILE
		
			IS PRODUCED.
		
		2. EACH STAGE IS COMPLETED WHEN ALL OF THE MERGES FOR ALL
		
			REFERENCES ARE COMPLETE.
		
		3. EACH PAIRWISE MERGE OPERATION IS CARRIED OUT ON A SEPARATE
		
			EXECUTION HOST
		
		4. THIS METHOD ASSUMES:
		
			1. THERE IS NO ORDER TO THE FILES
			
			2. ALL FILES MUST BE MERGED INTO A SINGLE FILE
		
			3. THE PROVIDED SUBROUTINE MERGES THE FILES
		
		INPUTS
		
=cut

sub pyramidMergeBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
$self->logDebug("(outputdir, references, splitfiles, infile, outfile)");
$self->logDebug("outputdir", $outputdir);
$self->logDebug("references", $references);
$self->logDebug("splitfiles", $splitfiles);
$self->logDebug("infile", $infile);
$self->logDebug("outfile", $outfile);


	#### SET DEFAULT infile AND outfile
	$infile = "out.bam" if not defined $infile;
	$outfile = "out.bam" if not defined $outfile;
	
	#### GET SAMTOOLS
	my $samtools = $self->samtools();

	#### LOAD UP WITH INITIAL BAM FILES
	my $reference_bamfiles;
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $bamfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);
		$reference_bamfiles->{$reference} = $bamfiles;
	}

	my $mergesub = sub {
		my $firstfile	=	shift;
		my $secondfile	=	shift;

		$self->logDebug("outfile", $outfile);
		$self->logDebug("firstfile", $firstfile);
		$self->logDebug("secondfile", $secondfile);

		#### KEEP THIS PART OF THE LOGIC HERE JUST IN CASE THE
		#### MERGE FUNCTION EXPECTS A PARTICULAR FILE SUFFIX
		my $outfile = $firstfile;
		if ( $outfile =~ /\.merge\.(\d+)$/ )
		{
			my $number = $1;
			$number++;
			$outfile =~ s/\d+$/$number/;	 
		}
		else
		{
			$outfile .= ".merge.1"
		}

		#### MERGE BAM FILES
		my $command = "$samtools/samtools merge $outfile $firstfile $secondfile;\n";
		
		return ($command, $outfile);
	};


	#### RUN PYRAMID MERGE ON ALL REFERENCES IN PARALLEL
	my $label = "pyramidMergeBam";
	$self->_pyramidMerge($outputdir, $references, $splitfiles, $infile, $outfile, $reference_bamfiles, $label, $mergesub);

	$self->logDebug("Completed.");
}


=head2

	SUBROUTINE		_pyramidMerge
	
	PURPOSE
	
		MERGE BY REFERENCE FILE IN PARALLEL USING THE SUPPLIED
		
		MERGE FUNCTION
		
		1. FOR EACH ROUND OF pyramidMerge:
		
				- COLLECT JOBS FOR EACH REFERENCE FROM mergeJobs
			
				- mergeJobs CALLS pairwiseMergeJobs
				
				- RUN ALL JOBS AND RETURN REMAINING NUMBER OF
				
					FILES FOR EACH REFERENCE IN HASH
				
		2. IF ONLY ONE FILE REMAINING IN INPUT FILES, mergeJobs
		
			WILL RETURN NULL
			
		3. IF THE reference-jobs HASH VALUES FOR ALL REFERENCES IS NULL,
		
			STOP RUNNING pyramidMerge AND RETURN
	
		4. THIS METHOD ASSUMES:
		
			1. THERE IS NO ORDER TO THE FILES
			
			2. ALL FILES MUST BE MERGED INTO A SINGLE FILE
		
			3. THE PROVIDED SUBROUTINE MERGES THE FILES
	
=cut

sub _pyramidMerge {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	my $reference_infiles	=	shift;
	my $label			=	shift;
	my $mergesub		=	shift;
	$self->logDebug("Agua::Cluster::_pyramidMerge(outputdir, references, splitfiles, infile, outfile, reference_infiles, label, mergesub)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("references: ");
	print join "\n", @$references;
	$self->logDebug("\n");
	#### SET CURRENT TIME (START TIMER)
	my $current_time =  time();
	
	my $alljobs = [];
	my $running = 1;
	my $counter = 0;
	while ( $running )
	{
		$counter++;
		
		for my $reference ( @$references )
		{
			$self->logDebug("reference_infiles->{$reference} not defined") and next if not defined $reference_infiles->{$reference};
			next if not @{$reference_infiles->{$reference}};

			my $outputfile = "$outputdir/$reference/$outfile";
			my $label = "_pyramidMerge-$reference-$counter";
			$self->logDebug("label", $label);

			my $jobs = [];
			my $inputfiles = $reference_infiles->{$reference};
			($jobs, $reference_infiles->{$reference}) = $self->mergeJobs(
				{
					inputfiles 	=> 	$inputfiles,
					outputfile 	=> 	$outputfile,
					mergesub	=>	$mergesub,
					label		=>	$label
				}
			);


		$self->logDebug("No. jobs: " . scalar(@$jobs));
		
			#### ADD TO ALL JOBS
			(@$alljobs) = (@$alljobs, @$jobs) if defined $jobs and @$jobs;
		}
		
		if ( not @$alljobs )
		{
			$running = 0;
			last;
		}
	
		#### RUN JOBS
		$self->runJobs($alljobs, $label);
		
		#### EMPTY ALLJOBS
		$alljobs = [];
	}
	
	#### SET EMPTY USAGE STATISTICS
	my $usage = [];
	
	#### GET DURATION (STOP TIMER)
	my $duration = Timer::runtime( $current_time, time() );

	#### PUSH ONTO GLOBAL USAGE STATS
	$self->addUsageStatistic($label, $duration, $usage);
	
	#### PRINT DURATION
	$self->logDebug("Completed $label at " . Timer::current_datetime() . ", duration", $duration);
	
	$self->logDebug("completed");	
}




=head2

	SUBROUTINE		mergeJobs
	
	PURPOSE
	
		RETURN JOBS TO MERGE FILES ON A CLUSTER.
		
		THIS METHOD ASSUMES:
		
			1. THERE IS NO ORDER TO THE FILES
			
			2. ALL FILES MUST BE MERGED INTO A SINGLE FILE
		
			3. THE PROVIDED SUBROUTINE MERGES THE FILES
			
=cut

sub mergeJobs {
	my $self			=	shift;
	my $args			=	shift;
	
	my $inputfiles		=	$args->{inputfiles};
	my $outputfile		=	$args->{outputfile};
	my $mergesub		=	$args->{mergesub};
	my $label			=	$args->{label};

	$self->logDebug("Agua::Cluster::mergeJobs(inputfiles, outputfile, mergesub)");
	$self->logDebug("No. inputfiles: " . scalar(@$inputfiles));
	$self->logDebug("outputfile", $outputfile);
	#### IF ONLY ONE FILE LEFT, MOVE THE LAST MERGED INPUT FILE TO THE OUTPUT FILE
	if ( scalar(@$inputfiles) == 1 )
	{
		$self->logDebug("Completed merging. Doing mv to outputfile");
		my $move = "mv -f $$inputfiles[0] $outputfile";
		$self->logDebug("move", $move);
		`$move`;
		
		#### RETURN NO JOBS AND NO INPUT FILES
		return ([], []);
	}

	#### MOVE THE LAST MERGED INPUT FILE TO THE OUTPUT FILE
	else
	{
		my ($outdir) = $$inputfiles[0] =~ /^(.+)\/[^\/]+$/; 
		$self->logDebug("label", $label);
		$self->logDebug("outdir", $outdir);

		#### SET JOBS
		my $jobs;
		($jobs, $inputfiles) = $self->pairwiseMergeJobs($inputfiles, $mergesub, $label, $outdir);
		$self->logDebug("No. REMAINING inputfiles: " . scalar(@$inputfiles));
		
		#### RETURN JOBS AND INPUT FILES
		return ($jobs, $inputfiles);
	}

}



=head2

	SUBROUTINE		pairwiseMergeJobs
	
	PURPOSE
	
		RETURN AN ARRAY OF MERGE COMMANDS FOR PAIRWISE MERGE 
		
		OF ALL FILES IN INPUT ARRAY OF SUBFILES

=cut

sub pairwiseMergeJobs {
	my $self		=	shift;
	my $inputfiles	=	shift;
	my $mergesub	=	shift;
	my $label		=	shift;
	my $outdir		=	shift;
	$self->logDebug("Agua::Cluster::pairwiseMergeJobs(job_objects)");
	$self->logDebug("length inputfiles: " . scalar(@$inputfiles));
	$self->logDebug("No. inputfiles: " . scalar(@$inputfiles));
	#### DO split MERGE OF INPUT FILES
	my $jobs = [];
	my $outputfiles = [];
	my $totalfiles = scalar(@$inputfiles);
	for ( my $i = 0; $i < @$inputfiles; $i+=2 )
	{
		#### SKIP IF ONLY ONE FILE LEFT
		push @$outputfiles, $$inputfiles[$i] and last if $i == scalar(@$inputfiles) - 1;

		#### MERGE NOTE
		my $subfile = $$inputfiles[$i];
		my $next_index = $i + 1;
		my $note = "echo 'Merging subfiles $i and $next_index of $totalfiles'";
		
		my $commands = [];
		push @$commands, $note;

		#### MERGE COMMAND
		my ($merge_command, $mergedfile) = &$mergesub($$inputfiles[$i], $$inputfiles[$i + 1]);
		push @$commands, $merge_command;

		#### SET LABEL
		my $this_label = $label . "-$i";

		#### SET JOB
		my $job = $self->setJob($commands, $this_label, $outdir);
		push @$jobs, $job;

		#### ADD MERGED FILE TO FILE TO BE MERGED IN NEXT ROUND
		push @$outputfiles, $mergedfile;
	}

	return ($jobs, $outputfiles);
}	





=head2

	SUBROUTINE		cumulativeMergeSam
	
	PURPOSE
	
		1. SUCCESSIVELY MERGE ALL OF THE SAM FILES FOR
		
			EACH SPLIT INPUT FILE FOR ALL PROVIDED
			
			REFERENCES
			
		2. CUMULATIVELY ADD TO A TEMP FILE (USED TO SHOW ONGOING)
		
		3. ONCE COMPLETE, RENAME TEMP FILE TO OUTPUT FILE

=cut

sub cumulativeMergeSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;

	#### CHECK INPUTS
	$self->logCritical("outputdir not defined. Exiting.") and exit if not defined $outputdir;
	$self->logCritical("references not defined. Exiting.") and exit if not defined $references;
	$self->logCritical("splitfiles not defined. Exiting.") and exit if not defined $splitfiles;
	$self->logCritical("infile not defined. Exiting.") and exit if not defined $infile;
	$self->logCritical("outfile not defined. Exiting.") and exit if not defined $outfile;
	$self->logDebug("Agua::Cluster::cumulativeMergeSam(outputdir, references, splitfiles, infile, outfile, toplines)");


	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));

	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);

	#####################################################################################
	######## STRATEGY 1. MERGE SUBDIR out.sam FILES FIRST, THEN SORT SINGLE SAM FILE
	#####################################################################################
	
	#### MERGE ALL SPLIT *.sam FILES INTO A SINGLE CHROMOSOME *.sam FILE
	$self->mergeSam($outputdir, $references, $splitfiles, $infile, $outfile);
	
	#### SORT SINGLE CHROMOSOME SAM FILE
	$self->sortSam($outputdir, $references, $outfile, $outfile);


	#####################################################################################
	##### STRATEGY 2. SORT SPLIT out.sam FILES FIRST, THEN MERGE AND SORT SINGLE SAM FILE
	#####################################################################################

	##### SORT ALL SPLIT out.sam FILES
	#$self->sortSubdirSam($outputdir, $references, $splitfiles, $infile, $outfile);
	
	##### MERGE ALL SPLIT out.sam FILES
	#$self->mergeSam($outputdir, $references, $splitfiles, $outfile, $outfile);
	
	##### SORT SINGLE SAM FILE
	#$self->sortSam($outputdir, $references, $infile, $outfile);
}

=head2

	SUBROUTINE		mergeSam
	
	PURPOSE
	
		1. SUCCESSIVELY MERGE ALL OF THE SAM FILES FOR EACH SPLIT
		
			INPUT FILE FOR ALL PROVIDED REFERENCES
			
=cut

sub mergeSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	$self->logDebug("Agua::Cluster::mergeSam(outputdir, references, splitfiles, infile, outfile, toplines)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);


	#### STRATEGY 1. MERGE SPLIT out.sam FILES FIRST, THEN SORT SINGLE SAM FILE
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $inputfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);
		#my $no_header = $self->noSamHeader($$inputfiles[0]);

		my $outputfile = "$outputdir/$reference/$outfile";
		$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;
		print `rm -fr $outputfile`;
		$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;

		my $commands = [];
		foreach my $inputfile ( @$inputfiles )
		{
			my $command = "cat $inputfile >> $outputfile";

			push @$commands, $command;
			push @$commands, "echo 'Merging file: ' $inputfile ";
		}
		my $job = $self->setJob( $commands, "mergeSam-$reference", "$outputdir/$reference" );
		#### OVERRIDE checkfile
		$job->{checkfile} = $outputfile;

		push @$jobs, $job;
	}

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "mergeSam" );	
	$self->logDebug("Completed.");
}


=head2

	SUBROUTINE		sortSubdirSam
	
	PURPOSE
	
		SORT SAM FILES IN EACH SPLIT SUBDIR
	
=cut

sub sortSubdirSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	$self->logDebug("Agua::Cluster::sortSubdirSam(outputdir, references, splitfiles, infile, outfile, toplines)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("references: ");
	print join "\n", @$references;
	$self->logDebug("\n");
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);

	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index = $self->getIndex();

	#### DO BATCH JOBS
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $inputfile = "$outputdir/$reference/$index/$infile";
		my $outputfile = "$outputdir/$reference/$index/$outfile";
		my $outdir = "$outputdir/$reference";
		$self->logDebug("inputfile", $inputfile);
		$self->logDebug("outputfile", $outputfile);
		$self->logDebug("outdir", $outdir);

		#### REMOVE OUTPUT FILE IF EXISTS
		$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;
		print `rm -fr $outputfile`;
		$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;

		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		my $command = qq{sort -t "\t" -k 3,3 -k 4,4n $inputfile -o $outputfile};
		my $job = $self->setBatchJob( [$command], "sortSubdirSam-$reference", $outputdir );

		push @$jobs, $job;
	}

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "sortSubdirSam" );	
	$self->logDebug("Completed.");
}

=head2

	SUBROUTINE		samHits
	
	PURPOSE
	
		1. FILTER HITS AND MISSES INTO SEPARATE SAM FILES
	
		2. DO ALL SAM FILES AT THE CHROMOSOME/REFERENCE LEVEL
		
=cut


sub samHits {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $hitfile			=	shift;
	my $missfile		=	shift;
	$self->logDebug("Agua::Cluster::samHits(outputdir, references, splitfiles, infile, outfile, toplines)");

	#### CHECK INPUTS
	$self->logCritical("infile not defined") and exit if not defined $infile;
	$self->logCritical("hitfile not defined") and exit if not defined $hitfile;

	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("infile", $infile);
	$self->logDebug("hitfile", $hitfile);
	$self->logDebug("missfile", $missfile)  if defined $missfile;

	#### GET TASKS ( = NO. SPLITFILES)
	my $tasks = scalar(@$splitfiles);

	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### DO BATCH JOBS
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $inputfile = "$outputdir/$reference/$infile";
		my $outputfile = "$outputdir/$reference//$hitfile" if defined $hitfile;
		my $missed = "$outputdir/$reference/$missfile" if defined $missfile;
		my $outdir = "$outputdir/$reference";

		#### REMOVE OUTPUT FILE IF EXISTS
		$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;
		print `rm -fr $outputfile`;
		$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;

		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		use FindBin qw($Bin);
		my $executable = "$Bin/samHits.pl";
		$self->logDebug("executable", $executable);
		my $command = qq{/usr/bin/perl $executable --inputfile $inputfile};
		$command .= qq{ --outputfile $outputfile} if defined $hitfile;
		$command .= qq{ --missfile $missed} if defined $missfile;
		$self->logDebug("command", $command);

		my $job = $self->setJob([$command], "samHits-$reference", $outputdir, $tasks);
		push @$jobs, $job;
	}

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "samHits" );	
	$self->logDebug("Completed.");
}



=head2

	SUBROUTINE		subdirSamHits
	
	PURPOSE
	
		1. FILTER HITS AND MISSES INTO SEPARATE SAM FILES

		2. DO ALL SAM OUTPUT FILES AT THE SUBDIR LEVEL
	
=cut


sub subdirSamHits {
	my $self			=	shift;

	return $self->localSubdirSamHits(@_) if not $self->cluster();	

	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $hitfile			=	shift;
	my $missfile		=	shift;
	$self->logDebug("Agua::Cluster::subdirSamHits(outputdir, references, splitfiles, infile, outfile, missfile)");

	#### CHECK INPUTS - infile AND hitfile REQUIRED
	$self->logCritical("infile not defined") and exit if not defined $infile;
	$self->logCritical("hitfile not defined") and exit if not defined $hitfile;

	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("infile", $infile);
	$self->logDebug("hitfile", $hitfile);
	$self->logDebug("missfile", $missfile)  if defined $missfile;

	#### GET TASKS ( = NO. SPLITFILES)
	my $tasks = scalar(@$splitfiles);

	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### SET INDEX PATTERN FOR BATCH JOB
	my $index = $self->getIndex();
	
	#### DO BATCH JOBS
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $inputfile = "$outputdir/$reference/$index/$infile";
		my $outputfile = "$outputdir/$reference/$index/$hitfile";
		my $missed = "$outputdir/$reference/$index/$missfile" if defined $missfile;
		my $outdir = "$outputdir/$reference";

		#### REMOVE OUTPUT FILE IF EXISTS
		$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;
		print `rm -fr $outputfile`;
		$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;

		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		#my $executable = "/nethome/bioinfo/apps/agua/0.5/bin/apps/samHits.pl";	
		use FindBin qw($Bin);
		my $executable = "$Bin/samHits.pl";
		$self->logDebug("executable", $executable);
		my $command = qq{/usr/bin/perl $executable --inputfile $inputfile};
		$command .= qq{ --outputfile $outputfile};
		$command .= qq{ --missfile $missed} if defined $missfile;
		
		$self->logDebug("command", $command);

		my $job = $self->setBatchJob([$command], "subdirSamHits-$reference", "$outputdir/$reference", $tasks);
		
		#### OVERRIDE checkfile
		$job->{checkfile} = $outputfile;

		push @$jobs, $job;
	}



	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "subdirSamHits" );	
	$self->logDebug("Completed.");
}


=head2

	SUBROUTINE		localSubdirSamHits
	
	PURPOSE
	
		1. FILTER HITS AND MISSES INTO SEPARATE SAM FILES

		2. DO ALL SAM OUTPUT FILES AT THE SUBDIR LEVEL

		3. RUN LOCALLY	
=cut


sub localSubdirSamHits {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $hitfile			=	shift;
	my $missfile		=	shift;
	$self->logDebug("Agua::Cluster::localSubdirSamHits(outputdir, references, splitfiles, infile, outfile, missfile)");

	#### CHECK INPUTS - infile AND hitfile REQUIRED
	$self->logCritical("infile not defined") and exit if not defined $infile;
	$self->logCritical("hitfile not defined") and exit if not defined $hitfile;

	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("references: @$references");
	$self->logDebug("infile", $infile);
	$self->logDebug("hitfile", $hitfile);
	$self->logDebug("missfile", $missfile)  if defined $missfile;

	#### GET TASKS ( = NO. SPLITFILES)
	my $tasks = scalar(@$splitfiles);

	#### GET CLUSTER
	my $cluster = $self->cluster();

	#### DO BATCH JOBS
	my $jobs = [];
	foreach my $reference ( @$references )
	{

		#### DO ALIGNMENTS FOR ALL SPLITFILES 
		my $counter = 0;
		foreach my $splitfile ( @$splitfiles )
		{
			$counter++;

			#### SET OUTPUT DIR TO SUBDIRECTORY CONTAINING SPLITFILE
			my ($basedir, $index, $filename) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;
			my $outdir = "$outputdir/$reference/$index";
			File::Path::mkpath($outdir) if not -d $outdir;
			$self->logDebug("Could not create output dir", $outdir) if not -d $outdir;

			my $inputfile = "$outputdir/$reference/$index/$infile";
			my $outputfile = "$outputdir/$reference/$index/$hitfile";
			my $missed = "$outputdir/$reference/$index/$missfile" if defined $missfile;
	
			#### REMOVE OUTPUT FILE IF EXISTS
			$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;
			print `rm -fr $outputfile`;
			$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;
	
			#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
			#my $executable = "/nethome/bioinfo/apps/agua/0.5/bin/apps/samHits.pl";	
			use FindBin qw($Bin);
			my $executable = "$Bin/samHits.pl";
			$self->logDebug("executable", $executable);
			my $command = qq{/usr/bin/perl $executable --inputfile $inputfile};
			$command .= qq{ --outputfile $outputfile};
			$command .= qq{ --missfile $missed} if defined $missfile;
			
			$self->logDebug("command", $command);
	
			my $job = $self->setJob([$command], "localSubdirSamHits-$reference", "$outputdir/$reference");
			
			#### OVERRIDE checkfile
			$job->{checkfile} = $outputfile;
	
			push @$jobs, $job;

		}

	}

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "localSubdirSamHits" );	
	$self->logDebug("Completed.");
}



=head2

	SUBROUTINE		noSamHeader
	
	PURPOSE
	
		1. RETURN 1 IF FILE CONFORMS TO THE SAM FORMAT, 0 OTHERWISE

		2. SAM REQUIREMENTS:
		
			- HAS AT LEAST 11 FIELDS
			
			- 4TH AND 5TH FIELDS STRICTLY NUMERIC
			
			- 10TH FIELD IS SEQUENCE (I.E., NON-NUMERIC)

	NOTES

		Sequence Alignment/Map (SAM) Format
		Version 0.1.2-draft (20090820)
		http://samtools.sourceforge.net/SAM1.pdf

		The alignment section consists of multiple TAB-delimited lines with each line describing an alignment. Each line is:
		<QNAME> <FLAG> <RNAME> <POS> <MAPQ> <CIGAR> <MRNM> <MPOS> <ISIZE> <SEQ> <QUAL> \
		[<TAG>:<VTYPE>:<VALUE> [...]]

		EXAMPLE
		
			HWI-EAS185:1:1:24:584#0/1
			0
			chrY
			2536991
			255
			52M
			*
			0
			0
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			\XXXX\^\\RNNNNMX\XYMN\X`\^JYX]W\\\[XJW[VW\X]BBBBBBBB
			XA:i:0
			MD:Z:52
			NM:i:0

=cut

sub noSamHeader {
	my $self		=	shift;
	my $file		=	shift;
	$self->logDebug("Agua::Cluster::noSamHeader(file, toplines, outputfile, topfile");
	$self->logDebug("file", $file);

	#### NB: DON'T SKIP HEADER
	open(FILE, $file) or die "Agua::Cluster::Merge::noSamHeader Can't open file: $file\n";
	my $line = <FILE>;
	$self->logDebug("line", $line);
	my @elements = split " ", $line;
	$self->logDebug("No. elements: ", $#elements + 1, "");
	return 0 if $#elements < 10;
	return 0 if $elements[3] !~ /^\d+$/;
	return 0 if $elements[4] !~ /^\d+$/;
	return 0 if $elements[9] !~ /^[A-Z]+$/i;

	return 1;	
}


=head2

	SUBROUTINE		removeTop
	
	PURPOSE
	
		REMOVE AN ARBITRARY NUMBER OF THE TOP ROWS OF A FILE

=cut

sub removeTop {
	my $self		=	shift;
	my $inputfile	=	shift;
	my $number_lines=	shift;
	my $outputfile	=	shift;
	my $topfile		=	shift;
	$self->logDebug("Agua::Cluster::removeTop(inputfile, number_lines, outputfile, topfile");
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("number_lines", $number_lines);
	$self->logDebug("outputfile", $outputfile)  if defined $outputfile;
	$self->logDebug("topfile", $topfile)  if defined $topfile;


	#### SET CURRENT TIME (START TIMER)
	my $current_time =  time();

	my $tempfile = $outputfile;
	$tempfile = $inputfile . "-removeTop" if not defined $outputfile;
	$topfile = $inputfile . ".top" if not defined $topfile;
	$self->logDebug("tempfile", $tempfile);
	$self->logDebug("topfile", $topfile);

	#### SAVE RECORD SEPARATOR
	my $oldsep = $/;
	$/ = "\n";

	open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
	open(TOPFILE, ">$topfile") or die "Can't open topfile: $topfile\n";
	for ( my $i = 0; $i < $number_lines; $i++ )
	{
		my $line = <FILE>;
		print TOPFILE $line;
	}
	close(TOPFILE);
	$self->logDebug("closed topfile", $topfile);
	
	open(TEMPFILE, ">$tempfile") or die "Can't open tempfile: $tempfile\n";
	while ( <FILE> )
	{
		print TEMPFILE $_;
	}
	close(FILE) or die "Can't close inputfile: $inputfile\n";
	close(TEMPFILE) or die "Can't close tempfile: $tempfile\n";

	print `mv $tempfile $inputfile` if not defined $outputfile;

	#### RESTORE RECORD SEPARATOR
	$/ = $oldsep;

	my $label = "removeTop";

	#### SET EMPTY USAGE STATISTICS
	my $usage = [];
	
	#### GET DURATION (STOP TIMER)
	my $duration = Timer::runtime( $current_time, time() );

	#### PUSH ONTO GLOBAL USAGE STATS
	$self->addUsageStatistic($label, $duration, $usage);
}

=head2

	SUBROUTINE		isSamfile
	
	PURPOSE
	
		1. RETURN 1 IF FILE CONFORMS TO THE SAM FORMAT, 0 OTHERWISE

		2. SAM REQUIREMENTS:
		
			- HAS AT LEAST 11 FIELDS
			
			- 4TH AND 5TH FIELDS STRICTLY NUMERIC
			
			- 10TH FIELD IS SEQUENCE (I.E., NON-NUMERIC)

	NOTES

		Sequence Alignment/Map (SAM) Format
		Version 0.1.2-draft (20090820)
		http://samtools.sourceforge.net/SAM1.pdf

		The alignment section consists of multiple TAB-delimited lines with each line describing an alignment. Each line is:
		<QNAME> <FLAG> <RNAME> <POS> <MAPQ> <CIGAR> <MRNM> <MPOS> <ISIZE> <SEQ> <QUAL> \
		[<TAG>:<VTYPE>:<VALUE> [...]]

		EXAMPLE
		
			HWI-EAS185:1:1:24:584#0/1
			0
			chrY
			2536991
			255
			52M
			*
			0
			0
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			\XXXX\^\\RNNNNMX\XYMN\X`\^JYX]W\\\[XJW[VW\X]BBBBBBBB
			XA:i:0
			MD:Z:52
			NM:i:0

=cut

sub isSamfile {
	my $self		=	shift;
	my $file		=	shift;
	my $skip_header	=	shift;
	$self->logDebug("Agua::Cluster::isSamfile(file, toplines, outputfile, topfile");
	$self->logDebug("file", $file);
	$self->logDebug("skip_header", $skip_header);

	open(FILE, $file) or die "Agua::Cluster::Merge::isSamfile Can't open file: $file\n";
	if ( defined $skip_header )
	{
		for ( 0..2 )
		{
			$self->logDebug("Skipping line");

			<FILE>;
		}
	}
	
	my $line = <FILE>;
	$self->logDebug("line", $line);
	my @elements = split " ", $line;
	$self->logDebug("No. elements: " . $#elements + 1);
	return 0 if $#elements < 10;
	return 0 if $elements[3] !~ /^\d+$/;
	return 0 if $elements[4] !~ /^\d+$/;
	return 0 if $elements[9] !~ /^[A-Z]+$/i;

	return 1;	
}


=head2

	SUBROUTINE		_cumulativeConcatMerge
	
	PURPOSE
	
		1. SUCCESSIVELY MERGE ALL OF THE SAM FILES FOR
		
			EACH SPLIT INPUT FILE FOR ALL PROVIDED
			
			REFERENCES
			
		2. CUMULATIVELY ADD TO A TEMP FILE (USED TO SHOW ONGOING)
		
		3. ONCE COMPLETE, RENAME TEMP FILE TO OUTPUT FILE

=cut

sub _cumulativeConcatMerge {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	my $label			=	shift;
	$self->logDebug("Agua::Cluster::_cumulativeConcatMerge(outputdir, references, splitfiles, infile, outfile, label)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("references: ");
	print join "\n", @$references;
	$self->logDebug("\n");

	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $inputfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);
		
		#### SET BAM OUTPUT FILE 
		my $refererence_outfile = "$outputdir/$reference/$outfile";
		
		#### SET OUTPUT DIR
		my ($outdir) = "$outputdir/$reference";
		$self->logDebug("outdir", $outdir);
		
		my $label = "_cumulativeConcatMerge-$reference";
		$self->logDebug("label", $label);
		
		#### GET CUMULATIVE MERGE COMMANDS
		my $commands = [];
		push @$commands, "rm -fr $refererence_outfile";
		foreach my $inputfile ( @$inputfiles )
		{
			push @$commands, "cat $inputfile >> $refererence_outfile";
		}
		my $job = $self->setJob($commands, $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN MERGE JOBS
	$self->runJobs($jobs, $label );
}




=head2

	SUBROUTINE		cumulativeMergeBam
	
	PURPOSE
	
		1. SUCCESSIVELY MERGE ALL OF THE BAM FILES FOR
		
			EACH SPLIT INPUT FILE FOR ALL PROVIDED
			
			REFERENCES
			
		2. CUMULATIVELY ADD TO A TEMP FILE (USED TO SHOW ONGOING)
		
		3. ONCE COMPLETE, RENAME TEMP FILE TO OUTPUT FILE

=cut

sub cumulativeMergeBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references	=	shift;
	my $splitfiles		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;

	#### GET SAMTOOLS
	my $samtools = $self->samtools();

	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $bamfiles = $self->subfiles($outputdir, $reference, $splitfiles, $infile);

		#### SET BAM FILE 
		my $bamfile = "$outputdir/$reference/$outfile";

		#### NOTE THAT MERGE REQUIRES BOTH INPUT FILES TO MERGE TO A DISTINCT
		#### OUTPUT FILE, I.E., NOT LIKE A STRAIGHT CONCAT: infile >> outfile
		my $mergesub = sub {
			my $outfile		=	shift;
			my $tempfile	=	shift;
			my $subfile		=	shift;

			#### MERGE BAM FILES
			return "$samtools/samtools merge $outfile $tempfile $subfile";
		};
		
		#### GET CUMULATIVE MERGE COMMANDS
		my $commands = $self->cumulativeMergeCommands($bamfiles, $bamfile, $mergesub);
		$self->logDebug("merge commands:");
		print join "\n", @$commands;
		$self->logDebug("\n");
		
		my $label = "cumulativeMergeBam-$reference";
		my ($outdir) = $bamfile =~ /^(.+)\/[^\/]+$/; 
		$self->logDebug("label", $label);
		$self->logDebug("outdir", $outdir);
		
		my $job = $self->setJob($commands, $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN MERGE JOBS
	$self->runJobs($jobs, 'cumulativeMergeBam');
}



=head2

	SUBROUTINE		cumulativeMergeCommands
	
	PURPOSE
	
		RETURN AN ARRAY OF MERGE COMMANDS TO MERGE THE PROVIDED
		
		ARRAY OF SUBFILES INTO A SINGLE OUTPUT FILE


qq{time $maq/maq filemerge $outfile $tempfile $subfile}; 	

=cut

sub cumulativeMergeCommands {
	my $self		=	shift;
	my $subfiles	=	shift;
	my $outfile		=	shift;
	my $mergesub	=	shift;
	$self->logDebug("Agua::Cluster::cumulativeMergeCommands(job_objects)");
	$self->logDebug("length subfiles: " . length($subfiles));
	#### SET temp.file FILE FOR INCREMENTAL MERGE
	my $tempfile = "$outfile.temp";

	#### COPY FIRST SUBFILE TO TEMP FILE
	my $first_subfile = splice( @$subfiles, 0, 1);

	my $commands = [];
	#push @$commands, "echo 'Copying first subfile ($first_subfile) to temp file: $tempfile'";
	push @$commands, "time cp $first_subfile $tempfile\n";
	
	#### DO CUMULATIVE MERGE OF REMAINING SUBFILE FILES INTO TEMP FILE
	my $total_subfiles = scalar(@$subfiles);
	for ( my $i = 0; $i < @$subfiles; $i++ )
	{
		my $subfile = $$subfiles[$i];
		#push @$commands, "echo `ls -al $tempfile`";
		#push @$commands, "echo 'Doing subfile $i of $total_subfiles'";

		#### MERGE COMMAND
		my $merge_command = &$mergesub($outfile, $tempfile, $subfile);
		
		push @$commands, $merge_command;
		#push @$commands, "echo `ls -al $outfile`";	
		push @$commands, "mv $outfile $tempfile";
	}
	push @$commands, "time mv $tempfile $outfile";

	return $commands;
}	






=head2

	SUBROUTINE		merge
	
	PURPOSE
	
		1. MERGE ALL FILES PER REFERENCE IN A SERIES OF PAIRWISE
		
			MERGE BATCHES
		
		2. RUN ALL PAIRWISE MERGES ON DIFFERENT EXECUTION HOSTS
		
			IN PARALLEL
		
		THIS METHOD ASSUMES:
		
			1. THERE IS NO ORDER TO THE FILES
			
			2. ALL FILES MUST BE MERGED INTO A SINGLE FILE
		
			3. THE PROVIDED SUBROUTINE MERGES THE FILES
			
=cut

sub merge {
	my $self			=	shift;
	my $args			=	shift;
	
	my $inputfiles		=	$args->{inputfiles};
	my $outputfile		=	$args->{outputfile};
	my $mergesub		=	$args->{mergesub};

	$self->logDebug("Agua::Cluster::merge(inputfiles, outputfile, mergesub)");
	$self->logDebug("No. inputfiles: " . scalar(@$inputfiles));
	$self->logDebug("outputfile", $outputfile);
	my $counter = 0;
	while ( scalar(@$inputfiles) > 1 )
	{
		my $jobs; 

		my $label = "merge-$counter";
		$counter++;
		my ($outdir) = $$inputfiles[0] =~ /^(.+)\/[^\/]+$/; 
		$self->logDebug("label", $label);
		$self->logDebug("outdir", $outdir);

		($jobs, $inputfiles) = $self->pairwiseMergeJobs($inputfiles, $mergesub, $label, $outdir);
		$self->logDebug("No. inputfiles: " . scalar(@$inputfiles));
		$self->logDebug("Last inputfile: " . $$inputfiles[scalar(@$inputfiles) - 1]);

		## RUN JOBS
		$self->runJobs($jobs, "merge-$counter");
	}

	#### MOVE THE LAST MERGED INPUT FILE TO THE OUTPUT FILE
	my $move = "mv -f $$inputfiles[0] $outputfile";
	$self->logDebug("move", $move);
	print `$move`;
}


1;
