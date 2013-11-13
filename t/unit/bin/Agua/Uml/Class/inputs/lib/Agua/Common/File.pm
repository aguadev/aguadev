package Agua::Common::File;
use Moose::Role;
use Method::Signatures::Simple;
#use Moose::Util::TypeConstraints;

#use Convert::Binary::C;

# Ints
has 'bytes'		=> ( isa => 'Int', is => 'rw', default => 200 );

=head2

	PACKAGE		Agua::Common::File
	
	PURPOSE
	
		FILE CHECKING AND INFO METHODS FOR Agua::Common
	
=cut

method setJsonParser () {
	return $self->jsonparser() if $self->jsonparser();
	#my $jsonparser = JSON->new() ;
	my $jsonparser = JSON->new->allow_nonref;
	$self->jsonparser($jsonparser);
	
	return $self->jsonparser();
}

method getFileCaches {
	#### GET USERNAME
	my $username = $self->username();
	$self->logError("username not defined") and return if not defined $username;
	
	#### GET DEPTH
	my $depth = $self->conf()->getKey("agua", "FILECACHEDEPTH");
	$self->logDebug("depth", $depth);
	
	#### SET FILECACHES
	my $filecaches = {};
	
	$self->projectFileCaches($filecaches, $username, $depth);
	
	$self->sourceFileCaches($filecaches, $username, $depth);
	
	$self->sharedProjectFileCaches($filecaches, $username, $depth);
	
	$self->sharedSourceFileCaches($filecaches, $username, $depth);
		
	#$self->logDebug("filecaches", $filecaches);
	return $filecaches;
}

method projectFileCaches ($filecaches, $username, $depth) {
	#### GET FILEROOT
	my $fileroot = $self->getFileroot();
	$self->logDebug("fileroot", $fileroot);

	#### GET JSON PARSER
	my $jsonparser = $self->setJsonParser();

	#### GET PROJECTS
	my $projects = $self->getProjects();	
	$self->logDebug("no. projects", scalar(@$projects));

	#### SET FILECACHES
	$filecaches->{$username} = {};
	
	foreach my $project ( @$projects ) {
		$self->logError("project has no name", $project) and next if not defined $project->{name};
		
		my $projectname = $project->{name};
		my $filepath = "$fileroot/$projectname";
		$self->logDebug("DOING filepath", $filepath);
	
		#### SET PROJECT FILECACHE
		my $json = $self->fullPathJson($filepath, $projectname, $projectname);
		$self->logDebug("json", $json);
		
		$self->logDebug("SETTING FILECACHES->{$username}->{$projectname}");
		$filecaches->{$username}->{$projectname} = $jsonparser->decode($json);
		
		#### SET PROJECT SUBDIRS FILECACHE
		$self->recursiveFileCaches($filecaches->{$username}, $filepath, $projectname, $projectname, $depth);
	}
}

method sourceFileCaches ($filecaches, $username, $depth) {
	#### GET JSON PARSER
	my $jsonparser = $self->setJsonParser();

	$filecaches->{$username} = {} if not defined $filecaches->{$username};

	#### GET SOURCES
	my $sources = $self->getSources();
	$self->logDebug("no. sources", scalar(@$sources));

	foreach my $source ( @$sources ) {
		$self->logError("source has no name", $source) if not defined $source->{name};
		$self->logDebug("source",$source);
		my $sourcename = $source->{location};
		my $filepath = $source->{location};
		$self->logDebug("DOING filepath", $filepath);
		
		#### SET SOURCE FILECACHE
		my $json = $self->fullPathJson($filepath, $sourcename, $sourcename);
		$self->logDebug("SETTING FILECACHE->{$sourcename}");
		$filecaches->{$username}->{$sourcename} = $jsonparser->decode($json);
			
		#### SET PROJECT SUBDIRS FILECACHE
		$self->recursiveFileCaches($filecaches->{$username}, $filepath, $sourcename, $sourcename, $depth);
	}
}

