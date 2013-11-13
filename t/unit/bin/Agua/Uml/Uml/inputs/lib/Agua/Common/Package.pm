package Agua::Common::Package;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

#### VARIABLES
has 'remoteroot'	=> ( isa => 'Str|Undef', is => 'rw', default	=> "https://api.github.com/repos" );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw', default	=> '' );
has 'installdir'	=> ( isa => 'Str|Undef', is => 'rw', default	=> '' );
has 'privacy'		=> ( isa => 'Str|Undef', is => 'rw', default	=> 'public');
has 'hubtype'		=> ( isa => 'Str|Undef', is => 'rw', default	=> "github" );
has 'version'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'build'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'type'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'application'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'owner'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'login'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'token'			=> ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'opsrepo'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'repository'	=> ( isa => 'Str|Undef', is => 'rw' );
has 'repodir'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'branch'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'opsdir'		=> ( isa => 'Str|Undef', is => 'rw' );

with 'Agua::Common::Package::Default';
with 'Agua::Common::Package::Sync';
with 'Agua::Common::Package::Upgrade';

=head2

	PACKAGE		Agua::Common::Package
	
	PURPOSE
	
		INSTALL/UPGRADE/REMOVE PACKAGES AND UPDATE package TABLE

=cut

#### PACKAGES
method getPackages {
=head2

    SUBROUTINE:     getPackages
    
    PURPOSE:

		RETURN ALL ENTRIES IN THE package TABLE
			
=cut

	#### GET USERNAME AND hubtype
	$self->logDebug("");
    my $username = $self->username();
	$self->logDebug("username", $username);
    my $hubtype = $self->hubtype();
	$self->logDebug("hubtype", $hubtype);

	#### GET INFO FOR EACH PACKAGE
	my $query = qq{
SELECT * FROM package
WHERE username='$username'};
	$self->logDebug("query", $query);
	my $packages = $self->db()->queryhasharray($query);
	$packages = $self->defaultPackages() if not defined $packages;
	$self->logDebug("BEFORE packages", $packages);
	
	#### SET USER LOGIN token
	my ($login, $token) = $self->setLoginCredentials($username, $hubtype, "private");
	$self->token($token);
	
	#### GET VERSIONS FOR ALL PACKAGES
	foreach my $package ( @$packages ) {
		$package->{current} = $self->getCurrentVersions($username, $package->{owner}, $package->{package}, $hubtype, $package->{privacy});
	}
	$self->logDebug("AFTER packages", $packages);
	
	return $packages;
}

method getCurrentVersions ($username, $owner, $repository, $hubtype, $privacy) {
	#### GET LOGIN AND TOKEN FOR USER IF STORED IN DATABASE
	$self->logDebug("owner", $owner);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	$self->logCritical("owner not defined") and exit if not defined $owner;
	$self->logCritical("owner is empty") and exit if not $owner;

	my $timeout = 5; # SECONDS
	$self->logDebug("doing getRemoteTagsTimeout    timeout: $timeout");
	#$self->logDebug("self->head()->ops", $self->head()->ops());
	
	my $tags = $self->head()->ops()->getRemoteTagsTimeout($owner, $repository, $timeout);
	$self->logDebug("tags", $tags);

	my $versions = [];
	foreach my $tag ( @$tags ) {
		push @$versions, $tag->{name};
	}
	$versions = $self->head()->ops()->sortVersions($versions);
	$self->logDebug("versions", $versions);

	@$versions = reverse @$versions;
	
	return $versions;
}

#### GET/SETTERS
method getPackage ($owner, $package, $installdir) {
	my $query = qq{SELECT * FROM package
WHERE owner='$owner'
AND installdir='$installdir'
AND package='$package'};
	$self->logDebug("query", $query);
	
	return $self->db()->queryhash($query);
}

method isPackage($username, $package) {
	return 1 if defined $self->getPackage($username, $package);
	return 0;
}

