package Agua::Common::Package::Default;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

=head2

	PACKAGE		Agua::Common::Package
	
	PURPOSE
	
		INSTALL/UPGRADE/REMOVE PACKAGES AND UPDATE package TABLE

=cut

#### DEFAULT WORKFLOW AND APP PACKAGES
method defaultPackages {
=head2

    SUBROUTINE:     defaultPackages
    
    PURPOSE:

        1. INSTALL THE DEFAULT PACKAGES FOR ALL USERS 

		2. FOR ADMIN USER, INSTALL THE ADMIN-ONLY DEFAULT PACKAGES

=cut

    my $username 	= $self->username();
	$self->logDebug("username", $username);

	#### ADD GENERAL PACKAGES TO package TABLE
	my $data 	=	{};
	$data->{owner} 		= 	$username;
	$data->{username} 	= 	$username;
	$data->{version} 	= 	"0.1.0";
	$data->{status} 	= 	"ready";

	### SET PUBLIC OPSREPO
	$self->setPublicOpsRepo($data);

	#### SET PRIVATE OPSREPO
	$self->setPrivateOpsRepo($data);
	
	#### SET PRIVATE WORKFLOWS
	$self->setPrivateWorkflows($data);
	
	#### SET PUBLIC WORKFLOWS
	$self->setPublicWorkflows($data);

	#### RETURN IF NOT ADMIN USER	
	my $admin = $self->conf()->getKey("agua", "ADMINUSER");
	$self->logDebug("admin", $admin);
	return if not $username eq $admin;

	#### ADD PACKAGES FOR ADMIN USER
	#### SET  bioapps
	$self->setBioApps($data);
	
	#### SET agua
	$self->setAgua($data);	
}

method setPublicOpsRepo ($data) {
	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	my $username = $data->{username};
	my $privacy = "public";
	$data->{package} 	=	$opsrepo;
	$data->{opsdir} 	= 	$self->setOpsDir($username, $opsrepo, $privacy, $opsrepo);
	$data->{installdir} = 	$self->setInstallDir($username, $username, $opsrepo, $privacy);
	$self->_addPackage($data);
}

method setPrivateOpsRepo ($data) {
	my $opsrepo = $self->conf()->getKey("agua", "PRIVATEOPSREPO");
	my $username = $data->{username};
	my $privacy = "private";
	$data->{package} 	=	$opsrepo;
	$data->{opsdir} 	= 	$self->setOpsDir($username, $opsrepo, $privacy, $opsrepo);
	$data->{installdir} = 	$self->setInstallDir($username, $username, $opsrepo, $privacy);
	$self->_addPackage($data);
}

method setPrivateApps ($data) {
	return $self->setApps($data, "private");
}

method setPublicApps ($data) {
	return $self->setApps($data, "public");
}

method setApps ($data, $privacy) {
	my $username = $data->{username};
	$data->{package} 	=	"apps";
	$data = $self->setPackageData($data, $username, $username, "apps", $privacy);
	$self->_addPackage($data);
}	

method setBioApps ($data) {
	#### ADD bioapps
	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	my $author = $self->conf()->getKey('bioapps', "AUTHOR");
	$data->{package} 	=	"bioapps";
	$data->{owner} 		= 	$author;
	$data->{opsdir} 	= 	$self->setOpsDir($author, $opsrepo, "public", "bioapps");
	$data->{version} 	= 	$self->conf()->getKey('bioapps', "VERSION");	
	$data->{installdir} = 	$self->conf()->getKey('bioapps', "INSTALLDIR");
	$self->logDebug("data", $data);

	return $self->_setBioApps($data);
}

method _setBioApps ($data) {
	$self->logDebug("data", $data);
	$self->_addPackage($data);
}

method setAgua ($data) {
	#### ADD agua
	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	my $author = $self->conf()->getKey('agua', "AUTHOR");
	$data->{package} 	=	"agua";
	$data->{owner} 		= 	$author;
	$data->{opsdir} 	= 	$self->setOpsDir($author, $opsrepo, "public", "agua");
	$data->{version} 	= 	$self->conf()->getKey('agua', "VERSION");	
	$data->{installdir} = 	$self->conf()->getKey('agua', "INSTALLDIR");
	$self->logDebug("data", $data);
		
	return $self->_setAgua($data);
}

method _setAgua ($data) {
	$self->logDebug("data", $data);
	return $self->_addPackage($data);
}

method setPackageData($data, $username, $owner, $package, $discretion) {
	#### ADD PUBLIC AND PRIVATE apps
	my $opsrepo = $self->conf()->getKey("agua", "OPSREPO");
	$data->{owner} 		= 	$owner;
	$data->{package} 	=	$package;
	$data->{opsdir} 	= 	$self->setOpsDir($username, $opsrepo, $discretion, $package);
	$data->{installdir} = 	$self->setInstallDir($username, $username, $package, $discretion);

	$self->logDebug("data", $data);
	return $data;
}

method addPackage () {
    my $username 	= 	$self->username();
	my $json		=	$self->json();
	$self->logDebug("username", $username);

	#### PRIMARY KEYS FOR package TABLE: package, type, location
	my $data 		= $json->{data};
	my $package 	= $data->{package};
	my $version 	= $data->{version};
	$self->logDebug("data", $data);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $required_fields = ['package', 'version', 'opsdir', 'installdir'];	
	my $not_defined = $self->db()->notDefined($data, $required_fields);
	$self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### ADD DATA
	my $success = $self->_addPackage($data);
	$self->logStatus("Could not add package $package") and exit if not $success;
 	$self->logStatus("Added package $package") if $success;
}

method _addPackage ($data) {
=head2

    SUBROUTINE:     _addPackage
    
    PURPOSE:

		ADD AN ENTRY TO THE PACKAGE TABLE OR UPDATE IF EXISTS
		
=cut
	my $table = "package";
	my $required_fields = ['owner', 'username', 'package', 'version', 'opsdir', 'installdir'];
	my $where = $self->db()->where($data, $required_fields);
	
	return $self->_addToTable($table, $data, $required_fields);
}

method removePackage {
=head2

    SUBROUTINE:     removePackage
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE A PACKAGE
		
=cut

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

1;

