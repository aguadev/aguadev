package Agua::Common::Stage;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Stage
	
	PURPOSE
	
		STAGE METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

=head2

	SUBROUTINE		updateStage
	
	PURPOSE

		ADD A STAGE TO THE stage TABLE

	INPUTS
	
		1. STAGE IDENTIFICATION - PROJECT, WORKFLOW, STAGE AND STAGE NUMBER
		
		2. INFORMATION FOR RUNNING THE STAGE (name, location, etc.)
		
	OUTPUTS
	
		1. A NEW ENTRY IN THE stage TABLE
		
	NOTES
	
		THE PARAMETERS FOR THIS STAGE ARE ADDED TO THE stageparameter TABLE

		IN A SEPARATE CALL TO THE $self->addParameters() SUBROUTINE

=cut

sub updateStage {
	my $self		=	shift;
        my $json 			=	$self->json();

 	$self->logDebug("Common::updateStage()");

	#### DO ADD STAGE WITH NEW NUMBER
	my $old_number = $json->{number};
	$json->{number} = $json->{newnumber};

	#### DO REMOVE STAGE WITH OLD NUMBER
	my $success = $self->_removeStage($json);
	$self->logStatus("Successfully removed stage $json->{name} from stage table") if $success;
	$self->logError("Could not remove stage $json->{name} from stage table") if not $success;
	
	$success = $self->_addStage($json);
	$self->logStatus("Successfully added stage $json->{name} into stage table") if $success;
	$self->logStatus("Could not add stage $json->{name} into stage table") if not $success;

	#### UPDATE THE APPNUMBER FIELD FOR ALL STAGE PARAMETERS
	#### BELONGING TO THIS PROJECT, WORKFLOW, APPNAME AND APPNUMBER
	#### NB: USE OLD NUMBER
	$json->{appnumber} = $old_number;
	$json->{appname} = $json->{name};
	my $unique_keys = ["username", "project", "workflow", "appname", "appnumber"];
	my $where = $self->db()->where($json, $unique_keys);
	my $query = qq{UPDATE stageparameter
SET appnumber='$json->{newnumber}'
$where};
	$self->logDebug("query", $query);
	$success = $self->db()->do($query);
	$self->logDebug("success", $success);
	
	$self->logStatus("Successful update of appnumber to $json->{newnumber} in stageparameter table") if $success;
	$self->logStatus("Could not update appnumber to $json->{newnumber} in stageparameter table") if not $success;
}

sub getStages {
=head2

    SUBROUTINE:     getStages
    
    PURPOSE:

        GET ARRAY OF HASHES:
		
			[
				appname1: [ s ], appname2 : [...], ...  ] 

=cut

	my $self		=	shift;
	my $json		=	shift;
	$self->logDebug("");

	#### SET OWNER 
    $json	=	$self->json() if not defined $json;	
	my $owner = $json->{username};
	$self->logDebug("owner", $owner);

    #### VALIDATE    
    $self->logError("User session not validated") and exit unless $self->validate();

	my $query = qq{SELECT * FROM stage
WHERE username='$owner'\n};
	$query .= qq{AND project='$json->{project}'\n} if defined $json->{project};
	$query .= qq{AND workflow='$json->{workflow}'\n} if defined $json->{workflow};
	$query .= qq{ORDER BY project, workflow, number};
	$self->logDebug("$query");
	my $stages = $self->db()->queryhasharray($query);
	$stages = [] if not defined $stages;
	#$self->logNote("stages", $stages);
	
	return $stages;
}

sub getStagesByWorkflow {
	my $self			=	shift;
	my $workflowobject	=	shift;
	$self->logDebug("workflowobject", $workflowobject);

	my $required = ["username", "project", "workflow"];
	my $where = $self->db()->where($workflowobject, $required);
	my $query = qq{SELECT * FROM stage
$where};
	#$self->logDebug("$query");

	my $stages = $self->db()->queryhasharray($query);
	$stages = [] if not defined $stages;
	#$self->logDebug("stages", $stages);

	return $stages;
}



