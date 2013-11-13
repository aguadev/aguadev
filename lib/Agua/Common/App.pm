package Agua::Common::App;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::App
	
	PURPOSE
	
		APPLICATION METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

sub getAppHeadings {
	my $self		=	shift;

    	my $json			=	$self->json();

	$self->logDebug("");

	#### VALIDATE    
    my $username = $json->{username};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### CHECK REQUESTOR
	print qq{ error: 'Agua::Common::App::getHeadings    Access denied to requestor: $json->{requestor}' } if defined $json->{requestor};
	
	my $headings = {
		leftPane => ["Parameters", "Packages"],
		middlePane => ["Parameters", "Modules", "App"],
		rightPane => ["App", "Packages", "Parameters"]
	};
	$self->logDebug("headings", $headings);
	
    return $headings;
}


sub getApps {
	my $self		=	shift;
	
    my $username	= 	$self->username();
	my $agua 		= 	$self->conf()->getKey("agua", "AGUAUSER");
	
    my $query = qq{SELECT * FROM app
WHERE owner = '$username'
OR owner='$agua'
ORDER BY owner, package, type, name};
	$self->logDebug("query", $query);
    my $apps = $self->db()->queryhasharray($query) || [];

	if ( not $self->isAdminUser($username)) {
		my $adminapps = $self->getAdminApps();
		@$apps = (@$apps, @$adminapps);
	}
	
	return $apps;
}

sub getAdminApps {
#### GET ONLY 'PUBLIC' APPS OWNED BY ADMIN USER
	my $self		=	shift;
	$self->logDebug("");

	#### GET ADMIN USER'S PUBLIC APPS
	my $admin = $self->conf()->getKey("agua", 'ADMINUSER');
	my $query = qq{SELECT app.* FROM app, package
WHERE app.owner = '$admin'
AND app.owner = package.username
AND package.privacy='public'
ORDER BY package, type, name};
    my $adminapps = $self->db()->queryhasharray($query) || [];
	$self->logDebug("adminapps", $adminapps);
	
	return $adminapps;
}

sub deleteApp {
=head2

    SUBROUTINE:     deleteApp
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE AN APPLICATION
		
=cut

	my $self		=	shift;

	my $data = $self->json()->{data};
	$data->{owner} = $self->json()->{username};
	$self->logDebug("data", $data);

	my $success = $self->_removeApp($data);
	return if not defined $success;

	$self->logStatus("Deleted application $data->{name}") if $success;
	$self->logError("Could not delete application $data->{name} from the apps table") if not $success;
	return;
}

