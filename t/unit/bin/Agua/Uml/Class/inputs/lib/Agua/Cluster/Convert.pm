package Agua::Cluster::Convert;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Data::Dumper;

################################################################################
##########################      CONVERT METHODS        #########################
################################################################################
=head2

	SUBROUTINE		simpleFastqHeader
	
	PURPOSE
	
		CONVERT FASTQ HEADER: REMOVE MACHINE ID AND ADD READ '#/NUMBER' 

=cut

sub simpleFastqHeader {
	my $self		=	shift;
	my $inputfiles	=	shift;
	my $matefiles	=	shift;
	my $label		=	shift;
	
	$label = "eland" if not defined $label;
	$self->logDebug("Agua::Cluster::simpleFastqHeader(inputfiles, matefiles)");

	$self->logDebug("inputfiles", $inputfiles);
	$self->logDebug("matefiles", $matefiles)  if defined $matefiles;

	my $infiles;
	push @$infiles, split ",", $inputfiles;
	$self->logDebug("infiles: @$infiles");
	
	my $outfiles;
	my $matenumber = 1;
	#my $matenumber;
	#$matenumber = 1 if defined $matefiles;
	foreach my $infile ( @$infiles )
	{
		my $outfile	=	$infile;
		$outfile =~ s/(\.[^\.]{1,5})$/.$label$1/;
		push @$outfiles, $outfile;
		$self->simpleHeader($infile, $outfile, $matenumber);
	}
	$self->inputfiles(join ",", @$outfiles);
	$self->logDebug("NEW inputfiles: " . $self->inputfiles());
	return if not defined $matefiles;

	#### DO MATEFILES
	$matenumber = 2;
	$infiles = undef;	
	push @$infiles, split ",", $matefiles;

	$outfiles = undef;
	foreach my $infile ( @$infiles )
	{
		my $outfile	=	$infile;
		$outfile =~ s/(\.[^\.]{1,5})$/.$label$1/;
		push @$outfiles, $outfile;
		$self->simpleHeader($infile, $outfile, $matenumber);
	}
	$self->matefiles(join ",", @$outfiles);
	$self->logDebug("NEW matefiles: " . $self->matefiles());	;
}



=head2

	SUBROUTINE		simpleHeader
	
	PURPOSE
	
		CONVERT FASTQ HEADER: REMOVE MACHINE ID AND ADD READ '#/NUMBER' 

=cut


sub simpleHeader {
	my $self		=	shift;
	my $infile		=	shift;
	my $outfile		=	shift;
	my $matenumber	=	shift;
	$self->logDebug("Agua::Cluster::simpleHeader(infile, outfile)");
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);
	
	my $command = "sed -e 's/ [A-Za-z0-9\\.\\_\\-]*:\\([0-9\\:]*[0-9\\:]*[0-9\\:]*[0-9\\:]*\\)/:\\1#0\\/$matenumber/' < $infile  | sed -e 's/[ ]*length=[0-9]*[ ]*//' > $outfile";
	$self->logDebug("command", $command);
	print `$command`;
}

=head2

	SUBROUTINE		subdirSamToBam
	
	PURPOSE
	
		CONVERT ALL SAM FILES IN chr*/<NUMBER> SUBDIRECTORIES
		
		INTO BAM FILES

			samtools view -bt ref_list.txt -o aln.bam aln.sam.gz

		INPUTS
		
			1. OUTPUT DIRECTORY USED TO PRINT CHROMOSOME-SPECIFIC
			
				SAM FILES TO chr* SUB-DIRECTORIES
			
			2. LIST OF REFERENCE FILE NAMES
		
			3. SPLIT INPUT FILES LIST
			
			4. NAME OF SAM INPUTFILE (E.G., "accepted_hits.sam")

=cut

sub subdirSamToBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 		=	shift;
	my $splitfiles		=	shift;
	my $inputfile		=	shift;
	
	#### SET SAMTOOLS INDEX
	my $samtools = $self->samtools();
	my $samtools_index = $self->samtoolsindex();
	
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $samfiles = $self->subfiles($outputdir, $reference, $splitfiles, $inputfile);
		#### 	1. CONVERT SAM FILES INTO BAM FILES
		# samtools view -bt ref_list.txt -o aln.bam aln.sam.gz
		my $bamfiles = [];
		my $counter = 0;
		my $commands = [];
		foreach my $samfile ( @$samfiles )
		{
			$counter++;
			
			my $bamfile = $samfile;
			$bamfile =~ s/sam$/bam/;
			my $command = "$samtools/samtools view -bt $samtools_index/$reference.fai -o $bamfile $samfile";
			push @$commands, $command;
		}

		my $label = "samToBam-$reference";
		my $outdir = "$outputdir/$reference";
		my $job = $self->setJob($commands, $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN CONVERSION JOBS
	$self->logDebug("DOING runJobs for " . scalar(@$jobs) . " jobs\n");
	$self->logDebug("DOING runJobs for " . scalar(@$jobs) . " jobs\n");

	$self->runJobs($jobs, 'subdirSamToBam');
	$self->logDebug("Completed samToBam");
}