sub addStage {
=head2

	SUBROUTINE		addStage
	
	PURPOSE

		ADD A STAGE TO THE stage TABLE

	INPUTS
	
		1. STAGE IDENTIFICATION - PROJECT, WORKFLOW, STAGE AND STAGE NUMBER
		
		2. INFORMATION FOR RUNNING THE STAGE (name, location, etc.)
		
	OUTPUTS
	
		1. A NEW ENTRY IN THE stage TABLE
		
	NOTES
	
		NB: THE PARAMETERS FOR THIS STAGE ARE ADDED TO THE stageparameter TABLE

		IN A SEPARATE CALL TO THE $self->addParameters() SUBROUTINE

=cut

	my $self		=	shift;
 	$self->logDebug("Common::addStage()");

    my $json 			=	$self->json();
	
	my $success = $self->_removeStage($json);
	$success = $self->_addStage($json);
	$self->logStatus("Added stage $json->{name} to workflow $json->{workflow}") if $success;
}

sub updateStageSubmit {
	my $self		=	shift;
 	$self->logDebug("Common::updateStageSubmit()");
    my $json 			=	$self->json();
	my $submit		=	$json->{submit};
	my $username	=	$json->{username};
	my $project		=	$json->{project};
	my $workflow	=	$json->{workflow};
	my $workflownumber	=	$json->{workflownumber};
	my $name		=	$json->{name};
	my $number		=	$json->{number};
	my $query = qq{UPDATE stage
SET submit='$submit'
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'
AND workflownumber='$workflownumber'
AND number='$number'};
	$self->logDebug("$query");
	my $success = $self->db()->do($query);
	$self->logError("Failed to update workflow $json->{workflow} stage $json->{number} submit: $submit'") if not defined $success or not $success;
	$self->logStatus("Updated workflow $json->{workflow} stage $json->{number} submit: $submit") if $success;
}


sub insertStage {
=head2

	SUBROUTINE		insertStage
	
	PURPOSE

		INSERT A STAGE AT A CHOSEN POSITION IN LIST OF STAGES

	INPUTS
	
		1. STAGE OBJECT CONTAINING FIELDS: project, workflow, name, number
		
		2. INFORMATION FOR RUNNING THE STAGE (name, location, etc.)
		
	OUTPUTS
	
		1. A NEW ENTRY IN THE stage TABLE
		
	NOTES
	
		NB: THE PARAMETERS FOR THIS STAGE ARE ADDED TO THE stageparameter TABLE

		IN A SEPARATE CALL TO THE $self->addParameters() SUBROUTINE

=cut

	my $self		=	shift;
        my $json 			=	$self->json();

 	$self->logDebug("Common::insertStage()");
 	$self->logDebug("json", $json);
	
	#### GET THE STAGES BELONGING TO THIS WORKFLOW
	my $where_fields = ["username", "project", "workflow"];
	my $where = $self->db()->where($json, $where_fields);
	my $query = qq{SELECT * FROM stage
$where};
	$self->logDebug("query", $query);
	my $stages = $self->db()->queryhasharray($query);
	$self->logDebug("stages", $stages);
	
	#### GET THE STAGE NUMBER 
	my $number = $json->{number};
	$self->logDebug("number", $number);

	#### CHECK IF REQUIRED FIELDS ARE DEFINED
	my $required_fields = ["username", "owner", "project", "workflow", "name", "number"];
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### JUST ADD THE STAGE AND ITS PARAMETERS TO stage AND stageparameters
	#### IF THERE ARE NO EXISTING STAGES FOR THIS WORKFLOW
	if ( not defined $stages or scalar(@$stages) == 0 )
	{
		my $success = $self->_addStage($json);
		$self->logError("Could not insert stage $json->{name} into workflow $json->{workflow}") and exit if not $success;
		
		$success = $self->addParameters();
		$self->logError("Could not insert stage $json->{name} into workflow $json->{workflow}") and exit if not $success;
		$self->logStatus("Inserted stage $json->{name} into workflow $json->{workflow}") if $success;
	}

	#### INCREMENT THE number FOR DOWNSTREAM STAGES IN THE stage TABLE
	for ( my $i = @$stages - 1; $i > $number - 2; $i-- )
	{
		my $stage = $$stages[$i];
		my $new_number = $i + 2;
		my $where_fields = ["username", "project", "workflow", "number"];
		my $where = $self->db()->where($stage, $where_fields);
		my $query = qq{UPDATE stage SET
number='$new_number'
$where};
		$self->logDebug("query", $query);
		my $success = $self->db()->do($query);
		$self->logDebug("success", $success);
	}
	
	#### INCREMENT THE appnumber FOR DOWNSTREAM STAGES IN THE stageparameter TABLE
	for ( my $i = @$stages - 1; $i > $number - 2; $i-- )
	{
		my $stage = $$stages[$i];
		$stage->{appnumber} = $stage->{number};
		my $new_number = $i + 2;
		my $where_fields = ["username", "project", "workflow", "appnumber"];
		my $where = $self->db()->where($stage, $where_fields);
		my $query = qq{UPDATE stageparameter SET
appnumber='$new_number'
$where};
		$self->logDebug("query", $query);
		my $success = $self->db()->do($query);
		$self->logDebug("success", $success);
	}

	my $success = $self->_addStage($json);
	$self->logError("Could not insert stage $json->{name} into stage table") and exit if not $success;	
	$success = $self->addParameters();
	$self->logError("Could not insert stage $json->{name} into workflow $json->{workflow}") and exit if not $success;	
 	$self->logStatus("Inserted stage $json->{name} into workflow $json->{workflow}") if $success;
}

