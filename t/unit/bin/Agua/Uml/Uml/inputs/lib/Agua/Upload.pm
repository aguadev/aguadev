use MooseX::Declare;

=head2

	PACKAGE		Agua::Upload
	
	PURPOSE

		1. SAVE FILE CONTENTS TO TEMP FILE
		
		2. CHECK PRIVILEGES, QUIT IF INSUFFICIENT
		
		3. TRANSFER TEMP FILE TO DESTINATION DIRECTORY

=cut

class Agua::Upload with (Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Base,
	Agua::Common::Database) {
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Agua::Admin;
use Conf::Agua;

# Ints
has 'SHOWLOG'		=> ( isa => 'Int', 		is => 'rw', default 	=> 	2 	);  
has 'PRINTLOG'		=> ( isa => 'Int', 		is => 'rw', default 	=> 	2 	);
has 'maxnamelength'=> ( isa => 'Int', 	is => 'rw', default 	=> 	80 	);
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'details'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'username'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'sessionId'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'filename'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'tempdir'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/tmp'	);
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', default	=>	'/tmp/upload.log'	);
has 'boundary'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
has 'boundarynumber'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

#### Objects
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'params'	=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0	);
has 'conf'		=> ( isa => 'Conf::Agua|Undef', is => 'rw', required => 0 );
has 'admin'		=> ( isa => 'Agua::Admin|Undef', is => 'rw', required => 0 );

####/////}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	#### OPEN LOGFILE
	my $logfile = $self->logfile() || "/tmp/upload.log";
	$self->logfile($logfile);
	$self->logDebug("Agua::Upload::initialise()");
}

method upload () {
	my ($details, $boundary_number) = $self->printTempfile();
	my $params = $self->parseParams($details, $boundary_number);
	$self->validateUser($params);
	$self->transferFile();
	#$self->stopLog();
}

method printTempfile () {
#### SAVE FILE CONTENTS TO TEMPORARY FILE
#### TEMP UPLOAD DIR MUST BE 'chmod 0777 tempdir'
	
	$self->logDebug();

	#### SET RECORD SEPARATOR AS BOUNDARY
	my $boundary = $self->getBoundary();
	my $boundary_number = $self->getBoundaryNumber($boundary);
	$/ = $boundary;
	
	my $tempdir 		= $self->tempdir(); 
	my $maxnamelength 	= $self->maxnamelength();
	my $tempfile;
	my $filename;
	my $contents;
	my $details;
	
	#### *** NOTE ***: GOOD FOR A FEW MEGS BUT CHANGE TO
	#### STREAM FOR LARGER FILE SIZES
	$/ = undef;
	binmode STDIN;
	my $input = <STDIN>;
	chomp($input);
	
	#### PRINT DATA TO TEMP FILE
	#### MIME FORMAT:
	#### Content-Disposition: form-data; name="uploadFile"; filename="test2.js"	
	if ( $input =~ /name="[^"]+";\s+filename="([^"]+).?\s+(.+?)\-+$boundary(.+)/ms )
	{
		$filename = $1;
		$contents = $2;
		$details = $3;
		$self->logDebug("filename not defined") and exit if not defined $filename or not $filename;
		
		$contents =~ s/^\s*Content-Type[^\n]+\n\s*\n//ms;
		$contents =~ s/\-+$//;
		$contents =~ s/[\r\n\-]+$//;

		#### SET FILENAME	
		$self->filename($filename);

		#### SET TEMPFILE
		$tempfile = $self->getTempfile($filename, $tempdir);
	
		open(TEMPFILE, ">$tempfile") or die "Can't open temp file: $tempfile\n";
		binmode TEMPFILE;
		print TEMPFILE $contents;
		close(TEMPFILE) or die "Can't close temp file: $tempfile\n";
	}
	
	return ($details, $boundary_number);
}


method getBoundary () {
#### GET BOUNDARY NUMBER FROM FIRST LINE OF INPUT
	$/ = "\n";
	my $firstline = <STDIN>;
	my ($boundary) = $firstline =~ /^Content-Type:\s*multipart\/form-data;\s*boundary=[\-]+(\d+)/;
	($boundary) = $firstline =~ /^[\-]+(\d+)/ if not defined $boundary;
	$self->logDebug("No boundary in first line", $firstline) and die if not defined $boundary;
	$self->boundary($boundary);
	
	return $boundary;
}

method getBoundaryNumber ($boundary) {
	my ($boundary_number) = $boundary =~ /(\d+)/;
	$self->logDebug("boundary_number", $boundary_number);
	$self->boundarynumber($boundary_number);
	
	return $boundary_number;
}


method parseParams ($details, $boundary_number) {
#### PARSE PARAMETERS FROM 	DETAILS
	$self->logDebug();
	my $params;
    while ($details =~ /^.+?name="([^"]+).?\s+(\S+).+?$boundary_number(.*)$/ms )
    {
        my $param = $1;
        my $value = $2;
        $details = $3;
        $value =~ s/\n[\-]+$boundary_number[\-]+$//msi;
        $value =~ s/\s+$//;
        $value =~ s/\s*[\-]+$//;
        $params->{$param} = $value;
        $params->{$param} = '' if not defined $params->{$param};
    }
	$self->params($params);
	
	return $params;
}

