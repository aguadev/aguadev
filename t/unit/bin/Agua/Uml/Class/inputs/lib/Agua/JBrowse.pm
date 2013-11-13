use MooseX::Declare;

=head2

	PACKAGE		JBrowse
	
	PURPOSE
	
		THIS MODULE ENABLES THE FOLLOWING USE SCENARIOS:
		
		
		1. USER GENERATES JBROWSE JSON FILES IN OWN FOLDER
	
		    1.1 CREATE USER-SPECIFIC VIEW FOLDER

			1.2 GENERATE JBrowse FEATURES IN PARALLEL ON A CLUSTER

		        plugins/view/jbrowse/users/__username__/__project__/__view__/data

			1.3 COPY BY ln -s ALL STATIC FEATURE TRACK SUBFOLDERS
			
				(I.E., AT THE chr*/FeatureDir LEVEL) TO THE USER'S VIEW FOLDER.
 			
				NB: __NOT__ AT A HIGHER LEVEL BECAUSE WE WANT TO BE ABLE
				
				TO ADD/REMOVE DYNAMIC TRACKS IN THE USER'S VIEW FOLDER WITHOUT
				
				AFFECTING THE PARENT DIRECTORY OF THE STATIC TRACKS.
				
				THE STATIC TRACKS ARE MERELY INDIVIDUALLY 'BORROWED' AS IS.


		2. USER ADDS/REMOVES TRACKS TO/FROM VIEW
		
			2.1 ADD/REMOVE FEATURE trackData.json INFORMATION TO/FROM data/trackInfo.js
			
			2.2 RERUN generate-names.pl AFTER EACH ADD/REMOVE
			
		
=cut

use strict;
use warnings;
use Carp;

#### EXTERNAL MODULES
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

