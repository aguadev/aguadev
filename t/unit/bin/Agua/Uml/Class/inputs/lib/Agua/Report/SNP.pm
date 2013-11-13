package Report::SNP;
=head2

	PACKAGE		Report::SNP
	
	PURPOSE
	
		FILTER SNPS BASED ON MULTIPLE CRITERIA AND
		
		OUTPUT DATA IN AGUA REPORT FORMAT

=cut

use strict;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/..";
use lib "$Bin/../external";

#### INHERIT FROM Report CLASS
require Exporter;
our @ISA = 	qw(Report); 
use Report;
use Common;

our $AUTOLOAD;

#### INTERNAL MODULES
use DBase::SQLite;
use Filter;
use Indexer;
use Util;

#### EXTERNAL MODULES
use File::Basename; # ALREADY IN PERL
use File::Copy;     # ALREADY IN PERL
use File::stat;     # ALREADY IN PERL
use Data::Dumper;   # ALREADY IN PERL
use Carp;           # ALREADY IN PERL

#### LOCALLY INSTALLED
use DBD::SQLite;

#### INSTALLED IN external
use JSON -support_by_pp;
use File::Remove;
use File::Copy::Recursive;

#### SET SLOTS
our @DATA = qw(
	USERNAME
	SESSIONID
	JSON
    MODE
    DBOBJECT
	CGI    
    CONF
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}

=head2

    SUBROUTINE     fileRows
    
    PURPOSE
        
		1. RETURN CONTENTS OF FILE GIVEN LINE OFFETS AND QUANTITY
		
=cut

