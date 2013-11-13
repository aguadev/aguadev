package Indexer;
use strict;
use warnings;
use Carp;

require Exporter;
our @EXPORT_OK = qw();
our $AUTOLOAD;

use vars qw($VERSION);
$VERSION = 0.1;

#### INTERNAL MODULES
#use Database;

#### EXTERNAL MODULES
#use DBI;
#use DBD::mysql;
#use Data::Dumper;

#### DEFAULT PARAMETERS
our $TYPE = "read";

=head2

	SUBROUTINE		new

	PURPOSE
	
		CREATE A NEW Indexer OBJECT
		
	INPUTS
	
        1. FULL PATH TO INPUT FILE
		
		2. [optional] TYPE OF INPUT FILE (USED TO DETERMINE
		
			AUTOMATICALLY WHICH REGEX TO USE TO GET ROW ID).
		
			OR, REGEX TO PARSE ROW ID FROM ROW.
		
	OUTPUTS
	
		1. A .TSV FILE CONFORMING TO THE indices TABLE
	
	NOTES

        EXTEND THIS TO FASTA FILES FROM DIFFERENT EXTERNAL DATABASES
        
        AND .ACE FILES, ETC.
    
	EXAMPLES
	
		#### INDEX .QUAL FILE IF NOT INDEXED
		my $acefile_index = Indexer->new(
			{
				"inputfile" => $acefile,
				"regex" => "Contig(\\d+)",
				"divider" => "\nCO",
				"type" => "contig"
			}
		);

		my $qualfile_index = Indexer->new(
			{
				"inputfile" => "/Users/young/FUNNYBASE/pipeline/$database/edit_dir/$database.fasta.qual"
			}
		);
	
		my $swissprot_index = Indexer->new(
			{
				"inputfile" => "/common/data/swissprot",
				"type" => "swissprot"
			}
		);

=cut


sub new
{
	my $self 		=	shift;
	my $arguments 	=	shift;
	
	$self = bless {},$self unless ref $self;

	my @data = qw(
		INPUTFILE
		OUTPUTFILE
		DATABASE
        USER
        PASSWORD
		REGEX
		CALLBACK
		DIVIDER
		TYPE
		DOT
		NUMERIC
	);

	#### SET DEFAULT RECORD TYPE
	$self->value("type", $TYPE);

	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments, \@data);

	return $self;
}


=head2

	SUBROUTINE		initialise
	
	PURPOSE

		INITIALISE THE Indexer OBJECT

=cut

sub initialise
{
    my $self		=	shift;
	my $arguments	=	shift;
	my $data		=	shift;
	
    #### SET DEFAULT RECORD DIVIDER
    $self->{_divider} = "\n>";           # DEFAULT FASTA SEPARATOR

    #### VALIDATE USER-PROVIDED ARGUMENTS
    ($arguments) = $self->validate_arguments($arguments, $data);	
    
    #### PROCESS USER-PROVIDED ARGUMENTS
	foreach my $key ( keys %$arguments )
	{
		$self->value($key, $arguments->{$key});
	}
    
    #### SET INDEX FILE
	if ( not defined $self->{_outputfile} )
	{
	    $self->{_outputfile} = $self->{_inputfile} . ".index";
	}

    #### SET INPUT AND OUTPUT FILEHANDLES
    $self->inputFilehandle();
    
	#### SET _regex AUTOMATICALLY BASED ON type
	$self->setRegex();
}


=head2

	SUBROUTINE		setRegex
	
	PURPOSE
	
		SET ID REGEX AUTOMATICALLY DEPENDING ON self->type

=cut

sub setRegex
{
	my $self		=	shift;
	
	my $type = $self->{_type};
	return if not defined $type;
	

	#### >gi|57043872|ref|XP_544419.1| PREDICTED: similar to seven in absentia homolog 1 isoform b isoform 1 [Canis familiaris]
	$self->{_regex} = '^>*gi\|[^\|]+\|ref\|([^\|\.]+)' if $type eq "refseq";
		
	# DEFAULT FASTA ID REGEX
	$self->{_regex} = "^>*([^\\.\\s]+)" if $type eq "fasta";
}



=head2

	SUBROUTINE		inputFilehandle
	
	PURPOSE

		SET INPUT FILEHANDLES (MAY BE NORMAL OR GZIPPED FILE)

=cut

sub inputFilehandle
{
    my $self		=	shift;
    
	my $inputfile	=	$self->{_inputfile};
	my $input_filehandle;

	#### OPEN FILE AND SET RECORD SEPARATOR
	if( $inputfile =~ /\.gz$/ )
	{
		my $divider = $self->{_divider};
		$/ = $divider if defined $divider;
		$self->logDebug("divider", $divider);

		$self->logDebug("Opening as .gz file....\n");
		my $pipe_command = "gunzip -c $inputfile |";
		
		open($input_filehandle, $pipe_command);
		$self->logDebug("first line:\n");
		<FILE>;
		$/ = "\n";
		print <FILE>;

		my $record;
		$/ = "\n";
		my $counter = 0;
		while ( defined ($record = <FILE>) and defined $record )
		{    
			$self->logDebug("first line:\n");
			print <FILE>;
			return;
		}
	}
	else
	{
		open($input_filehandle, $inputfile) or die "Indexer::inputFilehandle: Can't open input file: $inputfile\n";
	}
    
	$self->{_input_filehandle} = $input_filehandle;
}


