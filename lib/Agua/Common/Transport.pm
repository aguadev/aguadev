package Agua::Common::Transport;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Transport
	
	PURPOSE
	
		TRANSPORT METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

=head2

	SUBROUTINE		jsonSafe
	
	PURPOSE
	
		SUBSTITUTE OUT CHARACTERS THAT WOULD BREAK JSON PARSING
		
		WITH SAFE SYMBOL SETS, E.G., &quot; INSTEAD OF '"'
		
=cut

sub jsonSafe {
	my $self		=	shift;
	my $string		=	shift;
	my $mode		=	shift;
	
	#### CHECK MODE IS DEFINED
	die "Agua::Common::Transport::jsonSafe    mode not defined. Exiting.\n" if not defined $mode;

	#$self->logDebug("string: ****$string****");
	#$self->logDebug("mode: ****$mode****");

	#### SANITY CHECKS
	if ( not defined $string or not $string )
	{
		$self->logDebug("String not defined or empty. Returning ''");
		return ''; 
	}

	my $specialChars = [
		[ '&quot;',	"'" ],	
		[ '&quot;',	'"' ],	
		[ '&nbsp;', ' ' ],	
		#[ '&#35;', '#' ],	
		#[ '&#36;', '$' ],	
		#[ '&#37;', '%' ],	
		#[ '&amp;', '&' ],	
		#[ '&#39;', "'" ],	
		[ '&#40;', '\(' ],	
		[ '&#41;', '\)' ],	
		#[ '&frasl;', '\/' ],	
		[ '&#91;', '\[' ],	
		#[ '&#92;', '\\\\' ],	
		#[ '&#93;', '\]' ],	
		#[ '&#96;', '`' ],	
		[ '&#123;', '\{' ],	
		#[ '&#124;', '|' ],	
		[ '&#125;', '\}' ]	
	];
	#### REMOVE LINE RETURNS AND '\s' 
	#$self->logDebug("BEFORE regex returns string: ****$string****");
	$string =~ s/\s/ /gms;
	$string =~ s/\n/\\n/gms;
	#$self->logDebug("AFTER regex returns string: ****$string****");
	#$self->logDebug("Checking for specialChars");
	
	for ( my $i = 0; $i < @$specialChars; $i++) {
		if ( $mode eq 'toJson' ) {
			#$self->logDebug("Swapping $$specialChars[$i][0] for $$specialChars[$i][1]");
			no re 'eval';
			$string =~ s/$$specialChars[$i][1]/$$specialChars[$i][0]/msg;
			use re 'eval';
		}
		elsif ( $mode eq 'fromJson' ) {
			no re 'eval';
			$string =~ s/$$specialChars[$i][0]/$$specialChars[$i][1]/msg;
			use re 'eval';
		}
	}
	
	#$self->logDebug("Returning string", $string);

	return $string;	
}





=head2

	SUBROUTINE		downloadFile
	
	PURPOSE

		SEND A FILE DOWNLOAD

	INPUT
	
		1. USER VALIDATION: USERNAME, SESSION ID
		
		2. FILE PATH
		
	OUTPUT
		
		1. FILE DOWNLOAD Content-type: application/x-download
	
=cut

sub downloadFile {
	my $self		=	shift;

	my $json		=	$self->json();
	my $username	=	$json->{username};
	my $filepath	=	$json->{filepath};
	my $requestor	=	$json->{requestor};
	$self->logDebug("Common::downloadFile()");

	my $fileroot	=	$self->getFileroot($username);	
	$self->logDebug("filepath", $filepath);
	$self->logDebug("fileroot", $fileroot) if defined $fileroot;
	$self->logDebug("fileroot not defined") if not defined $fileroot;
	
	#### ADD FILEROOT IF FILEPATH IS NOT ABSOLUTE
	if ( $filepath !~ /^\// )
	{
		#### GET THE FILE ROOT FOR THIS USER OR ANOTHER
		my $fileroot;

		if ( defined $requestor )
		{	
			#### GET THE PROJECT NAME, I.E., THE BASE DIRECTORY OF THE FILE NAME
			my ($project) = ($filepath) =~ /^([^\/^\\]+)/;
		
			#### EXIT IF PROJECT ACCESS NOT ALLOWED
			if ( not $self->_canAccess($username, $project, $requestor, "project") )
			{
				$self->logError("user $requestor is not permitted access to project $project owned by user $username");
				exit;
			}
			
			#### ELSE USE OTHER USER'S FILEROOT
			$fileroot = $self->getFileroot($username);
			$self->logError("Fileroot not found for username: $username") and exit unless defined $fileroot;

			$self->logDebug("Requestor defined. Setting fileroot of user: $username with requestor", $requestor);
		}
		else
		{
			$fileroot = $self->getFileroot($username);
			$self->logError("Fileroot not found for user") and exit if not defined $fileroot;
		}
		
		$filepath = "$fileroot/$filepath";

		$self->logDebug("user's fileroot", $fileroot);
		$self->logDebug("new filepath", $filepath);
	}

	#### GET FILE SIZE
	#my $filesize = (stat($filepath))[7] or die "Can't get size of file: $filepath\n";
	$self->logError("Cannot find file: $filepath") and exit if not -s $filepath;
	my $filesize = -s $filepath
		or $self->logError("Cannot get size of file: $filepath") and exit;
	$self->logDebug("filesize", $filesize);
	
	#### GET FILE NAME
	my ($filename) = $filepath =~ /([^\/]+)$/;
	$self->logDebug("filename", $filename);
	
	#### EXIT IF FILE IS EMPTY
	$self->logError("File not found: $filepath") and exit if not -f $filepath;
	$self->logError("File is empty: $filepath") and exit if -z $filepath;
	
	#### PRINT DOWNLOAD HEADER
	print qq{Content-Disposition: attachment;filename="$filename"\n\n};
	print qq{Content-Length: $filesize\n\n};
	
	open(FILE, $filepath) or die "Can't open file: $filepath\n";
	binmode FILE;
	$/ = undef;
	print <FILE>;
	close(FILE);
}




1;