method setLoginCredentials ($username, $hubtype, $privacy) {
#### GET LOGIN AND TOKEN FOR USER IF STORED IN DATABASE
	$self->logCaller("");
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);
	$self->logDebug("privacy", $privacy);
	
	$privacy = "private" if not defined $privacy;
	$hubtype = $self->conf()->getKey("agua", "hubtype") if not defined $hubtype;
	$self->logCritical("hubtype not defined") and exit if not defined $hubtype;

	my $login = $self->login();
	my $token = $self->token();	
	$self->logDebug("login", $login);
	$self->logDebug("token", $token);

	if ( defined $login and defined $token and $privacy eq "private" ) {
		#### SET HEAD NODE OPS LOGIN AND CREDENTIALS
		$self->head()->ops()->login($login);
		$self->head()->ops()->token($token);
		$self->head()->ops()->setCredentials() if $privacy eq "private";

		$self->logDebug("returning login: $login and token: $token");		
		return ($login, $token)
	}

	if ( not defined $login or not defined $token ) {
		my $query = qq{SELECT login, token
FROM hub
WHERE username='$username'
AND hubtype='$hubtype'};
		$self->logDebug("query", $query);
		$self->logDebug("self->db()", $self->db());
		my $result = $self->db()->queryhash($query);
		$self->logDebug("result", $result);
		if ( defined $result )
		{
			$login = $result->{login} if not defined $login;
			$token = $result->{token} if not defined $token;
			if ( defined $login and $login
				and defined $token and $token ) {
				$self->login($login);
				$self->token($token);
	
				##### SET HEAD NODE OPS LOGIN AND CREDENTIALS
				$self->head()->ops()->login($login);
				$self->head()->ops()->token($token);
				$self->head()->ops()->setCredentials() if $privacy eq "private";
				
				$self->logDebug("returning login: $login and token: $token");
				return $login, $token;
			}
			else {
				return;
			}
		}
	}	
	return $login, $token;	
}

method setKeyfile ($username, $hubtype) {
	#### RETRIEVE keyfile FROM self->keyfile OR hub TABLE
	$self->logDebug("username", $username);
	$self->logDebug("hubtype", $hubtype);
	return $self->keyfile() if $self->keyfile();
	
	my $query = qq{SELECT keyfile FROM hub
WHERE username='$username'
AND hubtype='$hubtype'};
	$self->logDebug("query", $query);
	my $keyfile = $self->db()->query($query);
	$self->logDebug("keyfile", $keyfile);
	$self->keyfile($keyfile);
	
	return $keyfile;	
}

method setOpsDir ($owner, $opsrepo, $privacy, $package) {
=head2

	RETURN THE USER'S STANDARD *.ops FILE BASE DIRECTORY

		<Agua_installdir>/repos/<private|public>/<owner>/<opsrepo>/<owner>/<package>

		E.G.: /agua/repos/public/syoung/biorepository/syoung/bioapps

=cut
	$self->logError("type is neither public nor private") and exit if $privacy !~ /^(public|private)$/;
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
	my $opsdir = "$installdir/repos/$privacy/$owner/$opsrepo/$owner/$package";
	$self->logDebug("opsdir", $opsdir);
	File::Path::mkpath($opsdir);
	$self->logError("can't create opsdir: $opsdir") if not -d $opsdir;
	
	return $opsdir;
}

method setInstallDir ($username, $owner, $package, $privacy) {
=head2

	SUBROUTINE		setInstallDir
	
	PURPOSE
	
		RETURN THE STANDARD APPS DIRECTORY FOR THE USER:
		
			<userdir>/<username>/repos/<private|public>/<package>

			E.G.:

			/nethome/syoung/repos/private/syoung/private
			/nethome/syoung/repos/public/syoung/biorepository
			/nethome/syoung/repos/public/otherUser/otherApp

=cut

	$self->logDebug("privacy", $privacy);
	$self->logDebug("username", $username);
	$self->logDebug("owner", $owner);
	$self->logDebug("package", $package);
	$self->logDebug("type", $privacy);

	#### CHECK PRIVACY
	$self->logError("type is not public or private") and exit if $privacy !~ /^(public|private)$/;

	my $userdir = $self->conf()->getKey("agua", "USERDIR");
	my $reposubdir = $self->conf()->getKey("agua", "REPOSUBDIR");

	return "$userdir/$username/$reposubdir/$privacy/$package";
}

method setPackageDir ($username, $package, $privacy) {
	$self->logNote("username", $username);
	$self->logNote("package", $package);
	$self->logNote("type", $privacy);

	return $self->installdir() if $self->installdir();
	my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");

	return "$installdir/repos/$privacy/$username/$package";
}
1;



=head2

