use MooseX::Declare;

class File::Tools with Agua::Common::Logger {
	
=head2

	PACKAGE		File::Tools
	
	PURPOSE
	
		PERFORM BASIC FILE CHECKING AND MANIPULATION TASKS, SUCH AS:

			1. svn TOOLS - BACKUP/MIRROR WITH AUTO DELETE/ADD
			
			2. comment TOOLS - ADD/REMOVE/COMMENT DEBUG LINES IN PERL AND JS FILES
			
			3. NEXTGEN INPUT FILE QUALITY CHECKS

=cut

use strict;
use warnings;

#### EXTERNAL MODULES
use File::Remove;
use File::Copy;
use Data::Dumper;

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'logfile'  	    =>  ( isa => 'Str|Undef', is => 'rw' );

####///}}}

method getMode {
	$self->logDebug("FileTools::getMode()");
	my @temp = @ARGV;
	my $mode;
	GetOptions (
		'mode=s'	=> \$mode
	) ;
	@ARGV = @temp;
	
	return $mode;
}
#							ZIP/UNZIP
method unzip {
	my $type	=	shift;
	
}
#							FILE CONTENT CHECKING
method records {
=head2

	SUBROUTINE		records
	
	PURPOSE
	
		COUNT THE NUMBER OF RECORDS SEPARATED BY THE
		
		DESIRED SEPARATOR

=cut
	my $inputfile 		=	shift;
	my $separator		=	shift;
	my $compress		=	shift;
	my $dot				=	shift;
	
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("Separator", $separator);
	
	#### SET DEFAULT FASTA SEPARATOR OR USER-DEFINED SEPARATOR
	$/ = $separator if defined $separator;
	$/ = "\n>" if not defined $separator or not $separator;

	#### OPEN INPUT FILE
	if ( defined $compress )
	{
		open(FILE, "zcat $inputfile|" ) or die "Can't open file: $inputfile\n";
	}
	else
	{
		open(FILE, $inputfile) or die "Can't open file: $inputfile\n";
	}

	#### COUNT THE RECORDS
	my $records = 0;
    while ( <FILE> )
    {
		$self->logDebug("$records") if defined $dot and $records % $dot == 0;
		$records++;
    } 
	close(FILE);

	return $records;
}



method peek {
=head2

	SUBROUTINE		peek
	
	PURPOSE
	
        PRINT DATA FROM A SPECIFIED FILE:
        
            action = toptail
			
				FROM A TEXT FILE (E.G., TSV FILE):
                    
                -   RETURN TOP AND TAIL N LINES 
        
                -   FOR EACH LINE, RETURN AT MOST A SPECIFIED NUMBER OF CHARACTERS
            
            action = chars
			
				FROM A TEXT FILE (E.G., SEQUENCE FILE)
            
                -   RETURN N BYTES STARTING FROM A BYTE OFFSET
                
                -   RETURN LAST N BYTES IF BYTE OFFSET EXCEEDS FILE LENGTH
                
                -   RETURN FILE CONTENTS IF N BYTES EXCEEDS FILE LENGTH
			
	INPUTS
	
		1. inputfile EITHER TSV OR TEXT
		
        2. SPECIFY action: head, tail, headtail OR chars
        
        3. start POSITION (BYTES IF action = chars, LINES OTHERWISE)
		
	OUTPUTS

		1. PRINT FILE DATA TO STDOUT
	
=cut
	my $args		=	shift;

	$self->logObject("args", $args);

	my $username 	= 	$args->{username};
	my $inputfile	=	$args->{inputfile};
	my $start		=	$args->{start};
	my $action		=	$args->{action};
	my $quantity		=	$args->{quantity};
	
	#### RETURN FILE NOT EXISTS IF FILEPATH IS EMPTY
	if ( $inputfile =~ /^\s*$/)
	{
		$self->logError("inputfile not specified");
		exit;
	}


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES


#************************ USE awk /start/,/stop/ TO PRINT AN INTERVAL OF LINES




	#### ADD FILEROOT IF FILEPATH IS NOT ABSOLUTE.
	#### GET THE FILE ROOT FOR THIS USER IF requestor NOT DEFINED
	my $requestor = $args->{requestor};
	my $filepath = $inputfile;
	if ( not defined $requestor or not $requestor )
	{	
		$self->logDebug("Setting fileroot of user", $username);

		#### DO SETUID OF WORKFLOW.CGI AS USER
		my $fileroot = $self->getFileroot($username);
		
		#### QUIT IF FILEROOT NOT DEFINED OR EMPTY
		return {error => 'File::Tools::_checkFile    fileroot not defined for user: $username and filepath: $filepath' } if not defined $fileroot or not $fileroot;

		#### SET NEW FILEPATH
		$filepath = "$fileroot/$filepath";
		
		if ( $^O =~ /^MSWin32$/ )   {   $filepath =~ s/\//\\/g;  }
		$self->logDebug("filepath", $filepath);

		$self->_peek($filepath, $action, $start, $quantity);
		return;
	}
	if ( $^O =~ /^MSWin32$/ )   {   $filepath =~ s/\//\\/g;  }

	#### IF THE requestor FIELD IS DEFINED, THEN WE'RE HANDLING A REQUEST BY
	#### USER requestor TO VIEW A FILE IN A PROJECT OWNED BY USER username
	#### (THE CLIENT MAKES SEPARATE CALLS FOR SHARED FILES NOT OWNED
	#### BY THE LOGGED-IN USER WITH requestor=THIS USER AND username=OTHER USER, 
	#### SO THAT THE INSTANCE IS RUN AS SETUID 'THE_OTHER_USER' AND THEREBY HAS
	#### ACCESS TO THE OTHER USER'S PROJECT DIRECTORIES)
	$self->logDebug("Requestor defined. Setting fileroot of user: $username with requestor", $requestor);

	#### GET THE PROJECT NAME, I.E., THE BASE DIRECTORY OF THE FILE NAME
	my ($project) = ($filepath) =~ /^([^\/^\\]+)/;
	my $can_access_project = $self->_canAccess($username, $project, $requestor, "project");

	#### IF PROJECT RIGHTS NOT DEFINED, USE DEFAULT PROJECT RIGHTS 
	if ( not $can_access_project )
	{
		$self->logError("requestor $requestor cannot access project $project");
		return;
	}

	return $self->_peek($filepath, $action, $start, $quantity);
}

method _peek {
	my $inputfile	= 	shift;
	my $action		= 	shift;
	my $start		= 	shift;
	my $quantity	= 	shift;
	
	$self->logDebug("action $action...");
	$self->logDebug("start $start...");

	#### CHECK INPUTS
	die "inputfile not defined (Use --help for usage)\n" if not defined $inputfile;
	die "start not defined (Use --help for usage)\n" if not defined $start;
	die "action not defined (Use --help for usage)\n" if not defined $action;
	$start =~ s/\s+//g;
	die "start is not numeric: '$start' (Use --help for usage)\n" if $start !~ /^\d+$/;
	die "action must be head, tail or bytes: '$action' (Use --help for usage)\n" if $action !~ /^(head|tail|bytes)/;

	#### PRINT LINES INTO A SEPARATE FILE PER UNIQUE VALUE IN COLUMN
	$self->logDebug("action $action...");
	$self->logDebug("start $start...");


	#### EXIT IF FILE NOT FOUND
	if ( not -f $inputfile and not -d $inputfile )
	{
		return "{  error: 'File::Tools::_peek    Can't find inputfile found: $inputfile' }";
	}

	#### GET CURRENT SUBDIR FROM FIRST LINE
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
	my $line = <FILE>;
	my $counter = 0;
	while ( $counter < $start )
	{
		$line = <FILE>;
	}
	$self->logDebug("line", $line);
	close(FILE);



	#### DO HEAD OR TAIL IF action = head OR tail
	if ( $action eq "head" or $action eq "tail" )
	{
		my $peek = `tail +$start $inputfile | head -n$quantity`;
		if ( not defined $peek or not $peek )
		{
			return "{  error: 'File::Tools::filepeek    peek at start $start and quantity $quantity not defined for inputfile: $inputfile' }";
		}		
		$peek =~ s/\n/\\n/g;
		$peek =~ s/'/\\'/;
		
		return $peek;
	}
	if ( $action eq "head" or $action eq "tail" )
	{
		my $peek = `tail +$start $inputfile | head -n$quantity`;
		if ( not defined $peek or not $peek )
		{
			return "{  error: 'File::Tools::filepeek    peek at start $start and quantity $quantity not defined for inputfile: $inputfile' }";
		}		
		$peek =~ s/\n/\\n/g;
		$peek =~ s/'/\\'/;
		
		return $peek;
	}

	
	#### GET quantity
	elsif ( defined $quantity and defined $start )
	{
		my $peek = '';
		open(FILE, $inputfile) or $self->logError("Could not find file: $inputfile") and exit;
		seek FILE, $start, 0;
		read(FILE, $peek, $quantity);
		close(FILE);

		if ( not defined $peek or not $peek )
		{
			return "{  error: 'File::Tools::filepeek    peek at start $start and quantity $quantity not defined for inputfile: $inputfile' }";
		}

		print "{ peek: '$peek' }";
		return;
	}

}






#							TSV FILE MANIPULATION
=head2

	SUBROUTINE		columnSplit
	
	PURPOSE
	
		1. sort FILE BY VALUES IN SPECIFIED COLUMN
		
		2. SPLIT LINES IN FILE INTO ONE OR MORE FILES NAMED AFTER THE
		
			VALUE IN THE SPECIFIED COLUMN
			
	INPUTS
	
		1. INPUT FILE CONTAINING A SPECIFIED KEY COLUMN
		
		2. NUMBER OF KEY COLUMN
		
		3. OUTPUT DIRECTORY TO CREATE ONE SUBDIR PER UNIQUE KEY VALUE
		
		5. PREFIX AND SUFFIX FOR OUTPUT FILES

	OUTPUTS

		1. ONE FILE PER UNIQUE KEY VALUE CONTAINING SOLELY THE PARTICULAR
		
			KEY VALUE IN THE SPECIFIED COLUMN
	
=cut

method columnSplit {
	my $args		=	shift;

	my $suffix	=	$args->{suffix};
	my $inputdir	=	$args->{inputdir};
	my $inputfile	=	$args->{inputfile};
	my $outputdir	=	$args->{outputdir};
	my $column		=	$args->{column};
	my $outputfile	=	$args->{outputfile};
	my $separator	=	$args->{separator};
	
	#### SET VALUE TO ZERO IF inputfile NOT DEFINED
	#### OTHERWISE, SET VALUE TO THE inputfile (ORDINAL) NUMBER
	#### WHERE 1 IS THE LAST inputfile
	die "Either inputfile or inputdir must be defined (Use --help for usage)\n"
		if not defined $inputfile and not defined $inputdir;
	die "column not defined (Use --help for usage)\n" if not defined $column;
	$column =~ s/\s+//g;
	die "column is not numeric: '$column' (Use --help for usage)\n" if $column !~ /^\d+$/;

	#### SET OUTPUT DIR
	$outputdir = $inputdir if not defined $outputdir
		and defined $inputdir;

	#### SET SEPARATOR TO DEFAULT IF NOT DEFINED
	my $DEFAULT_SEPARATOR = "\\s+";
	$self->logDebug("Using default separator: whitespace") if not defined $separator;
	$separator = $DEFAULT_SEPARATOR if not defined $separator;

	#### CREATE OUTPUT DIR
	File::Path::mkpath($outputdir) if not -d $outputdir;
	die "Can't create output directory: $outputdir\n" if not -d $outputdir;

	#### DO SINGLE FILE IF SPECIFIED	
	$self->_columnSplit(
	{
		inputfile	=>	$inputfile,
		column 		=>	$column,
		outputdir	=>	$outputdir,
		outputfile	=>	$outputfile,
		separator	=>	$separator,
		suffix		=>	$suffix
	})
		and return if not defined $inputdir;

	#### DO ALL FILES IN INPUT DIRECTORY
	opendir(DIR, $inputdir) or die "Can't open inputdir directory: $inputdir\n";
	my @infiles = readdir(DIR);
	close(DIR);
	
	
	foreach my $infile ( @infiles )	
	{
		my $filepath = "$inputdir/$infile";
		next if not -f $filepath;
		
		my $outfile = $infile;

		$self->_columnSplit(
		{
			inputfile	=>	"$inputdir/$infile",
			column 		=>	$column,
			outputdir	=>	$outputdir,
			outputfile	=>	$outfile,
			separator	=>	$separator,
			suffix		=>	$suffix
		});
		
	}		
}

method _columnSplit {
	my $args		=	shift;

	my $suffix		=	$args->{suffix};
	my $inputfile	=	$args->{inputfile};
	my $outputdir	=	$args->{outputdir};
	my $column		=	$args->{column};
	my $outputfile	=	$args->{outputfile};
	my $separator	=	$args->{separator};
	
	#### SET OUTPUT FILE/DIR
	($outputfile) = $inputfile =~ /([^\/]+)$/
		if not defined $outputfile and defined $inputfile;
	($outputdir) = $inputfile =~ /^(.+?)\/[^\/]+$/
		if not defined $outputdir and defined $inputfile;
	
$self->logDebug("outputfile", $outputfile);
$self->logDebug("outputdir", $outputdir);
	

	#### PRINT LINES INTO A SEPARATE FILE PER UNIQUE VALUE IN COLUMN
	$self->logDebug("Printing files with unique values in column $column...");
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";

	#### GET CURRENT SUBDIR FROM FIRST LINE
	my $line = '';
	while ( $line =~ /^\s*$/ or $line =~ /^#/ )	{	$line = <FILE>;	}
	my @elements = split "$separator", $line;
	my $value  = $elements[$column - 1];
	die "Current value not defined in line: $line\n" if ( not defined $value );


$self->logDebug("value", $value);	
$self->logDebug("inputfile", $inputfile);
	

	#### CREATE SUBDIR
	my $subdir_path = "$outputdir/$value";
	File::Path::mkpath($subdir_path) if not -d $subdir_path;
	$self->logError("File::Tools::columnSplit    Can't create output sub-directory: $subdir_path") if not -d $subdir_path;

	#### OPEN OUTPUT FILE AND PRINT FIRST LINE
	my $outfile = "$subdir_path/$outputfile";
	$outfile .= ".$suffix" if defined $suffix;
	$self->logDebug("outfile", $outfile);
	open(OUTFILE, ">$outfile") or die "Can't open output file: $column\n";
	print OUTFILE $line;
	
	#### GO THROUGH LINES FOR ALL VALUES 
	my $counter = 0;
	while ( <FILE> )
	{
		next if $_ =~ /^\s*$/ or $_ =~ /^#/;
		
		my @elements = split "$separator", $_;
		my $current_value  = $elements[$column - 1];
		die "Current value not defined in line: $_\n" if ( not defined $current_value );
	
		if ( $value =~ /^$current_value$/ )
		{
			print OUTFILE $_;
		}
		else
		{
			close(OUTFILE);
			$value = $current_value;

			#### OPEN NEW OUTPUT FILE	
			my $subdir_path = "$outputdir/$current_value";
			$self->logDebug("Creating new method directory", $subdir_path) if not -d $subdir_path;
			File::Path::mkpath($subdir_path) or die "Can't create output sub-directory: $subdir_path\n" if not -d $subdir_path;

			#### OPEN NEW OUTPUT FILE AND PRINT 
			$outfile = "$subdir_path/$outputfile";
			$outfile .= ".$suffix" if defined $suffix;
			$self->logDebug("outfile", $outfile);
			open(OUTFILE, ">$outfile") or die "Can't open output file: $outfile\n";
			print OUTFILE $_;
		}
		
		$counter++;
	}
	close(OUTFILE);
	close(FILE);
}


method columnAverage {
=head2

    SUBROUTINE     columnAverage
    
    PURPOSE
    
		REPLACE A STRING IN A FILE AND WRITE TO A NEW FILE
		
	NOTES
	
		REQUIRES: /bin/mv TO BE INSTALLED
        
=cut
	my $args		=	shift;
	$self->logDebug("File::Tools::columnAverage(args)");
	
	my $inputfile	=	$args->{inputfile};
	my $column		=	$args->{column};
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("column", $column);

	#### CHECK COLUMN IS INTEGER VALUE
	$self->logDebug("column not an integer", $column) and return if not $column =~ /^\d+$/;
	
	#### GET SUM
	my $command = qq{awk '{sum+=\$$column} END { print sum/NR }' $inputfile};
	my $sum = `$command`;
	$self->logDebug("sum", $sum);
	
	return $sum;
}



method columnSum {
=head2

    SUBROUTINE     columnSum
    
    PURPOSE
    
		REPLACE A STRING IN A FILE AND WRITE TO A NEW FILE
		
	NOTES
	
		REQUIRES: /bin/mv TO BE INSTALLED
        
=cut
	my $args		=	shift;
	$self->logDebug("File::Tools::columnSum(args)");
	
	my $inputfile	=	$args->{inputfile};
	my $column		=	$args->{column};
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("column", $column);

	#### CHECK COLUMN IS INTEGER VALUE
	$self->logDebug("column not an integer", $column) and return if not $column =~ /^\d+$/;
	
	#### GET SUM
	my $command = qq{awk '{sum += \$$column} END {print sum}' $inputfile};
	my $sum = `$command`;
	$self->logDebug("sum", $sum);
	
	return $sum;
}


method replaceString {
=head2

    SUBROUTINE     replaceString
    
    PURPOSE
    
		REPLACE A STRING IN A FILE AND WRITE TO A NEW FILE
		
	NOTES
	
		REQUIRES: /bin/mv TO BE INSTALLED
        
=cut
	my $args		=	shift;
	$self->logObject("args", $args);
	
	my $inputfile	=	$args->{inputfile};
	my $outputfile	=	$args->{outputfile};
	my $query		=	$args->{query};
	my $target		=	$args->{target};
	my $global		=	$args->{global};
	

	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("query", $query);
	$self->logDebug("target", $target);

	#### COMMAND
	my $command = "cat $inputfile | sed 's/$query/$target/' > $outputfile";
	$command = "cat $inputfile | sed 's/$query/$target/g' > $outputfile" if defined $global;
	$self->logDebug("$command");
	print `$command`;

}	# replaceString


method selectColumns {
=head2

    SUBROUTINE     selectColumns
    
    PURPOSE
    
		REMOVE DUPLICATE LINES BASED ON USER-INPUT KEY COLUMNS
        
	NOTES
	
		REQUIRES: /bin/cut AND /bin/mv

=cut
	my $args		=	shift;
	
	my $inputfile	=	$args->{inputfile};
	my $outputfile	=	$args->{outputfile};
	my $columns		=	$args->{columns};

	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("columns", $columns);

	#### SORT INPUT FILE BASED ON ORDERED KEYS
	if ( $inputfile eq $outputfile )
	{
		my $cut_command = qq{/bin/cut -f $columns $inputfile > $inputfile-temp};
		$self->logDebug("cut_command", $cut_command);
		print `$cut_command`;
		my $move_command = qq{/bin/mv -f $inputfile-temp $inputfile};
		$self->logDebug("move_command", $move_command);
		print `$move_command`;
	}
	else
	{
		my $cut_command = qq{/bin/cut -f $columns $inputfile > $outputfile};
		$self->logDebug("cut_command", $cut_command);
		print `$cut_command`;
	}

}	# selectColumns



method removeDuplicates {
=head2

***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******

    SUBROUTINE     removeDuplicates
    
    PURPOSE
    
		REMOVE DUPLICATE LINES BASED ON USER-INPUT KEY COLUMNS
        
	NOTES
	
		REQUIRES: /bin/sort

***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******
***** ONWORKING ***** DO NOT USE *******

=cut
### ***** ONWORKING ***** DO NOT USE *******
### ***** ONWORKING ***** DO NOT USE *******
### ***** ONWORKING ***** DO NOT USE *******
### ***** ONWORKING ***** DO NOT USE *******
### ***** ONWORKING ***** DO NOT USE *******
### ***** ONWORKING ***** DO NOT USE *******
	my $args		=	shift;
	
	my $inputfile	=	$args->{inputfile};
	my $outputfile	=	$args->{outputfile};
	my $columns		=	$args->{columns};
	
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("columns", $columns);

	#### SET TEMP FILE
	my $tempfile = "$inputfile.temp";

	#### SORT INPUT FILE BASED ON ORDERED KEYS
	my $sort_command = qq{/bin/sort -o $tempfile};
	foreach my $column ( @$columns )
	{
		$sort_command .= " -k $column ";
	}
	$sort_command .= qq{ $inputfile };
	$self->logDebug("sort_command", $sort_command);
	print `$sort_command`;

	#### OPEN ENGINES
	open(FILE, $tempfile) or die "Can't open tempfile: $tempfile\n";
	open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";

	#### CHECK COLUMNS EXIST IN FILE
	$self->logDebug("Removing duplicates...");
	$/ = "\n";
	my $first_line = <FILE>;
	my $firstkey = $self->getKey($first_line, $columns);
	print OUT $first_line;
	
	while ( <FILE> )
	{
		
		last if not defined $_;
		
		my $secondkey = $self->getKey($_, $columns);
		
		#### SKIP WRITING THE LINE
		if ( $secondkey eq $firstkey )
		{
			$self->logDebug("firstkey ", $firstkey);
			$self->logDebug("secondkey", $secondkey);
			
			$firstkey = $secondkey;
			return;
		}
		else
		{
			
			print OUT $_;
		}
	}
	close(FILE);
	close(OUTFILE);

}	# removeDuplicates


method getKey {
	my $line		=	shift;
	my $columns 	=	shift;
	
	my @elements = split "\t", $line;
	my $firstkey = '';
	foreach my $column ( @$columns )
	{
		$firstkey .= $elements[$column];
	}
	
	return $firstkey;	
}





#							CONVERSION METHODS
method convertHeader {
=head2

    SUBROUTINE     convertHeader
    
    PURPOSE
    
		CHECK THAT PAIRED READS HAVE CORRESPONDING IDS
        
    INPUT
    
        1. INPUT FILE
		
		2. PAIRED FILE
		
		3. FILE TYPE (fasta|fastq)
            
    OUTPUT
    
        1. FIRST RECORD COUNT AT WHICH IDS DIFFER
		
		2. OR, TOTAL COUNT OF RECORDS IF THERE WERE NO DIFFERING IDS

=cut
	my $args		=	shift;
	$self->logDebug("");
	
	my $inputfile	=	$args->{inputfile};
	my $outputfile	=	$args->{outputfile};
	my $paired		=	$args->{paired};
	my $dot 		=	$args->{dot};
	
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("paired", $paired);

	my $counter = 0;
	$/ = "\n";
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
	open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";

	while ( <FILE> )
	{
		$self->logDebug("$counter") if $counter % $dot == 0;
		
		my $sequence_header = $_;
		my $sequence = <FILE>;
		my $paired_header = <FILE>;
		my $quality = <FILE>;

		####CONVERT THIS:
		####@SRR002271.28 FC2012M_R1:1:1:881:458                         
		####
		####TO THIS:
		####
		####>SLXA-B3_604:6:1:533:275 
		####	
		####OR THIS:
		####
		####>SLXA-B3_604:6:1:533:275/1 

		# MAKE THE NEW HEADER WORK WITH ELAND_standalone.pl
		#
		# check the fasta header and extract information for the qseq file
		# we assume the fasta header to be of the following format:
		# --- {shortRunfolderName}:{lane}:{tile}:}{x}:{y}#{indexBases}/[1|2]
		#method parseHeader($)
		#{
		#	my ($machineNum,$lane,$tile,$x,$y,$index,$read);
		#	# initialize                                      

		if ( $sequence_header =~ /^\@(\S+)\s+\S+:(\d+):(\d+):(\d+):(\d+)/ )
		{
			my $id = $1;
			my $lane = $2;
			my $tile = $3;
			my $x = $4;
			my $y = $5;
			
			my $new_header = "$id:$lane:$tile:$x:$y#";
			$new_header .= "/$paired" if defined $paired;
			print OUTFILE "\@$new_header\n";
			print OUTFILE $sequence;
			print OUTFILE "\+$new_header\n";
			print OUTFILE $quality;
		}

		$counter++;
	}

}	# convertHeader





method reduceReads {
=head2

    SUBROUTINE     reduceReads
    
    PURPOSE
    
		GET THE UNIQUE CHARACTERS IN TWO FILES AND FIND
		
		WHICH CHARACTERS ARE ONLY PRESENT IN ONE OF THE FILES
        
    INPUT
    
        1. TWO INPUT FILES
		
    OUTPUT
    
        1. SIX OUTPUTS:
			
			file1_only	count
			file1_only	characters
			file2_only	count
			file2_only	characters
			both		count
			both		characters

=cut
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $type		=	shift;
	my $length		=	shift;
	my $dot			=	shift;

	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("type", $type);
	$self->logDebug("length", $length);
	$self->logDebug("dot", $dot);

	#### OPEN FILES
	open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
	
	#### GO THROUGH READS PRINTING TO OUTPUT FILE	
	my $number_reads = 0;
	while ( <FILE> )
	{
		$self->logDebug("$number_reads") if $number_reads % $dot == 0;
		
		#### PRINT SEQUENCE HEADER TO OUTPUT FILE
		print OUTFILE $_;

		#### DO SEQUENCE
		if ( $type =~ /^fasta$/i )
		{
			my $sequence = <FILE>;
			if ( $number_reads == 0 )
			{
				$sequence =~ s/\s+//g; 
				if ( length($sequence) < $length )
				{
					$self->logError("Sequence length (", length($sequence), " is less desired length: $length. Exiting.");
					return;
				}
			}
			print OUTFILE substr($sequence, 0, $length), "\n";
			
			$number_reads++;
		}

		#### DO SEQUENCE, QUALITY HEADER AND QUALITY
		else
		{
			my $sequence = <FILE>;
			my $quality_header = <FILE>;
			my $quality = <FILE>;

			if ( $number_reads == 0 )
			{
				$sequence =~ s/\s+//g; 
				if ( length($sequence) < $length or length($quality) < $length )
				{
					my $seqlength = length($sequence);
					my $quallength = length($quality);
					$self->logError("Sequence length $seqlength and/or quality length $quallength is less than desired length: $length. Exiting.");
					return;
				}
			}
			print OUTFILE substr($sequence, 0, $length), "\n";
			print OUTFILE $quality_header;
			print OUTFILE substr($quality, 0, $length), "\n";
		}
		
		$number_reads++;
	}
	close(FILE) or die "Can't close input file: $inputfile\n";
	close(OUTFILE) or die "Can't close output file: $outputfile\n";
	
	return 1;
}







method symbolic2numeric {
=head2

	SUBROUTINE		symbolic2numeric
	
	PURPOSE
	
		CONVERT SYMBOLIC QUALITY VALUES TO NUMERIC QUALITY VALUES
	
=cut
	my $quality		=	shift;

	#### GET ASCII LETTER-NUMBER MAPPING
	my $ascii 		= 	$self->ascii();

    my @symbols = split "", $quality;
    my $numeric_quality = '';
	my $symbol_counter = 0;
    foreach my $symbol ( @symbols )
    {
		if ( not defined $ascii->{$symbol} )
		{
			$self->logError("ascii not defined for symbol $symbol_counter: **$symbol**\nin quality: ***$quality***");
			exit;
		}

		#### NB: MINUS 33 FOR STANDARD SANGER FASTQ (NOT 64 AS IN SOLEXA FASTQ) 
		#### http://seqanswers.com/forums/showthread.php?t=1110
		#### there are now three types of FASTQ files floating about; standard Sanger FASTQ with quality scores expressed as ASCII(Qphred+33), Solexa FASTQ with ASCII(Qsolexa+64) and Solexa FASTQ with ASCII(Qphred+64)		
		my $number = $ascii->{$symbol} - 33;
		#die "no number for symbol: $symbol\n" if not defined $ascii->{$symbol};
		
		
		if ( $number < 0 )
		{
			$number = 0;
		}
        $numeric_quality .= "$number ";

		$symbol_counter++;
    }
	$numeric_quality =~ s/\s+$//;

    #$self->logDebug("Quality (numeric)", $numeric_quality);


	return $numeric_quality;	
}



method ascii {
=head2

	SUBROUTINE		ascii
	
	PURPOSE
	
		PROVIDE A HASH OF MAPPINGS BETWEEN ASCII SYMBOLS AND THEIR DECIMAL NUMBERS
		
=cut
	my $key			=	shift;
	my $value		=	shift;
	
	#### RETURN SELF->ASCII IF ALREADY DEFINED
	if ( defined $self->{_ascii} )
	{
		return $self->{_ascii};
	}
	
	
    my $ascii;    

	if ( not defined $key )
	{
		$key = "symbol";
	}
	if ( not defined $value )
	{
	    $value = "dec";
	}

    my $data = $self->_ascii_data();
    my @lines = split "\n", $data;
    my @headings = split "\t", $lines[0];
    
	my %headings_hash;
    my $counter = 0;
    foreach my $heading ( @headings )
    {
        $headings_hash{$heading} = $counter;
        $counter++;
    }

    my $value_number = $headings_hash{$value};
    my $key_number = $headings_hash{$key};
    if ( not defined $value_number )
    {
        die "method ascii(). Value $value number not defined in headings: @headings\n";
    }
    if ( not defined $key_number )
    {
        die "method ascii(). Key $key number not defined in headings: @headings\n";
    }

    for ( my $i = 1; $i < $#lines + 1; $i++ )
    {
        my $line = $lines[$i];
 		my @elements = split "\t", $line;

		if ( @elements )
		{
	        $ascii->{$elements[$key_number]} = $elements[$value_number];
		}
    }
	
	$ascii->{"\n"}	=	10;	#### LINE FEED
	$ascii->{' '}	= 	32;		#### SPACE


	#### SET SELF->ASCII
	$self->{_ascii} = $ascii;
	
    return $ascii;
}



method _ascii_data {
=head2

	SUBROUTINE		data
	
	PURPOSE
	
		PROVIDE A TABLE OF MAPPINGS BETWEEN ASCII SYMBOLS AND THEIR DECIMAL NUMBERS
		
=cut

    my $data = qq{dec	octal	hex	binary	symbol
0	0	0	0	NUL  (Null char.)
1	1	1	1	SOH  (Start of Header)
2	2	2	10	STX  (Start of Text)
3	3	3	11	ETX  (End of Text)
4	4	4	100	EOT  (End of Transmiss	ion)
5	5	5	101	ENQ  (Enquiry)
6	6	6	110	ACK  (Acknowledgment)
7	7	7	111	BEL  (Bell)
8	10	8	1000	BS  (Backspace)
9	11	9	1001	HT  (Horizontal Tab)
10	12	00A	1010	LF  (Line Feed)
11	13	00B	1011	VT  (Vertical Tab)
12	14	00C	1100	FF  (Form Feed)
13	15	00D	1101	CR  (Carriage Return)
14	16	00E	1110	SO  (Shift Out)
15	17	00F	1111	SI  (Shift In)
16	20	10	10000	DLE  (Data Link Escape	)
17	21	11	10001	DC1  (XON) (Device Control 1)
18	22	12	10010	DC2      (Device Control 2)
19	23	13	10011	DC3  (XOFF)(Device Control 3)
20	24	14	10100	DC4      (Device Control 4)
21	25	15	10101	NAK  (Negative Acknowledgement)
22	26	16	10110	SYN  (Synchronous Idle)
23	27	17	10111	ETB  (End of Trans. Block)
24	30	18	11000	CAN  (Cancel)
25	31	19	11001	EM  (End of Medium)
26	32	01A	11010	method  (Substitute)
27	33	01B	11011	ESC  (Escape)
28	34	01C	11100	FS  (File Separator)
29	35	01D	11101	GS  (Group Separator)
30	36	01E	11110	RS  (Req to Send)(RecSep)
31	37	01F	11111	US  (Unit Separator)
32	40	20	100000	SP  (Space)
33	41	21	100001	!
34	42	22	00100010	"
35	43	23	100011	#
36	44	24	100100	\$
37	45	25	100101	\%
38	46	26	100110	&
39	47	27	100111	'
40	50	28	101000	(
41	51	29	101001	)
42	52	02A	101010	*
43	53	02B	101011	+
44	54	02C	00101100	,
45	55	02D	101101	-
46	56	02E	101110	.
47	57	02F	101111	/
48	60	30	110000	0
49	61	31	110001	1
50	62	32	110010	2
51	63	33	110011	3
52	64	34	110100	4
53	65	35	110101	5
54	66	36	110110	6
55	67	37	110111	7
56	70	38	111000	8
57	71	39	111001	9
58	72	03A	111010	:
59	73	03B	111011	;
60	74	03C	111100	<
61	75	03D	111101	=
62	76	03E	111110	>
63	77	03F	111111	?
64	100	40	1000000	\@
65	101	41	1000001	A
66	102	42	1000010	B
67	103	43	1000011	C
68	104	44	1000100	D
69	105	45	1000101	E
70	106	46	1000110	F
71	107	47	1000111	G
72	110	48	1001000	H
73	111	49	1001001	I
74	112	04A	1001010	J
75	113	04B	1001011	K
76	114	04C	1001100	L
77	115	04D	1001101	M
78	116	04E	1001110	N
79	117	04F	1001111	O
80	120	50	1010000	P
81	121	51	1010001	Q
82	122	52	1010010	R
83	123	53	1010011	S
84	124	54	1010100	T
85	125	55	1010101	U
86	126	56	1010110	V
87	127	57	1010111	W
88	130	58	1011000	X
89	131	59	1011001	Y
90	132	05A	1011010	Z
91	133	05B	1011011	[
92	134	05C	1011100	\\
93	135	05D	1011101	]
94	136	05E	1011110	^
95	137	05F	1011111	_
96	140	60	1100000	`
97	141	61	1100001	a
98	142	62	1100010	b
99	143	63	1100011	c
100	144	64	1100100	d
101	145	65	1100101	e
102	146	66	1100110	f
103	147	67	1100111	g
104	150	68	1101000	h
105	151	69	1101001	i
106	152	06A	1101010	j
107	153	06B	1101011	k
108	154	06C	1101100	l
109	155	06D	1101101	m
110	156	06E	1101110	n
111	157	06F	1101111	o
112	160	70	1110000	p
113	161	71	1110001	q
114	162	72	1110010	r
115	163	73	1110011	s
116	164	74	1110100	t
117	165	75	1110101	u
118	166	76	1110110	v
119	167	77	1110111	w
120	170	78	1111000	x
121	171	79	1111001	y
122	172	07A	1111010	z
123	173	07B	1111011	{
124	174	07C	1111100	|
125	175	07D	1111101	}
126	176	07E	1111110	~
127	177	07F	1111111	DEL};

    return $data;
}









    


method sortFile {
=head2

	SUBROUTINE		sortFile
	
	PURPOSE
	
		USE LINUX COMMAND LINE sort TO SORT FILE
		
		E.G., SORT SAM FILE BY REFERENCE COORDINATE

			sort -k 3,3 -k 4,4n hits.sam

			http://lowfatlinux.com/linux-sort.html


	sort file1 file2 | uniq	Union of unsorted files
 	sort file1 file2 | uniq -d	Intersection of unsorted files
 	sort file1 file1 file2 | uniq -u	Difference of unsorted files
 	sort file1 file2 | uniq -u	Symmetric Difference of unsorted files
 	join -t'\0' -a1 -a2 file1 file2	Union of sorted files
 	join -t'\0' file1 file2	Intersection of sorted files
 	join -t'\0' -v2 file1 file2	Difference of sorted files
 	join -t'\0' -v1 -v2 file1 file2	Symmetric Difference of sorted files

=cut
	my $args		=	shift;

$self->logDebug("(args)");	
#exit;


	my $inputfile	=	$args->{inputfile};
	my $outputfile	=	$args->{outputfile};
	my $column		=	$args->{column};
	my $numeric		=	$args->{numeric};
	my $reverse		=	$args->{reverse};
	
	#my $command = "LANG=C sort -k 3,3 -k 4,4n $inputfile";
	
	#my $command = "LANG=C sort -k $column ";
	my $command = "sort ";
	$command .= "-n " if defined $numeric;
	$command .= "-r " if defined $reverse;
	$command .= "-k $column ";
	$command .= "$inputfile ";
	$command .= "-o $outputfile ";
	$self->logDebug("$command\n");
	`$command`;
}




#							QC METHODS
method matesPaired {
=head2

    SUBROUTINE     matesPaired
    
    PURPOSE
    
		CHECK TWO LISTS OF FIRST AND SECOND MATE PAIR
		
		FILES FOR EQUAL NUMBER OF FILES AND ORDER OF FILES.
		
		ASSUMES THE MATE PAIR NUMBER IS THE LAST DIGIT IN
		
		THE FILE NAME
        
    INPUT
    
        1. ARRAY REFERENCE FOR FIRST MATE FILES ARRAY
		
        2. ARRAY REFERENCE FOR SECOND MATE FILES ARRAY
		
    OUTPUT
    
        1. RETURN 1 IF NUMBER OF FILES MATCHES AND FILES
		
			ARE IN COMPLIMENTARY ORDER.
			
		2. OTHERWISE, PRINT ERROR AND EXIT

=cut
	my $inputfiles	=	shift;
	my $matefiles	=	shift;

	$self->logDebug("File::Tools::matesPaired(inputfiles, matefiles)");

	$self->logDebug("inputfiles: @$inputfiles");
	$self->logDebug("matefiles: @$matefiles");
		
	#### CHECK EQUAL NUMBER OF FILES		
	if ( scalar(@$inputfiles) != scalar(@$matefiles) )
	{
		$self->logError("Number of read files (", scalar(@$inputfiles), " is not the same as the number of mate files (", scalar(@$matefiles), "). Exiting");
		exit;
	}

	#### CHECK ORDER OF FILES
	for ( my $i = 0; $i < @$inputfiles; $i++ )	
	{
		my $inputfile = $$inputfiles[$i];
		$self->logDebug("inputfile:\n$inputfile");
		my $matefile = $inputfile;
		$self->logDebug("BEFORE matefile:\n$matefile");
		my ($match) = $matefile =~ s/(_1\D+)$/_2$1/;
		$self->logDebug("match:\n$match");
		$self->logDebug("AFTER matefile:\n$matefile");
		if ( $matefile ne $$matefiles[$i] )
		{
			$self->logError("Expected matefile:\n$matefile\nBut found file:\n$$matefiles[$i]. Exiting");
			exit;
		}
	}

	return 1;
}	# matesPaired


method mergeFiles {
=head2

    SUBROUTINE     mergeFiles
    
    PURPOSE
    
		CHECK THAT PAIRED READS HAVE CORRESPONDING IDS
        
    INPUT
    
        1. OUTPUT FILE
		
		2. ARRAY OF INPUT FILES
		
    OUTPUT
    
        1. MERGED DATA IN OUTPUT FILE

=cut
	my $outputfile	=	shift;
	my $files		=	shift;
	$self->logDebug("File::Tools::mergeFiles(outputfile, files, dot)");
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("files: @$files");

	#### CHECK INPUT FILES EXIST
	foreach my $file ( @$files )
	{
		$self->logError("File::Tools::mergeFiles inputfile not found: $file") if not -f $file;
	}

	### MERGE IF MORE THAN ONE INPUT FILE
	if ( scalar(@$files) > 1 )
	{
		$self->logDebug("Merging input files");
		my $command = "cat @$files > $outputfile";
		`$command`;
	}
	
	### OTHERWISE, COPY FILE-TO-FILE
	else
	{
		$self->logError("Sole input file identical to output file: $outputfile") if $$files[0] eq $outputfile;

		$self->logDebug("Copying input files");
		File::Copy::copy($$files[0], $outputfile) or die "Can't copy output file: $$files[0] to outputfile: $outputfile\n";
	}
	
	return -f $outputfile;

}	# mergeFiles


method comparePair {
=head2

    SUBROUTINE     comparePair
    
    PURPOSE
    
		CHECK THAT PAIRED READS HAVE CORRESPONDING IDS
        
    INPUT
    
        1. INPUT FILE
		
		2. PAIRED FILE
		
		3. FILE TYPE (fasta|fastq)
            
    OUTPUT
    
        1. FIRST RECORD COUNT AT WHICH IDS DIFFER
		
		2. OR, TOTAL COUNT OF RECORDS IF THERE WERE NO DIFFERING IDS

=cut
	my $inputfile	=	shift;
	my $matefile	=	shift;
	my $type		=	shift;
	my $dot 		=	shift;
	
	$dot = 1000000 if not defined $dot;
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("type", $type);
	die "Type must be either 'line', 'fasta' or 'fastq'\n" if not $type =~ /^(line|fasta|fastq)$/i;

	my $comparePair;
	my $counter = 0;

	$/ = "\n";
	open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
	open(PAIRED, $matefile) or die "Can't open paired file: $matefile\n";

	if ( $type eq "line" )
	{
		my $counter = 0;
		while ( <FILE> )
		{
			my $line = $_;
			my $paired = <PAIRED>;

			#$self->logDebug("line", $line);
			#$self->logDebug("paired", $paired);
			$line =~ s/\/[12]$//;
			$paired =~ s/\/[12]$//;

			if ( $line ne $paired )
			{
				$comparePair->{number} = $counter;
				$comparePair->{name} = $line;
				$comparePair->{paired} = $paired;
				last;
			}

			$counter++;
		}

		$comparePair->{total} = $counter;
		
		return $comparePair;
	}

	elsif ( $type eq "fastq" )
	{
		while ( <FILE> )
		{
			$self->logDebug("$counter") if $counter % $dot == 0;
			
			my $sequence_header = $_;
			<FILE>;
			<FILE>;
			<FILE>;

			my $paired_header = <PAIRED>;
			<PAIRED>;
			<PAIRED>;
			<PAIRED>;

			if ( $sequence_header !~ /$paired_header/	 )
			{
				$self->logDebug("Mismatch at counter", $counter);
				$self->logDebug("sequence header", $sequence_header);
				$self->logDebug("paired header", $paired_header);

				$comparePair->{number} = $counter;
				$comparePair->{name} = $sequence_header;
				$comparePair->{paired} = $paired_header;
				last;
			}

			$counter++;
		}

		$comparePair->{total} = $counter;
		
		return $comparePair;
	}

	elsif ( $type eq "fasta" )
	{
		while ( <FILE> )
		{
			my $sequence_header = $_;
			<FILE>;

			my $paired_header = <PAIRED>;
			<PAIRED>;

			#$self->logDebug("sequence header", $sequence_header);
			#$self->logDebug("paired header", $paired_header);

			if ( $sequence_header ne $paired_header )
			{
				$comparePair->{number} = $counter;
				$comparePair->{name} = $sequence_header;
				$comparePair->{paired} = $paired_header;
				last;
			}
		
			$counter++;
		}

		$comparePair->{total} = $counter;		
		
		return $comparePair;
	}

}	# comparePair



method readQuality {
=head2

    SUBROUTINE     readQuality
    
    PURPOSE
    
		GET THE UNIQUE CHARACTERS IN TWO FILES AND FIND
		
		WHICH CHARACTERS ARE ONLY PRESENT IN ONE OF THE FILES
        
    INPUT
    
        1. TWO INPUT FILES
		
    OUTPUT
    
        1. SIX OUTPUTS:
			
			file1_only	count
			file1_only	characters
			file2_only	count
			file2_only	characters
			both		count
			both		characters

=cut
	my $file		=	shift;
	my $type		=	shift;

	$self->logDebug("file", $file);

	#### EXTRACT CHARACTERS THAT ARE ONLY IN ONE FILE
	my $quals;
	
	#### STORE ALL THE UNIQUE CHARACTERS IN THE FILES 
	my $file_chars = fileChars($file);
	
	my $overall_quality = 0;
	my $number_reads = 0;
	open(FILE, $file) or die "Can't open input file: $file\n";
	while ( <FILE> )
	{
		$self->logDebug("$number_reads") if $number_reads % 10000 == 0;
		my $header = $_;
		if ( not defined $header )
		{
			$self->logDebug("header not defined in read $number_reads");
			$self->logDebug("next line: <FILE>");
			$number_reads++;
			exit;
		}
		$header =~ s/\n$//;
		if ( $type =~ /^fasta$/i )
		{
			my $quality = <FILE>;
			my @values = split " ", $quality;
			my $sum = 0;
			foreach my $value ( @values )	{	$sum += $value;	}
			
			$quals->{reads}->{$header} = $sum;
			$overall_quality += $sum;
			$number_reads++;
		}
		else
		{
			#### SKIP SEQUENCE AND QUALITY HEADER
			<FILE>; <FILE>;
			my $quality = <FILE>;
			my $symbolic_quality = $self->symbolic2numeric($quality);
			if ( not defined $symbolic_quality )
			{
				$self->logDebug("Problem with quality");
			}
			my @values = split " ", $symbolic_quality;
			$self->logDebug("character not defined") if not @values;
			
			my $sum = 0;
			foreach my $value ( @values )	{	$sum += $value;	}

			$quals->{reads}->{$header} = $sum;
			$overall_quality += $sum;
			$number_reads++;
		}
		
		
		#use Data::Dumper;
		
	}
	
	$overall_quality = $overall_quality / $number_reads;
	$quals->{average} = $overall_quality;
	$quals->{number} = $number_reads;
	
	return $quals;
}






method compareChars {
=head2

    SUBROUTINE     compareChars
    
    PURPOSE
    
		GET THE UNIQUE CHARACTERS IN TWO FILES AND FIND
		
		WHICH CHARACTERS ARE ONLY PRESENT IN ONE OF THE FILES
        
    INPUT
    
        1. TWO INPUT FILES
		
    OUTPUT
    
        1. SIX OUTPUTS:
			
			file1_only	count
			file1_only	characters
			file2_only	count
			file2_only	characters
			both		count
			both		characters

=cut
	my $inputfile1	=	shift;
	my $inputfile2	=	shift;

	$self->logDebug("inputfile1", $inputfile1);
	$self->logDebug("inputfile2", $inputfile2) if defined $inputfile2;

	#### EXTRACT CHARACTERS THAT ARE ONLY IN ONE FILE
	my $inputfile1_only = [];
	my $inputfile2_only = [];
	
	#### PUT THE REST IN HERE
	my $both_chars	= {};
	
	#### STORE ALL THE UNIQUE CHARACTERS IN THE FILES 
	my $inputfile1_chars = fileChars($inputfile1);
	my $inputfile2_chars = fileChars($inputfile2);
	
	#### GET ALL THE UNIQUE CHARACTERS IN THE FILES
	my @inputfile1_keys = keys ( %$inputfile1_chars );
	my @inputfile2_keys = keys ( %$inputfile2_chars );

	#### GET ALL CHARACTERS THAT ARE ONLY FOUND IN THE FIRST FILE
	foreach my $key ( @inputfile1_keys )
	{
		if ( exists $inputfile2_chars->{$key} )
		{
			if ( not exists $both_chars->{$key} )
			{
				$both_chars->{$key} = 1;
			}
		}
		else
		{
			push @$inputfile1_only, { $key => $inputfile1_chars->{$key} };	
		}
	}


	#### GET ALL CHARACTERS THAT ARE ONLY FOUND IN THE SECOND FILE
	foreach my $key ( @inputfile2_keys )
	{
		if ( exists $inputfile1_chars->{$key} )
		{
			if ( not exists $both_chars->{$key} )
			{
				$both_chars->{$key} = 1;
			}
		}
		else
		{
			push @$inputfile2_only, { $key => $inputfile2_chars->{$key} };	
		}
	}

	#### REFORMAT 'BOTH' RESULTS
	my $both;
	foreach my $key ( keys %$both_chars )
	{
		push @$both, { $key => $both_chars->{$key} };
	}

	my $criteria;
	$criteria->{file1_only}->{count} = scalar(@$inputfile1_only);
	$criteria->{file1_only}->{characters} = $inputfile1_only;
	$criteria->{file2_only}->{count} = scalar(@$inputfile2_only);
	$criteria->{file2_only}->{characters} = $inputfile2_only;
	$criteria->{both}->{count} = scalar(@$both);
	$criteria->{both}->{characters} = $both;
	
	return $criteria;
}



method fileChars {
	my $file 		=	shift;
	$self->logDebug("File::Tools::fileChars(file);");
	$self->logDebug("file", $file);
	
	#### GET INPUTFILE1 CHARACTERS
	my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat($file);	
	$self->logDebug("file size", $size);

	open(FILE, $file) or die "Can't open file: $file, $!\n";
	my $offset = 0;	
	my $file_chars;
	while ( $offset < $size )
	{
		seek FILE, $offset, 0;
		my $char = getc FILE;
		if ( not exists $file_chars->{$char} )
		{
			$file_chars->{$char} = 1;
		}
		else
		{
			$file_chars->{$char}++;
		}
		
		$offset++;
	}
	close(FILE);

	$self->logObject("file chars", $file_chars);

	return $file_chars;
}




method readLengths {
=head2

    SUBROUTINE     readLengths
    
    PURPOSE
    
		CHECKs:
		
			1. READ LENGTHS ARE UNIFORM

			2. SEQUENCE AND QUALITY HEADERS MATCH

			3. QUALITY LENGTH EQUALS SEQUENCE LENGTH
        
    INPUT
    
        1. INPUT FILE
		
		2. FILE TYPE (fasta|fastq)
            
    OUTPUT
    
        1. HASH OF READ LENGTHS AND COUNTS

=cut
	my $inputfile	=	shift;
	my $type		=	shift;
	
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("type", $type);
	die "Type must be either 'fasta' or 'fastq'\n" if not $type =~ /^(fasta|fastq)$/i;

	my $readlengths;	
	if ( $type eq "fastq" )
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
		my $counter = 0;
		while ( <FILE> )
		{
			$counter++;
			$self->logDebug("$counter") if $counter % 10000 == 0;
			#$self->logDebug("Counter", $counter);
			
			my $sequence_header = $_;
			my $sequence = <FILE>;
			my $quality_header = <FILE>;
			my $quality = <FILE>;

			#$self->logDebug("sequence header", $sequence_header);
			#$self->logDebug("sequence", $sequence);
			#$self->logDebug("quality header", $quality_header);
			#$self->logDebug("quality", $quality);

			#### CHOP FIRST CHARACTER OF HEADER
			$sequence_header =~ s/^.//;
			$quality_header =~ s/^.//;
			
			#### CHECK HEADERS MATCH
			die "Headers do not match\nsequence_header: $sequence_header\n\nquality_header: $quality_header\n" if $sequence_header ne $quality_header;
			
			#### CHECK LENGTH OF SEQUENCE AND QUALITY
			die "Sequence and quality of different length:\nsequence length: ", length($sequence), "\nquality length: ", length($quality), "\n" if length($sequence) != length($quality);
			
			if ( not exists $readlengths->{length($sequence)} )
			{
				$readlengths->{length($sequence)} = 1;
			}
			else
			{
				$readlengths->{length($sequence)}++;
			}
		}
		
		return $readlengths;
	}
	else
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
		while ( <FILE> )
		{
			my $sequence_header = $_;
			my $sequence = <FILE>;

			$self->logDebug("sequence header", $sequence_header);
			$self->logDebug("sequence", $sequence);

			#### CHOP FIRST CHARACTER OF HEADER
			$sequence_header =~ s/^.//;
			
			if ( not exists $readlengths->{length($sequence)} )
			{
				$readlengths->{length($sequence)}  = 1;
			}
			else
			{
				$readlengths->{length($sequence)}++;
			}
		}
		
		return $readlengths;
	}

}	# readLengths




method filterReadLength {
=head2

    SUBROUTINE     filterReadLength
    
    PURPOSE
    
		FILTER OUT ALL READS WHOSE SEQUENCE OR QUALITY STRINGS
		
		ARE NOT THE SPECIFIED LENGTH
        
    INPUTS
    
        1. INPUT FILE
		
		2. FILE TYPE (fasta|fastq)
           
		3. READ LENGTH
		
		4. OUTPUT FILE
		
    OUTPUTS
    
        1. FILE CONTAINING SEQUENCES

=cut
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $type		=	shift;
	my $length 		=	shift;

	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("type", $type);
	$self->logDebug("length", $length);
	die "Type must be either 'fasta' or 'fastq': $type\n" if not $type =~ /^(fasta|fastq)$/i;

	#### OPEN OUTFILE
	open(OUTFILE, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
	if ( $type eq "fastq" )
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
		while ( <FILE> )
		{
			#$self->logDebug("Counter", $counter);
			
			my $sequence_header = $_;
			my $sequence = <FILE>;
			my $quality_header = <FILE>;
			my $quality = <FILE>;

			#$self->logDebug("sequence header", $sequence_header);
			#$self->logDebug("sequence: $sequence, length: ", length($sequence), "");
			#$self->logDebug("quality header", $quality_header);
			#$self->logDebug("quality: $quality, length: ", length($quality), "");

			#### CHECK LENGTH OF SEQUENCE AND QUALITY
			next if not defined $sequence or not defined $quality;
			next if length($quality) != $length;
			next if length($sequence) != $length;

			print OUTFILE "$sequence_header$sequence$quality_header$quality";
		}
	}
	else
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
		while ( <FILE> )
		{
			my $sequence_header = $_;
			my $sequence = <FILE>;

			#$self->logDebug("sequence header", $sequence_header);
			#$self->logDebug("sequence", $sequence);

			#### CHOP FIRST CHARACTER OF HEADER
			$sequence_header =~ s/^.//;
			
			#### CHECK LENGTH OF SEQUENCE AND QUALITY
			next if not defined $sequence;
			next if length($sequence) != $length;

			print OUTFILE "$sequence_header$sequence";
		}
	}

}	# filterReadLength

method trimRead {
=head2

    SUBROUTINE     trimRead
    
    PURPOSE
    
		1. TRIM FASTA OR FASTQ READS AT 5' END AND/OR TRUNCATE
		
			TO SPECIFIED LENGTH
		
		2. IGNORE READS THAT ARE SHORTER THAN THE SPECIFIED LENGTH
        
    INPUTS
    
        1. INPUT FILE
		
		2. OUTPUT FILE
		
		3. FILE TYPE (fasta|fastq)
           
		4. START TRIM LENGTH (E.G., 1 TO REMOVE FIRST READ)
		
		5. TRUNCATED LENGTH (AFTER START TRIM)
		
    OUTPUTS
    
        1. FILE CONTAINING SEQUENCES

=cut
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $type		=	shift;
	my $length 		=	shift;
	my $start		=	shift;
	$self->logDebug("\nFile::Tools::trimRead(inputfile, type, outputfile, length, start)");

	#### CHECK INPUTS
	$start = 0 if not defined $start;
	$self->logError("File::Tools::trimRead    length not defined. Exiting") if not defined $length;
	
	$self->logDebug("inputfile", $inputfile);
	$self->logDebug("outputfile", $outputfile);
	$self->logDebug("type", $type);
	$self->logDebug("length", $length);
	$self->logDebug("start", $start);
	die "Type must be either 'fasta' or 'fastq': $type\n" if not $type =~ /^(fasta|fastq)$/i;

	#### OPEN OUTFILE
	open(OUTFILE, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
	if ( $type eq "fastq" )
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
		while ( <FILE> )
		{
			my $sequence_header = $_;
			my $sequence = <FILE>;
			my $quality_header = <FILE>;
			my $quality = <FILE>;
		
			$sequence =~ s/\s+//g;
			$quality =~ s/\s+//g;

			$self->logDebug("sequence header", $sequence_header);
			$self->logDebug("quality header", $quality_header);
			$self->logDebug("sequence: $sequence, length: ", length($sequence), "");
			$self->logDebug("quality:  $quality, length: ", length($quality), "");

			#### CHECK LENGTH OF SEQUENCE AND QUALITY
			next if not defined $sequence or not defined $quality;
			next if length($quality) < ($length + $start);
			next if length($sequence) < ($length + $start);
			
			if ( $start )
			{
				$sequence = substr($sequence, $start);
				$quality = substr($quality, $start);
			}

			$sequence = substr($sequence, 0, $length);
			$quality = substr($quality, 0, $length);

			
			print OUTFILE "$sequence_header$sequence\n$quality_header$quality\n";
		}
	}
	else
	{
		$/ = "\n";
		open(FILE, $inputfile) or die "Can't open input file: $inputfile\n";
		while ( <FILE> )
		{
			my $sequence_header = $_;
			my $sequence = <FILE>;

			#$self->logDebug("sequence header", $sequence_header);
			#$self->logDebug("sequence", $sequence);

			#### CHOP FIRST CHARACTER OF HEADER
			$sequence_header =~ s/^.//;
			
			#### CHECK LENGTH OF SEQUENCE AND QUALITY
			next if not defined $sequence;
			next if length($sequence) != $length;

			print OUTFILE "$sequence_header$sequence";
		}
	}
	close(OUTFILE) or die "Can't close outputfile: $outputfile\n";

}	# trimRead



##############################################################################
#							SVN METHODS
method svnBackup {
=head2

    SUBROUTINE     svnBackup
    
    PURPOSE
    
        ADD AND DELETE FILES FROM THE REPOSITORY BASED ON 
	
		A FILESYSTEM WHICH: 
		
		1) DOES NOT HAVE SVN ENABLED, OR 2) HAS SVN ENABLED FOR ANOTHER
		
		REPOSITORY (E.G., A NON-COMPATIBLE WINDOWS REPOSITORY)
		
		OR, 3) IS A WORKING DIRECTORY OF THE TARGET REPOSITORY.

		THE DESIRED OUTCOME IS TO ENSURE THAT THE FILESYSTEMS OF THE
		
		SOURCE DIRECTORY AND THE TARGET REPOSITORY BECOME IDENTICAL
		
		BY ADDING AND DELETING FILES IN THE REPOSITORY. 
        
    INPUT
    
        1. SOURCE DIRECTORY 
		
		2. TARGET REPOSITORY
		
		3. MESSAGE FOR COMMIT
        
    OUTPUT
    
        1. THE TARGET REPOSITORY FILESYSTEM MIRRORS IDENTICALLY THE
		
		SOURCE DIRECTORY 
		
		2. TWO INTERMEDIATE DIRECTORIES ARE GENERATED:
		
			TRANSIT - CREATED FRESH FILLED WITH FILESYSTEM COPIED FROM THE
					SOURCE DIRECTORY, WITH ALL .svn FOLDERS RECURSIVELY REMOVED
			
			SVN	-	WORKING DIRECTORY POPULATED BY CHECKOUT, EMPTIED EXCEPT 
					FOR .svn FOLDERS AND THEN FILLED WITH FILESYSTEM COPIED FROM
					TRANSIT FOLDER
					
	NOTES
	
		METHOD
		
		1. GENERATE THESE VARIABLES (ASSUMING SOURCE IS "html/plugins/project"):
		
		sourcedir /data/agua/0.3/html/plugins/project
		transitdir /data/agua/0.3transit/html/plugins/project
		workingdir /data/agua/0.3transit/html/plugins/project
		repository file:///srv/svn/agua/trunk/html/plugins/project



		2. TRANSFER ALL FILES TO TRANSIT DIRECTORY
		
		mkdir -p /data/agua/0.3transit/html/plugins/project
		cp -r /data/agua/0.3/html/plugins/project/* /data/agua/0.3transit/html/plugins/project
		
		

		3. CLEAN OUT .svn FROM TRANSIT DIRECTORY
		
		/data/agua/0.3/bin/scripts/svn.pl --mode clean --workingdir /data/agua/0.3transit/trunk/html/plugins/project 
		
		
		
		4. CHECKOUT REPOSITORY FILES INTO SVN WORKING DIRECTORY
		
		mkdir -p /data/agua/0.3svn/html/plugins/project
		cd /data/agua/0.3svn/html/plugins/project
		svn checkout file:///srv/svn/agua/trunk/html/plugins/project ./
		
		
		
		5. EMPTY CHECKED OUT WORKING DIRECTORY LEAVING ONLY .svn FOLDERS
		
		/data/agua/0.3/bin/scripts/svn.pl --mode empty --workingdir /data/agua/0.3svn/html/plugins/project 
		
		
		
		6. COPY CLEANED FILESYSTEM OVER TO EMPTY (.svn ONLY) WORKING DIRECTORY
		
		cp -r /data/agua/0.3transit/html/plugins/project/* /data/agua/0.3svn/html/plugins/project

		
		
		7. SYNCHRONISE TO MAKE THE REPOSITORY MIRROR THE WORKING DIRECTORY
		
		/data/agua/0.3/bin/scripts/svn.pl --mode sync --workingdir /data/agua/0.3svn/trunk/html/plugins/project --repository file:///srv/svn/agua/trunk/html/plugins/project


=cut

	#$| = 1;
	my $args		=	shift;

	####	EXAMPLE ARGUMENTS:
	####	/data/agua/0.3/bin/scripts/svn.pl \
	####	--mode backup \
	####	--base /data/agua/0.3 \
	####	--source html/plugins/project \
	####	--repository file:///srv/svn/agua/trunk/html/plugins/project \
	####	--message "Added modular CSS for OptionsTitlePane upload. Onworking poll for status"


	$self->logDebug("File::Tools::svnSync(args)");
	$self->logObject("args", $args);

	my $base	=	$args->{base};
	my $source	=	$args->{source};
	my $repository	=	$args->{repository};
	my $message		=	$args->{message};
	$message = 'sync' if not defined $message;

	$self->logDebug("base", $base);
	$self->logDebug("source", $source);
	$self->logDebug("repository", $repository);
	$self->logDebug("message", $message);

	####	1. GENERATE THESE VARIABLES (ASSUMING SOURCE IS "html/plugins/project"):
	####	
	####	sourcedir /data/agua/0.3/html/plugins/project
	####	transitdir /data/agua/0.3trall /datansit/html/plugins/project
	####	workingdir /data/agua/0.3transit/html/plugins/project
	####	repository file:///srv/svn/agua/trunk/html/plugins/project
	####	

	$self->logDebug("1. Setting variables and checking files and folders...");
	
	my $sourcedir = "$base/$source";
	my $transitdir = "$base-transit/$source";
	my $workingdir = "$base-svn/$source";
	$self->logDebug("sourcedir", $sourcedir);
	$self->logDebug("workingdir", $workingdir);
	$self->logDebug("transitdir", $transitdir);

	#### CHECK SOURCE DIR
	$self->logError("Can't find source directory: $sourcedir") if not -d $sourcedir;
	
	#### CHECK REPOSITORY
	my $list_output = `svn list $repository`;
	$self->logError("Can't list repository: $repository") if not defined $list_output or not $list_output;
	
	#### CREATE TRANSIT DIR
	if ( -d $transitdir )
	{
		my $recursive = 1;
		File::Remove::rm(\$recursive, $transitdir) or die "Can't remove existing transit directory: $transitdir\n";
	}
	`mkdir -p $transitdir`;
	die "Can't create transit directory: $transitdir\n" if not -d $transitdir;
	
	#### CREATE WORKING DIR PARENT
	$workingdir =~ s/\/$//;
	my ($workingdir_parent) = $workingdir =~ /^(.+)\/[^\/]+$/;
	if ( -d $workingdir_parent )
	{
		my $recursive = 1;
		File::Remove::rm(\$recursive, $workingdir_parent) or die "Can't remove existing working directory parent: $workingdir_parent\n";
	}
	`mkdir -p $workingdir_parent`;
	die "Can't create working directory parent: $workingdir_parent\n" if not -d $workingdir_parent;	

	####	2. TRANSFER ALL FILES TO TRANSIT DIRECTORY
	####	
	####	mkdir -p /data/agua/0.3transit/html/plugins/project
	####	cp -r /data/agua/0.3/html/plugins/project/* /data/agua/0.3transit/html/plugins/project

	$self->logDebug("2. Transfering files to transit directory...");
	my $transfer = "cp -r $sourcedir/* $transitdir";
	$self->logDebug("$transfer");
	print `$transfer`;

	####	3. CLEAN OUT .svn FROM TRANSIT DIRECTORY
	####	
	####	/data/agua/0.3/bin/scripts/svn.pl --mode clean --workingdir /data/agua/0.3transit/trunk/html/plugins/project 
	####	

	$self->logDebug("3. Cleaning transit directory...");
	$self->svnClean( { workingdir => $transitdir } );
	####	4. CHECKOUT REPOSITORY FILES INTO SVN WORKING DIRECTORY
	####	
	####	mkdir -p /data/agua/0.3svn/html/plugins/project
	####	cd /data/agua/0.3svn/html/plugins/project
	####	svn checkout file:///srv/svn/agua/trunk/html/plugins/project ./
	####	

	$self->logDebug("4. Checking out repository to working directory...");
	chdir($workingdir_parent) or die "File::Tools::svnSync    Can't chdir to working directory parent: $workingdir_parent\n";
	my $checkout = "svn checkout $repository";
	$self->logDebug("$checkout");
	print `$checkout`;


	####	5. EMPTY CHECKED OUT WORKING DIRECTORY LEAVING ONLY .svn FOLDERS
	####	
	####	/data/agua/0.3/bin/scripts/svn.pl --mode empty --workingdir /data/agua/0.3svn/html/plugins/project 
	####	

	$self->logDebug("5. Emptying working directory of files (except .svn folders)...");
	$self->svnEmpty( { workingdir => $workingdir } );
	####	6. COPY CLEANED FILESYSTEM OVER TO EMPTY (.svn ONLY) WORKING DIRECTORY
	####	
	####	cp -r /data/agua/0.3transit/html/plugins/project/* /data/agua/0.3svn/html/plugins/project
	####	
	
	$self->logDebug("6. Copying 'clean' filesystem in transit directory to 'empty' filesystem in working directory...");
	my $copy = "cp -pr $transitdir/* $workingdir";
	$self->logDebug("$copy");
	print `$copy`;


	####	7. SYNCHRONISE TO MAKE THE REPOSITORY MIRROR THE WORKING DIRECTORY
	####	
	####	/data/agua/0.3/bin/scripts/svn.pl --mode sync --workingdir /data/agua/0.3svn/trunk/html/plugins/project --repository file:///srv/svn/agua/trunk/html/plugins/project
	####

	#### SET ARGS
	$self->logDebug("6. Synchronising working directory with repository...");
	$args->{workingdir} = $workingdir;
	$self->svnSync($args);

	return 1;
}







method svnSync {
=head2

    SUBROUTINE     svnSync
    
    PURPOSE
    
        SYNCHRONISE BETWEEN AN .svn WORKING DIR AND A REPOSITORY
		
		I.E., DO add AND delete OF NEW AND MISSING FILES IN THE
		
		WORKING DIRECTORY THEN COMMIT TO REPOSITORY
        
    INPUT
    
        1. WORKING DIRECTORY /full/path/to/file
		
		2. REPOSITORY /full/path/to/file
        
    OUTPUT
    
        1. WORKING DIRECTORY WITH ALL NEW FILES ADDED AND ALL
		
			MISSING FILES DELETED
		
		2. WORKING DIRECTORY COMMITTED TO THE RESPOSITORY

	NOTES
	
		1. RUN svnAddDelete TO ADD/DELETE FILES
		
		2. DO 'svn update' IN top WORKING DIRECTORY TO UPDATE THE
		
			LOCAL .svn DATAFILES THAT ANY DELETED FILES HAVE BEEN
			
			REMOVED FROM THE REPOSITORY.

=cut

	#$| = 1;
	my $args		=	shift;

	$self->logDebug("File::Tools::svnSync(args)");
	$self->logObject("args", $args);

	my $sourcedir	=	$args->{sourcedir};
	my $workingdir	=	$args->{workingdir};
	my $repository	=	$args->{repository};
	my $message		=	$args->{message};
	
	$self->logDebug("workingdir", $workingdir);
	$self->logDebug("repository", $repository);
	$message = 'sync' if not defined $message;
	$self->logDebug("message", $message);

	chdir($workingdir) or die "File::Tools::svnSync    Can't chdir to working directory: $workingdir\n";
	
	#### 	1. RUN svnAddDelete TO ADD/DELETE FILES
	$self->svnAddDelete($sourcedir, $workingdir, $repository, $message);

	####	2. DO 'svn update' IN top WORKING DIRECTORY TO UPDATE THE
	####	LOCAL .svn DATAFILES REGARDING ANY DELETED FILES THAT HAVE 
	####	BEEN REMOVED FROM THE REPOSITORY.
	my $cleanup = "svn cleanup $workingdir";
	$self->logDebug("$cleanup");
	print `$cleanup`;
	
	my $update = "svn update";
	$self->logDebug("$update");
	print `$update`;


	#$self->logDebug("$cleanup  $workingdir");

	#####	3. DO 'svn commit' IN top WORKING DIRECTORY TO UPDATE THE
	#####	LOCAL .svn DATAFILES REGARDING ANY FILES THAT HAVE BEEN ADDED
	#my $commit = "svn commit \-m $message";
	#$self->logDebug("$commit");

}



method svnAddDelete {
=head2

    SUBROUTINE     svnAddDelete
    
    PURPOSE
    
        DO add AND delete OF NEW AND MISSING FILES IN THE
		
		WORKING DIRECTORY
        
    INPUT
    
        1. WORKING DIRECTORY /full/path/to/file
		
		2. REPOSITORY /full/path/to/file
        
    OUTPUT
    
        1. WORKING DIRECTORY WITH ALL NEW FILES ADDED AND ALL
		
			MISSING FILES DELETED

	NOTES
	
		METHOD
		
		1. GET LIST OF FILES/DIRS IN REPOSITORY
		
			svn list repository/directory

		2. GET LIST OF FILES/DIRS IN WORKING DIRECTORY, E.G.:
		
		3. GET WORKINGDIR-ONLY, REPOSITORY-ONLY AND CONFLICT FILES
		
			I.E., WHERE FILE TYPE (I.E., FILE/DIR) IS NOT THE SAME BETWEEN
			
			THE REPOSITORY AND THE WORKING DIR
		
		4. DELETE ALL FILES NOT PRESENT IN THE WORKING DIRECTORY:
		
			svn delete file:///srv/svn/agua/trunk/dummy.txt -m "delete file"

		5. ADD ALL FILES NOT PRESENT IN THE REPOSITORY:
		
			svn add dummy.txt

		6. DEAL WITH FILE TYPE CONFLICTS (E.G., WORKINGDIR/temp IS A
		
			DIRECTORY BUT REPOSITORY/temp IS A FILE):
			
			1. DELETE FILE FROM REPOSITORY
			
			2. FILE IN THE WORKING DIR TO '*-temp'
			
			3. DO 'svn update'
			
			4. REVERSE THE MOVE OF THE FILE IN THE WORKING DIR 
			
			5. DO 'svn add filename'



		NB: MUST DO 'svn update' IN WORKING DIRECTORY TO UPDATE
	
		.svn FILES THAT THE MISSING FILES HAVE BEEN REMOVED
		
		FROM THE REPOSITORY. THIS WILL DELETE THE FILES ON THE
		
		LOCAL DIRECTORY IF PRESENT (THIS SHOULD NOT HAPPEN SINCE
		
		WE'RE DELETING THEM BECAUSE THEY ARE NOT PRESENT)


		NNB: AN ALTERNATE METHOD:

		1. RUN svn status INSIDE THE WORKING DIRECTORY TO GET ALL FILES
		
		WHICH ARE NOT IN THE REPOSITORY (WITH '?' STATUS). ADD THESE
		
		USING THE 'svn add' COMMAND, JUST LIKE:
		
			svn status | grep '?' | sed 's/^.* /svn add /' | bash
		
=cut

	#$| = 1;
	my $sourcedir	=	shift;
	my $workingdir	=	shift;
	my $repository	=	shift;
	my $message		=	shift;

	$self->logDebug("File::Tools::svnAddDelete(sourcedir, workingdir, repository, message)");
	$self->logDebug("sourcedir", $sourcedir);
	$self->logDebug("workingdir", $workingdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("message", $message);

	####	1. FOR THIS DIRECTORY, GET LIST OF FILES IN REPOSITORY
	my $repository_filehash;
	my @lines = `svn -v list $repository`;
	foreach my $line ( @lines )
	{
		my ($filename) = $line =~ /(\S+)$/;
		next if $filename =~ /^\.\/$/;
		#$self->logDebug("filename", $filename);
		if ( $filename =~ s/\/$// )
		{
			#$self->logDebug("filename: $filename IS A DIRECTORY");
			$repository_filehash->{$filename} = "directory";
		}
		else
		{
			#$self->logDebug("filename: $filename IS A FILE");
			$repository_filehash->{$filename} = "file";
		}
	}
	$self->logDebug("repository_filehash:");
	foreach my $filename ( sort (keys %$repository_filehash) )
	{
		$self->logDebug("\t\t$filename\t:\t$repository_filehash->{$filename}");
	}
	$self->logDebug("");

	####	2. COMPARE WITH FILES/DIRS IN WORKING DIRECTORY, E.G.:
	my $workingdir_filehash;
	my $workingdir_files;

	#### GET FILES
	my $directory = $sourcedir if defined $sourcedir;
	$directory = $workingdir if not defined $sourcedir;
	
	@$workingdir_files = `ls -al $directory`;
	shift @$workingdir_files;
	foreach my $line ( @$workingdir_files )
	{
		next if $line =~ /\.(\.?)$/;
		next if $line =~ /\.svn$/;
		#$self->logDebug("line", $line);
		
		my ($filename) = $line =~ /^.+\d+\s+(.+?)$/;  
		#$self->logDebug("filename", $filename);
		chomp($filename);
		if ( $line =~ /^d/ )
		{
			#$self->logDebug("filename: $filename IS A DIRECTORY");
			$workingdir_filehash->{$filename} = "directory";
		}
		else
		{
			#$self->logDebug("filename: $filename IS A FILE");
			$workingdir_filehash->{$filename} = "file";
		}
	}
	$self->logDebug("workingdir_filehash:");
	foreach my $filename ( sort (keys %$workingdir_filehash) )
	{
		$self->logDebug("\t\t$filename\t:\t$workingdir_filehash->{$filename}");
	}
	$self->logDebug("");
	
	####	3. GET WORKINGDIR-ONLY, REPOSITORY-ONLY AND CONFLICT FILES
	####	
	####		I.E., WHERE FILE TYPE (I.E., FILE/DIR) IS NOT THE SAME BETWEEN
	####		
	####		THE REPOSITORY AND THE WORKING DIR
	####
	my $workingdir_only = [];
	my $repository_only = [];
	my $conflictfiles = [];

	#### GET REPOSITORY ONLY FILES AND CONFLICT FILES, AND DO svnAddDelete
	#### RECURSIVELY ON ANY SUB-DIRECTORIES
	#$self->logDebug("Getting repository-only files for workingdir", $workingdir);
	foreach my $filename ( keys %$repository_filehash )
	{
		#$self->logDebug("filename", $filename);
		next if $filename =~ /^\.$/ or $filename =~ /^\.\.$/;
		if ( not exists $workingdir_filehash->{$filename} )
		{
			push @$repository_only, $filename ;
		}

		#### GET CONFLICT FILES (E.G., SAME NAME BUT IS A DIRECTORY IN THE WORKING
		#### DIR AND A FILE IN THE REPOSITORY)
		elsif ( $repository_filehash->{$filename} eq "file" and not -f "$workingdir/$filename"
			   or $repository_filehash->{$filename} eq "directory" and not -d "$workingdir/$filename" )
		{
			push @$conflictfiles, $filename;
		}

		#### DO svnAddDelete RECURSIVELY ON ANY DIRECTORIES IN WORKINGDIR
		#### THAT ARE ALSO IN THE REPOSITORY
		elsif ( $repository_filehash->{$filename} eq "directory" )
		{
			$self->logDebug("Doing svnAddDelete('$sourcedir/$filename', '$workingdir/$filename', '$repository/$filename', '$message')");
			
			my $source;
			$source = "$sourcedir/$filename" if defined $source;
			
			$self->svnAddDelete($source, "$workingdir/$filename", "$repository/$filename", $message);
		}
	}

	#### PRINT OUT REPOSITORY-ONLY FILES FOR DEBUG
	$self->logObject("Repository only", @$repository_only);
	$self->logDebug(""); 

	#### PRINT OUT CONFLICT FILES FOR DEBUG
	$self->logObject("Conflict files:", @$conflictfiles );

	#### GET WORKINGDIR-ONLY FILES
	#$self->logDebug("Getting workingdir-only files for workingdir", $workingdir);
	foreach my $filename ( keys %$workingdir_filehash )
	{
		$self->logDebug("filename", $filename);
		if ( not exists $repository_filehash->{$filename} )
		{
			$self->logDebug("PUSHING to workingdir_only filename", $filename);
			push @$workingdir_only, $filename ;
		}
	}

	#### PRINT OUT WORKINGDIR-ONLY FILES FOR DEBUG
	$self->logObject("Workingdir only:", @$workingdir_only);

	#### 	MOVE TO WORKING DIRECTORY
	chdir($workingdir) or die "File::Tools::svnAddDelete    Can't chdir to working directory: $workingdir\n";


	####	4. DELETE ALL FILES NOT PRESENT IN THE WORKING DIRECTORY:
	####	
	####		svn delete file:///srv/svn/agua/trunk/dummy.txt -m "delete file"
	####
	foreach my $filename ( @$repository_only )
	{
		my $delete = "svn delete $repository/$filename -m sync ";
		$self->logDebug("$delete");
		print `$delete`;
	}
	
	
	####	5. ADD ALL FILES NOT PRESENT IN THE REPOSITORY:
	####	
	####		svn add dummy.txt
	####
	foreach my $filename ( @$workingdir_only )
	{
		my $add = "svn add $filename";
		$self->logDebug("$add");
		print `$add`;
	}


	####	DO 'svn commit' IN top WORKING DIRECTORY TO UPDATE THE
	####	LOCAL .svn DATAFILES REGARDING ANY FILES THAT HAVE BEEN ADDED
	my $commit = qq{svn commit \-m "$message"};
	$self->logDebug("$commit");
	print `$commit`;

	#####	DO 'svn update' TO 
	#my $update = "svn update";
	#$self->logDebug("$update");


	####	6. DEAL WITH FILE TYPE CONFLICTS (E.G., WORKINGDIR/temp IS A
	####	
	####		DIRECTORY BUT REPOSITORY/temp IS A FILE):
	####		
	####		1. DELETE FILE FROM REPOSITORY
	####		
	$self->logDebug("DOING conflict files...");	
	foreach my $filename ( @$conflictfiles )
	{
		my $delete = "svn rm $repository/$filename -m sync ";
		$self->logDebug("$delete");
		print `$delete`;
	}


	####		2. FILE IN THE WORKING DIR TO '*-temp'
	####		
	foreach my $filename ( @$conflictfiles )
	{
		my $move = "mv $workingdir/$filename $workingdir/$filename-temp";
		$self->logDebug("$move");
		print `$move`;
	}


	####		3. DO 'svn update'
	####		
	my $update = "svn update";
	$self->logDebug("$update");
	print `$update`;


	####		4. REVERSE THE MOVE OF THE FILE IN THE WORKING DIR 
	####		
	foreach my $filename ( @$conflictfiles )
	{
		my $move = "mv $workingdir/$filename-temp $workingdir/$filename";
		$self->logDebug("$move");
		print `$move`;
	}

	####		5. DO 'svn add filename'
	foreach my $filename ( @$conflictfiles )
	{
		my $add = "svn add $filename";
		$self->logDebug("$add");
		print `$add`;
	}


	####		6. DO 'svn update'
	####		
	$commit = qq{svn commit -m "$message"};
	$self->logDebug("$commit");
	print `$commit`;

	
	return 1;	
}


method svnEmpty {
=head2

    SUBROUTINE     svnEmpty
    
    PURPOSE
    
        REMOVE *** ALL BUT THE .svn DIRS *** IN ALL DIRECTORIES AND SUBDIRECTORIES
        
    INPUT
    
        1. INPUT DIRECTORY /full/path/to/file
            
    OUTPUT
    
        1. INPUT DIRECTORY WITH **** ALL BUT THE .svn DIRECTORIES *** REMOVED

=cut
	my $args 		=	shift;
	
	my $directory = $args->{workingdir};

	$self->logDebug("File::Tools::svnEmpty(dir)");	
	$self->logDebug("dir", $directory);
	$directory =~ s/\s+/\\ /g;	
	$directory =~ s/\(/\\(/g;	
	$directory =~ s/\)/\\)/g;	
	$self->logDebug("AFTER REGEX dir", $directory);
	
	my $files;
	@$files = `ls -a $directory`;
	
	#$self->logDebug("files: @$files");
	foreach my $file ( @$files )
	{
		chomp($file);
		next if $file =~ /^\.$/ or $file =~ /^\.\.$/ or $file =~ /^\.svn$/;
		$file = "$directory/$file";
		#$self->logDebug("file", $file);
		
	    if ( $file !~ /\/\.svn$/ and -f $file )
		{
			$self->logDebug("Removing file", $file);
			my $recursive = 0;
			File::Remove::rm(\$recursive, $file);
			if ( -f $file )
			{
				$self->logDebug("!!! Could not remove file", $file);
			}
		}
		elsif ( -d $file )
		{
			$self->svnEmpty( { 'workingdir' => $file } );
		}	
	}
	
	return 1;	
}




method svnClean {
=head2

    SUBROUTINE     svnClean
    
    PURPOSE
    
        REMOVE .svn DIRS IN DIRECTORIES AND SUBDIRECTORIES
        
    INPUT
    
        1. INPUT DIRECTORY /full/path/to/file
            
    OUTPUT
    
        1. INPUT DIRECTORY WITH ALL .svn FILES REMOVED

=cut
	my $args 		=	shift;
	
	my $directory = $args->{workingdir};

	$self->logDebug("File::Tools::svnClean(dir)");	
	$self->logDebug("dir", $directory);
	$directory =~ s/\s+/\\ /g; #### SPACE BETWEEN WORDS IN FILENAME ON WINDOWS	
	$directory =~ s/\(/\\(/g;	
	$directory =~ s/\)/\\)/g;	
	#$self->logDebug("AFTER REGEX dir", $directory);

	#$directory =~ s/\\+/\\\\/g if $^O =~ /^MSWin32$/;
	#$directory =~ s/\/+/\\/g if $^O =~ /^MSWin32$/;
	
	my $files;
	if ( not -d $directory )
	{
		$self->logDebug("not a directory", $directory);
		return;
	}
	opendir(DIR,$directory) or die "File::Tools::svnClean    Can't open directory: $directory\n";
	@$files = readdir(DIR);
	close(DIR);

	#@$files = `ls -a $directory`;
	
	#$self->logDebug("files: @$files");
	foreach my $file ( @$files )
	{
		chomp($file);
		next if $file =~ /^\.$/ or $file =~ /^\.\.$/;
		$file = "$directory/$file";
		#$self->logDebug("file", $file);

		#$file =~ s/\/+/\\/g if $^O =~ /^MSWin32$/;
		
	    if ( $file =~ /\/\.svn$/ and -d $file )
		{
			$self->logDebug("Removing directory", $file);
			my $recursive = 1;
			File::Remove::rm(\$recursive, $file);
			if ( -d $file )
			{
				$self->logDebug("!!! Could not remove directory", $file);
			}
		}
		elsif ( -d $file )
		{
			$self->svnClean( { workingdir => $file } );
		}	
	}
	
	return 1;	
}



method comment {
=head2

    SUBROUTINE     comment
    
    PURPOSE
    
		UNCOMMENT, COMMENT OR REMOVE COMMENTS IN DIFFERENT FILETYPES:
	
			PROCESS INPUTS TO DECIDE WHETHER ITS AN INPUT FILE OR DIRECTORY.
			
			PROCESS INPUTS TO DECIDE WHICH ACTIONS TO TAKE
        
    INPUT
    
		ARGS HASH CONTAINING THE FOLLOWING ITEMS:
		
			1. INPUT FILE /full/path/to/file
			
			2. OUTPUT FILE (MUST BE DIFFERENT TO INPUT FILE)
		
			3. ACTION (add|uncomment|comment|clean)
			
				uncomment	UNCOMMENT ONCE ALL TARGETED LINES
		
				comment		COMMENT ONCE ALL TARGETED LINES

				clean		REMOVE ALL TARGETED LINES

				add         ADD A DEBUG OUTPUT LINE AT THE START OF EVERY METHOD

			4. REGEX TO SELECT TARGET LINES
			
			5. COMMENT TEXT
			
			6. FILE TYPE (E.G., js, perl), WHICH IS USED TO SPECIFY 
        
				TARGETED LINES:
				
					TYPE        TARGET
					
					js          console.log(
			
					perl        $self->logDebug("  ");
    
    OUTPUT
    
        1) OUTPUT FILE WITH CHANGED LINES WITH RESPECT TO THE
        
            INPUT FILE (I.E., UNCOMMENTED, COMMENTED OR REMOVED LINES)
			
		** OR **
		
        2) OUTPUT DIRECTORY CONTAINING OUTPUT FILES AS DESCRIBED IN 1) ABOVE

=cut
	my $args		=	shift;

    my $inputfile   =   $args->{inputfile};
    my $outputfile  =   $args->{outputfile};
    my $inputdir   	=   $args->{inputdir};
    my $outputdir  	=   $args->{outputdir};
    my $type       	=   $args->{type};
    my $action      =   $args->{action};
    my $recursive   =   $args->{recursive};
    my $regex      	=   $args->{regex};
    my $comment     =   $args->{comment};
    my $function	=   $args->{function};
    my $namedepth	=   $args->{namedepth};
    my $nameseparator	=	$args->{nameseparator};
 	
	#### SET DEFAULTS IF NOT DEFINED
	$args->{regex} = "^.+?\\s*console\\.log\\(" if not defined $regex;
	$args->{function} = "^(\\s*)(\\S+)\\s*[:=]\\s*function\\s*\\(([^\\)]*)\\)\\s*({*)\$" if not defined $function;
	$args->{namedepth} = 3 if not defined $namedepth;
	$args->{nameseparator} = "." if not defined $nameseparator;
	$args->{comment} = "//" if not defined $comment;

	#### CHECK FOR REQUIRED inputfile
	die "Neither input file nor directory defined. Use option -h for help.\n"
		if not defined $inputfile and not defined $inputdir;
	die "Input file not defined. Use option -h for help.\n" if not defined $inputfile and defined $outputfile;
	die "Output file not defined. Use option -h for help.\n" if not defined $outputfile and not defined $outputdir;

	die "Action not defined. Use option -h for help.\n" if not defined $action;
	die "Type not defined. Use option -h for help.\n" if not defined $type;
	die "You must specify both 'regex' AND 'comment'. Use option -h for help.\n"
		if defined $regex xor defined $comment;
	die "File type not supported (js|perl)\n" if $type !~ /^(js|perl)$/i;
	die "Action not supported (add|uncomment|comment|clean)\n" if $action !~ /^(add|uncomment|comment|clean)$/i;
	
	if ( $type =~ /^perl$/i )
	{
		#### SET REGEX
		$args->{regex} = "^\\s+print\\s+\$" if not defined $regex;
		
		#### SET COMMENT
		$args->{comment} = "#" if not defined $comment;
		
		#### SET FUNCTION REGEX
		$args->{function} = "^\\s*sub\\s+(\\S+)";
		$args->{nameseparator} = "::";
	}

	#### PROCESS INPUT FILE IF DEFINED
	if ( defined $inputfile and defined $outputfile )
	{
		$self->logDebug("Doing single file...");
		#$self->logDebug("inputfile", $inputfile);
		
	
		return $self->comment_action($args);
	}
	
	#### OTHERWISE, PROCESS FILES IN INPUT FOLDER
	elsif ( defined $inputdir and defined $outputdir )
	{
		$self->logDebug("Doing directory", $inputdir);
		
		die "Can't create directory: $outputdir\n" if not -d $outputdir and not mkdir($outputdir);
	
		my $inputfiles = Util::files($inputdir);
		
		#### GET DIRECTORIES
		my $directories;
		@$directories = @$inputfiles;
		for ( my $i = 0; $i < @$directories; $i++ )
		{
			my $dir = "$inputdir/$$directories[$i]";
			
		
			if ( not -d $dir )
			{
				
				splice @$directories, $i, 1;
				$i--;
			}
		}
		$self->logObject("directories:", $directories);
		my $args_copy = Util::copy_hash($args);
		
		#### DO ALL SUBDIRECTORIES RECURSIVELY IF '--recursive' OPTION SPECIFIED
		if ( defined $recursive )
		{
			foreach my $directory ( @$directories )
			{
				$args_copy->{inputdir} = "$inputdir/$directory";
				$args_copy->{outputdir} = "$outputdir/$directory";
				$self->comment($args_copy);
			}
		}
		
		#### FILTER FILES
		$inputfiles = Util::by_suffix($inputfiles, "\.js") if $type =~ /^js$/i;
		$inputfiles = Util::by_suffix($inputfiles, "\.pl") if $type =~ /^perl$/i;

		$self->logDebug("Inputfiles: @$inputfiles");
		
		foreach my $inputfile ( @$inputfiles )
		{
			my $outputfile = "$outputdir/$inputfile";
			$inputfile = "$inputdir/$inputfile";

			#### SET NAME SPACE
			$inputfile =~ s/\\/\//g if $^O =~ /^MSWin32$/;
			$outputfile =~ s/\\/\//g if $^O =~ /^MSWin32$/;

			$args->{inputfile} = $inputfile;
			$args->{outputfile} = $outputfile;

			$self->comment_action($args);		
		}
		
		return $outputdir;
	}
}


method comment_action {
=head2

    SUBROUTINE     comment_action
    
    PURPOSE
    
        UNCOMMENT, COMMENT OR REMOVE COMMENTS IN DIFFERENT FILETYPES
        
    INPUT
    
		ARGS HASH CONTAINING THE FOLLOWING ITEMS:
		
			1. INPUT FILE /full/path/to/file
			
			2. OUTPUT FILE (MUST BE DIFFERENT TO INPUT FILE)
		
			3. ACTION (uncomment|comment|clean)
			
				uncomment   UNCOMMENT ONCE ALL TARGETED LINES
		
			4. REGEX TO SELECT LINES FOR (UN)COMMENTING
			
			5. COMMENT TEXT
    
    OUTPUT
    
        1. OUTPUT FILE WITH CHANGED LINES WITH RESPECT TO THE
        
            INPUT FILE (I.E., UNCOMMENTED, COMMENTED OR REMOVED LINES)

=cut
	my $args		=	shift;

    my $inputfile   =   $args->{inputfile};
    my $outputfile  =   $args->{outputfile};
    my $action      =   $args->{action};
    my $type       =   $args->{type};
    my $regex       =   $args->{regex};
    my $comment     =   $args->{comment};	
    my $function	=   $args->{function};
    my $namedepth	=   $args->{namedepth};
    my $nameseparator	=	$args->{nameseparator};

	#### USE TEMPORARY FILE FOR OUTPUT IF INPUT AND OUTPUT FILE ARE THE SAME
	my $overwrite = 0;
	if ( $inputfile eq $outputfile )
	{
		$overwrite = 1;
		$outputfile = $outputfile . "-temp";
	}
    $self->logDebug("inputfile", $inputfile);
    $self->logDebug("outputfile", $outputfile);
	

    #### OPEN FILES
    open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
    open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
    
    #### PERFORM ACTION ON EACH LINE
	my $curly = 1;
	my $functionname = '';
	my $arguments;
	my $space = '';
	my $namespace = '';
    while ( <FILE> )
    {
        use re 'eval';	# EVALUATE $pattern AS REGULAR EXPRESSION

		if ( $action =~ /^add$/i )
		{
			#### ASSUMES THAT THE CURLY BRACKET IS EITHER ON THE END OF THE LINE
			#### OR AT THE BEGINNING OF THE FOLLOWING LINE:
			####
			#### myFunction : function (arguments) {
			####
			#### OR
			####
			#### myFunction : function (arguments)
			#### {
			
			#### THE PREVIOUS LINE CONTAINED A FUNCTION DECLARATION 
			#### BUT NO OPENING CURLY BRACKET.
			
			#### LOOK FOR OPENING CURLY BRACKET IN THIS LINE.
			if ( not defined $curly or not $curly )
			{
				
				print OUTFILE $_;
			
				if ( $_ =~ /^\s*{/ )
				{
					if ( $type =~ /^js$/ )
					{
						print OUTFILE $space , qq{    console.log("$functionname\t$namespace.$functionname($arguments)");\n};
					}
					elsif ( $type =~ /^js$/ )
					{
						print OUTFILE $space , qq{    print("++++ $functionname\t$namespace.$functionname($arguments)")\n};
					}
					
					$curly = 1;
				}
				else
				{
					print OUTFILE $_;
				}
			}
			#### LINE WITH FUNCTION DECLARATION, CHECK IF CURLY ON THIS LINE
			else
			{
				if ( $_ =~ /$function/ )
				{
					
					$space = $1;
					$functionname = $2;
					$arguments = $3;
					$curly = $4;
					
					
					$space = '' if not defined $space;
					
					
					
					
					#### SET NAME SPACE
					$inputfile =~ s/\\/\//g if $^O =~ /^MSWin32$/;
					
					
					my $temp = $inputfile;
					my @matches;
					while ( $temp =~ s/\/([^\/]+)$// )
					{
						push @matches, $1;
					}
					$namespace = '';
					for ( my $i = $namedepth; $i > -1; $i-- )
					{
						if ( $i == $namedepth - 1 )
						{
							$matches[$i] =~ s/\.[^\.\D]+$//;
							$namespace = $matches[$i] 
						}
						else
						{
							$matches[$i] =~ s/\.[^\.]+$//;
							$namespace .= $nameseparator . $matches[$i] 
						}
					}
					
					#### PRINT THIS LINE
					print OUTFILE $_;
					
					#### PRINT COMMENT LINE IF CURLY WAS FOUND IN LINE
					#### (OTHERWISE, CHECK FOR CURLYL IN NEXT LINE AND PRINT
					#### AFTER THAT LINE)
					if ( $curly )
					{
						
						print OUTFILE $space . qq{    console.log("$namespace.$functionname\t$namespace.$functionname($arguments)");\n};
						$curly = 1;
					}
				}
				else
				{
					print OUTFILE $_;
				}
			}
		}
		else
		{
			if ( $_ =~ /$regex/ )
			{
				$_ = "$comment" . $_ if $action =~ /^comment$/i;
				$_ =~ s/^(\s*)$comment/$1/ if $action =~ /^uncomment$/i;
				next if $action =~ /^clean$/;
			}

	        print OUTFILE $_;
		}

        no re 'eval';# STOP EVALUATING AS REGULAR EXPRESSION
        
    }


	#### IF OVERWRITE, MOVE OUTPUT FILE TO INPUT FILE
	if ( $overwrite )
	{
		File::Copy::copy($inputfile,"$inputfile-safe");
		File::Copy::move($outputfile, $inputfile);
		File::Remove::remove("$inputfile-safe");
	}
	
	$self->logDebug("Finished outputfile", $inputfile);
		
	return $inputfile;
}








}