package Agua::Cluster::Sort;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;
################################################################################
##########################        SORT METHODS         #########################
################################################################################
=head2

	SUBROUTINE		sortBam
	
	PURPOSE
	
		SORT BAM FILE BY LEFTMOST COORDINATES
		
		# samtools sort out.bam out.sorted.bam
		
		NB: Optionally create temporary files <out.prefix>.%d.bam

		when the whole alignment cannot be fitted into memory

		(controlled by option -m)
		
=cut

sub sortBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 		=	shift;
	my $inputfile		=	shift;
	my $outputfile		=	shift;
$self->logDebug("(outputdir, references, inputfile, outputfile)");
$self->logDebug("outputdir", $outputdir);
$self->logDebug("references: @$references");
$self->logDebug("inputfile", $inputfile);
$self->logDebug("outputfile", $outputfile);

	
	#### SET DEFAULT INPUT FILE
	$inputfile = "out.bam" if not defined $inputfile;

	#### SET DEFAULT OUTPUT FILE STUB
	$outputfile = $inputfile if not defined $outputfile;
	
	#### SET SORTED FILE NAME AS OUTPUT FILE
	my $sortedfile = $outputfile;
	
	#### GET SAMTOOLS
	my $samtools = $self->samtools();
	
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $bamfile = "$outputdir/$reference/$inputfile";
		my $sortedfile_stub = "$outputdir/$reference/$sortedfile";
		$sortedfile_stub =~ s/\.bam$//;

		#### SET SORTED FILE STUB AS '.temp' IF INPUT FILE IS SAME AS OUTPUT FILE
		$sortedfile_stub .= ".temp" if $inputfile eq $outputfile;
		$self->logDebug("sortedfile", $sortedfile);

		my $command = "$samtools/samtools sort $bamfile $sortedfile_stub;\n";
		
		#### mv .temp FILE TO OUTPUT FILE IF INPUT FILE IS SAME AS OUTPUT FILE
		$command .= "mv -f $sortedfile_stub.bam $outputfile" if $inputfile eq $outputfile;
		
		my $label = "sortBam-$reference";
		my $outdir = "$outputdir/$reference";

		my $job = $self->setJob( [ $command ], $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN JOBS
	$self->runJobs($jobs, "sortBam");
}


=head2

	SUBROUTINE		sortSam
	
	PURPOSE
	
		SORT SAM FILE FOR EACH REFERENCE:
		
			1. SORT SAM FILE BY LEFTMOST COORDINATES
		
			2. USE LINIX sort -k 4 TO SORT BY THE FOURTH COLUMN IN SAM FILE
		
			HWI-EAS185:1:3:1636:994#0       0       chr1    3035487 255     52M     *       0       0     CTTTGGGTGCTCTCACACTCCCGAGACTAGAGTGGGGGTCCCCGAAAGGGGG    aaa_a`a\_aaaaaaaaaZaaa_X`Xa`a``VJY\`\ZP`aBBBBBBBBBBB    NM:i:1

	
=cut

sub sortSam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references		=	shift;
	my $infile			=	shift;
	my $outfile			=	shift;
	$self->logDebug("Agua::Cluster::sortSam(outputdir, references, splitfiles, infile, outfile, toplines)");
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("No. references: " . scalar(@$references));
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);

	#### SORT SINGLE SAM FILE
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		my $inputfile = "$outputdir/$reference/$infile";
		my $outputfile = "$outputdir/$reference/$outfile";
		
		#### HANDLE INPUTFILE = OUTPUTFILE
		my $writeover = 0;
		$writeover = 1 if $outputfile eq $inputfile;
		$outputfile .= ".temp" if $outputfile eq $inputfile;
		$self->logCritical("outputfile is a directory: $outputfile") and exit if -d $outputfile;

		#### CLEAN UP PREVIOUS OUTPUTFILE
		print `rm -fr $outputfile`;
		$self->logCritical("Can't remove outputfile: $outputfile") and exit if -f $outputfile;

		#### SET EXECUTABLE SCRIPT TO CONVERT SAM TO TSV
		my $command = qq{sort -t "	" -k 3,3 -k 4,4n $inputfile -o $outputfile; };

		#### HANDLE INPUTFILE = OUTPUTFILE
		$command .= qq{mv -f $outputfile $inputfile} if $writeover; 

		$self->logDebug("command", $command);
		my $job = $self->setJob( [$command], "sortSam-$reference", "$outputdir/$reference" );
		#### OVERRIDE checkfile
		$outputfile =~ s/\.temp$//;
		$job->{checkfile} = $outputfile;

		push @$jobs, $job;
	}
	$self->logDebug("Doing runJobs, no. jobs: " . scalar(@$jobs));

	#### RUN COMMANDS IN PARALLEL
	$self->runJobs( $jobs, "sortSam" );	
	$self->logDebug("Completed.");
}



=head2

	SUBROUTINE		indexBam
	
	PURPOSE
	
		CONVERT SAM FILES INTO BAM FILES
		# samtools index aln.sorted.bam
		
=cut

sub indexBam {
	my $self			=	shift;
	my $outputdir		=	shift;
	my $references 	=	shift;
	
	#### SET SAMTOOLS INDEX
	my $samtools = $self->samtools();
	my $samtools_index = $self->samtoolsindex();
	
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		#### GET SAM FILES
		my $bamfile = "$outputdir/$reference/out.bam";

		my $command = "$samtools/samtools index $bamfile";
		my $label = "indexBam-$reference";
		my $outdir = "$outputdir/$reference";

		my $job = $self->setJob( [ $command ], $label, $outdir);
		push @$jobs, $job;
	}

	#### RUN JOBS
	$self->runJobs($jobs, "indexBam");
}





1;