class Agua::JBrowse with (Agua::Cluster::Checker,
	Agua::Cluster::Cleanup,
	Agua::Cluster::Jobs,
	Agua::Cluster::Loop,
	Agua::Cluster::Usage,
	Agua::Cluster::Util,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::SGE) {
#### INTERNAL MODULES

use Conf::Agua;
use Data::Dumper;
use File::Path;
use File::Copy;
use JSON 2;
use IO::File;
use Fcntl ":flock";
use POSIX qw(ceil floor);

# FLAGS
has 'compress'		=> ( isa => 'Bool|Undef', is => 'rw', default => 0 );
# INTS
has 'chunksize'		=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'sortmem'		=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
has 'SHOWLOG'		=> ( isa => 'Int', is => 'rw', default => 4 );  
has 'PRINTLOG'		=> ( isa => 'Int', is => 'rw', default => 5 );
# STRINGS
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'inputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'filename'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'filetype'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'label'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'key'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'refseqfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'trackfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'jbrowse'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'species'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'build'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'htmlroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'chromofile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
# OBJECTS
has 'conf'			=> ( isa => 'Conf::Agua|Undef', is => 'rw' );
has 'config'		=> ( isa => 'HashRef', is => 'rw');
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw');

	####/////}

method BUILD ($hash) {
	$self->setJsonParser();
}

method gtfToGff ($args) {
=head2

	SUBROUTINE		gtfToGff
	
	PURPOSE
	
		CONVERT GTF TO GFF FILES

	INPUTS
	
		1. REFSEQS FILE CONTAINING AN ENTRY FOR EACH REFERENCE CHROMOSOME
	
=cut
	$self->logDebug(")");
	$self->logDebug("args", $args);
	
	#### DO SINGLE FILE IF SPECIFIED	
	$self->_gtfToGff($args)
		and return if not defined $args->{inputdir};

	#### DO ALL FILES IN INPUT DIRECTORY
	opendir(DIR, $args->{inputdir}) or die "Can't open inputdir directory: $args->{inputdir}\n";
	my @infiles = readdir(DIR);
	close(DIR);
	
	foreach my $infile ( @infiles )	
	{
		my $filepath = "$args->{inputdir}/$infile";
		next if not -f $filepath;
		next if not $infile =~ /\.gtf$/;

		$self->logDebug("infile", $infile);
		$args->{inputfile} = $infile;
		($args->{feature}) = $infile;
		$args->{feature} =~ s/\.[^\.]{3,5}$//;
		$self->_gtfToGff($args);	
	}		
}

method _gtfToGff ($args) {
=head

	SUBROUTINE		_gtfToGff
	
	PURPOSE
	
		CONVERT A CHROMOSOME GTF FILE INTO GFF FORMAT
		
	NOTES
	
		TOP FOLDER OF inputdir PATH MUST BE THE NAME OF THE
		
		CHROMOSOME
=cut
	my $inputdir	=	$args->{inputdir};
	my $inputfile	=	$args->{inputfile};
	my $outputdir	=	$args->{outputdir};
	my $feature		=	$args->{feature};
	my $refseqfile	=	$args->{refseqfile};
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("feature", $feature);
	$self->logDebug("refseqfile", $refseqfile);

	#### GET REFSEQ	RECORD FOR THIS CHROMOSOME
	my ($chromosome) = $inputdir =~ /([^\/]+)$/;
	my $refseq = $self->getRefseq($refseqfile, $chromosome);
	$self->logDebug("refseq", $refseq);
	
	return if not $refseq;

	my @args;
	push @args, "--inputfile $inputfile";
	push @args, "--inputdir $inputdir";
	push @args, "--outputdir $outputdir";
	push @args, "--feature $feature";
	push @args, "--refseqfile $refseqfile";

	$self->logDebug("Doing files in input directory", $inputdir);
	#### GET REFERENCE SEQUENCE INFO
	my $reference = $refseq->{name};
	my $start = $refseq->{start};
	my $end = $refseq->{end};
	$self->logDebug("reference", $reference);
	$self->logDebug("start", $start);
	$self->logDebug("end", $end);

	#### CREATE OUTPUT SUBDIR IF NOT EXISTS
	my $output_subdir = "$outputdir/$reference";
	File::Path::mkpath($output_subdir) or die "Can't create output subdir: $output_subdir" if not -d $output_subdir;
	
	my $infile = "$inputdir/$inputfile";
	my $outfile = "$outputdir/$inputfile";
	$outfile =~ s/gtf$/gff/;
	$self->logDebug("infile", $infile);
	$self->logDebug("outfile", $outfile);
	
	#### OPEN OUTPUT FILE AND PRINT RUN COMMAND, DATE AND REFERENCE SEQUENCE LINE
	$self->logDebug("Can't find input file", $infile) and next if not -f $infile;
	open(OUTFILE, ">$outfile") or die "Can't open output file: $outfile\n";
	print OUTFILE "### $0 @args\n";
	print OUTFILE "####", Util::datetime(), "\n\n";
	print OUTFILE "$reference\trefseqfile\trefseqfile\t$start\t$end\t.\t.\t.\tName=$reference\n";
	
	#### OPEN INPUT FILE
	open(FILE, $infile) or die "Can't open input file: $infile\n";
	$/ = "\n";
	my $counter = 0;
	while ( <FILE> )
	{
		next if $_ =~ /^\s*$/;
		$counter++;
		if ( $counter % 10000 == 0 ) {	$self->logDebug("$counter");	}
		my ($start, $last) = $_ =~ /^(\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+)(.+)$/;
		$self->logDebug("last not defined in line", $_)
			and next if not defined $start;
		$self->logDebug("last not defined in line", $_)
			and next if not defined $last;
		
		#### PARSE END OF LINE INFO
		my @elements = split ";", $last;
		$last = '';
		foreach my $element ( @elements )
		{
			next if $element =~ /^\s*$/;
			$element =~ s/^\s+//;
			$element =~ s/\s+$//;
			my ($key, $value) = $element =~ /^(\S+)\s+(.+)$/;
			
			if ( $key eq "transcript_id" )
			{
				$value =~ s/"//g;
				$last = "Name=$value";
			}
		}
		$last =~ s/;$//;
	
		#### PARSE START OF LINE INFO
		my @fields = split " ", $start;
		
		#### SET FEATURE
		$fields[2] = $feature;
		
		#### CORRECT SCORE TO NO DECIMAL PLACES
		$fields[5] =~ s/\.[0]+//g;
	
		#### ADD LAST ENTRY TO FIELDS
		push(@fields, $last);
		my $line = join "\t", @fields;
		print OUTFILE "$line\n";
	}
	close(FILE);
	close(OUTFILE);
	$self->logDebug("$outfile");

}


method getRefseq ($refseqfile, $chromosome) {
	$self->logDebug("chromosome)");
	#### CREATE REFSEQ HASH
	my $skip_assign = "refSeqs =";
	my $refseqs = $self->readJson($refseqfile, $skip_assign);
	$self->logDebug("refseqs[0]", $$refseqs[0]);

	foreach my $entry ( @$refseqs )
	{
		return $entry if $entry->{name} eq $chromosome;
	}

	return;
}

#### GENERATE refSeqs.js
method generateReference ($inputdir, $outputdir, $chunksize) {
=head2

	SUBROUTINE		generateReference
	
	PURPOSE	
  
		1. CREATE seq DIR WITH *.txt FILE CHUNKS FOR REFERENCE SEQUENCE
		
		2. CREATE refSeqs.js JSON FILE CONTAINING ENTRIES FOR ALL CHROMOSOMES

    INPUT

			1. chromosome-sizes.txt FILE GENERATED BY chromosomeSizes.pl

			cat /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta/chromosome-sizes.txt
			
				chr1    0       273269105       273269105
				chr2    273269106       536640798       263371692
				chr3    536640799       711125402       174484603
				chr4    711125403       901993930       190868527
				chr5    901993931       1078552066      176558135
	
			2. CHUNK SIZE FOR GENERATING FEATURES
			
			3. OUTPUT DIRECTORY
			
    OUTPUT
    
        1. OUTPUT FILE refSeqs.js IN OUTPUT DIRECTORY
	
		refSeqs =
		[
		   {
			  "length" : 247249719,
			  "name" : "chr1",
			  "seqDir" : "data/seq/chr1",
			  "seqChunkSize" : 20000,
			  "end" : 247249719,
			  "start" : 0
		   }
		   ,
		   {
			  "length" : 242951149,
			  "name" : "chr2",
			  "seqDir" : "data/seq/chr2",
			  "seqChunkSize" : 20000,
			  "end" : 242951149,
			  "start" : 0
		   }
		   ,
		   ...
		]

=cut
	
	#### GET VARIABLES IF NOT DEFINED
	$outputdir	=	$self->outputdir() if not defined $outputdir;
	$inputdir	=	$self->inputdir() if not defined $inputdir;
	$chunksize	=	$self->chunksize() if not defined $chunksize;

	#### CHECK INPUTS
	$self->logError("Agua::JBrowse::generateRefseq    outputdir not defined") and exit if not defined $outputdir;
	$self->logError("Agua::JBrowse::generateRefseq    inputdir not defined") and exit if not defined $inputdir;
	$self->logError("Agua::JBrowse::generateRefseq    chunksize not defined") and exit if not defined $chunksize;

	#### CREATE OUTPUT DIR IF NOT EXISTS	
	$self->logDebug("outputdir is a file", $outputdir) if -f $outputdir;
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logDebug("Can't create output dir", $outputdir) if not -d $outputdir;
	
	#### GET CHROMOSOMES 
	my $files = $self->getFiles($inputdir);
	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] !~ /\.fa$/ ) {
			splice(@$files, $i, 1);
			$i--;
		}
	}
	$files = $self->sortNaturally($files);
	
	my $volume		=	$self->conf()->getKey("bioapps", "DATAVOLUME");
	$self->logDebug("volume", $volume);

	my $jbrowse 	= 	$self->conf()->getKey("applications:$volume", "JBROWSE");
	$self->logDebug("jbrowse", $jbrowse);	
	my $executable = "$jbrowse/prepare-refseqs.pl";

	`mkdir -p $outputdir/data`;
	$self->logDebug("Can't create outputdir: $outputdir") if not -d $outputdir;
	chdir($outputdir);
	
	foreach my $file ( @$files )
	{
		my $command = qq{$executable \\
--fasta $inputdir/$file \\
--out data \\
--chunksize $chunksize};
		print "$command\n";
		print `$command`;
	}
	
	#### REPORT 
	my $refseqfile = "$outputdir/data/refSeqs.js";
	$self->logDebug("Printed refseqfile", $refseqfile);
}