=head2

	SUBROUTINE		run
	
	PURPOSE
	
		SYNONYM FOR buildIndex
		
=cut

sub run
{
    my $self            =   shift;
	return $self->buildIndex(@_);
}


=head2

	SUBROUTINE		buildIndex
	
	PURPOSE
	
		CREATE A .TSV FILE:
        
        1. CONFORMS TO indices TABLE FORMAT:
		
            CREATE TABLE IF NOT EXISTS indices (
    
                id          varchar(30) NOT NULL,
                location    int(16),
                offset      int(16),    # SIZE OF RECORD IN BYTES
                
                PRIMARY KEY  (id)
            )
        
        2. TABLE NAME IS "indices" +  FILENAME
        
            E.G.: indices_supercraw0_fasta

=cut

sub buildIndex
{
    my $self            =   shift;
    $self->logDebug("Indexer::buildIndex    Indexer::buildIndex()");

	my $numeric				=	$self->{_numeric};
    my $input_filehandle    =   $self->{_input_filehandle};
    my $outputfile    		=   $self->{_outputfile};
    my $database            =   $self->{_database};
    my $regex            	=   $self->{_regex};
    my $divider             =   $self->{_divider};
    my $dot             	=   $self->{_dot};
	my $callback 			= 	$self->{_callback};

	$self->logDebug("Indexer::buildIndex    numeric", $numeric) if defined $numeric;
	$self->logDebug("Indexer::buildIndex    divider", $divider);
    $self->logDebug("Indexer::buildIndex    ID REGEX", $regex) if defined $regex;

    my $outfh;
    if ( not open($outfh, ">$outputfile") )	{	croak "Indexer::inputFilehandle: Can't open output index file: $outputfile\n";	}

    #### SET OFFSETS
    my $previous_offset = 0;
    my $offset;

    my $counter = 0;
    $/ = $divider;
    while ( <$input_filehandle> )
    {
		$_ =~ s/^$divider// if $counter == 0;
		
		$self->logDebug("$counter") if defined $dot and $counter % $dot == 0;
		chomp($_);
		$self->logDebug("Indexer::buildIndex    line", $_);

		#### GET THE CURRENT POSITION IN BYTES AND THE SIZE OF THE LINE
        $offset = tell($input_filehandle);  
        my $size = $offset - $previous_offset;

		if ( defined $regex )
		{
			my $id;
			if ( defined $callback )
			{
				$id = &$callback($_); 
			}
			else
			{
				use re 'eval';		# EVALUATE $pattern AS REGULAR EXPRESSION
				($id) = $_ =~ /$regex/ms;
				no re 'eval';		# STOP EVALUATING AS REGULAR EXPRESSION
			}

			#### EXIT IF ID NOT DEFINED
			$self->Error("Can't get ID for line: $_") if not defined $id;
			$self->logDebug("Indexer::buildIndex    Id", $id);

			print $outfh "$id\t$previous_offset\t$size\n";
		}
		else
		{
			print $outfh "$previous_offset\t$size\n";
		}
        $previous_offset = $offset;
		
		$counter++;
    }

	#### PRINT NUMBER OF LINES AT END OF INDEX FILE
	print $outfh $counter;
	
	#### CLOSE FILE
    close($outfh);
    
    $self->logDebug("Indexer::buildIndex    outputfile printed:\n\n$outputfile\n");
	
	return $counter;
}


=head2

	SUBROUTINE		seekRecord
	
	PURPOSE
	
		SEEK AN INDEXED RECORD IN A FILE

    INPUT
    
        1. RECORD ID
        
    OUTPUT
    
        FASTA-FORMAT RECORD

=cut

sub seekRecord
{
    my $self    =   shift;
    my $id      =   shift;
    
    #### DELETE PREVIOUS BLAST DATA FOR THIS TARGET
    my ($location, $size) = $self->location_size($id);
    $self->logDebug("Location", $location);
    $self->logDebug("Size", $size);
	
    if ( not defined $location )    {   $self->logDebug("ID not found: $id ");   return;   }
    
    my $input_filehandle = $self->{_input_filehandle};

    my $record;
    seek($input_filehandle, $location, 0);
    read($input_filehandle, $record, $size);

    return $record;
}


=head2

	SUBROUTINE		record
	
	PURPOSE
	
		RETURN AN INDEXED FASTA RECORD

    INPUT
    
        1. RECORD ID
        
    OUTPUT
    
        FASTA-FORMAT RECORD

=cut

