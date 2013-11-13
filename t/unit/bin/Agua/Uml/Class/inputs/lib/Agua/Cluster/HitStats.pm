package Agua::Cluster::HitStats;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;

#has 'submit'	=> ( isa => 'Int', is => 'rw', default => 0 );
#has 'cluster'	=> ( isa => 'Str', is => 'rw', default => '' );
#has 'queue'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'walltime'	=> ( isa => 'Str', is => 'rw', default => '' );
#has 'cpus'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'qstat'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'qsub'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'maxjobs'	=> ( isa => 'Str', is => 'rw', default => '' );
#has 'sleep'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'cleanup'	=> ( isa => 'Str', is => 'rw', default => '' );
#has 'dot'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'verbose'	=> ( isa => 'Str', is => 'rw', default => '' );
#
################################################################################
##########################       HIT STATS METHODS        ######################
################################################################################
=head2

	SUBROUTINE		readHits
	
	PURPOSE
	
		MERGE THE 'READ' COLUMN OF ALL *-index.sam FILES 
		
	NOTES
	
		1. EXTRACT READS IDS ONLY FROM ALIGNMENT FILE
			AND PRINT TO .hitid FILE

		2. MERGE ALL .hitid FILES FOR ALL SPLIT INPUT FILES
		
			FOR EACH REFERENCE INTO SINGLE .hitid FILE
			
		3. SORT .hitid FILE
		
		4. COUNT DUPLICATE LINES WITH uniq -c AND OUTPUT
		
			INTO .hitct FILE
			
		5. GENERATE DISTRIBUTION OF HITS PER READ
		
		6. REPEAT 2 - 5 GOING FROM chromosome.hitid TO
		
			genome.hitct FILE
			
=cut

sub readHits {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $splitfiles		=	shift;
	my $label			=	shift;
	my $samfile			=	shift;
	$self->logDebug("Agua::Cluster::readHits(outputdir, references, splitfiles, label)");
	$self->logCritical("samfile not defined") and exit if not defined $samfile;
	
	my $hitfile = "out.hitid";
	my $countfile = "out.hitct";
	my $count_filepath = "$outputdir/$countfile";
	my $sorted_filepath = "$outputdir/$countfile.sorted";
	my $bin_filepath = "$outputdir/$countfile.bins";
	
	#### 1. EXTRACT HIT READS IDS FROM CHROMOSOME SAM FILE
	####	AND PRINT TO CHROMOSOME .hitid FILE
	####
	$self->hitIdFiles($outputdir, $references, $samfile, $hitfile);
	$self->logDebug("Completed hitIdFiles");
	
	#### 2. SORT .hitid FILES
	####
	$self->logDebug("Doing sortHitFiles()");
	$self->sortHitFiles($outputdir, $references, $hitfile, $hitfile);
	$self->logDebug("Completed sortHitFiles()");

	######## 3. MERGE .hitid FILES FOR ALL CHROMOSOMES INTO
	########		SINGLE .hitid FILE FOR WHOLE GENOME
	########
	#####$self->logDebug("Doing mergeHits()");
	#####$self->mergeHits($outputdir, $references, $hitfile, $hitfile, $label);
	#####$self->logDebug("Completed mergeHits()");

	### 3. MERGE .hitid FILES FOR ALL CHROMOSOMES INTO
	###		SINGLE .hitid FILE FOR WHOLE GENOME
	###
	$self->logDebug("Doing pyramidMergeHits()");
	$self->pyramidMergeHits($outputdir, $references, $hitfile, "$hitfile", $label);
	$self->logDebug("Completed pyramidMergeHits()");


	######### 3. SORT .hitid FILE
	#########
	#####my $sort_command = "sort $outputdir/$hitfile -o $outputdir/$hitfile";
	#####$self->logDebug("sort command", $sort_command);
	#####my $sort_job = $self->setJob( [$sort_command], "sortHitId", $outputdir );
	#####$self->runJobs( [ $sort_job ], "sortHitId" );	
	#####$self->logDebug("Completed sortHitId");
	

	#### 4. COUNT DUPLICATE LINES WITH uniq -c AND OUTPUT
	####	INTO .hitct FILE
	####	
	my $uniq_command = "uniq -c $outputdir/$hitfile > $outputdir/$countfile";
	$self->logDebug("uniq command", $uniq_command);
	$self->logDebug("uniq command", $uniq_command);
	my $uniq_job = $self->setJob( [ $uniq_command ], "uniqHitId", $outputdir );
	$self->runJobs( [ $uniq_job ], "uniqHitId" );	
	$self->logDebug("Completed uniqHitId");



	##### 5. SORT HIT COUNTS FILE BY HIT COUNTS
	#####
	my $count_command = qq{sort -t "\t" -b -k 1,1n $count_filepath -o $sorted_filepath};
	$self->logDebug("count command", $count_command);
	my $count_job = $self->setJob( [ $count_command ], "countHitId", $outputdir );
	$self->runJobs( [ $count_job ], "countHitId" );	
	$self->logDebug("Completed countHitId");


	#### 6. BIN HIT COUNTS
	####
	my $bin_command = qq{sed -e 's/[ ]*\\([0-9]*\\) [A-Z0-9\\.\\:\\#\\/]*/\\1/' < $sorted_filepath | sed -e 's/[ ]*//g' | uniq -c > $bin_filepath};
	$self->logDebug("bin command", $bin_command);

	my $bin_job = $self->setJob( [ $bin_command ], "binHitCounts", $outputdir );
	$self->runJobs( [ $bin_job ], "binHitCounts" );	
	$self->logDebug("Completed binHitCounts");


}