method validateUser($params) {
	$self->logDebug();
	#### SANITY CHECK
	$self->logDebug("username not defined") and exit if not defined $params->{username};
	$self->logDebug("sessionId not defined") and exit if not defined $params->{sessionId};

	#### SET username AND sessionId
	my $username = $params->{username};
	my $session_id = $params->{sessionId};
	$self->logDebug("username", $username);
	$self->logDebug("session_id", $session_id);
	$self->username($username);
	$self->sessionId($session_id);

	#### SET DATABASE HANDLE
	$self->setDbh();
	
	#### VALIDATE
	$self->logDebug("Doing self->validate()");
	$self->logError("Validation failed for username", $username) and exit if not $self->validate();
	$self->logDebug("username validated", $username);

	#$self->admin($admin);
}

method transferFile () {
#### TRANSFER DOWNLOADED FILE TO USER'S DIRECTORY
	$self->logDebug("");

	my $username 		= $self->username();
	my $filename 		= $self->filename();
	my $maxnamelength 	= $self->maxnamelength();
	
	#### GET FILEROOT
	#my $fileroot = $self->admin()->getFileroot($username);
	my $fileroot = $self->getFileroot($username);
	$self->logDebug("fileroot", $fileroot);
	$self->logDebug("No fileroot for user", $username) and exit if not defined $fileroot and not $fileroot;
	
	#### SET DESTINATION DIR INCLUDING INTERVENING PATH IF ANY
	my $destinationdir = "$fileroot";
	my $path = $self->params()->{path};
	$destinationdir .= "/$path" if defined $path and $path;
	$self->logDebug("destinationdir", $destinationdir);
	
	#### CHECK DESTINATION
	my $tempfile = $self->tempfile();
	if ( not -d $destinationdir )
	{
		`rm $tempfile`;
		$self->logDebug("destinationdir not found", $destinationdir);
		exit;
	}
	
	#### GET FILE PATH
	my $filepath = $self->setFilepath($filename, $destinationdir, $maxnamelength);
	$self->logDebug("filepath", $filepath);
	
	#### MOVE TEMP FILE TO DESTINATION DIRECTORY
	#### *** NB *** : THIS DOESN'T REPORT AN ERROR IF IT FAILS TO COPY -- FIX LATER
	
	$self->logDebug("Doing File::Copy::move($tempfile, $filepath)");
	File::Copy::move($tempfile, $filepath) or $self->logError("Cannot move from tempfile: $tempfile to filepath", $filepath) and exit;
	$self->logStatus("Completed copy to filepath", $filepath);
}

method getTempfile ($filename, $tempdir) {
	my $tempfile = "$tempdir/$filename" . rand(10000000);
	$tempfile = "$tempdir/$filename" . rand(10000000) while ( -e $tempfile );
	$self->tempfile($tempfile);
	$self->logDebug("tempfile", $tempfile);

	return $tempfile;
}

method setFilepath ($filename, $directory, $maxnamelength) {
	$self->logDebug("");
    $self->logDebug("filename", $filename);
    $self->logDebug("directory", $directory);
    $self->logDebug("maxnamelength", $maxnamelength);

    #### GET SHORTENED FILENAME
    if ( $filename =~ /(.+)\.(.+)/ ) {
        my ($fn,$ext) = ($1,$2);
        $fn = substr($fn, 0, $maxnamelength);
    
        #### RETURN SHORTENED FILENAME IF NOT EXISTS
        return "$directory/$fn.$ext" if not -e "$directory/$fn.$ext";
    
        ### CHANGE THE FILE NAME 
        my $i = 0;
        $i++ while ( -e "$directory/$fn.$i.$ext" );
    
		#### MOVE THE EXISTING FILE TO THE SHORT NAME
		#### AND UPLOAD THE FILE USING THE LONG NAME
		$self->logDebug("transferUpload    Doing File::Copy::move('$directory/$fn.$ext', '$directory/$fn.$i.$ext')...");
		use File::Copy;
		File::Copy::move("$directory/$fn.$ext", "$directory/$fn.$i.$ext") or die "{    error: 'Cannot move from file: $directory/$fn.$ext to file: $directory/$fn.$i.$ext' ";

        $self->logDebug("Returning $fn.$ext");
        return "$directory/$fn.$ext";
    }
    else {
        my $fn = substr($filename, 0, $maxnamelength);
    
        #### RETURN SHORTENED FILENAME IF NOT EXISTS
        return "$directory/$fn" if not -e "$directory/$fn";
    
        ### CHANGE THE FILE NAME 
        my $i = 0;
        $i++ while ( -e "$directory/$fn.$i" );
    
		#### MOVE THE EXISTING FILE TO THE SHORT NAME
		#### AND UPLOAD THE FILE USING THE LONG NAME
		$self->logDebug("Doing File::Copy::move('$directory/$fn', '$directory/$fn.$i')...");
		use File::Copy;
		File::Copy::move("$directory/$fn", "$directory/$fn.$i") or $self->logError("Cannot move from file: $directory/$fn to file $directory/$fn.$i") and exit;
	
        $self->logDebug("Returning $fn");
        return "$directory/$fn";
    }
}





}