sub location_size
{
    my $self        =   shift;
    my $id          =   shift;

	$self->logDebug("++++ Indexer.location_size()");
	$self->logDebug("ID", $id);

    #### MAKE SURE INPUT ID IS IN CORRECT FORMAT
	my $type = $self->{_type};
	$self->logDebug("Record type", $type);
	if ( $type eq "read" )
	{
		$id =~ s/_/-/g;
		$id =~ s/\..+$//;
		my ($experiment, $plate, $well) = $id =~ /^([^\-]+)\-([^\-]+)\-([^\-]+)/;
		if ( not defined $experiment or not defined $plate or not defined $well )
		{
			$self->logDebug("Id done not have correct format ([^\-]+)\-([^\-]+)\-([^\-]+): $id \n");
			
			return;
		}
		$experiment = sprintf "%.3d", $experiment;
		if ( length($plate) < 3)    {   $plate = sprintf "%.3d", $plate;   }
		$well = uc($well);
		$id = "$experiment-$plate-$well";
	}
	
	
    my $dbh = $self->{_databasehandle};
	my $location;
	my $size;
	if ( defined $dbh )
	{
		my $table = $self->{_table};
		
		my $query = qq{SELECT location, offset
		FROM $table
		WHERE id='$id'};
		$self->logDebug("$query");
		
		my $hash = Database::simple_queryhash($dbh, $query);
		if  (not defined $hash )    {   return; } 
		$location = $hash->{location};
		$size = $hash->{offset};
		
		$self->logDebug("Location", $location);
		$self->logDebug("Size", $size);
	}
	else
	{
		if ( not defined $self->{_indexhash} )
		{
			$self->load_indexhash();
		}
		if ( defined $self->{_indexhash} )
		{
			$location = $self->{_indexhash}->{$id}->{location};
			$size = $self->{_indexhash}->{$id}->{size};
		}
	}
    
    
    
    return ($location, $size);
}


=head2

	SUBROUTINE		load_indexhash
	
	PURPOSE

		LOAD THE INDEX FILE INTO A HASH AND STORE AS _indexhash
		
=cut

sub load_indexhash
{
    my $self		=	shift;

	my $outputfile = $self->{_outputfile};
	$self->logDebug("outputfile", $outputfile);

	my $indexhash;
	open(OUTPUTFILE, $outputfile) or die "Can't open index file: $outputfile: $@\n";
	while ( <OUTPUTFILE> )
	{
		next if $_ =~ /^\s*$/;
		$_ =~ /^(\S+)\s+(\S+)\s+(\S+)/;
		$indexhash->{$1}->{location} = $2;
		$indexhash->{$1}->{size} = $3;
	}
	
	$self->{_indexhash} = $indexhash;
}



=head2

	SUBROUTINE		value
	
	PURPOSE

		SET A PARAMETER OF THE BioSVG OBJECT TO A GIVEN value
		(E.G., IN new FROM IN THE ORDERED ARRAY OF ARGUMENTS)
		OR SET TO '' IF THE value IS UNDEFINED

    INPUT
    
        1. parameter TO BE SET
		
		2. value TO BE SET TO
    
    OUTPUT
    
        1. THE SET parameter INSIDE THE BioSVG OBJECT
		
=cut




sub value
{
#	$self->logDebug("++++ Indexer::value()");
	
    my $self		=	shift;
	my $parameter	=	shift;
	my $value		=	shift;

	$parameter = lc($parameter);
    if ( not defined $value)	{	$value = '';	}
	$self->{"_$parameter"} = $value;
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
	my $data		=	shift;

	my $datahash;
	foreach my $key ( @$data )	{	$datahash->{lc($key)} = 1;	}

	my $hash;
	foreach my $argument ( keys %$arguments )
	{
		if ( exists $datahash->{lc($argument)} )
		{
			$hash->{$argument} = $arguments->{$argument};
		}
		else
		{
			
#			warn "'$argument' is not a known parameter of the BioSVG Object\n";
		}
	}

	return $hash;
}


# This takes the place of such accessor definitions as:
#  sub get_attribute { ... }
# and of such mutator definitions as:
#  sub set_attribute { ... }
sub AUTOLOAD
{
    my ($self, $newvalue) = @_;

    my ($operation, $attribute) = ($AUTOLOAD =~ /(get|set)(_\w+)$/);

    # Is this a legal method name?
    unless($operation && $attribute) {
        croak "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
    }
    unless(exists $self->{$attribute}) {
        croak "No such attribute '$attribute' exists in the class ", ref($self);
    }

    # Turn off strict references to enable "magic" AUTOLOAD speedup
    no strict 'refs';

    # AUTOLOAD accessors
    if($operation eq 'get') 
    {
        # define subroutine
        *{$AUTOLOAD} = sub { shift->{$attribute} };

    # AUTOLOAD mutators
    }
    elsif($operation eq 'set') 
    {
        # define subroutine
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
sub DESTROY
{
    my($self) = @_;
}