=head2

	SUBROUTINE		sortHitFiles
	
	PURPOSE
	
		SORT out.hitid FILE FOR EACH REFERENCE CHROMOSOME
	
=cut

sub sortHitFiles {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	$self->logDebug("Agua::Cluster::sortHitFiles(outputdir, references, splitfiles, infile, outfile, toplines)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("references: ");
	print join "\n", @$references;
	$self->logDebug("\n");
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);

	#### SORT SINGLE SAM FILE
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $inputfile = "$outputdir/$reference/$infile";
		my $outputfile = "$outputdir/$reference/$outfile";
		
		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		my $command = qq{sort $inputfile -o $outputfile; };

		$self->logDebug("command", $command);
		my $job = $self->setJob( [$command], "sortHitFiles-$reference", "$outputdir/$reference" );
		push @$jobs, $job;
	}
	$self->logDebug("Doing runJobs, no. jobs: " . scalar(@$jobs));

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "sortHitFiles" );	
	$self->logDebug("Completed.");
}

=head2

	SUBROUTINE		hitIdFiles
	
	PURPOSE
	
		1. EXTRACT READS IDS ONLY FROM ALIGNMENT FILE
			AND PRINT TO .hitid FILE

=cut

sub hitIdFiles {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $samfile			=	shift;
	my $hitfile_name	=	shift;
	my $samfile_name	=	shift;
$self->logDebug("Agua::Cluster::hitIdFiles(outputdir, tsvfiles, sqlite, cluster, label)");
	
	$samfile_name = "out.sam" if not defined $samfile_name;
	
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		$self->logDebug("Creating hit files in parallel for reference", $reference);

		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		my $executable = "$Bin/samHits.pl";
		my $inputfile = "$outputdir/$reference/$samfile";
		my $outputfile = "$outputdir/$reference/$hitfile_name";		
		my $command = "/usr/bin/perl $executable --inputfile $inputfile | cut -f 1 > $outputfile";
		my $job = $self->setJob( [$command], "hitIdFiles-$reference", "$outputdir/$reference" );
		push @$jobs, $job;
	}

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "hitIdFiles" );	
	$self->logDebug("Completed");
}

=head2

	SUBROUTINE		mergeHits
	
=cut

