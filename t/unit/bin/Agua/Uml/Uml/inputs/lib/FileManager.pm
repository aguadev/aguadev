package FileManager;
=head2

		PACKAGE		FileManager
		
		PURPOSE
		
			THE FileManager OBJECT PERFORMS SETUID AND FILE
			
			MANIPULATION TASKS
			
=cut

use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw();
our $AUTOLOAD;

#### INTERNAL MODULES

#### EXTERNAL MODULES
use File::Path;
use File::Remove;
use File::stat;
use Data::Dumper;
use JSON;
{
	use Data::Dumper;	
}

#### FLUSH BUFFER
#$| = 1;

#### SET SLOTS
our @DATA = qw(
	JSON
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}


=head2

	SUBROUTINE		filePeek
	
	PURPOSE
	
		PRINT LINES OF A FILE FROM A PARTICULAR OFFSET
	
=cut

sub filePeek
{
	my $self		=	shift;

	my $filepath = $self->{_json}->{filepath};
	my $offset = $self->{_json}->{offset};
	my $lines = $self->{_json}->{lines};
	my $bytes = $self->{_json}->{bytes};

	return "{ error: 'FileManager::filePeek    offset not defined' }" and exit if not defined $offset;
	return "{ error: 'FileManager::filePeek    filepath not defined' }" and exit if not defined $filepath;
	return "{ error: 'FileManager::filePeek    lines and bytes not defined' }" and exit if not defined $lines and not defined $bytes;

	#### EXIT IF FILEPATH NOT FOUND
	if ( not -f $filepath and not -d $filepath )
	{
		return "{  error: 'FileManager::filepeek    file or directory not found: $filepath' }";
	}


	#### GET LINES 
	if ( defined $lines and defined $offset )
	{
		my $peek = `tail +$offset $filepath | head -n$lines`;
		if ( not defined $peek or not $peek )
		{
			return "{  error: 'FileManager::filepeek    peek at offset $offset and lines $lines not defined for filepath: $filepath' }";
		}
		
		$peek =~ s/\n/\\n/g;
		$peek =~ s/'/\\'/;
		return $peek;
	}

	
	#### GET BYTES
	elsif ( defined $bytes and defined $offset )
	{
		my $peek = '';
		$peek =~ s/'/\\'/;
		open(FILE, $filepath) or $self->logError("Could not find file: $filepath") and exit;
		seek FILE, $offset, 0;
		read(FILE, $peek, $bytes);
		close(FILE);

		if ( not defined $peek or not $peek )
		{
			return "{  error: 'FileManager::filepeek    peek at offset $offset and bytes $bytes not defined for filepath: $filepath' }";
		}

		print "{ peek: '$peek' }";
		return;
	}
}




=head2

	SUBROUTINE		checkFiles
	
	PURPOSE
	
		PRINT FILE INFO FOR ONE OR MORE FILES OR DIRECTORIES
		
	INPUTS
	
		AN ARRAY OF FILE HASHES
		[
			{ filehash1 }, 
			{ filehash2 },
			...
		]
		
	OUTPUTS
	
		AN ARRAY (SAME ORDER AS INPUTS) OF FILE INFORMATION HASHES
		[
			{ fileinfo1 },
			{ fileinfo2 },
			...
		]		
=cut

sub checkFiles
{
	my $self		=	shift;
	$self->logDebug("FileManager::checkFiles()");

    ### VALIDATE    
    $self->logError("User session not validated") and exit unless $self->validate();

	#### GET ARRAY OF FILE HASHES
	my $files = $self->{_json}->{files};
	
	#### GET FILE INFO FOR EACH FILE/DIRECTORY
	my $fileinfos = [];
	foreach my $file ( @$files )
	{
		$self->logObject("file", $file);
		my $filepath = $file->{value};
		
		push@$fileinfos, $self->_checkFile($filepath);	
	}
	
	#### PRINT FILE INFO	
	$self->printJSON($fileinfos);
	return;
}


=head2

	SUBROUTINE		checkFile
	
	PURPOSE
	
		PRINT FILE INFO FOR A FILE OR DIRECTORY
	
=cut

sub checkFile
{
	my $self		=	shift;

	$self->logDebug("FileManager::checkFile()");
    #### GET JSON
    my $json  =	$self->{_json};

	my $fileinfo = $self->_checkFile();
	$self->logObject("fileinfo", $fileinfo);

	$self->printJSON($fileinfo);
	return;
}

=head2

	SUBROUTINE		_checkFile
	
	PURPOSE
	
		RETURN A HASH CONTAINING FILE INFORMATION (EXISTS, SIZE,
		
		DATE MODIFIED, ETC.) FOR ONE OR MORE FILES AND DIRECTORIES
	
	INPUTS
	
		A FILE PATH STRING
		
	OUTPUTS
	
		A FILE INFORMATION HASH:
		{
			info1 : '...',
			info2 : '...',
			...
		}
		
		OR AN ERROR HASH:
		{
			error : '...'
		}

	NOTES
	
		IF THE FILEPATH IS ABSOLUTE, THE USER SHOULD HAVE THE CORRECT PERMISSIONS
		TO ACCESS THE DATA BASED ON THE SCRIPT'S SET UID AND SET GID.

		IF THE requestor FIELD IS DEFINED, THIS MEANS ITS A REQUEST BY THE USER
		requestor TO VIEW FILE INFO IN PROJECTS OWNED BY THE USER username.