sub fileRows {
    my $self        =   shift;
	my $filename	=	shift;
	my $start		=	shift;
	my $rows		=	shift;
	$self->logDebug("Report::SNP::fileRows(filename, start, rows)");
	$self->logDebug("filename", $filename);
	
	#### SET START IF NOT DEFINED
	$start = 0 if not defined $start;
	$self->logDebug("start", $start);

	#### SET ROWS IF NOT DEFINED OR EXCEEDS LINES
	my $number_lines = $self->numberLines();
	$rows = $number_lines - $start - 1 if not defined $rows;
	$rows = $number_lines - $start - 1 if $number_lines < $start + $rows;
	$self->logDebug("rows", $rows)  if defined $rows;

	#### GET OFFSETS AND SIZE FROM INDEX
	my $indexfile = $self->get_indexfile();
	$self->logDebug("indexfile", $indexfile);

	open(INDEX, $indexfile) or die "Report::SNP::fileRows     Can't open index file: $indexfile\n";
	my @indexlines = <INDEX>;
	close(INDEX);	
	$self->logDebug("\$#indexlines", $#indexlines);

	my ($offset, $size) = $indexlines[$start] =~ /^(\S+)\s+(\S+)/;
	$self->logDebug("offset", $offset);
	my $stop;
	#($stop) = $indexlines[$start + $rows] =~ /^(\S+)/;
	($stop) = $indexlines[$start + $rows] =~ /^(\S+)/ if $rows > 0;
	($stop) = $size if $rows == 0;
	$self->logDebug("stop", $stop);
	
	#### SET SIZE
	$size = $stop - $offset;
	
	my $lines;
	my $record;
	open(FILE, $filename) or die "Report::SNP::fileRows     Can't open file: $filename\n";
    seek(FILE, $offset, 0);
    read(FILE, $lines, $size);

	$self->logDebug("lines", $lines);

	return $lines;		
}


=head2

    SUBROUTINE     numberLines
    
    PURPOSE
        
		RETURN NUMBER OF LINES PRINTED IN FINAL LINE OF INDEX FILE
		
=cut

sub numberLines {
    my $self        =   shift;
	$self->logDebug("Report::SNP::numberLines(indexfile)");

	my $indexfile	=	$self->get_indexfile();
	$self->logDebug("indexfile", $indexfile);
	
	#### READ LAST LINE TO GET NUMBER OF LINES IN FILE
	$/ = "\n";

	my $number_lines;
	if ( $^O !~ /^MSWin32$/ )
	{
		open(REVERSE_FILE, "| /usr/bin/tac $indexfile");
		$number_lines = <REVERSE_FILE>;
		close REVERSE_FILE;
		$self->logDebug("number_lines", $number_lines);
	}
	else
	{
		open(FILE, $indexfile) or die "Filter::SNP::numberLines    Can't open indexfile: $indexfile\n";
		my @lines = <FILE>;
		close FILE;
		$number_lines = $lines[$#lines];
	}

	$self->logDebug("number_lines", $number_lines);

	return $number_lines;
}


=head2

    SUBROUTINE     indexFile
    
    PURPOSE
        
		1. INDEX LINE STARTS AND LENGTHS IN FILE
		
		2. RETURN TOTAL NUMBER OF LINES
		
=cut

sub indexFile {
	my $self		=	shift;
	my $inputfile	=	shift;
	$self->logDebug("Report::SNP::indexFile(inputfile)");
	$self->logDebug("inputfile", $inputfile);

	my $indexfile = $inputfile . ".index";
	my $indexer = Indexer->new(
		{
			inputfile => $inputfile,
			outputfile => $indexfile
		}		
	);
	my $number_lines = $indexer->run();
	$self->logDebug("number_lines", $number_lines);
	
	#### SET self->indexfile
	$self->{_indexfile} = $indexfile;
	
	return $number_lines;
}



=head2

    SUBROUTINE     downloadSNP
    
    PURPOSE
        
		1. RETURN CONTENTS OF FILE GIVEN LINE OFFETS AND QUANTITY
		
=cut

sub downloadSNP {
	my $self		=	shift;
	$self->logDebug("Report::SNP::downloadSNP()");
	
    use JSON;
    my $jsonParse = JSON->new();

    my $db 	=	$self->{_db};
    my $json 		=	$self->{_json};
    $self->logDebug("json", $json);
    $self->logDebug("\n");

	my $filename = $self->filename($json);
	#my $number_lines = $self->numberLines();
	
	
	#### TBC #### 
}

=head2

    SUBROUTINE     reportfile
    
    PURPOSE
        
        RETURN THE REPORT FILE PATH BASED ON USERNAME, PROJECT,
		
		WORKFLOW, AND REPORT NAME
		
=cut

sub reportfile {
	my $self		=	shift;
	my $json		=	shift;
    $self->logDebug("Report::SNP::reportfile(json)");
	
	#### RETURN ABSOLUTE PATH
	my $project = $json->{project};
	my $workflow = $json->{workflow};
	my $username = $json->{username};
	my $report = $json->{report};

    #### GET FILEROOT
    my $fileroot = $self->getFileroot($username);
    $self->logError("fileroot not defined. Exiting") and exit if not defined $fileroot;
	$self->logError("project not defined. Exiting") and exit if not defined $project;
	$self->logError("workflow not defined. Exiting") and exit if not defined $workflow;
	$self->logError("report not defined. Exiting") and exit if not defined $report;
	$self->logError("username not defined. Exiting") and exit if not defined $username;

	
    $self->logDebug("username", $username);
    $self->logDebug("fileroot", $fileroot);

	#### MAKE '.reports' DIRECTORY IF NOT EXISTS
	my $reportfolder = "$fileroot/$project/$workflow/.reports";
	File::Path::mkpath($reportfolder) if not -d $reportfolder;
	$self->logError("Can't create reportfolder: $reportfolder") and die if not -d $reportfolder;
	
	return "$reportfolder/$report.tsv";
}



=head2

    SUBROUTINE     filter
    
    PURPOSE
        
        1. FILTER A LIST OF SNPS BASED ON USER-DEFINED CRITERIA
        
            1. chromosome
            2. variant
            3. depth
            4. sense
            5. exonic
            6. dbSNP

        2. PRINT RESULTS TO FILE
			
			PRINT TOTAL NUMBER OF LINES IN LAST LINE OF FILE
			
			FOR USE BY fileChunks WHEN BROWSER REQUESTS FURTHER
			
			FILTER FILE LINES BEYOND THE INITIAL LINES OUTPUT TO
			
			JSON
        
		3. PRINT A JSON OBJECT CONTAINING:
		
			1. THE NUMBER OF SNPS PASSING EACH SUCCESSIVE FILTER

			2. THE FIRST 1,000 LINES OF RESULTS (ARRAY OF ARRAYS)

			   {"variantResult":"3986","depthResult":"326","chromosomeResult":"3986","outputResult":"[['CCDS15.1','chr1','161','161','T','C','25','12','1193074','1193074','m','CTG','CCG','Leucine','Proline','-','-','0','\\r'],['CCDS15.1','chr1','150','150','G','C','23','61','1193085','1193085','m','TGG','TGC','Tryptophan'...
		
	NOTES

		1. BROWSER CAN REQUEST FURTHER 1,000 LINE CHUNKS AS NEEDED
		
			USING THE fileChunk SUBROUTINE
		
		2. PRINT JUST THE TABLE HEADERS AND THEN AN ARRAY OF

			LINES TO REDUCE TRANSPORT:

			   outputResult : {
					headers: [ 'column1', 'column2', ... ],
					data: [
								[ 1,2,3,... ],
								[ ... ],
								...
					]
				}
	
		AT THE CLIENT END, CONVERT THIS INTO THE FOLLOWING FORMAT
		WHERE EACH HASH CONTAINS column1 => value1, ETC. PAIRS:

		   {
			   identifier :"id",
			   label : "id",
			   items : [ array of hashes ]
		   }
		   
=cut

sub filter {
	my $self		=	shift;
	my $inputfile	=	shift;
	my $outputfile	=	shift;
	my $filters		=	shift;
	my $columns		=	shift;
	my $values		=	shift;
	my $types		=	shift;
	$self->logDebug("Report::SNP::filter()");
	
	#### INSTANTIATE FILTER OBJECT AND RUN FILTER
	my $filter = Filter->new();
	my $counters = $filter->filterColumns(
		{
			inputfile 	=> $inputfile,
			outputfile 	=> $outputfile,
			columns 	=> $columns,
			values 		=> $values,
			types 		=> $types
		}
	);
	
	$self->logDebug("counters", $counters);
	
	#### GATHER FILTERED INFO AND LINES OF OUTPUT
	my $results;
	for ( my $i = 0; $i < @$counters; $i++ )
	{
		my $name = $$filters[$i] . "Results";
		$results->{$name} = $$counters[$i];
	}
	$self->logDebug("results", $results);
	
	#### INDEX REPORT FILE
	$self->indexFile($outputfile);
	
	my $max_rows = $self->numberLines();
	
	#### GET 
	my $start = 0;
	my $maxrows = 1000;
	my $rows = $self->fileRows($outputfile, $start, $maxrows);
	my $output_rows = [];
	my @array = split "\n", $rows;
	foreach my $line ( @array )
	{
		my @elements = split "\t", $line;
		push @$output_rows, \@elements;
	}
	$self->logDebug("output_rows", $output_rows);
	
	my $jsonParse = JSON->new();

	if ( not defined $output_rows )
	{
		print "{}";
		exit(0);
	}

	#### NEST JSON AS STRING WITHIN JSON
    my $dataJson = $jsonParse->encode($output_rows);
    $dataJson =~ s/"/'/g;
    $results->{outputResult} = $dataJson;

    my $report_json = $jsonParse->encode($results);
    print "$report_json\n";
}



=head2

    SUBROUTINE     filterQuery
    
    PURPOSE
        
        1. FILTER A LIST OF SNPS BASED ON USER-DEFINED CRITERIA
        
            1. chromosome
            2. variant
            3. depth
            4. sense
            5. exonic
            6. dbSNP

        2. OUTPUT THE NUMBER OF SNPS PASSING EACH SUCCESSIVE FILTER

        3. PRINT RESULTS TO FILE
        

	NOTES

		PRINT JUST THE TABLE HEADERS AND THEN AN ARRAY OF
		LINES TO REDUCE TRANSPORT:
		   outputResult : {
			   headers: [ 'column1', 'column2', ... ],
			   data: [
						   [ 1,2,3,... ],
						   [ ... ],
						   ...
			   ]
		   }
	
		AT THE CLIENT END, CONVERT THIS INTO THE FOLLOWING FORMAT
		WHERE EACH HASH CONTAINS column1 => value1, ETC. PAIRS:

		   {
			   identifier :"id",
			   label : "id",
			   items : [ array of hashes ]
		   }
		   

		454HCDiffs.txt FORMAT:
		
			name    chromosome      ccdsstart       ccdsstop        referencenucleotide     variantnucleotide       depth   variantfrequency        chromosomestart chromosomestop  sense   referencecodon    variantcodon    referenceaa     variantaa       strand  snp     score   strand
			CCDS3.1 chr1    770     770     C       T       3       100%    881093  881093  missense        GCC     GTC     Alanine Valine  -                       -
			CCDS3.1 chr1    780     780     G       A       3       100%    879243  879243  synonymous      CTG     CTA     Leucine Leucine -                       -
			CCDS3.1 chr1    790     790     C       G       3       100%    879233  879233  missense        CTG     GTG     Leucine Valine  -                       -

=cut

sub filterQuery {
	my $self		=	shift;
	$self->logDebug("Report::SNP::filterQuery()");
	
    my $jsonParse 	= JSON->new();
    my $json 		=	$self->{_json};

    $self->logDebug("json", $json);
    $self->logDebug("\n");

    #### GET ABSOLUTE PATH TO INPUT FILE
	my $inputfile = $json->{fileInput};
    my $username = $json->{username};
    my $fileroot = $self->getFileroot($username);
	$inputfile = "$fileroot/$inputfile";
	$inputfile =~ s/\//\\/g if $^O =~ /^MSWin32$/;
    $self->logDebug("username", $username);
    $self->logDebug("fileroot", $fileroot);

	#### GENERATE PATH TO OUTPUT REPORT FILE
	my $reportfile = $self->reportfile($json);
	$reportfile =~ s/\//\\/g if $^O =~ /^MSWin32$/;

	#### DEFAULT: SET COLUMNS BASED ON EXTENDED PILEUP CONTAINING SNP AND dbSNP ANNOTATION
    my $filters = ["chromosome", "variant", "depth", "effect", "exonic", "dbsnp"];
	my $columns = [1, 3, 7, 23, 16, 11];
	my $types	= ["eq", ">=", ">=", "eq", "eq", "*"];
	my $activetypes = [];
	my $values = [];
	#### REDUCE THE FILTERS TO THOSE CHECKED
	for ( my $i = 0; $i < @$filters; $i++ )
	{
		my $filter = $$filters[$i];
		my $checkbox = $filter . "Checkbox";
		if ( not defined $json->{$checkbox}
			or $json->{$checkbox} eq "false"
			or not $json->{$checkbox} )
		{
			$$activetypes[$i] = "";
		}
		else
		{
			$$activetypes[$i] = $$types[$i];
		}
	}
#	
	#### SET VALUES
	for ( my $i = 0; $i < @$filters; $i++ )
	{
		my $combo = $$filters[$i] . "Combo";
		$combo = $$filters[$i] . "Spinner" if $$filters[$i] eq "depth";
		$combo = $$filters[$i] . "Input" if $$filters[$i] eq "variant";
		$$values[$i] = $json->{$combo};
	}
	#### SAVE THE FILTER PARAMETERS TO THIS STAGE NUMBER IN THIS WORKFLOW
	$self->addStage($inputfile, $reportfile, $filters, $columns, $values, $activetypes);	

	$self->filter($inputfile, $reportfile, $filters, $columns, $values, $activetypes);	




#    my $output_rows;
#    for ( my $counter = 0; $counter < @$filter_order; $counter++ )
#    {
#        my $filter = $$filter_order[$counter];
#        $self->logDebug("Filter: **$filter**");
#
#        my $query = $queries->{$filter};
#        $self->logDebug("Query", $query);
#        $self->db()->do($query);
#
#        my $result_query = "SELECT COUNT(*) FROM $filter$random";
#        $self->logDebug("result_query", $result_query);
#        my $result = $self->db()->query($result_query);
#		$self->logDebug("result", $result);
#
#        #### GET OUTPUT RESULTS IN LAST FILTER
#        if ( $counter == @$filter_order - 1 and $result != 0 )
#        {
#            my $query = qq{SELECT * FROM $filter$random ORDER BY chromosome, chromosomestart, ccdsstart};
#			$self->logDebug("GETTING DATA OUTPUT");
#			$self->logDebug("$query");
#			$output_rows = $self->db()->querytwoDarray($query);
#			$self->logDebug("output rows: "  . scalar(@$output_rows) . "");
#        }        
#        
#		my $resultName = $filter . "Result";
#		$results->{$resultName} = $result;
#    }
#
#
#	if ( not defined $output_rows )
#	{
#		print "{}";
#		exit(0);
#	}
#
#    my $dataJson = $jsonParse->encode($output_rows);
#
#    $dataJson =~ s/"/'/g;
#    $results->{outputResult} = $dataJson;
#
#
#	#### DROP TABLES
#	foreach my $filter ( @$filter_order )
#	{
#		$query = qq{DROP TABLE $filter$random};
#		$self->logDebug("$query");
#		$self->db()->do($query);		
#	}
#	
#
#    
#	
#    #open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
#    #print OUTFILE $dataJson;
#    #close(OUTFILE);    
#    
#    my $report_json = $jsonParse->encode($results);
#    print "$report_json\n";
#    exit(0);
}


=head2

    SUBROUTINE     addStage
    
    PURPOSE
        
        UPDATE THIS STAGE OR ADD IT IF IT DOES NOT ALREADY EXIST IN THE WORKFLOW
	
=cut

sub addStage {
	

	
}



=head2

    SUBROUTINE     filterReport
    
    PURPOSE
        
        1. FILTER A LIST OF SNPS BASED ON USER-DEFINED CRITERIA
        
        2. OUTPUT THE NUMBER OF SNPS PASSING EACH SUCCESSIVE FILTER

        3. GENERATE A SET OF DATABASE TABLES, ONE FOR EACH FILTER LEVEL
            
        4. FILTERS:
            
            1. chromosome
            2. variant
            3. depth
            4. sense
            5. exonic
            6. dbSNP

	NOTES

		PRINT JUST THE TABLE HEADERS AND THEN AN ARRAY OF
		LINES TO REDUCE TRANSPORT:
		   outputResult : {
			   headers: [ 'column1', 'column2', ... ],
			   data: [
						   [ 1,2,3,... ],
						   [ ... ],
						   ...
			   ]
		   }
	
		AT THE CLIENT END, CONVERT THIS INTO THE FOLLOWING FORMAT
		WHERE EACH HASH CONTAINS column1 => value1, ETC. PAIRS:

		   {
			   identifier :"id",
			   label : "id",
			   items : [ array of hashes ]
		   }
		   

		454HCDiffs.txt FORMAT:
		
			name    chromosome      ccdsstart       ccdsstop        referencenucleotide     variantnucleotide       depth   variantfrequency        chromosomestart chromosomestop  sense   referencecodon    variantcodon    referenceaa     variantaa       strand  snp     score   strand
			CCDS3.1 chr1    770     770     C       T       3       100%    881093  881093  missense        GCC     GTC     Alanine Valine  -                       -
			CCDS3.1 chr1    780     780     G       A       3       100%    879243  879243  synonymous      CTG     CTA     Leucine Leucine -                       -
			CCDS3.1 chr1    790     790     C       G       3       100%    879233  879233  missense        CTG     GTG     Leucine Valine  -                       -

=cut

sub filterReport {
	my $self		=	shift;

	$self->logDebug("Report::SNP::filterReport()");
	
    use JSON;
    my $jsonParse = JSON->new();

    my $db 	=	$self->{_db};
    my $json 		=	$self->{_json};
    $self->logDebug("json", $json);
    $self->logDebug("\n");
	
    #### GET ABSOLUTE PATH
    my $username = $json->{username};
    my $fileroot = $self->getFileroot($username);
    $self->logDebug("username", $username);
    $self->logDebug("fileroot", $fileroot);

    my $diffsfile = $json->{fileInput};
    $diffsfile = "$fileroot/$diffsfile";
    if ( $^O =~ /^MSWin32$/ )
    {
        $diffsfile =~ s/\//\\/g;
    }
    $self->logDebug("Diffsfile", $diffsfile);

    my $dbfile = $diffsfile;
    $dbfile =~ s/\.txt$//;
    $dbfile .= ".dbl";    
    $self->logDebug("Dbfile", $dbfile);

    if ( not -f $diffsfile )	
    {
        $self->logError("username: $username Could not find diffs file: $diffsfile");
        exit 1;
    }
    

    #### GENERATE diffsxxx TABLE WHERE xxx IS A RANDOM NUMBER
	$self->logDebug("BEFORE Generate diffs database.");
    my ($random) = $self->diffs2db($diffsfile, $dbfile);
	$self->logDebug("AFTER Generate diffs database.");

	
	#### TO DO: USE 2-D HASH TO ALLOW DIFFERENT ORDERS OF FILTERS	
	#### PUSH INTO ARRAY BASED ON GIVEN ORDER
	#### INCLUDE REAL INPUT NAMES FOR SIMPLER CODE
    #my $inputnames = ["chromosomeCombo", "variantInput", "depthSpinner", "senseCombo", "exonicCombo", "dbsnpCombo"];



	#### SET ORDER OF FILTERS
    my $filter_order = ["chromosome", "variant", "depth", "sense", "exonic", "dbsnp"];
    my $filters = $json->{filters};


    $self->logDebug("filters", $filters);
    $self->logDebug("filters->{chromosome}", $filters->{chromosome});
	
	#### DELETE EXISTING TABLES
	foreach my $table ( @$filter_order )
	{
	    my $query = "DROP TABLE IF EXISTS $table$random";
	    $self->logDebug("$query");
		my $result = $self->db()->do($query);
		$self->logDebug("result", $result);
	}

    #### SET UP QUERIES FOR EACH FILTER
    #### "filterOrder": [ "chromosome", "variant", "depth", "sense", "exonic", "dbsnp" ]
    my $queries;
	
	#### CHROMOSOME
    $queries->{chromosome} = "CREATE TABLE chromosome$random AS SELECT * FROM diffs$random";
    if ( $json->{chromosomeCheckbox} eq "true" )  {   $queries->{chromosome} .= " WHERE chromosome = '$json->{chromosomeCombo}'"; }
	
	#### VARIANT FREQUENCY
    $queries->{variant} = "CREATE TABLE variant$random AS SELECT * FROM chromosome$random";
    if ( $json->{variantCheckbox} eq "true" )
	{
		my $variantInput = $json->{variantInput};
		$variantInput =~ s/%$//;
		$queries->{variant} .= " WHERE variantfrequency >= $variantInput";
	}
	
	#### READ DEPTH
    $queries->{depth} = "CREATE TABLE depth$random AS SELECT * FROM variant$random";    
    if ( $json->{depthCheckbox} eq "true")  {   $queries->{depth} .= " WHERE depth >= $json->{depthSpinner}";    }

	#### SENSE
    my $sense = lc($json->{senseCombo});
    $self->logDebug("Sense", $sense);
	$queries->{sense} = "CREATE TABLE sense$random AS SELECT * FROM depth$random";
    if ( $json->{senseCheckbox} eq "true" )  {   $queries->{sense} .= " WHERE sense = '$json->{senseCombo}'";    }
	
	#### EXONIC
    #### SINCE THIS IS EXOME DATA, DO NOTHING RIGHT NOW
    $queries->{exonic} = "CREATE TABLE exonic$random AS SELECT * FROM sense$random";
    #### LATER: ADD EXON/INTRON COLUMN INTO *headers-SNPs.txt FILE
    # if ( defined $json->{exonic} )  {   $queries->{exonic} .= " WHERE chr=$json->{exonic}";    }
    
	#### dbSNP
	#### DISABLED RIGHT NOW FOR DEBUGGING OF dbSNP CHECKER
    $queries->{dbsnp} = "CREATE TABLE dbsnp$random AS SELECT * FROM exonic$random";
    #if ( $filters->{dbsnp} eq "Only dbSNP" )  {   $queries->{dbsnp} .= " WHERE dbsnp != ''";    }
    #elsif ( $filters->{dbsnp} eq "Only non-dbSNP" )  {   $queries->{dbsnp} .= " WHERE dbsnp == ''";    }
	
    $self->logDebug("queries", $queries);
	
	
    #### PUT RESULTS HERE, TO BE RETURNED TO CLIENT AS JSON STRING
    my $results;

    my $query = "SELECT COUNT(*) FROM diffs$random";
    my $result = $self->db()->query($query);
    $results->{totalResult} = $result;

    #### DO SUCCESSIVE FILTERS
    my $project = $json->{project};
    my $workflow = $json->{workflow};
    my $report = $json->{report};
    my $outputfile = "$fileroot/$username/$project/$workflow/$report.json";
    if ( $^O =~ /^MSWin32$/ )
    {
        $outputfile =~ s/\//\\/g;
    }
    my $output_rows;
    for ( my $counter = 0; $counter < @$filter_order; $counter++ )
    {
        my $filter = $$filter_order[$counter];
        $self->logDebug("Filter: **$filter**");

        my $query = $queries->{$filter};
        $self->logDebug("Query", $query);
        $self->db()->do($query);

        my $result_query = "SELECT COUNT(*) FROM $filter$random";
        $self->logDebug("result_query", $result_query);
        my $result = $self->db()->query($result_query);
		$self->logDebug("result", $result);

        #### GET OUTPUT RESULTS IN LAST FILTER
        if ( $counter == @$filter_order - 1 and $result != 0 )
        {
            my $query = qq{SELECT * FROM $filter$random ORDER BY chromosome, chromosomestart, ccdsstart};
			$self->logDebug("GETTING DATA OUTPUT");
			$self->logDebug("$query");
			$output_rows = $self->db()->querytwoDarray($query);
			$self->logDebug("output rows: "  . scalar(@$output_rows) . "");
        }        
        
		my $resultName = $filter . "Result";
		$results->{$resultName} = $result;
    }

	if ( not defined $output_rows )
	{
		print "{}";
		exit(0);
	}

    my $dataJson = $jsonParse->encode($output_rows);

    $dataJson =~ s/"/'/g;
    $results->{outputResult} = $dataJson;


	#### DROP TABLES
	foreach my $filter ( @$filter_order )
	{
		$query = qq{DROP TABLE $filter$random};
		$self->logDebug("$query");
		$self->db()->do($query);		
	}
	

    
    #open(OUTFILE, ">$outputfile") or die "Can't open output file: $outputfile\n";
    #close(OUTFILE);    
    
    my $report_json = $jsonParse->encode($results);
    print "$report_json\n";
    exit(0);
}




=head2

    SUBROUTINE     diffs2db
    
    PURPOSE

		1. CREATE A NEW UNIQUE diffsxxx TABLE WHERE xxx IS A RANDOM NUMBER

		2. LOAD THE DATA INTO THE diffsxxx TABLE
		
		3. RETURN THE RANDOM NUMBER
		
		
	####### NB: COULD DO THIS BY CREATING RANDOMISED DATABASE NAMES
	####### BUT THIS WOULD REQUIRE THE AGUA USER TO HAVE SUFFICIENT
	####### PRIVILEGES TO CREATE AND DESTROY TABLES...

=cut

sub diffs2db {
    my $self        =   shift;
    my $diffsfile   =   shift;
    my $dbfile      =   shift;
    $self->logDebug("Report::SNP::diffs2db(diffsfile, dbfile)");
    $self->logDebug("Diffsfile", $diffsfile);
    $self->logDebug("Dbfile", $dbfile);
    
	my $dbtype = $self->{_conf}->{DBTYPE};
	$self->logDebug("dbtype", $dbtype);

	#### SET UP VARIABLES
	my $table;
	my $sqlfile = "sql/diffs.sql";  
	my $ignore = 1;		#### IGNORE THIS NUMBER OF INITIAL LINES	
	my $db;	

	$db = $self->{_db};
	$self->logDebug("db", $db);

	my $random = sprintf "%06d", rand(1000000);
	$self->logDebug("random number", $random);



	#### SET RANDOM NUMBER TO BE ADDED AT THE END OF TABLE NAMES
	$table = "diffs" . $random;
	$self->logDebug("table", $table);

	my $counter = 0;
	while ( $self->db()->isTable($table, $sqlfile) )
	{
		$self->logDebug("table already exists", $table);
		
		$counter++;
		$random = sprintf "%06d", rand(1000000);
		$table = "diffs" . $random;
		$self->logDebug("table", $table);
		
		last if $counter == 3;
	}

$random = 244079;
$table = "diffs" . $random;


	$self->logDebug("table", $table);

	#### CONVERT DIFFS INPUT FILE PATH TO LINUX FORMAT FOR MYSQL
	$self->logDebug("BEFORE diffsfile", $diffsfile);
	$diffsfile =~ s/\\/\//g;
	$self->logDebug("AFTER diffsfile", $diffsfile);
	
	#### GET 'CREATE TABLE ...' SQL
	my $sql = $self->createSQL($sqlfile, $table);
	
	#### CREATE THE TABLE. THIS WILL RETURN 0 IF QUERY IS MALFORMED, 1 OTHERWISE.
	$self->logDebug("create table sql", $sql);
	my $success = $self->db()->do($sql);
	$self->logDebug("create table success", $success);
	$self->logError("Could not create table $table using sql query: $sql") and exit if not $success;


	#### FOR DEBUGGING:
	#### DELETE FROM TABLE IN CASE DATA EXISTS ALREADY
	my $query = qq{DELETE FROM $table};
	my $delete = $self->db()->do($query);
	$self->logDebug("table delete", $delete);

	#### GET PRELOAD COUNT FOR DEBUGGING
	$query = qq{SELECT COUNT(*) FROM $table};
	my $count = $self->db()->query($query);
	$self->logDebug("BEFORE LOAD table count", $count);

	#### CREATE CLEANED-UP TSV FILE
	my $tsvfile = $self->diffs2tsv($diffsfile, $ignore);
	$self->logDebug("printed tsvfile", $tsvfile);
	
	#### LOAD DATA INTO TABLE WITHOUT DUPLICATE LINES
	#### AND SKIPPING THE HEADER LINES
	$query = qq{LOAD DATA LOCAL INFILE '$tsvfile' INTO TABLE $table};
	$self->logDebug("$query");
	
	$success = $self->db()->do($query);
	$self->logDebug("success", $success);

	$count = $self->db()->query("SELECT COUNT(*) FROM $table");
	$self->logDebug("AFTER LOAD table count", $count);	;

    return $random;
}


=head2

	SUBROUTINE		createSQL
	
	PURPOSE
	
		READ AN SQLFILE AND INSERT NEW TABLE NAME INTO CREATE STATEMENT
		
=cut

sub createSQL {
	my $self		=	shift;
	$self->logDebug("(sqlfile, table)");
	my $sqlfile		=	shift;
	my $table		=	shift;
	
	#### GET SQL FOR TABLE
	open(FILE, $sqlfile) or die "Can't open sqlfile $sqlfile: $!\n";
	my $temp = $/;
	undef $/;
	my $sql = <FILE>;
	close(FILE);
	$/ = $temp;
	$sql =~ s/\s*$/;/g;

	#### INSERT NEW RANDOMISED TABLE NAME
	if ( $sql =~ /^\s*CREATE TABLE IF NOT EXISTS/msi )
	{
		$sql =~ s/^\s*CREATE TABLE IF NOT EXISTS \S+/CREATE TABLE IF NOT EXISTS $table/;
	}
	else
	{
		$sql =~ s/^\s*CREATE TABLE \S+/CREATE TABLE $table/;
	}
	
	$self->logDebug("sql", $sql);
	return $sql;
}


=head2

	SUBROUTINE		diffs2tsv
	
	PURPOSE
	
		CONVERT A 454Diffs.txt FILE TO A .TSV FILE
		
=cut

sub diffs2tsv {
	my $self		=	shift;
	$self->logDebug("(sqlfile, table)");
	my $diffsfile	=	shift;
	my $ignore 		= 	shift;
	
	#### CREATE .TSV FILE
	my $tsvfile = $diffsfile;
	$tsvfile =~ s/\.txt//;
	$tsvfile .= ".tsv";
	$tsvfile =~ s/\\/\//g;
	$self->logDebug("tsvfile", $tsvfile);
	
	#### CONVERT THE DIFFS INTO TSV DATA WITH THE RIGHT NUMBER OF COLUMNS
	my $number_columns = 19;
	open(DIFFSFILE, $diffsfile) or die "Can't open diffs file: $diffsfile\n";
	open(TSVFILE, ">$tsvfile") or die "Can't open output .tsv file: $tsvfile\n";
	$/ = "\n";
	
	#### REMOVE THE COLUMN HEADINGS LINE OF THE DIFFS FILE
	for ( my $i = 0; $i < $ignore; $i++)	{	<DIFFSFILE>;	}

	#### CONVERT TO TSV FORMAT
	while ( <DIFFSFILE> )
	{
		next if ( $_ =~ /^\s*$/ );
		
		my @elements = split " ", $_;
		
		#### REMOVE '%' FROM VARIANT FREQUENCY COLUMN
		$elements[7] =~ s/%$//;
		
		print TSVFILE join "\t", @elements;
		print TSVFILE "\t" x ($number_columns - ($#elements + 1));
		print TSVFILE "\n";
	}
	close(DIFFSFILE) or die "Couldn't close diffs file: $diffsfile\n";
	close(TSVFILE) or die "Couldn't close .tsv file: $tsvfile\n";
	
	return $tsvfile;
}



####################################################################
####################################################################
########				HOUSEKEEPING METHODS
####################################################################
####################################################################




=head2

	SUBROUTINE		new
	
	PURPOSE
	
		CREATE THE NEW self OBJECT AND INITIALISE IT, FIRST WITH DEFAULT 
		
		ARGUMENTS, THEN WITH PROVIDED ARGUMENTS

=cut

sub new
{
 	my $class 		=	shift;
	my $arguments 	=	shift;
   
	my $self = {};
    bless $self, $class;

	#### CHECK CONF->FILEROOT IS PRESENT AND NOT EMPTY
	if ( not defined $arguments->{CONF} or not $arguments->{CONF} )
	{
		$self->logError("CONF is not defined");
        exit;
    }
	else
	{
		$self->{_conf} = $arguments->{CONF};
	}
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);
    return $self;
}


=head2

	SUBROUTINE		initialise
	
	PURPOSE

		INITIALISE THE self OBJECT:
			
			1. LOAD THE DATABASE, USER AND PASSWORD FROM THE ARGUMENTS
			
			2. FILL OUT %VARIABLES% IN XML AND LOAD XML
			
			3. LOAD THE ARGUMENTS

=cut

sub initialise
{
    my $self		=	shift;
	my $arguments	=	shift;

    ##### SET DEFAULT 'ROOT' USER
    #$self->value('root', $ROOT);
    #
    #### VALIDATE USER-PROVIDED ARGUMENTS
	($arguments) = $self->validate_arguments($arguments, $DATAHASH);	
    
	#### LOAD THE USER-PROVIDED ARGUMENTS
	foreach my $key ( keys %$arguments )
	{		
		#### LOAD THE KEY-VALUE PAIR
		$self->value($key, $arguments->{$key});
	}
}


=head2

	SUBROUTINE		value
	
	PURPOSE

		SET A PARAMETER OF THE self OBJECT TO A GIVEN value

    INPUT
    
        1. parameter TO BE SET
		
		2. value TO BE SET TO
    
    OUTPUT
    
        1. THE SET parameter INSIDE THE self OBJECT
		
=cut

sub value
{
    my $self		=	shift;
	my $parameter	=	shift;
	my $value		=	shift;

	$parameter = lc($parameter);
    if ( defined $value)
	{	
		$self->{"_$parameter"} = $value;
	}
}

=head2

	SUBROUTINE		validate_arguments

	PURPOSE
	
		VALIDATE USER-INPUT ARGUMENTS BASED ON
		
		THE HARD-CODED LIST OF VALID ARGUMENTS
		
		IN THE data ARRAY
=cut

sub validate_arguments
{
	my $self		=	shift;
	my $arguments	=	shift;
	my $DATAHASH	=	shift;
	
	my $hash;
	foreach my $argument ( keys %$arguments )
	{
		if ( $self->is_valid($argument, $DATAHASH) )
		{
			$hash->{$argument} = $arguments->{$argument};
		}
		else
		{
			warn "'$argument' is not a known parameter\n";
		}
	}
	
	return $hash;
}


=head2

	SUBROUTINE		is_valid

	PURPOSE
	
		VERIFY THAT AN ARGUMENT IS AMONGST THE LIST OF
		
		ELEMENTS IN THE GLOBAL '$DATAHASH' HASH REF
		
=cut

sub is_valid
{
	my $self		=	shift;
	my $argument	=	shift;
	my $DATAHASH	=	shift;
	
	#### REMOVE LEADING UNDERLINE, IF PRESENT
	$argument =~ s/^_//;
	
	#### CHECK IF ARGUMENT FOUND IN '$DATAHASH'
	if ( exists $DATAHASH->{lc($argument)} )
	{
		return 1;
	}
	
	return 0;
}





=head2

	SUBROUTINE		AUTOLOAD

	PURPOSE
	
		AUTOMATICALLY DO 'set_' OR 'get_' FUNCTIONS IF THE
		
		SUBROUTINES ARE NOT DEFINED.

=cut

sub AUTOLOAD {
    my ($self, $newvalue) = @_;
    my ($operation, $attribute) = ($AUTOLOAD =~ /(get|set)(_\w+)$/);
    # Is this a legal method name?
    unless($operation && $attribute) {
        croak "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
    }
    unless( exists $self->{$attribute} or $self->is_valid($attribute) )
	{
        #croak "No such attribute '$attribute' exists in the class ", ref($self);
		return;
    }

    # Turn off strict references to enable "magic" AUTOLOAD speedup
    no strict 'refs';

    # AUTOLOAD accessors
    if($operation eq 'get') {
        # define subroutine
        *{$AUTOLOAD} = sub { shift->{$attribute} };

    # AUTOLOAD mutators
    }elsif($operation eq 'set') {
        # define subroutine4
		
        *{$AUTOLOAD} = sub { shift->{$attribute} = shift; };

        # set the new attribute value
        $self->{$attribute} = $newvalue;
    }

    # Turn strict references back on
    use strict 'refs';

    # return the attribute value
    return $self->{$attribute};
}


# When an object is no longer being used, this will be automatically called
# and will adjust the count of existing objects
sub DESTROY {
    my($self) = @_;

	#if ( defined $self->{_databasehandle} )
	#{
	#	my $dbh =  $self->{_databasehandle};
	#	$dbh->disconnect();
	#}

#    my($self) = @_;
}



1;