sub mergeHits {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $hitfile_name	=	shift;
	my $outfile_name	=	shift;
	my $label			=	shift;
	$self->logDebug("Agua::Cluster::mergeHits(outputdir, references, hitfile_name, outfile_name, label)");

	$self->logDebug("label", $label);
	
	#### DO MERGE OF SORTED FILES
	my $outputfile = "$outputdir/$outfile_name";
	my $commands = [];
	push @$commands, "rm -fr $outputfile";

	my $command = "sort -m ";
	foreach my $reference ( @$references )
	{
		$command .= " $outputdir/$reference/$hitfile_name ";
	}
	$command .= " -o $outputfile";
	push @$commands, $command;
	$self->logDebug("merge commands: @commands");
	$self->logDebug("\n");
	
	my $job = $self->setJob($commands, $label, $outputdir);

	#### RUN MERGE JOBS
	$self->runJobs([ $job ], "mergeHits-$label" );
}

=head2

	SUBROUTINE		pyramidMergeHits
	
=cut

sub pyramidMergeHits {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $hitfile_name	=	shift;
	my $outfile_name	=	shift;
	my $label			=	shift;
	$self->logDebug("Agua::Cluster::pyramidMergeHits(outputdir, references, hitfile_name, outfile_name, label)");
	$self->logDebug("label", $label);
	
	#### DO MERGE OF SORTED FILES
	my $outputfile = "$outputdir/$outfile_name";

	my $mergesub = sub {
		my $firstfile	=	shift;
		my $secondfile	=	shift;

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

		#### MERGE SORTED FILES
		my $command = "sort -m $firstfile $secondfile -o $outfile\n";
		
		return ($command, $outfile);
	};

	#### REMOVE OUTPUT FILE IF EXISTS
	$self->logDebug("Doing rm -fr $outputfile") if -f $outputfile;
	print `rm -fr $outputfile` if -f $outputfile;
	$self->logDebug("Can't delete outputfile", $outputfile) if -f $outputfile;

	#### SET CURRENT TIME (START TIMER)
	my $current_time =  time();

	#### GENERATE INPUT FILE LIST
	my $inputfiles = [];
	foreach my $reference ( @$references )
	{
		push @$inputfiles, "$outputdir/$reference/$hitfile_name";
	}
	
	my $alljobs = [];
	my $running = 1;
	my $counter = 0;
	while ( $running )
	{
		$self->logDebug("running");
		$counter++;
		
		my $outputfile = "$outputdir/$outfile_name";
		my $label = "_pyramidMerge-$counter";
		$self->logDebug("label", $label);

		my $jobs = [];
		($jobs, $inputfiles) = $self->mergeJobs(
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
	my $datetime = Timer::current_datetime();
	$self->logDebug("completed label", $label);
	$self->logDebug("completed datetime", $datetime);
	$self->logDebug("completed duration", $duration);
}


=head2

	SUBROUTINE		splitReads
	
	PURPOSE
	
		1. IF SPLIT READS FILE IS NOT PRESENT OR EMPTY:
		
			-	COUNT TOTAL NUMBER OF READS PER INPUT SPLIT FILE
		
		2. OTHERWISE, GATHER THE ABOVE READ COUNTS FROM THE
		
			SPLIT READS FILE
			
		3. 	RETURN HASH OF FILENAMES VS. READ COUNTS
		
=cut

sub splitReads {	
	my $self			=	shift;
	my $splitreadsfile	=	shift;
	my $splitfiles		=	shift;
	my $clean			=	shift;
	$self->logDebug("Agua::Cluster::splitReads(splitreadsfile, splitfiles, clean)");
	$self->logDebug("splitreadsfile", $splitreadsfile);
	$self->logDebug("clean", $clean);

	my $reads = {};
	my $total_reads = 0;
	if ( defined $clean or not -f $splitreadsfile )
	{
		open(OUT, ">$splitreadsfile") or die "Can't open splitreadsfile: $splitreadsfile\n";
		foreach my $filepair ( @$splitfiles )
		{
			foreach my $file ( @$filepair )
			{
				my $lines = $self->countLines($file);
				my $read_count = $lines / 4;
				$total_reads += $read_count;
				$self->logDebug("$file read_count", $read_count);
				$reads->{splitfiles}->{$file} = $read_count;
				print OUT "$file\t$read_count\n";
			}
		}
		close(OUT) or die "Can't close splitreadsfile: $splitreadsfile\n";
		$self->logDebug("splitreadsfile printed:\n\n$splitreadsfile\n");
	}
	else
	{
		open(FILE, $splitreadsfile) or die "Can't open splitreadsfile: $splitreadsfile\n";
		while ( <FILE> )
		{
			next if $_ =~ /^\s*$/;
			my ($file, $read_count) = /^(\S+)\s+(\d+)/;
			
			$self->logDebug("file read_count: $file    $read_count");
			$reads->{splitfiles}->{$file} = $read_count;
			$total_reads += $read_count;
		}
		close(FILE) or die "Can't close splitreadsfile: $splitreadsfile\n";
	}
	$reads->{total} = $total_reads;

	$self->logDebug(`cat $splitreadsfile`);
	
	return $reads;
}




=head2

	SUBROUTINE		splitHits
	
	PURPOSE
	
		1. IF SPLIT HITS FILE IS NOT PRESENT OR EMPTY:
		
			-	COUNT THE HITS PER CHROMOSOME, BREAKDOWN BY
			
				INPUT SPLIT FILE
		
		2. OTHERWISE, GATHER THE ABOVE HIT COUNTS FROM THE
		
				SPLIT HITS FILE
			
		3. 	RETURN HASH OF FILENAMES VS. HIT COUNTS
		
=cut

sub splitHits {	
	my $self			=	shift;
	my $splithitsfile	=	shift;
	my $splitfiles		=	shift;
	my $references		=	shift;
	my $clean			=	shift;
	$self->logDebug("Agua::Cluster::splitHits(splithitsfile, splitfiles, reference, clean)");
	$self->logDebug("splithitsfile", $splithitsfile);
	$self->logDebug("references", $references);
	$self->logDebug("clean", $clean);
	
	my $hits = {};
	my $total_hits = 0;
	if ( defined $clean or not -f $splithitsfile )
	{
		
		open(OUT, ">$splithitsfile") or die "Can't open splithitsfile: $splithitsfile\n";

		my $samfiles;
		for my $reference ( @$references )
		{	
			#### GATHER STATS FROM ALL SPLITFILES
			my $total_hits = 0;
			foreach my $splitfile ( @$splitfiles )
			{
				#### SET *.sam FILE
				my ($basedir, $index) = $$splitfile[0] =~ /^(.+?)\/(\d+)\/([^\/]+)$/;
				my $outputdir = "$basedir/$reference";
				my $samfile = "$outputdir/$index/accepted_hits.sam";
				push @$samfiles, $samfile;
				$self->logDebug("samfile", $samfile);
	
				my $hit_count = $self->countLines($samfile);
				$self->logDebug("hit_count", $hit_count);
				$hits->{$reference}->{splitfiles}->{$$splitfile[0]} = $hit_count;
				print OUT "$reference\t$$splitfile[0]\t$hit_count\n";

				$total_hits += $hit_count;
			}
			
			#### SAVE TOTAL HITS COUNT
			$hits->{$reference}->{totalhits} = $total_hits;
		}	
		close(OUT) or die "Can't close splithitsfile: $splithitsfile\n";
		$self->logDebug("splithitsfile printed:\n\n$splithitsfile\n");
	}
	else
	{
		open(FILE, $splithitsfile) or die "Can't open splithitsfile: $splithitsfile\n";
		while ( <FILE> )
		{
			next if $_ =~ /^\s*$/;
			my ($file, $hit_count) = /^\S+\s+(\S+)\s+(\d+)/;
			$hits->{splitfiles}->{$file} = $hit_count;
			$total_hits += $hit_count;
		}
		close(FILE) or die "Can't close splithitsfile: $splithitsfile\n";
	}

	$self->logDebug(`cat $splithitsfile`);
	
	return $hits;
}




=head2

	SUBROUTINE		countLines
	
	PURPOSE
	
		QUICKLY COUNT AND RETURN THE NUMBER OF LINES IN A FILE
		
=cut

sub countLines {
	my $self		=	shift;
	my $file		=	shift;
	
	open(FILE, $file) or die "Can't open file: $file\n";
	my $counter = 0;
	while(<FILE>)
	{
		$counter++;
	}
	close(FILE);
	
	return $counter;
}




1;