method sharedProjectFileCaches ($filecaches, $username, $depth) {
	#### GET FILEROOT
	my $fileroot = $self->getFileroot();
	$self->logDebug("fileroot", $fileroot);

	#### GET JSON PARSER
	my $jsonparser = $self->setJsonParser();

	#### SHARED PROJECTS
	my $aguauser = $self->conf()->getKey("agua", "AGUAUSER");
	my $sharedprojecthash 	= 	$self->getSharedProjects();
	foreach my $owner ( keys %$sharedprojecthash ) {
		$self->logDebug("owner", $owner);
		$filecaches->{$owner} = {};
	
		#### IGNORE AGUA USER
		next if $owner eq $aguauser;
	
		my $sharedprojects = $sharedprojecthash->{$owner};
		foreach my $sharedproject ( @$sharedprojects ) {

			$self->logError("sharedproject has no name", $sharedproject) and return if not defined $sharedproject->{name};
			
			my $sharedprojectname 	= $sharedproject->{name};
			my $projectowner 		= $sharedproject->{username};
			my $fileroot 			= $self->getFileroot($projectowner);
			$self->logDebug("fileroot", $fileroot);
	
			my $filepath = "$fileroot/$sharedprojectname";
			$self->logDebug("DOING filepath", $filepath);
				
			#### SET PROJECT FILECACHE
			my $json = $self->fullPathJson($filepath, $sharedprojectname, $sharedprojectname);
			$self->logDebug("SETTING FILECACHE->{$sharedprojectname}");
			$filecaches->{$owner}->{$sharedprojectname} = $jsonparser->decode($json);
		
			$self->recursiveFileCaches($filecaches->{$owner}, $filepath, $sharedprojectname, $sharedprojectname, $depth);
		}
	}
}

method sharedSourceFileCaches ($filecaches, $username, $depth) {
	#### GET JSON PARSER
	my $jsonparser = $self->setJsonParser();

	#### GET SHARED SOURCES
	my $sharedsourcehash	= 	$self->getSharedSources();
	$self->logDebug("sharedsourcehash", $sharedsourcehash);
	return if not defined $sharedsourcehash;
	
	foreach my $owner ( keys %$sharedsourcehash ) {
		$self->logDebug("owner", $owner);
		$filecaches->{$owner} = {} if not defined $filecaches->{$owner};
	
		my $sharedsources = $sharedsourcehash->{$owner};
		foreach my $sharedsource ( @$sharedsources ) {
			$self->logError("sharedsource has no name", $sharedsource) if not defined $sharedsource->{name};
			$self->logDebug("sharedsource",$sharedsource);
			my $sharedsourcename = $sharedsource->{location};
			my $filepath = $sharedsource->{location};
			$self->logDebug("DOING filepath", $filepath);
	
			#### SET SOURCE FILECACHE
			my $json = $self->fullPathJson($filepath, $sharedsourcename, $sharedsourcename);
			$self->logDebug("SETTING FILECACHE->{$sharedsourcename}");
			$filecaches->{$username}->{$sharedsourcename} = $jsonparser->decode($json);
			
			$self->recursiveFileCaches($filecaches->{$owner}, $filepath, $sharedsourcename, $sharedsourcename, $depth);
		}
	}	
}

method recursiveFileCaches ($filecaches, $filepath, $relativepath, $filename, $depth) {
	#$self->logDebug("XXXXX    filecaches", $filecaches);
	$self->logDebug("XXXXX    filepath", $filepath);
	$self->logDebug("XXXXX    filename", $filename);
	$self->logDebug("XXXXX    depth", $depth);

	return if $depth < 1;
	$depth--;
	$self->logDebug("XXXXX    new depth", $depth);

	my $jsonparser = $self->setJsonParser();
	#my $json = $self->fullPathJson($filepath, $relativepath, $filename);
	#$self->logDebug("SETTING FILECACHE->{$filename}");
	#$filecaches->{$filename} = $jsonparser->decode($json);
	
	if ( -d $filepath ) {
		$self->logDebug("DOING DIRECTORY");
		
		my $files = $self->getFileDirs($filepath);
		foreach my $file ( @$files ) {
			my $subpath = "$filepath/$file";
			$self->logDebug("Doing subpath: $subpath");
			
			my $outputpath = "$relativepath/$file";
			
			my $json = $self->fullPathJson($subpath, $outputpath, $file);
			$self->logDebug("json", $json);
			$self->logDebug("SETTING FILECACHE->$outputpath");
			$filecaches->{$outputpath} = $jsonparser->decode($json);			
			$self->recursiveFileCaches($filecaches, "$filepath/$file", "$relativepath/$file", $file, $depth);
		}
	}
	else {
		#print "SKIPPING recursiveFilecaches BECAUSE FILEPATH IS A FILE: $filepath\n";
	}
	
	return;
}