sub _addStage {
=head2

	SUBROUTINE		_addStage
	
	PURPOSE

		INTERNAL USE ONLY: ATOMIC ADDITION OF A STAGE TO THE stage TABLE
        
=cut

	my $self		=	shift;
	my $data		=	shift;
 	$self->logDebug("data", $data);	
	
	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "stage";
	my $required_fields = ["username", "owner", "project", "workflow", "workflownumber", "name", "number", "type"];
	
	my $inserted_fields = $self->db()->fields($table);

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### DO ADD
 	$self->logDebug("Doing _addToTable(table, data, required_fields)");
	my $success = $self->_addToTable($table, $data, $required_fields, $inserted_fields);	
 	$self->logDebug("_addToTable(stagedata) success", $success);
	
	#### ADD IT TO THE report TABLE IF ITS A REPORT
 	$self->logDebug("data->{type}", $data->{type});
	if ( $success and defined $data->{type} and $data->{type} eq "report" )
	{
		$data->{appname} = $data->{name};
		$self->data($data);
		
		$success = $self->_addReport();
	 	$self->logDebug("_addStage() success", $success);
	}
	
	return $success;
}

sub _removeStage {
=head2

	SUBROUTINE		_removeStage
	
	PURPOSE

		SAVE THE JSON (INPUTS, OUTPUTS AND ARGUMENTS) FOR EACH
        
        APPLICATION IN THE WORKFLOW, SENT AS A JSON STRING
      
=cut

	my $self		=	shift;
	my $data		=	shift;
 	$self->logDebug("data", $data);

	#### CHECK UNIQUE FIELDS ARE DEFINED
	#### NB: ALSO CHECK name THOUGH NOT NECCESSARY FOR UNIQUE ID
	#### NNB: type IS NEEDED TO IDENTIFY IF ITS A REPORT
	my $required_fields = ["username", "project", "workflow", "number", "name", "type"];
	my $not_defined = $self->db()->notDefined($data, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	my $table = "stage";
	my $success = $self->_removeFromTable($table, $data, $required_fields);
	
	#### REMOVE IT FROM THE report TABLE TOO IF ITS A REPORT
	if ( $success and defined $data->{type} and $data->{type} eq "report" )
	{
		$data->{appname} = $data->{name};
		$data->{appnumber} = $data->{number};
		$self->data($data);
		
		$success = $self->_removeReport();
	}
	
	return $success;
}

sub removeStage {
=head2

	SUBROUTINE		removeStage
	
	PURPOSE

		REMOVE STAGE FROM this.stages
        
        REMOVE ASSOCIATED STAGE PARAMETER ENTRIES FROM this.stageparameter
      
=cut

	my $self		=	shift;
 	$self->logDebug("Common::removeStage()");

        my $json 			=	$self->json();

 	$self->logDebug("json", $json);
	
	#### GET THE STAGES BELONGING TO THIS WORKFLOW
	my $where_fields = ["username", "project", "workflow"];
	my $where = $self->db()->where($json, $where_fields);
	my $query = qq{SELECT * FROM stage
$where};
	$self->logDebug("query", $query);
	my $stages = $self->db()->queryhasharray($query);
	if ( not defined $stages or scalar(@$stages) == 0 )
	{
	 	$self->logError("{ error: 'Agua::Common::Stage::removeStage    No stages in this workflow $json->{workflow} ") and exit;
	}
	
#	#### GET THE STAGE PARAMETERS BELONGING TO THIS WORKFLOW
#	$query = qq{SELECT * FROM stageparameter
#$where};
#	$self->logDebug("query", $query);
#	my $stageparameters = $self->db()->queryhasharray($query);
#	if ( not defined $stageparameters or scalar(@$stageparameters) == 0 )
#	{
#	 	$self->logError("{ error: 'Agua::Common::Stage::removeStage    No stageparameters in this workflow $json->{workflow} ") and exit;
#	}

	#### REMOVE STAGE FROM stage TABLE
	my $success = $self->_removeStage($json);
 	$self->logError("{ error: 'Agua::Common::Stage::removeStage    Could not delete stage $json->{name} from stage table") and exit if not defined $success;
	
	#### REMOVE STAGE FROM stageparameter TABLE
	my $table2 = "stageparameter";
	$json->{appname} = $json->{name};
	$json->{appnumber} = $json->{number};
	my $required_fields2 = ["username", "project", "workflow", "appname", "appnumber"];
	$success = $self->_removeFromTable($table2, $json, $required_fields2);
 	$self->logError("{ error: 'Agua::Common::Stage::removeStage    Could not remove stage $json->{name} from $table2 table") and exit if not defined $success;

	#### QUIT IF THIS WAS THE LAST STAGE IN THE WORKFLOW
	my $number = $json->{number};
	if ( $number > scalar(@$stages) )
	{
	 	$self->logStatus("Removed stage $json->{name} from workflow $json->{workflow} ");
		return;
	}

	#### OTHERWISE, DECREMENT THE number FOR DOWNSTREAM STAGES IN THE stage TABLE
	for ( my $i = $number; $i < @$stages; $i++ )
	{
		my $stage = $$stages[$i];
		
		my $where_fields = ["username", "project", "workflow", "number"];
		my $where = $self->db()->where($stage, $where_fields);
		my $query = qq{UPDATE stage SET
number='$i'
$where};
		$self->logDebug("query", $query);
		my $success = $self->db()->do($query);
		$self->logDebug("success", $success);

		#### UPDATE report TABLE IF ITS A REPORT
		if ( $stage->{type} eq "report" )
		{
			$stage->{appname} = $stage->{name};
			$stage->{appnumber} = $stage->{number};
			my $where_fields = ["username", "project", "workflow", "appname", "appnumber"];
			my $where = $self->db()->where($stage, $where_fields);
			
			my $query = qq{UPDATE report SET
appnumber='$i'
$where};
			$self->logDebug("'update report' query", $query);
			my $success = $self->db()->do($query);
			$self->logDebug("'update report' success", $success);
			
		}
	}
	
	#### DECREMENT THE appnumber FOR DOWNSTREAM STAGES IN THE stageparameter TABLE
	for ( my $i = $number; $i < @$stages; $i++ )
	{
		my $stage = $$stages[$i];
		$stage->{appnumber} = $stage->{number};
		
		my $where_fields = ["username", "project", "workflow", "appnumber"];
		my $where = $self->db()->where($stage, $where_fields);
		my $query = qq{UPDATE stageparameter SET
appnumber='$i'
$where};
		$self->logDebug("query", $query);
		my $success = $self->db()->do($query);
		$self->logDebug("update stage number to $i, success", $success);
	}

 	$self->logStatus("Removed stage $json->{name} from workflow $json->{workflow}");
}



1;