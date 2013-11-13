package Agua::Common::App;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::App
	
	PURPOSE
	
		APPLICATION METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

sub getApps {
=head2

    SUBROUTINE:     getApps
    
    PURPOSE:

        RETURN A JSON LIST OF THE APPLICATIONS IN THE apps TABLE

=cut

	my $self		=	shift;
	
    my $username;
	$username = $self->json()->{username} if defined $self->json();
    $username = $self->username() if not defined $username;

	#### GET USER'S OWN APPS	
    my $query = qq{SELECT * FROM app
WHERE owner = '$username'
ORDER BY type,name};
	$self->logDebug("query", $query);
    my $apps = $self->db()->queryhasharray($query);
	
	$apps = [] if not defined $apps;
	
	return $apps;
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

    	my $json			=	$self->json();
	$self->logDebug("json", $json);
	
	#### GET DATA FOR PRIMARY KEYS FOR apps TABLE:
	####    name, type, location
	my $data = $json->{data};
	my $name = $data->{name};
	my $type = $data->{type};
	my $location = $data->{location};
	
	#### CHECK INPUTS
	$self->logError("Name $name not defined or empty") and return if not defined $name or $name =~ /^\s*$/;
	$self->logError("Name $type not defined or empty") and return if not defined $type or $type =~ /^\s*$/;
	$self->logError("Name $location not defined or empty") and return if not defined $location or $location =~ /^\s*$/;
		
	$self->logDebug("name", $name);
	$self->logDebug("type", $type);
	$self->logDebug("location", $location);

	#### SET owner AS USERNAME
	$data->{owner} = $json->{username};
	
	#### EXIT IF ONE OR MORE PRIMARY KEYS IS MISSING	
	$self->logError("Either name, type or location not defined") and return if not defined $name or not defined $type or not defined $location;

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
	}
	
	#### ADD
	my $success = $self->_addApp($app);
	$self->logDebug("success", $success);
	$self->logError("Could not insert application $name into app table ") and return if not $success;

	$self->logStatus("Inserted application $name into app table");
	return;
}


sub _addApp {
	my $self		=	shift;
	my $data		=	shift;
	$self->logNote("data", $data);
	
	my $owner 	=	$data->{owner};
	my $name 	=	$data->{name};

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $table = "app";
	my $required_fields = ["owner", "package", "installdir", "name", "type"];
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
		
	my $table = "parameter";
	my $required_fields = ["owner", "name", "appname", "paramtype"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;
	
	#### REMOVE IF EXISTS ALREADY
	$self->_removeFromTable($table, $data, $required_fields);
}


1;