method fileStats ($filepath) {
=head2

    SUBROUTINE:     fileStats
    
    PURPOSE:
		
		Return the following file statistics:
			-   size (bytes)
			-   directory ("true"|"false")
			-   modified (seconds Unix time)

=cut

$self->logDebug("filepath", $filepath);

    my $fileStats;

    my $filesize = -s $filepath;
    if ( not defined $filesize )
    {
        $filesize = '';
    }
    
    my $directory = -d $filepath;
    if ( not -f $filepath and not -d $filepath )
    {
        $directory = qq{""};
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
        $modified = qq{""}
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

method fileSystem {
=head2

    SUBROUTINE:     fileSystem
    
    PURPOSE:
	
		Return the JSON details of all files and directories
    
		in the file system. JSON format:
		
		"total":4,
		"items":
		[
		   {
			   "name":"dijit",
			   "parentDir":".",
			   "path":".\/dijit",
			   "directory":true,
			   "size":0,
			   "modified" :1227075503,
			   "":
			   [
				   "ColorPalette.js",
               
=cut

    $self->logDebug("self->json", $self->json());
	
    #### GET USER NAME
    my $username = $self->json()->{username};
	
    #### FOR SECURITY, REMOVE ALL '..', '\', '/', ETC. FROM USERNAME
    $username =~ s/[><\\\/\.\.\(\)]//g;
    $self->logDebug("username", $username);

    #### VALIDATE
	$self->logError("User session not validated") and return if not $self->validate();

	#### GET QUERY, I.E., NAME OF PROJECT
    my $query = $self->json()->{query};
    $query =~ s/"//g if defined $query;    
    $query =~ s/\%22//g if defined $query;    
    #$query =~ s/\%20/\//g if defined $query;    
    if ( not defined $query or $query =~ /^{}$/ )
    {
        $query = '';
    }
    $self->logDebug("query", $query) if defined $query;

	#### GET ADDITIONAL PATH IF DEFINED
    my $path = $self->json()->{path};
    $self->logDebug("path", $path) ;

	#### CHECK IF WE ARE REQUESTING ACCESS TO SOMEONE ELSE'S FILES
	my $owner = $self->json()->{owner};
    $self->logDebug("owner", $owner);

	#### IF ITS A SOURCE, LOCATION IS DEFINED
	my $location = $self->json()->{location};
	$location = '' if not defined $location or $location eq "undefined";
	$self->logDebug("location", $location)  if defined $location;

	#### DECIDE FILE ROOT
	#### EXIT IF NOT ALLOWED ACCESS TO FILES OWNED BY 'OWNER'
	my $fileroot = $self->decideFileroot($username, $owner, $path, $query, $location);
	$self->logDebug("fileroot", $fileroot);

	#### SET USER NAME TO OWNER IF DEFINED
	$username = $owner if defined $owner and $owner;

	#### DECIDE FULL PATH
	my $fullpath = $self->decideFullpath($path, $query, $location, $fileroot);
    $self->logDebug("fullpath", $fullpath);
    
    if ( not defined $path or not $path ) {
        $path = $query || "";
    }
    
    #### GET THE FILE/DIR NAME FROM THE FILEPATH
    my $outputname = '';
    if ( defined $query and $query ) {
        ($outputname) = $query =~ /([^\/\\]+)$/;        
    }
	$self->logDebug("outputname", $outputname);

    #### GET THE FILE/DIR NAME FROM THE FILEPATH
    my $outputpath = $query;
	$outputpath = $location if not defined $outputpath or not $outputpath;
	$outputpath = "$path/$outputname" if not defined $outputpath or not $outputpath;
	$self->logDebug("outputpath", $outputpath);
	
	my $json = $self->fullPathJson($fullpath, $outputpath, $outputname, $path);
	$json =~ s/\s+//g;
	print $json;
}

method fullPathJson ($fullpath, $outputpath, $outputname) {
	$self->logDebug("fullpath", $fullpath);
	$self->logDebug("outputpath", $outputpath);
	$self->logDebug("outputname", $outputname);

    #### IF ITS THE BASE DIRECTORY, I.E., query IS '{}' (path IS NOT DEFINED),
    #### DO { 'total': 3, 'items': [ ... ]} WHERE '...' IS AN
    #### ARRAY OF JSONS FOR EACH FILE/DIR IN THE BASE DIRECTORY
    #### (THE SUB-DIRECTORIES JSON INCLUDES THEIR children)
    my $json = '';
	if ( -d $fullpath )
    {
		$self->logDebug("fullpath is a directory");
		$self->logDebug("whoami: " . `whoami`);

        opendir(DIRHANDLE, $fullpath) or die "Can't open base directory: $fullpath: $!";
        my @filenames = sort readdir(DIRHANDLE);
        close(DIRHANDLE);
        
        #### REMOVE '.' AND '..'
        shift @filenames;
        shift @filenames;
		
		$self->logDebug("filenames in fullpath $fullpath: ");
		for ( my $i = 0; $i < $#filenames + 1; $i++ )
		{
			$self->logDebug("filenames[$i]", $filenames[$i]);

			#### REMOVE ALL .DOT DIRECTORIES
			if ( $filenames[$i] =~ /^\./ )
			{
				$self->logDebug("Splicing out directory", $filenames[$i]);
				splice @filenames, $i, 1;
				$i--;
			}
		}
		$self->logDebug("filenames: @filenames");
        
        my $total = $#filenames + 1;

        #### START JSON
        $json = "{\n";

        $json .= qq{"name": "$outputname",\n};
        $json .= qq{"path": "$outputname",\n};
    
        #### PRINT THE TOTAL ITEMS
        $json .= qq{"total": "$total",\n};

        #### START THE items SQUARE BRACKETS
        $json .= qq{"items": [\n};

        foreach my $file (@filenames)
        {
            #### SET FILEPATH AND CHANGE TO BACKSLASH FOR WINDOWS
            my $filepath = "$fullpath/$file";
			$self->logDebug("Doing self->fileJson with outputname", $outputname);
			$self->logDebug("Doing self->fileJson with filepath", $filepath);
			$self->logDebug("Doing self->fileJson with outputpath", $outputpath);

            $json .= $self->fileJson($outputname, $filepath, $outputpath);
            $json .= ",\n";
        }
        $json =~ s/,$/\n/;

        $json .= "]\n";
        $json .= "}\n";
        
		$json =~ s/\s+//g;
    }
    elsif ( -f $fullpath )
    {
		$self->logDebug("fullpath is a file");
		my ($parentDir) = $outputpath =~ /^(.+)\/[^\/]+$/;
		$self->logDebug("parentDir", $parentDir);
        $json = $self->fileJson($outputname, $fullpath, $parentDir);
    }
	else
	{
		$self->logDebug("fullpath not found");
		my ($parentDir) = $outputpath =~ /^(.+)\/[^\/]+$/;
		$self->logDebug("parentDir", $parentDir);
        $json = $self->fileJson($outputname, $fullpath, $parentDir);
	}

	return $json;	
}

method decideFullpath ($path, $query, $location, $fileroot) {
	$self->logDebug("path", $path);
	$self->logDebug("query", $query);
	$self->logDebug("location", $location);
	$self->logDebug("fileroot", $fileroot);
	
	#### SET USERDIR AND CHANGE TO BACKSLASH FOR WINDOWS
    my $fullpath = '';
    if ( defined $location and $location ) {
		$self->logDebug("Location is defined. Setting fullpath = $location");
	    $fullpath = "$location";

        #### ADD query IF DEFINED
        if ( defined $path and $path ) {
			$self->logDebug("path is defined. Setting fullpath .= '/$path'");
            $fullpath .= "/$path";
        }
        if ( defined $query and $query and $query !~ /^\// ) {
			$self->logDebug("query is defined. Setting fullquery .= '/$query'");
            $fullpath .= "/$query";
        }
        elsif ( defined $query and $query and $query =~ /^\// ) {
			$self->logDebug("query is defined AND full path. Setting fullpath = '$query'");
            $fullpath = $query;
        }
    }
    else {
		if ( $query =~ /^\// ) {
			$fullpath = $query;
		}
		else {
		
			$fullpath = "$fileroot";
	
			#### ADD query IF DEFINED
			if ( defined $query and $query ) {
				$fullpath .= "/$query";
			}
			elsif ( defined $path and $path ) {
				$fullpath .= "/$path";
			}
		}
    }

	return $fullpath
}

method decideFileroot ($username, $owner, $path, $query, $location) {
	my $fileroot = '';
	if ( defined $owner and $owner ne $username )
	{	
		$fileroot = $self->getFileroot($owner);
		$self->logDebug("owner is defined. fileroot", $fileroot);
		
		#### GET THE PROJECT NAME, I.E., THE BASE DIRECTORY OF THE FILE NAME
		my ($project) = ($query) =~ /^([^\/^\\]+)/;
		my $type = "project";
		$type = "source" if defined $location and $location;

		my $groupname = $self->json()->{groupname};
	    $self->logDebug("groupname", $groupname);
		$self->logError("groupname not defined") and exit if not defined $groupname;

		my $can_access = $self->canViewGroup($owner, $groupname, $username, $type);
		$self->logDebug("can_access", $can_access);
		
		if ( not $can_access )
		{
			$self->logError("user $username is not permitted access to file path $path");
			return;
		}
	}
	else
	{
		#### GET FILE ROOT FOR THIS USER
		$fileroot = $self->getFileroot();
		$self->logDebug("fileroot", $fileroot);
	}
    $self->logDebug("fileroot", $fileroot);

	return $fileroot;
}

method fileJson ($path, $filepath, $parentDir) {
=head2

    SUBROUTINE:     fileJson
    
    PURPOSE:        Get the details for each file and its children if its a directory
    
=cut
	$self->logDebug("path", $path);
	$self->logDebug("filepath", $filepath);
	$self->logDebug("parentDir", $parentDir);

    #### START JSON    
    my $json = "{\n";

    #### GET FILE STATS (size, directory, modified)
    my $fileStats = $self->fileStats($filepath);
    
    #### GET THE FILE/DIR NAME FROM THE FILEPATH
    my ($name) = $filepath =~ /([^\/]+)$/;
   
    $json .= qq{    "name": "$name",\n};
    $json .= qq{    "path": "$parentDir/$name",\n};
    $json .= qq{    "parentPath": "$parentDir",\n};
    $json .= qq{    "parentDir": "$parentDir",\n};
    $json .= qq{    "directory": $fileStats->{directory},\n};
    $json .= qq{    "size": "$fileStats->{filesize}",\n};
    $json .= qq{    "modified": $fileStats->{modified},\n};

    #### DO CHILDREN 
    if ( $fileStats->{directory} =~ /^true$/ )
    {
        $json .= qq{    "children": [\n};

        opendir(DIRHANDLE, $filepath) or die "Can't open filepath: $filepath: $!";
        my @filenames = sort readdir(DIRHANDLE);
        close(DIRHANDLE);

        #### REMOVE '.' AND '..'
        shift @filenames;
        shift @filenames;
        
        foreach my $file ( @filenames )
        {
            $json .= qq{        "$file",\n};    
        }
        $json =~ s/,\n$/\n/;
        $json .= "    ]\n";
    }
    else
    {
		#$self->bytes(200);

        #### GET A SAMPLE FROM THE TOP OF THE FILE
        my $sample;
		my $bytes = $self->bytes();
        if ( -B $filepath
			or $filepath =~ /\.ebwt$/
			or $filepath =~ /\.bfa$/
			or $filepath = /\.vld$/
			or $filepath = /\.2bpb$/ )
        {
            $sample = "Binary file";
        }
        elsif ( -f $filepath and not -z $filepath )
        {
            open(FILEHANDLE, $filepath);
            seek(FILEHANDLE, 0, 0);
            read(FILEHANDLE, $sample, $bytes);
        }
    
        #### SET TO '' IF FILE IS EMPTY
        if ( not defined $sample or not $sample )
        {
            $sample = '';
        }
		else
		{
			$self->logDebug("BEFORE jsonSafe, sample", $sample);
			$sample = $self->jsonSafe($sample, 'toJson');
			$self->logDebug("AFTER jsonSafe, sample", $sample);
		}
        $json .= qq{    "sample": "$sample", };
        $json .= qq{    "bytes" : "$bytes" };
    }

    #### END JSON
    $json .= "}";

	$self->logDebug("json", $json);
    
    return $json;
}



method filePeek {
=head2

	SUBROUTINE		filePeek
	
	PURPOSE
	
		PRINT LINES OF A FILE FROM A PARTICULAR OFFSET
	
=cut

	my $filepath = $self->json()->{filepath};
	my $offset = $self->json()->{offset};
	my $lines = $self->json()->{lines};
	my $bytes = $self->json()->{bytes};

	return "{ error: 'Agua::Common::File::filePeek    offset not defined' }" and return if not defined $offset;
	return "{ error: 'Agua::Common::File::filePeek    filepath not defined' }" and return if not defined $filepath;
	return "{ error: 'Agua::Common::File::filePeek    lines and bytes not defined' }" and return if not defined $lines and not defined $bytes;

	#### EXIT IF FILEPATH NOT FOUND
	if ( not -f $filepath and not -d $filepath )
	{
		return "{  error: 'Agua::Common::File::filepeek    file or directory not found: $filepath' }";
	}

	#### GET LINES 
	if ( defined $lines and defined $offset )
	{
		my $peek = `tail +$offset $filepath | head -n$lines`;
		if ( not defined $peek or not $peek )
		{
			return "{  error: 'Agua::Common::File::filepeek    peek at offset $offset and lines $lines not defined for filepath: $filepath' }";
		}		
		$peek =~ s/\n/\\n/g;
		$peek =~ s/'/\\'/;
		
		return $peek;
	}

	
	#### GET BYTES
	elsif ( defined $bytes and defined $offset )
	{
		my $peek = '';
		open(FILE, $filepath) or $self->logError("Could not find file: $filepath") and return;
		seek FILE, $offset, 0;
		read(FILE, $peek, $bytes);
		close(FILE);

		if ( not defined $peek or not $peek )
		{
			return "{  error: 'Agua::Common::File::filepeek    peek at offset $offset and bytes $bytes not defined for filepath: $filepath' }";
		}

		print "{ peek: '$peek' }";
	}
}

method checkStageFiles {
=head2

	SUBROUTINE		checkStageFiles
	
	PURPOSE
	
		PRINT FILE INFO FOR ONE OR MORE FILES OR DIRECTORIES FOR
		
		ONE OR MORE STAGES
		
	INPUTS
	
		AN ARRAY OF ARRAYS OF FILE HASHES
		[
			[ { filehash1 }, { filehash2 } ],
			...
		]
		
	OUTPUTS
	
		AN ARRAY OF ARRAYS (SAME ORDER AS INPUTS) OF FILE INFORMATION HASHES
		[
			[ { fileinfo1 }, { fileinfo2 } ],
			...
		]		
=cut


	$self->logDebug("");

    ### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	#### GET ARRAY OF FILE HASHES
	my $stagefiles = $self->json()->{stagefiles};
	my $stagefileinfos = [];
	foreach my $stage ( @$stagefiles )
	{
		#### GET FILE INFO FOR EACH FILE/DIRECTORY
		my $fileinfos = [];
		foreach my $file ( @$stage )
		{
			$self->logDebug("file : ", $file);
			my $filepath = $file->{value};
			
			push@$fileinfos, $self->_checkFile($filepath);	
		}
		
		push @$stagefileinfos, $fileinfos;
	}
	
	#### PRINT FILE INFO	
	$self->printJSON($stagefileinfos);
}


method checkFiles {
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


	$self->logDebug("");

    ### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	#### GET ARRAY OF FILE HASHES
	my $files = $self->json()->{files};
	
	#### GET FILE INFO FOR EACH FILE/DIRECTORY
	my $fileinfos = [];
	foreach my $file ( @$files )
	{
		$self->logDebug("file : ", $file);
		my $filepath = $file->{value};
		
		push@$fileinfos, $self->_checkFile($filepath);	
	}
	
	#### PRINT FILE INFO	
	$self->printJSON($fileinfos);
}

method checkFile {
=head2

	SUBROUTINE		checkFile
	
	PURPOSE
	
		PRINT FILE INFO FOR A FILE OR DIRECTORY
	
=cut


	$self->logDebug("");

    #### GET JSON
    my $json  =	$self->json();

    #### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	my $fileinfo = $self->_checkFile();
	$self->logDebug("fileinfo", $fileinfo);
	$self->logDebug("\n");

	$self->printJSON($fileinfo);
}

method _checkFile ($filepath) {
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
			error : '...'+
		}

	NOTES
	
		IF THE FILEPATH IS ABSOLUTE, THE USER SHOULD HAVE THE CORRECT PERMISSIONS
		TO ACCESS THE DATA BASED ON THE SCRIPT'S SET UID AND SET GID.

		IF THE requestor FIELD IS DEFINED, THIS MEANS ITS A REQUEST BY THE USER
		requestor TO VIEW FILE INFO IN PROJECTS OWNED BY THE USER username.

=cut


	$self->logDebug("");

    #### GET JSON
    my $json  =	$self->json();

    ### VALIDATE    
    $self->logError("User session not validated") and return unless $self->validate();

	#### GET FILE PATH AND USERNAME
	$filepath = $json->{filepath} if not defined $filepath;
	my $username = $json->{username};
    
	#### RETURN FILE NOT EXISTS IF FILEPATH IS EMPTY
	if ( $filepath =~ /^\s*$/) {
		$self->printJSON({ filepath => "$filepath", exists => "false"});
		return;
	}

	#### IF THE FILEPATH IS ABSOLUTE, THE USER SHOULD HAVE THE CORRECT PERMISSIONS
	#### TO ACCESS THE DATA BASED ON THE SCRIPT'S SET UID AND SET GID
	if ( $filepath =~ /^\// ) {
		return $self->getFileinfo($filepath);
	}

	#### ADD FILEROOT IF FILEPATH IS NOT ABSOLUTE.
	#### GET THE FILE ROOT FOR THIS USER IF requestor NOT DEFINED
	if ( not defined $json->{requestor} ) {
		$self->logDebug("Setting fileroot of user", $username);

		#### DO SETUID OF WORKFLOW.CGI AS USER
		my $fileroot = $self->getFileroot($username);
		
		#### QUIT IF FILEROOT NOT DEFINED OR EMPTY
		return {error => 'Agua::Common::File::_checkFile    fileroot not defined for user: $username and filepath: $filepath' } if not defined $fileroot or not $fileroot;

		#### SET NEW FILEPATH
		$filepath = "$fileroot/$filepath";
		$self->logDebug("RETURNING fileinfo for filepath", $filepath);
		return $self->getFileinfo($filepath);
	}

	#### IF THE requestor FIELD IS DEFINED, THIS MEANS
	#### ITS A REQUEST BY THE USER requestor TO VIEW FILE INFO IN PROJECTS
	#### OWNED BY THE USER username.

	#### (THE CLIENT MAKES SEPARATE CALLS FOR SHARED FILES NOT OWNED
	#### BY THE LOGGED-IN USER WITH requestor=THIS USER AND username=OTHER USER, 
	#### SO THAT IF THE INSTANCE IS RUN AS SETUID THE OTHER USER IT THEREBY HAS
	#### ACCESS TO THE OTHER USER'S PROJECT DIRECTORIES

	my $requestor = $json->{requestor};
	my $fileroot = $self->getFileroot($username);
	return { error => 'Agua::Common::File::_checkFile    Fileroot not found for user' } if not defined $fileroot;
	$self->logDebug("Requestor defined. Setting fileroot of user: $username with requestor", $requestor);

	#### GET THE PROJECT NAME, I.E., THE BASE DIRECTORY OF THE FILE NAME
	my ($project) = ($filepath) =~ /^([^\/^\\]+)/;
	my $can_access_project = $self->_canAccess($username, $project, $requestor, "project");

	#### IF PROJECT RIGHTS NOT DEFINED, USE DEFAULT PROJECT RIGHTS 
	if ( not $can_access_project ) {
		return { error => 'Requestor $requestor cannot access project $project' };
	}
	else {
		$fileroot = $self->getFileroot($username);

		#### QUIT IF FILEROOT NOT DEFINED OR EMPTY
		$self->logError("Fileroot not found for username: $username") if not defined $fileroot or not $fileroot;
		$self->logDebug("fileroot", $fileroot);

		$filepath = "$fileroot/$filepath";
		return $self->getFileinfo($filepath);		
	}	
}

method printJSON ($data) {
#### PRINT JSON FOR AN OBJECT
	
	#### PRINT JSON AND EXIT
	my $jsonParser = JSON->new();
	#my $jsonText = $jsonParser->encode->allow_nonref->($data);
    #my $jsonText = $jsonParser->objToJson($data, {pretty => 1, indent => 4});
    my $jsonText = $jsonParser->pretty->indent->encode($data);
	print $jsonText;
}

method getFileinfo ($filepath) {
####		RETURN FILE STATUS: EXISTS, SIZE, CREATED

	$self->logDebug("filepath", $filepath);

	use File::stat;
	use Time::localtime;

	my $fileinfo;
	$fileinfo->{filepath} = $filepath;
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

	$self->logDebug("filepath", $filepath);

    return $fileinfo;
}


method fileType ($type, $filepath) {
=head2

	SUBROUTINE		fileType
	
	PURPOSE

		DETERMINE IF A FILE BELONGS TO ONE OF A LIST OF PREDETERMINED
		
		FILE TYPES (E.G., FASTA, FASTQ, BINARY FASTA, SQUASH, .ACE, .TSV, .CSV)
	
	NOTES
	
		1. ON 64-BIT MACHINES NEED TO FIX THIS ERROR:

		'bits/predefs.h' not found
		
		BY LOADING libc INCLUDES FOR 32-BIT BUILDS:
		
		sudo apt-get install libc6-dev-i386

		
=cut
	
	return $self->checkEbtw($filepath) if $type eq "ebwt";
}

method checkEbwt ($ebwtfile, $headerfile) {
#### TO DO
	$self->logDebug("Can't find ebwtfile: $ebwtfile") and return if not -f $ebwtfile;
	$self->logDebug("Can't find headerfile: $headerfile") and return if not -f $headerfile;

	require Convert::Binary::C;
	my $c = new Convert::Binary::C ByteOrder => 'BigEndian';
	
	#### ADD include PATHS AND GLOBAL PREPROCESSOR defines
	$c->Include('/usr/lib/gcc/x86_64-linux-gnu/4.6/include',
				'/usr/include')
	  ->Define(qw( __USE_POSIX __USE_ISOC99=1 ));
	
	#### PARSE HEADER FILE
	$c->parse_file($headerfile);
	

	
}

method fileIntegrity {
=head2

	SUBROUTINE		fileIntegrity
	
	PURPOSE

		THIS METHOD HAS TWO USES:

		1. DETERMINE WHETHER A FILE BELONGS TO A USER-DEFINED FILE TYPE
		
			(E.G., FASTA, FASTQ, BINARY FASTA, SQUASH, .ACE, .TSV, .CSV)
		
		2. IF IT DOES, DETERMINE WHETHER IT CONFORMS TO THE SPECIFICATIONS
		
			OF THAT FILE TYPE
	
=cut

	#### PLACEHOLDER
}

method discUsage {
#### TBC: KEEP TRACK OF FILESYSTEM SIZES IN EACH PROJECT	
}

method checkQuota {
#### TBC: LIMIT FILE ADDITIONS BEYOND A PRESET USER QUOTA (DEFAULT = NONE)	
}





1;