sub _removeApp {
	my $self		=	shift;
	my $data		=	shift;

	my $table = "app";
	my $required = ["owner", "package", "name", "type"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### REMOVE
	return $self->_removeFromTable($table, $data, $required);
}

sub saveApp {
=head2

    SUBROUTINE:     saveApp
    
    PURPOSE:

        SAVE APPLICATION INFORMATION
		
=cut

	my $self		=	shift;

	#### VALIDATE    
    my $username = $self->username();
	$self->logError("User $username not validated") and return unless $self->validate($username);
	
	#### GET DATA FOR PRIMARY KEYS FOR apps TABLE:
	####    name, type, location
	my $json		=	$self->json();
	$self->logDebug("json", $json);
	my $data = $json->{data};
	my $name = $data->{name};
	my $type = $data->{type};
	my $location = $data->{location};
	$self->logDebug("name", $name);
	$self->logDebug("type", $type);
	$self->logDebug("location", $location);
	
	#### CHECK INPUTS
	$self->logError("Name $name not defined or empty") and return if not defined $name or $name =~ /^\s*$/;
	$self->logError("Name $type not defined or empty") and return if not defined $type or $type =~ /^\s*$/;
	$self->logError("Name $location not defined or empty") and return if not defined $location or $location =~ /^\s*$/;
	
	my $success	=	$self->_saveApp($data);
	$self->logDebug("success", $success);
	$self->logError("Could not insert application $name into app table ") and return if not $success;

	$self->logStatus("Inserted application $name into app table");
	return;
}

sub _saveApp {
	my $self		= 	shift;
	my $data		=	shift;
	$self->logDebug("data", $data);
		
	#### GET APP IF ALREADY EXISTS
	my $table = "app";
	my $fields = ["owner", "package", "name", "type"];
	my $where = $self->db()->where($data, $fields);
	my $query = qq{SELECT * FROM $table $where};
	$self->logDebug("query", $query);
	my $app = $self->db()->queryhash($query);
	$self->logDebug("app", $app);
	
	#### REMOVE APP IF EXISTS
	if ( defined $app ) {
		$self->_removeApp($data);

		#### ... AND COPY OVER DATA ONTO APP
		foreach my $key ( keys %$data ) {
			$app->{$key} = $data->{$key};
		}
		$self->logDebug("app", $app);		

		#### ADD APP MODIFIED WITH DATA
		my $success = $self->_addApp($app);
		return if not defined $success;
	}
	
	#### ADD DATA
	return $self->_addApp($data);
}

sub _addApp {
	my $self		=	shift;
	my $data		=	shift;
	$self->logNote("data", $data);
	
	my $owner 	=	$data->{owner};
	my $name 	=	$data->{name};

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $table = "app";
	my $required_fields = ["owner", "package", "name", "type"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
		
	#### DO ADD
	return $self->_addToTable($table, $data, $required_fields);	
}

sub saveParameter {
=head2

    SUBROUTINE:     saveParameter
    
    PURPOSE:

        VALIDATE THE admin USER THEN SAVE APPLICATION INFORMATION
		
=cut

	my $self		=	shift;
	$self->logDebug("Admin::saveParameter()");

    	my $json			=	$self->json();

	#### GET DATA FOR PRIMARY KEYS FOR parameters TABLE:
    my $username 	= 	$json->{username};
	my $data 		= 	$json->{data};
	my $appname 	= 	$data->{appname};
	my $name 		= 	$data->{name};
	my $paramtype 	= 	$data->{paramtype};

	#### SET owner AS USERNAME IN data
	$data->{owner} = $username;
	
	#### CHECK INPUTS
	$self->logError("appname not defined or empty") and return if not defined $appname or $appname =~ /^\s*$/;
	$self->logError("name not defined or empty") and return if not defined $name or $name =~ /^\s*$/;
	$self->logError("paramtype not defined or empty") and return if not defined $paramtype or $paramtype =~ /^\s*$/;
	
	$self->logDebug("name", $name);
	$self->logDebug("paramtype", $paramtype);
	$self->logDebug("appname", $appname);

	my $success = $self->_addParameter($data); 
	if ( $success != 1 ) {
		$self->logError("Could not insert parameter $name into app $appname");
	}
	else {
		$self->logStatus("Inserted parameter $name into app $appname");
	}

	return;
}

sub _addParameter {
	my $self		=	shift;
	my $data		=	shift;

	my $username	=	$data->{username};
	my $appname		=	$data->{appname};
	my $name		=	$data->{name};

	my $table = "parameter";
	my $required = ["owner", "appname", "name", "paramtype", "ordinal"];
	my $updates = ["version", "status"];

	#### REMOVE IF EXISTS ALREADY
	my $success = $self->_removeFromTable($table, $data, $required);
	$self->logNote("Deleted app success") if $success;
		
	#### INSERT
	my $fields = $self->db()->fields('parameter');
	my $insert = $self->db()->insert($data, $fields);
	my $query = qq{INSERT INTO $table VALUES ($insert)};
	$self->logNote("query", $query);	
	return $self->db()->do($query);
}

sub deleteParameter {
=head2

    SUBROUTINE:     deleteParameter
    
    PURPOSE:

        VALIDATE THE admin USER THEN DELETE AN APPLICATION
		
=cut

	my $self		=	shift;
	
	#### GET DATA 
	my $json			=	$self->json();
	my $data = $json->{data};

	#### REMOVE
	my $success = $self->_removeParameter($data);
	$self->logStatus("Deleted parameter $data->{name}") and return if defined $success and $success;

	$self->logError("Could not delete parameter $data->{name}");
	return;
}

sub _removeParameter {
	my $self		=	shift;
	my $data		=	shift;
	$self->logDebug("data", $data);
	
	my $table = "parameter";
	my $required_fields = ["owner", "name", "appname", "paramtype"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
	#### REMOVE IF EXISTS ALREADY
	$self->_removeFromTable($table, $data, $required_fields);
}




1;