method createRefseqsFile ($outputdir, $chromofile, $chunksize) {
=head2

	SUBROUTINE		generateRefseqFile
	
	PURPOSE	
  
		CREATE A refSeqs.js JSON FILE CONTAINING ENTRIES FOR ALL CHROMOSOMES
		
		IN THE REFERENCE GENOME, E.G., IF NEED TO MODIFY SEQUENCE DIR OR
		
		CHUNK SIZE INDEPENDENTLY OF RUNNING JBROWSE'S prepare-refseqs.pl

    INPUT

			1. chromosome-sizes.txt FILE GENERATED BY chromosomeSizes.pl

			cat /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta/chromosome-sizes.txt
			
				chr1    0       273269105       273269105
				chr2    273269106       536640798       263371692
				chr3    536640799       711125402       174484603
				chr4    711125403       901993930       190868527
				chr5    901993931       1078552066      176558135
	
			2. CHUNK SIZE FOR GENERATING FEATURES
			
			3. OUTPUT DIRECTORY
			
    OUTPUT
    
        1. OUTPUT FILE refSeqs.js IN OUTPUT DIRECTORY
	
		refSeqs =
		[
		   {
			  "length" : 247249719,
			  "name" : "chr1",
			  "seqDir" : "data/seq/chr1",
			  "seqChunkSize" : 20000,
			  "end" : 247249719,
			  "start" : 0
		   }
		   ,
		   {
			  "length" : 242951149,
			  "name" : "chr2",
			  "seqDir" : "data/seq/chr2",
			  "seqChunkSize" : 20000,
			  "end" : 242951149,
			  "start" : 0
		   }
		   ,
		   ...
		]
		
	EXAMPLES

/nethome/bioinfo/apps/agua/0.5/bin/apps/jbrowseRefseq.pl \
--chromofile /nethome/bioinfo/data/sequence/chromosomes/rat/rn4/fasta/chromosome-sizes.txt \
--outputdir /nethome/syoung/base/pipeline/jbrowse/ucsc/0.5/rat/rn4 \
--chunk 20000
	
	

=cut

	#### GET VARIABLES IF NOT DEFINED
	$outputdir	=	$self->outputdir() if not defined $outputdir;
	$chromofile	=	$self->chromofile() if not defined $chromofile;
	$chunksize	=	$self->chunksize() if not defined $chunksize;

	#### CHECK INPUTS
	$self->logError("Agua::JBrowse::generateRefseq    outputdir not defined") and exit if not defined $outputdir;
	$self->logError("Agua::JBrowse::generateRefseq    chromofile not defined") and exit if not defined $chromofile;
	$self->logError("Agua::JBrowse::generateRefseq    chunksize not defined") and exit if not defined $chunksize;

	#### OPEN INPUT FILE
	open(FILE, $chromofile) or die "Can't open chromofile: $chromofile\n";
	my @lines = <FILE>;
	close(FILE);

	#### CREATE OUTPUT DIR IF NOT EXISTS	
	$self->logDebug("outputdir is a file", $outputdir) if -f $outputdir;
	File::Path::mkpath($outputdir) if not -d $outputdir;
	$self->logDebug("Can't create output dir", $outputdir) if not -d $outputdir;
	
	#### OPEN OUTPUT FILE
	my $outputfile = "$outputdir/refSeqs.js";
	open(OUTFILE, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
	
	my $data;
	foreach my $line ( @lines )
	{
		next if $line =~ /^#/ or $line =~ /^\s*$/;

		#### FORMAT:
		#### chr1    0       273269105       273269105
		#### chr2    273269106       536640798       263371692
		my ($chromosome, $length) = $line =~ /^(\S+)\s+\S+\s+\S+\s+(\S+)$/;
		$self->logDebug("chromosome not defined in line", $line) and exit if not defined $chromosome;
		$self->logDebug("length not defined in line", $line) and exit if not defined $length;
		push @$data, {
			length 	=>	$length,
			name	=>	$chromosome,
			seqDir	=>	"data/seq/$chromosome",
			seqChunkSize	=>	$chunksize,
			end		=>	$length,
			start	=>	0
		};
	}

	#### WRITE TO JSON FILE WITH ASSIGNED NAME 'refSeqs'	
	my $callback = sub { return $data };
	$self->modifyJsonfile($outputfile, "refSeqs", $callback);
	$self->logDebug("printed outputfile:");
	$self->logDebug("\n$outputfile\n");
}

#### GENERATE names.json
method generateNames () {
=head2
	
	SUBROUTINE		generateNames
	
	PURPOSE
	
		UPDATE OR CREATE NEW names.json FILE INCORPORATING
		
		ALL FEATURES IN THE trackInfo.js FILE

=cut

	my $inputdir	=	$self->inputdir();
	my $outputdir	=	$self->outputdir();
	my $refseqfile	=	$self->refseqfile();
	my $filetype	=	$self->filetype();
	my $jbrowse		=	$self->jbrowse();
	
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("outputdir", $outputdir);
	$self->logDebug("refseqfile", $refseqfile);
	$self->logDebug("jbrowse", $jbrowse);
	
	#### GET LIST OF REFERENCES
	my $references = $self->parseReferences();
	$self->logDebug("references: @$references");

	#### SET EXECUTABLE
	my $executable = "$jbrowse/generate-names.pl";
	$self->logDebug("executable", $executable);

	#### DO ALL FILES SPECIFIED IN FEATURES HASH
	my $jobs = [];
	foreach my $reference ( @$references )
	{
		$self->logDebug("reference $reference");

		#### CONVERT TO GFF
		####/nethome/syoung/base/apps/aqwa/0.4/html/plugins/view/jbrowse/bin/generate-names.pl \
		####-v /nethome/syoung/base/pipeline/jbrowse/ucsc/reference/chr1/data/tracks/*/*/names.json

		my $command = "cd $outputdir/$reference; $executable -v $outputdir/$reference/data/tracks/*/*/names.json";
		$self->logDebug("command", $command);
		my $job = $self->setJob( [$command], "generateNames-$reference", $outputdir );
		push @$jobs, $job;
	}

	$self->logDebug("No. jobs: " . scalar(@$jobs) .  "\n");
	$self->logDebug("jobs[0]", $$jobs[0]);
	
	#### RUN COMMANDS IN PARALLEL
	$self->logDebug("Running pileupToSnp");
	$self->runJobs( $jobs, "generateNames" );	
	$self->logDebug("Completed conversion from SAM to TSV files");
}


method addTrack (Str $trackdatafile, Str $trackinfofile) {
	$self->logDebug("trackinfofile", $trackinfofile);
	$self->logDebug("trackdatafile", $trackdatafile);
	my $trackinfo = $self->getTrackinfo($trackinfofile);
	my $trackdata = $self->getTrackdata($trackdatafile);

	#### GET ENTRY
	my $url = $self->setTrackUrl($trackdata);
	my $entry = $self->setTrackEntry($trackdata, $url);
	$self->logDebug("entry", $entry);

	#### QUIT IF FEATURE ALREADY EXISTS IN LIST
	$self->logDebug("trackdata already found in trackinfo", $entry) if $self->objectInArray($trackinfo, $entry, ["key", "label", "type", "url"]);
	return 0 if $self->objectInArray($trackinfo, $trackdata, ["key", "label", "type", "url"]);

	#### OTHERWISE, ADD TO LIST
	unshift @$trackinfo, $entry;
	$self->writeJson($trackinfofile, $trackinfo, "trackInfo = ");
	
	return 1;
}

method setTrackUrl (HashRef  $trackdata ) {
	return 'data/tracks/{refseq}/' . $trackdata->{label}
		. '/trackData.json';	
}

method setTrackEntry (HashRef  $trackdata, Str $url) {
	return 	{
		key => $trackdata->{key},
		label => $trackdata->{label},
		type => $trackdata->{type},
		url => $url
	};
}

method removeTrack (Str $trackdatafile, Str $trackinfofile) {
	$self->logDebug("trackinfofile", $trackinfofile);
	$self->logDebug("trackdatafile", $trackdatafile);

	my $trackinfo = $self->getTrackinfo($trackinfofile);
	my $trackdata = $self->getTrackdata($trackdatafile);

	#### GET ENTRY
	my $url = $self->setTrackUrl($trackdata);
	$self->logDebug("url", $url);
	my $entry = $self->setTrackEntry($trackdata, $url);
	$self->logDebug("entry", $entry);

	##### ADD TRACK 
	#my $url = 'data/tracks/{refseq}/'
	#			. $trackdata->{key}
	#			. '/trackData.json';
	#my $entry;
	#$entry->{key} = $trackdata->{key};
	#$entry->{label} = $trackdata->{label};
	#$entry->{type} = $trackdata->{type};
	#$entry->{url} = $url;

	#### QUIT IF FEATURE IS NOT IN LIST
	my $index = $self->_indexInArray($trackinfo, $entry, ["key", "label", "type", "url"]);
	$self->logDebug("index", $index);

	$self->logDebug("trackdata not found in trackinfo", $entry) and return if not defined $index;

	#### OTHERWISE, REMOVE FROM LIST
	splice(@$trackinfo, $index, 1);
	$self->writeJson($trackinfofile, $trackinfo, "trackInfo = ");	
}

method addTrackinfo (Str $sourceinfofile, Str $targetinfofile) {
	$self->logDebug("targetinfofile", $targetinfofile);
	$self->logDebug("sourceinfofile", $sourceinfofile);

	my $targetinfo = $self->getTrackinfo($targetinfofile);
	$self->logDebug("targetinfo", $targetinfo);
	$self->logDebug("targetinfo not defined or empty for targetinfofile", $targetinfofile) and exit if not defined $targetinfo;
	
	my $sourceinfo = $self->getTrackinfo($sourceinfofile);
	$self->logDebug("sourceinfo", $sourceinfo);
	$self->logDebug("sourceinfo not defined for sourceinfofile", $sourceinfofile) and exit if not defined $sourceinfo;

	$self->logDebug("REF(sourceinfo): " . ref($sourceinfo));
	$self->logDebug("REF(targetinfo): " . ref($targetinfo));

	#### QUIT IF FEATURE ALREADY EXISTS IN LIST
	if ( $self->objectInArray($targetinfo, $$sourceinfo[0], ["key", "label", "type", "url"]) )
	{
		$self->logDebug("sourceinfo already found in targetinfo", $sourceinfo);
		return 0;
	}

	#### OTHERWISE, ADD TO TOP OF LIST
	unshift @$targetinfo, $$sourceinfo[0];
	
	$self->writeJson($targetinfofile, $targetinfo, "trackInfo = ");	
	$self->logDebug("Feature info written to targetinfofile", $targetinfofile);
	$self->logDebug("final targetinfo:", $targetinfo);

	return 1;
}

method removeTrackinfo (HashRef $featureobject, Str $targetinfofile) {
	$self->logDebug("(featureobject, targetinfofile)");
	$self->logDebug("featureobject", $featureobject);
	$self->logDebug("targetinfofile", $targetinfofile);

	my $targetinfo = $self->getTrackinfo($targetinfofile);
	$self->logDebug("targetinfo", $targetinfo);
	$self->logDebug("targetinfo not defined or empty for targetinfofile", $targetinfofile) and exit if not defined $targetinfo or not @$targetinfo;
	
	#### QUIT IF FEATURE ALREADY EXISTS IN LIST
	my ($index) = $self->_indexInArray($targetinfo, $featureobject, ["key", "label"]);
	if ( not defined $index )
	{
		$self->logDebug("featureobject not found in targetinfo", $featureobject);
		return ;
	}
	$self->logDebug("index", $index);

	#### OTHERWISE, REMOVE FROM LIST
	splice(@$targetinfo, $index, 1);
	$self->logDebug("final targetinfo", $targetinfo);

	$self->writeJson($targetinfofile, $targetinfo, "trackInfo = ");
}


method getTrackdata ($trackdatafile) {
	my $trackdata = $self->readJson($trackdatafile, 0);
	#$self->logDebug("trackdata", $trackdata);

	return $trackdata;
}
	
method getTrackinfo ($trackinfofile) {
	$self->logDebug("(trackinfofile)");
	$self->logDebug("trackinfofile", $trackinfofile);

	my $trackinfo = $self->readJson($trackinfofile, "trackInfo = ");

	return $trackinfo;
}
	
#### GENERATE FEATURES
method jbrowseFeatures () {
=head2
	
	SUBROUTINE		jbrowseFeatures
	
	PURPOSE
	
		DO ALL FEATURES OF ALL CHROMOSOMES IN PARALLEL:
		
			1. INPUT GFF FILES (E.G., DOWNLOADED FROM UCSC) IN
			
				EACH chr* DIRECTORY INSIDE THE referencedir
				
			2. USE flatfile-to-json.pl TO GENERATE FEATURES

	INPUTS
	
		1. DIRECTORY CONTAINING INPUT GFF OR BAM FILES
		
			OR
			
			A GFF OR BAM FILE
		
		2. refSeqs.json FILE CONTAINING 
		
		3. OUTPUT DIRECTORY TO PRINT data DIR

	NOTES
	
		1. CREATE DIRECTORIES FOR OUTPUT FILES
		
		2. COPY refSeqs.js TO EACH SUB DIRECTORY
		
		3. RUN flatfile-to-json.pl AS ARRAY JOB

=cut

	my $inputdir	=	$self->inputdir();
	my $featuresdir	=	$self->featuresdir();
	my $refseqfile	=	$self->refseqfile();
	my $configfile	=	$self->configfile();
	my $label		=	$self->label();
	my $key			=	$self->key();
	my $filetype	=	$self->filetype();
	my $jbrowse		=	$self->jbrowse();
	my $species		=	$self->species();
	my $build		=	$self->build();
	$self->logDebug("()");
	$self->logDebug("inputdir", $inputdir);
	$self->logDebug("featuresdir", $featuresdir);
	$self->logDebug("refseqfile", $refseqfile);
	$self->logDebug("label", $label);
	$self->logDebug("key", $key);
	$self->logDebug("jbrowse", $jbrowse);
	
	#### CHECK INPUTS
	die "inputdir not defined (Use --help for usage)\n" and exit if not defined $inputdir;
	die "featuresdir not defined (Use --help for usage)\n" and exit if not defined $featuresdir;
	die "refseqfile not defined (Use --help for usage)\n" and exit if not defined $refseqfile;
	die "filetype not defined (Use --help for usage)\n" and exit if not defined $filetype;
	die "jbrowse not defined (Use --help for usage)\n" and exit if not defined $jbrowse;
	die "species not defined (Use --help for usage)\n" and exit if not defined $species;
	die "build not defined (Use --help for usage)\n" and exit if not defined $build;

	#### PROCESS CONFIG FILE
	$self->processConfigfile();

	#### CHECK DIRS
	$self->logDebug("Can't find featuresdir", $featuresdir) and exit if not -d $featuresdir;

	#### 1. CREATE DIRECTORIES FOR OUTPUT FILES
	####  	AND COPY refSeqs.js TO EACH SUB DIRECTORY
	$self->createFeaturedir($key);

	#### 2. RUN flatfile-to-json.pl IN PARALLEL IF MULTIPLE FILES PRESENT
	$self->runFlatfileToJson();

	$self->logDebug("COMPLETED");
}


method createFeaturedir ($feature) {
=head2

	SUBROUTINE	runFlatfileToJson
	
	PURPOSE
	
		1. CREATE DIRECTORIES FOR OUTPUT FILES
		
		2. COPY refSeqs.js TO EACH SUB DIRECTORY

=cut
	$self->logDebug("(feature)");

	$feature = $self->key() if not defined $feature;
	$self->logDebug("feature", $feature);

	#### GET FEATURES PARENT DIR AND REFSEQ FILE
	my $featuresdir = $self->featuresdir();
	my $refseqfile = $self->refseqfile();

	#### CHECK INPUTS
	$self->logDebug("Can't find featuresdir", $featuresdir) and exit if not -d $featuresdir;
	$self->logDebug("Can't find refseqfile", $refseqfile) and exit if not -f $refseqfile;
	$self->logDebug("featuresdir already exists as a file", $featuresdir) and exit if -f $featuresdir;

	$self->logDebug("featuresdir", $featuresdir);
	$self->logDebug("refseqfile", $refseqfile);

	#### 1. CREATE OUTPUT DIRECTORY 
	my $featuredir = "$featuresdir/$feature";
	File::Path::mkpath($featuredir);
	$self->logDebug("Can't create featuredir", $featuredir) and exit if not -d $featuredir;
	
	#### 2. CREATE data DIRECTORY
	my $datadir = "$featuredir/data";
	$self->logDebug("datadir already exists as a file", $datadir) and exit if -f $datadir;
	File::Path::mkpath($datadir);
	$self->logDebug("Can't create datadir", $datadir) and exit if not -d $datadir;

	#### 3. COPY refSeqs.js FILE TO THE data DIRECTORY
	my $inputrefseq = "$datadir/refSeqs.js";
	File::Copy::copy($refseqfile, $inputrefseq) or die "Can't copy refseqfile: $refseqfile\n";
	
	#### REMOVE dojo.provide LINE FROM REFSEQ
	open(FILE, $inputrefseq) or die "Can't open inputrefseq file: $inputrefseq\n";
	my $temp = $/;
	$/ = undef;
	my $contents = <FILE>;
	$/ = $temp;
	close(FILE) or die "Can't close inputrefseq file: $inputrefseq\n";
	
	$contents =~ s/^dojo\.provide[^\n]+\n//;
	open(OUT, ">$inputrefseq") or die "Can't open inputrefseq file: $inputrefseq\n";
	print OUT $contents;
	close(OUT) or die "Can't close inputrefseq file: $inputrefseq\n";

	###### 4. CHANGE TO OUTPUT DIR
	#chdir($featuresdir) or die "Can't change to output dir: $featuresdir\n";
	
	return $featuredir;
}


method runFlatfileToJson () {
=head2

	SUBROUTINE	runFlatfileToJson
	
	PURPOSE
	
		RUN flatfile-to-json FOR EVERY REFERENCE SEQUENCE
		
		AGAINST EVERY inputdir/reference/filename INPUT FILE

=cut
	$self->logDebug("()");
	
	#### GET INPUT AND OUTPUT DIRS
	my $inputdir = $self->inputdir();
	my $refseqfile = $self->refseqfile();
	my $configfile = $self->configfile();
	
	#### ADD ENVIRONMENT VARIABLES TO INPUTDIR PATH (E.G., %project%)
	$inputdir = $self->addEnvars($inputdir);
	$self->logDebug("inputdir", $inputdir);

	#### GET FILETYPE, FILENAME, LABEL AND KEY
	my $filename = $self->filename();
	my $filetype = $self->filetype();
	my $label = $self->label();
	my $key = $self->key();
	
	#### SET EXECUTABLE
	my $jbrowse = $self->jbrowse();
	my $executable = "$jbrowse/flatfile-to-json.pl";
	#$executable = "$jbrowse/bam-to-json.pl" if $filetype eq "bam";
	$self->logDebug("executable", $executable);

	#### GET LIST OF REFERENCES
	#my $references = $self->parseReferences();
	my $references = $self->listReferenceSubdirs($inputdir);
	$self->logDebug("references: @$references");

	#### DO ALL FILES SPECIFIED IN FEATURES HASH
	my $jobs = [];
	my $registered;
	if ( defined $filename )
	{
		my $feature = $self->key();
		#my ($feature) = $filename =~ /^(.+)(\.[^\.]+)$/;
		$self->logDebug("filename", $filename);
		$self->logDebug("feature", $feature);
		$self->registerFeature($feature);

		foreach my $reference ( @$references )
		{
			next if $reference =~ /\./;
			my $label = $feature;
			my $outdir = $self->createFeaturedir($key);
			my $infile = "$inputdir/$reference/$filename";
			$self->logDebug("key", $key);
			$self->logDebug("label", $label);
			$self->logDebug("executable", $executable);
			$self->logDebug("infile", $infile);
			$self->logDebug("outdir", $outdir);
			$jobs = $self->addJob($jobs, $key, $label, $executable, $infile, $outdir);
		}
	}
	else
	{
		$self->logDebug("filename not defined. Searching for files in inputdir", $inputdir);
		
		my $registered;
		foreach my $reference ( @$references )
		{
			next if $reference =~ /^\./;
			my $chromodir = "$inputdir/$reference";
			next if not -d $chromodir;

			opendir(DIR, $chromodir) or die "Can't open inputdir/reference: $inputdir/$reference\n";
			my @files = readdir(DIR);
			close(DIR);
			foreach my $file ( @files )
			{
				next if $file !~ /^chr[A-Z0-9]+$/i;
				$self->logDebug("file", $file);

				my $infile = "$inputdir/$reference/$file";
				$self->logDebug("infile", $infile);
				next if not -f $infile;

				#### REGISTER FEATURE
				my ($feature) = $file =~ /^(.+)(\.[^\.]+)$/;
				$self->logDebug("file", $file);
				$self->logDebug("feature", $feature);

				if ( not exists $registered->{$feature} )
				{
					$self->registerFeature($feature);
				}
				else
				{
					$registered->{$feature} = 1;
				}

				#### ADD JOB
				my $label = "jbrowseFeatures-$reference-$feature";
				my $outdir = $self->createFeaturedir($feature);
				
				$jobs = $self->addJob($jobs, $key, $label, $executable, $infile, $outdir);
				$self->logDebug("No. jobs: " . scalar(@$jobs));;
			}
		}
	}

	#### RUN COMMANDS IN PARALLEL
#	$self->logDebug("jobs", $jobs);
	$self->runJobs( $jobs, "jbrowseFeatures" );	
	$self->logDebug("Completed running jobs");
}

method registerFeature($feature) {
	#### OVERRIDE THIS METHOD IN OWNING CLASS	
	}

method addJob ($jobs, $key, $label, $executable, $inputfile, $outputdir) {
=head2

	SUBROUTINE		addJob
	
	PURPOSE
	
		PUSH JBROWSE FEATURE GENERATION JOB ONTO THE jobs ARRAY
	
	NOTES
	
		flatfile-to-json.pl USAGE:

		USAGE: $0 [--gff <gff3 file> | --gff2 <gff2 file> | --bed <bed file>] [--out <output directory>] --tracklabel <track identifier> --key <human-readable track name> [--cssClass <CSS class for displaying features>] [--autocomplete none|label|alias|all] [--getType] [--getPhase] [--getSubs] [--getLabel] [--urltemplate "http://example.com/idlookup?id={id}"] [--extraData <attribute>] [--subfeatureClasses <JSON-syntax subfeature class map>] [--clientConfig <JSON-syntax extra configuration for FeatureTrack>]
		
			--out: defaults to "data"
			--cssClass: defaults to "feature"
			--autocomplete: make these features searchable by their "label", by their "alias"es, both ("all"), or "none" (default).
			--getType: include the type of the features in the json
			--getPhase: include the phase of the features in the json
			--getSubs:  include subfeatures in the json
			--getLabel: include a label for the features in the json
			--urltemplate: template for a URL that clicking on a feature will navigate to
			--arrowheadClass: CSS class for arrowheads
			--subfeatureClasses: CSS classes for each subfeature type, in JSON syntax
				e.g. '{"CDS": "transcript-CDS", "exon": "transcript-exon"}'
			--clientConfig: extra configuration for the client, in JSON syntax
				e.g. '{"featureCss": "background-color: #668; height: 8px;", "histScale": 2}'
			--type: only process features of the given type
			--nclChunk: NCList chunk size; if you get "json text or perl structure exceeds maximum nesting level" errors, try setting this lower (default: $nclChunk)
			--extraData: a map of feature attribute names to perl subs that extract information from the feature object
				e.g. '{"protein_id" : "sub {shift->attributes(\"protein_id\");} "}'
			--compress: compress the output (requires some web server configuration)
			--sortMem: the amount of memory in bytes to use for sorting
	

	 bam-to-json.pl USAGE:
	 
	 /data/apps/jbrowse/1.2.6/bin/bam-to-json.pl --bam <bam file> 
			[--out <output directory] 
			[--tracklabel <track identifier>] 
			[--key <human-readable track name>] 
			[--cssClass <class>] 
			[--clientConfig <JSON client config>] 
			[--nclChunk <NCL chunk size in bytes>] 
			[--compress]
	
	    --bam: bam file name
	    --out: defaults to "data"
	    --cssclass: defaults to "basic"
	    --clientConfig: extra configuration for the client, in JSON syntax
	        e.g. '{"featureCss": "background-color: #668; height: 8px;", "histScale": 5}'
	    --nclChunk: size of the individual NCL chunks
	    --compress: compress the output (requires some web server configuration)

=cut
	$self->logDebug("(jobs, label, executable, inputfile)");
	$self->logDebug("key", $key);
	$self->logDebug("label", $label);
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("executable", $executable);
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputdir", $outputdir);

	my $filetype = $self->filetype();
	$self->logDebug("filetype", $filetype);

	return $jobs if not -f $inputfile or $inputfile !~ /\.$filetype$/;

	my $config = $self->getFeatureConfig($key);
	$self->logDebug("config", $config);

	my $command = "cd $outputdir; ";
	$command .= " $executable ";
	$command .= " --" . $self->filetype . " $inputfile ";
	$command .= " --tracklabel $label ";
	$command .= " --key $key ";
	#$command .= " --autocomplete all "; # if $filetype ne "bam";
	$command .= " --getType " if $filetype ne "bam";
	$command .= " --nclChunk " 	. $self->chunksize() if $self->chunksize();
	$command .= " --compress " 	. $self->compress() if $self->compress();
	$command .= " --sortMem " 	. $self->sortmem() if $self->sortmem();
	
	if ( defined $config )
	{
		my $flags = ["--getPhase",  "--getSubs"];
		my $flag_slots = ["phase",  "subfeatures"];
		for ( my $i = 0; $i < @$flags; $i++ )
		{
			$command .= " $$flags[$i] "
				if defined $config->{$$flag_slots[$i]};
		}

		my $params = ["--cssClass", "--urltemplate", "--arrowheadClass"];
		my $param_slots  = [ "class", "urlTemplate", "arrowheadClass" ];
		for ( my $i = 0; $i < @$params; $i++ )
		{
			$command .= " $$params[$i] $config->{$$param_slots[$i]} "
				if defined $config->{$$param_slots[$i]};
		}

		my $objects = [ "subfeatureClasses",  "--clientConfig",  "--extraData"];
		my $object_slots = [ "subfeature_classes",  "clientConfig",  "extraData"];
		for ( my $i = 0; $i < @$objects; $i++ )
		{
			$self->logDebug("objects[$i]", $$objects[$i]);
			
			$self->logDebug("config->$$object_slots[$i]", $config->{$$object_slots[$i]}) if defined $config->{$$object_slots[$i]};
			
			if ( defined $config->{$$object_slots[$i]} )
			{
				$command .= " $$objects[$i] \'";
				$command .= $self->parseJson(($config->{$$object_slots[$i]}));
				$command .= "\' ";
			}
		}	
	}
	$self->logDebug("command", $command);

	my $job = $self->setJob( [$command], $label, $outputdir );
	push @$jobs, $job;
	$self->logDebug("no. jobs: " . scalar(@$jobs));;
	
	return $jobs;
}

#### JSON METHODS
method processConfigfile () {
	$self->logDebug("()");

	my $configfile	=	$self->configfile();
	return if not defined $configfile or not $configfile;
	
	$self->logDebug("configfile", $configfile);
	my $config = $self->readJson($configfile, 0);
	$self->logDebug("Can't process config from configfile", $configfile) and exit if not defined $config or not $config;
	
	$self->logDebug("config", $config);

	$self->config($config);
}


method getFeatureConfig ($feature) {

	my $config	=	$self->config();
$self->logDebug("config", $config);

	return if not defined $config or not $config;

	foreach my $track ( @{$config->{tracks}} )
	{
		return $track if $track->{track} eq $feature;
	}

	return;
}

method parseReferences () {
=head2

	SUBROUTINE	parseReferences
	
	PURPOSE
	
		PARSE REFERENCE SEQUENCE NAMES FROM refSeqs.js JSON FILE

=cut
	$self->logDebug("(inputfiles)");

	my $refseqfile = $self->refseqfile();

	#### INITIALISE JSON PARSER
	my $jsonparser = JSON->new();

	#### GET .json FILE HASH
	open(ARGS, $refseqfile) or die "Can't open args file: $refseqfile\n";
	$/ = undef;
	my $contents = <ARGS>;
	close(ARGS);
	die "Json file is empty\n" if $contents =~ /^\s*$/;
	$contents =~ s/\n//g;
	$contents =~ s/^.*refSeqs\s*=\s*//;
	$contents =~ s/^\s*refSeqs\s*=\s*//;
	$self->logDebug("contents", $contents);
	
	my $refseq_hashes = $jsonparser->decode($contents);
	$self->logDebug("refseq_hashes", $refseq_hashes);

	my $references = [];
	foreach my $refseq_hash ( @$refseq_hashes )
	{
		push @$references, $refseq_hash->{name} if defined $refseq_hash->{name};
	}
	
	return $references;	
}


method featurehash ($json, $inputfile) {
	
	my $featurehash;
	my @inputtypes = keys %{$json->{features}};
	@inputtypes = sort @inputtypes;
	foreach my $inputtype ( @inputtypes )
	{
		#use re 'eval';# EVALUATE $pattern AS REGULAR EXPRESSION
		if ( $inputfile =~ /$inputtype/ )
		{
			$featurehash = $json->{features}->{$inputtype};
			last;
		}
		#no re 'eval';# EVALUATE $pattern AS REGULAR EXPRESSION
	}

	return $featurehash;
}


method setJsonParser () {
	return $self->jsonparser() if $self->jsonparser();
	#my $jsonparser = JSON->new() ;
	my $jsonparser = JSON->new->allow_nonref;
	$self->jsonparser($jsonparser);
	
	return $self->jsonparser();
}


method readJson ($file, $assign) {
=head2

	SUBROUTINE		readJson
	
	PURPOSE
	
		PARSE DATA FROM JSON FILE
		
		(THIS SUBROUTINE AND FOLLOWING TWO ADAPTED FROM JBROWSE JsonGenerator.pm)

	INPUTS
	
		1. JSON FILE LOCATION
		
		2. DEFAULT CONTENT IF EMPTY
		
		3. SKIP ASSIGN IF NO VARIABLE NAME IN FIRST LINE

	OUTPUTS
	
		1. FILE CONTENTS MINUS VARIABLE NAME LINE IF assign SPECIFIED
		
=cut
	$self->logNote("file", $file);
	$self->logNote("assign", $assign) if defined $assign;
	
	#### CHECK INPUT
	$self->logNote("file not defined. Exiting") and exit if not defined $file;
    $self->logNote("file is empty", $file) and return if not -s $file;

	my $jsonparser = $self->jsonparser();
	$self->jsonparser($jsonparser);
	
	my $OLDSEP = $/;
	my $fh = new IO::File $file, O_RDONLY or die "couldn't open $file: $!";
	flock $fh, LOCK_SH;
	undef $/;
	my $contents = <$fh>;
	$fh->close() or die "couldn't close $file: $!";
	$/ = $OLDSEP;

	#### SKIP TEXT IN assign IF DEFINED
	$assign =~ s/\s+$//;
	$assign =~ s/^\s+//;
	$contents =~ s/$assign// if $assign;
    $self->logNote("contents", $contents);

	my $object = $jsonparser->decode($contents);
	$self->logNote("object", $object);

    return $jsonparser->decode($contents);
}

method parseJson ($object) {
	
	my $jsonparser = $self->jsonparser();
	
	return $jsonparser->objToJson($object);
}

method writeJson ($file, $toWrite, $assignation) {
=head2

	SUBROUTINE		writeJson
	
	PURPOSE
	
		1. PRINT DATA TO A JSON FILE
		
		2. PRINT IN 'PRETTY' FORMAT BY DEFAULT

=cut

	$self->logNote("toWrite", $toWrite);
	$self->logNote("file", $file);
	$self->logNote("assignation", $assignation);

	#### CHECK FILE
	$self->logNote("file not defined. Exiting") and exit if not defined $file;

    #### CREATE JSON OBJECT
    my $jsonparser = $self->jsonparser();
	my $json = '';
	$json .= $assignation if defined $assignation;
	#$json .= $jsonparser->objToJson($toWrite, {pretty => 1, indent => 2});
	#$json .= $jsonparser->pretty->encode($toWrite, {pretty => 1, indent => 2});
	$json .= $jsonparser->pretty->encode($toWrite);
	$self->logNote("json", $json);

    #### WRITE JSON TO FILE
    my $fh = new IO::File $file, O_WRONLY | O_CREAT or die "couldn't open $file: $!";
    flock $fh, LOCK_EX;
    $fh->seek(0, SEEK_SET);
    $fh->truncate(0);
	$fh->print($json);
    $fh->close() or die "couldn't close $file: $!";
	
	$self->logNote("Wrote to file", $file);
}

method modifyJsonfile ($file, $varName, $callback) {
=head2

	SUBROUTINE		modifyJsonfile
	
	PURPOSE
	
		1. MODIFY THE DATA IN AN EXISTING JSON FILE OR WRITE A NEW FILE
		
		2. USE A CALLBACK SUBROUTINE WITH THE EXISTING DATA PROVIDED AS
		
			AN ARGUMENT
		
		3. ASSIGN VARIABLE NAME IN FIRST LINE OF FILE, E.G.: "refSeqs =\n"		

	INPUTS
	
		1. INPUT JSON FILE WITH VARIABLE NAME ASSIGNED IN FIRST LINE
		
		2. CALLBACK FUNCTION FOR MODIFYING EXISTING DATA, E.G., 'ADD
		
			AN ELEMENT TO A HASH ARRAY'
			
		3. VARIABLE NAME FOR THE DATA IN THE JSON FILE
		
	OUTPUTS
	
		1. JSON FILE WITH MODIFIED VARIABLE NAME AND DATA

=cut

    my ($data, $assign);
    my $fh = new IO::File $file, O_RDWR | O_CREAT or die "couldn't open $file: $!";
    flock $fh, LOCK_EX;

    #### GET DATA AND REMOVE INITIAL VARIABLE LINE IF FILE IS NOT EMPTY
    if (($fh->stat())[7] > 0)
	{
        $assign = $fh->getline();
        my $jsonString = join("", $fh->getlines());
        $data = JSON::from_json($jsonString) if (length($jsonString) > 0);

        #### PREPARE TO WRITE OVER ANY EXISTING FILE DATA
        $fh->seek(0, SEEK_SET);
        $fh->truncate(0);
    }
	
    #### add assignment line
    $fh->print("$varName = ");

    #### modify data, write back
    $fh->print(JSON::to_json($callback->($data), {pretty => 1}));
    $fh->close() or die "couldn't close $file: $!";
}





#### UTILS
method getDirs ($directory) {
	$self->logDebug("directory", $directory);
	opendir(DIR, $directory) or die "Can't open directory: $directory\n" and exit;
	my $dirs;
	@$dirs = readdir(DIR);
	closedir(DIR) or die "Can't close directory: $directory";
	
	for ( my $i = 0; $i < @$dirs; $i++ ) {
		if ( $$dirs[$i] =~ /^\.+$/ ) {
			splice @$dirs, $i, 1;
			$i--;
		}
		my $filepath = "$directory/$$dirs[$i]";
		if ( not -d $filepath ) {
			splice @$dirs, $i, 1;
			$i--;
		}
	}
	@$dirs = sort @$dirs;
	
	return $dirs;	
}

method getFiles ($directory) {
	opendir(DIR, $directory) or $self->logDebug("Can't open directory", $directory);
	my $files;
	@$files = readdir(DIR);
	closedir(DIR) or $self->logDebug("Can't close directory", $directory);

	for ( my $i = 0; $i < @$files; $i++ ) {
		if ( $$files[$i] =~ /^\.+$/ ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	for ( my $i = 0; $i < @$files; $i++ ) {
		my $filepath = "$directory/$$files[$i]";
		if ( not -f $filepath ) {
			splice @$files, $i, 1;
			$i--;
		}
	}

	return $files;
}

method sortNaturally ($array) {
#### SORT BY NUMBER
#### 	- NUMBERS COME BEFORE LETTERS
#### 	- THEN SORT LETTERS BY cmp

	$self->logDebug("array", $array);
	
	sub naturally {
		my ($aa) = $a =~ /(\d+)[^\/^\d]*$/;
		my ($bb) = $b =~ /(\d+)[^\/^\d]*$/;
	
		#### SORT BY NUMBER, OR cmp
		if ( defined $aa and defined $bb )	{	$aa <=> $bb	}
		elsif ( not defined $aa and not defined $bb )	{	$a cmp $b;	}
		elsif ( not defined $aa )	{	1;	}
		elsif ( not defined $bb )	{	-1;	}
	}
	
	if ( not defined $array ) 	{	return;	}
	@$array = sort naturally @$array;
	
	return wantarray ? @$array : $array;
}




}	#### END