=cut

sub _checkFile
{
	my $self		=	shift;
	my $filepath	=	shift;
	$self->logDebug("FileManager::_checkFile(filepath)");
	#$self->logDebug("filepath", $filepath);

    #### GET JSON
    my $json  =	$self->{_json};

	#### GET FILE PATH AND USERNAME
	$filepath = $json->{filepath} if not defined $filepath;
	my $username = $json->{username};

	return $self->fileinfo($filepath);
}


=head2

	SUBROUTINE		printJSON
	
	PURPOSE
	
		PRINT JSON FOR AN OBJECT USING THE FOLLOWING FLAGS:

			allow_nonref
		
=cut

sub printJSON
{
	my $self		=	shift;
	my $data		=	shift;
	
	#### PRINT JSON AND EXIT
	my $jsonParser = JSON->new();
	#my $jsonText = $jsonParser->encode->allow_nonref->($data);
    my $jsonText = $jsonParser->objToJson($data, {pretty => 1, indent => 4});
	print $jsonText;
}



=head2

	SUBROUTINE		fileinfo
	
	PURPOSE
	
		RETURN FILE STATUS: EXISTS, SIZE, CREATED

=cut

sub fileinfo
{
	my $self		=	shift;
	my $filepath		=	shift;
	$self->logDebug("plugins.workflow.Workflow.fileinfo(filepath)");
	if ( $^O =~ /^MSWin32$/ )   {   $filepath =~ s/\//\\/g;  }
	$self->logDebug("filepath", $filepath);

	use File::stat;
	use Time::localtime;

	my $fileinfo;
	$fileinfo->{exists} = "false";
	return $fileinfo if $filepath =~ /^\s*$/;
	return $fileinfo if not -f $filepath and not -d $filepath;

    use File::stat;
    my $sb = stat($filepath);
	$fileinfo->{exists} = "true";
	$fileinfo->{size} = $sb->size;
	$fileinfo->{permissions} = $sb->mode & 0777;
	$fileinfo->{modified} = ctime($sb->mtime);
	#$fileinfo->{modified} = scalar localtime $sb->mtime;
	$fileinfo->{type} = "file";
	$fileinfo->{type} = "directory" if -d $filepath;

    return $fileinfo;
}


=head2

    SUBROUTINE:     fileStats
    
    PURPOSE:        Return the following file statistics:
                    -   size (bytes)
                    -   directory ("true"|"false")
                    -   modified (seconds Unix time)
        
=cut

sub fileStats
{
    my $self        =   shift;
    my $filepath    =   shift;



    my $fileStats;

    my $filesize = -s $filepath;
    if ( not defined $filesize )
    {
        $filesize = '';
    }
    
    my $directory = -d $filepath;
    if ( not -f $filepath and not -d $filepath )
    {
        $directory = "''";
    }
    elsif ( not $directory )
    {
        $directory = "false";
    }
    else
    {
        $directory = "true";
    }

    my $modified = -M $filepath;
    if ( not defined $modified )
    {
        $modified = "''"
    }
    else
    {
        $modified = int(time() - $modified * 24 * 60);
    }
    
    $fileStats->{filesize} = "$filesize";
    $fileStats->{directory} = "$directory";
    $fileStats->{modified} = "$modified";
    
    return $fileStats;
}



################################################################################
##################			HOUSEKEEPING SUBROUTINES			################
################################################################################

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

	SUBROUTINE		new
	
	PURPOSE
	
		CREATE THE NEW self OBJECT AND INITIALISE IT, FIRST WITH DEFAULT 
		
		ARGUMENTS, THEN WITH PROVIDED ARGUMENTS

        THE PASSWORD FOR THE DEFAULT ROOT USER CAN BE SET ON THE MYSQL
        
        COMMAND LINE:
        
        use myEST;
        insert into users values('admin', 'mypassword', now());

=cut

sub new
{
 	my $class 		=	shift;
	my $arguments 	=	shift;
        
	my $self = {};
    bless $self, $class;
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);

    return $self;
}


=head2

	SUBROUTINE		value
	
	PURPOSE

		SET A PARAMETER OF THE self OBJECT TO A GIVEN value

    INPUT
    
        1. parameter TO BE SET
		
		2. value TO BE SET TO
    
    OUTPUT
    
        1. THE SET parameter INSIDE THE BioSVG OBJECT
		
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

	$self->logDebug("++++ FileManager::AUTOLOAD(self, newvalue)");
    return if not defined $newvalue or not $newvalue;
	$self->logDebug("New value", $newvalue);

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