=head2

	SUBROUTINE		bamToSam
	
	PURPOSE
	
		CONVERT EACH CHROMOSOME BAM FILE INTO A SAM FILE
		
=cut

sub bamToSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
$self->logDebug("Agua::Cluster::bamToSam(outputdir, references, infile, outfile)");
$self->logDebug("outputdir", $outputdir);
$self->logDebug("references: @$references");
$self->logDebug("infile", $infile);
$self->logDebug("outfile", $outfile);

	#### SET DEFAULT FILE NAMES IF NOT DEFINED
	$infile = "accepted_hits.bam" if not defined $infile;
	$outfile = "accepted_hits.sam" if not defined $outfile;
	
	#### GET SAMTOOLS
	my $samtools = $self->samtools();

	my $jobs = [];
	# CONVERT BAM TO SAM: samtools view -o out.sam in.bam 
	foreach my $reference ( @$references )
	{
		my $bamfile = "$outputdir/$reference/$infile";
		my $samfile = "$outputdir/$reference/$outfile";
		my $command = "$samtools/samtools view -o $samfile $bamfile";
$self->logDebug("command", $command);

		my $label = "bamToSam-$reference";
		my ($outputdir) = $bamfile =~ /^(.+)\/[^\/]+$/; 
		$self->logDebug("label", $label);
		$self->logDebug("outputdir", $outputdir);
		
		my $job = $self->setJob([$command], $label, $outputdir);
		push @$jobs, $job;
	}

	#### RUN CONVERSION JOBS
	$self->logDebug("DOING bamToSam conversion...");
	$self->runJobs($jobs, "bamToSam");
	$self->logDebug("FINISHED bamToSam conversion.");
}


=head2

	SUBROUTINE		samToBam
	
	PURPOSE
	
		CONVERT SAM FILES INTO (UNSORTED) BAM FILES

			samtools view -bt ref_list.txt -o aln.bam aln.sam.gz
		
=cut

sub samToBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	
	#### SET DEFAULT FILE NAMES IF NOT DEFINED
	$infile = "out.sam" if not defined $infile;
	$outfile = "out.bam" if not defined $outfile;

	#### SET SAMTOOLS INDEX
	my $samtools = $self->samtools();
	my $samtools_index = $self->samtoolsindex();

	$self->removeFa($outputdir, $references, $infile, $outfile);
	
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $samfile = "$outputdir/$reference/$infile";
		my $bamfile = "$outputdir/$reference/$outfile";

		my $command = "$samtools/samtools view -bt $samtools_index/$reference.fai -o $bamfile $samfile";
		
		$self->logDebug("command", $command);
		
		my $label = "samToBam-$reference";
		my $outdir = "$outputdir/$reference";

		my $job = $self->setJob( [ $command ], $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN JOBS
	$self->runJobs($jobs, "samToBam");
}


sub removeFa {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 		=	shift;
	my $infile			=	shift;
	
	#### SET DEFAULT FILE NAMES IF NOT DEFINED
	$infile = "out.sam" if not defined $infile;
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $samfile = "$outputdir/$reference/$infile";
		my @commands;
		push(@commands, "sed s/$reference.fa/$reference/ $samfile > $samfile.temp");
		push(@commands, "mv $samfile.temp $samfile");
		$self->logDebug("commands: @commands");
		$self->logDebug("\n");
		my $label = "removeFa-$reference";
		my $outdir = "$outputdir/$reference";

		my $job = $self->setJob( \@commands, $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN JOBS
	$self->runJobs($jobs, "removeFa");
}


sub convertReferences {	#### CONVERT .fa REFERENCE FILES TO INDEXED *ebwt FILES
	my $self		=	shift;
	my $inputdir	=	shift;
	my $outputdir	=	shift;
	my $subdirs		=	shift;
	
	#### CHECK INPUTS
	$self->logCritical("inputdir not defined ") and exit if not defined $inputdir;
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("subdirs", $subdirs)  if defined $subdirs;

	#### CREATE OUTPUTDIR
	$outputdir = $inputdir if not defined $outputdir;
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logError("Cannot create outputdir: $outputdir") and exit(1) if not -d $outputdir;

	if ( defined $subdirs ) {
		my $subdirectories = $self->getSubdirs($inputdir);
		$self->logDebug("subdirectories: @$subdirectories");
		foreach my $subdirectory ( @$subdirectories )
		{
			next if $subdirectory =~ /^\./;
			my $dirpath = "$inputdir/$subdirectory";
			next if not -d $dirpath;
			chdir($outputdir) or die "Can't change to download directory: $outputdir\n";
			$self->indexReferenceFiles("$inputdir/$subdirectory", "$outputdir/$subdirectory");
		}
	}
	else {
		$self->indexReferenceFiles($inputdir, $outputdir);
	}
	
	$self->logDebug("AFTER indexReferenceFiles()");
	
}


1;