method updatePackageVersion ($username, $opsdir, $package, $installdir, $version, $build) {
	$self->logDebug("");
####	Installed version: 0.2, build: 00007
	my $now = $self->db()->now();
	my $query = qq{SELECT 1 FROM package
WHERE username = '$username'
AND opsdir='$opsdir'
AND package='$package'};
	$self->logDebug("query", $query);
	my $exists = $self->db()->query($query);
	if ( $exists ) {
		$query = qq{UPDATE package
SET version='$version',
build='$build',
datetime=$now
WHERE username = '$username'
AND opsdir='$opsdir'
AND package='$package'};
		$self->logDebug("query", $query);
		$self->db()->do($query);
	}
	else {
		my $now = $self->db()->now();
		$query = qq{INSERT INTO package
VALUES ('$username', '$package', '$version', '$build', '$opsdir', '$installdir', '$now)};
		$self->logDebug("query", $query);
		$self->db()->do($query);
	}
}



method removePackage {
=head2

    SUBROUTINE:     removePackage
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE A PACKAGE
		
#=cut

    	my $json			=	$self->json();

    my $username 	= $self->username();
	$self->logDebug("username", $username);

	#### PRIMARY KEYS FOR package TABLE: package, type, location
	my $data 		= $json->{data};
	my $package 	= $data->{package};
	my $version 	= $data->{version};
	$self->logDebug("package", $package);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ['package', 'version', 'opsdir', 'installdir'];	
	my $not_defined = $self->db()->notDefined($data, $required_fields);
	$self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### DELETE SOURCE
	my $query = qq{DELETE FROM package
WHERE username='$username'
AND version='$version'
AND package='$package'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	if ( $success == 1 )
	{
		$self->logStatus("Removed package $package");
	}
	else
	{
		$self->logError("Could not remove package $package");
	}
}




#	#$self->logDebug("data", $data);
#	my $username	=	$data->{username};
#	my $owner		=	$data->{owner};
#	my $package		=	$data->{package};
#	my $opsdir		=	$data->{opsdir};
#
#	#### CHECK REQUIRED FIELDS ARE DEFINED
#	my $required_fields = ['username', 'owner', 'package', 'version', 'installdir'];	
#	my $not_defined = $self->db()->notDefined($data, $required_fields);
#	$self->logError("undefined values: @$not_defined") and exit if @$not_defined;
#	
#	my $fields = $self->db()->fields('package');
#	$self->logDebug("fields: @$fields");
#
#	#### CHECK IF THIS ENTRY EXISTS ALREADY
#	my $query = qq{SELECT 1 FROM package
#WHERE username='$username'
#AND owner='$owner'
#AND opsdir='$opsdir'
#AND package='$package'};
#    $self->logDebug("$query");
#    my $already_exists = $self->db()->query($query);
#	my $now = $self->db()->now();
#	
#	#### UPDATE THE package TABLE ENTRY IF EXISTS ALREADY
#	if ( defined $already_exists )
#	{
#		#### UPDATE THE package TABLE
#		my $set = '';
#		foreach my $field ( @$fields )
#		{
#			if ( $field eq "datetime" ) {
#				$set .= "$field = $now,\n";
#			}
#			else {
#				$data->{$field} = '' if not defined $data->{$field};
#				$data->{$field} =~ s/'/"/g;
#				$set .= "$field = '$data->{$field}',\n";
#			}
#		}
#		$set =~ s/,\s*$//;
#		#$self->logDebug("set", $set);
#		
#		my $query = qq{UPDATE package
#SET $set
#WHERE username='$username'
#AND owner='$owner'
#AND opsdir='$opsdir'
#AND package='$package'};
#		$self->logDebug("query", $query);
#		
#		return $self->db()->do($query);
#	}
#	#### OTHERWISE, INSERT THE ENTRY
#	else
#	{
#		my $values = '';
#		foreach my $field ( @$fields )
#		{
#			if ( $field eq "datetime" ) {
#				$values .= "$now,\n";
#			}
#			else {
#				my $value = $data->{$field};
#				$value = '' if not defined $value;
#				$values .= "'$value',\n";
#			}
#		}
#		$values =~ s/,\s*$//;
#
#		my $query = qq{INSERT INTO package
#VALUES ($values) };
#		$self->logDebug("$query");
#
#		return $self->db()->do($query);


=cut