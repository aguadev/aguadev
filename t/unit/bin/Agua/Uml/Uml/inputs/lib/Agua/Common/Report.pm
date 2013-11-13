package Agua::Common::Report;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Report
	
	PURPOSE
	
		REPORT METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

##############################################################################
#				REPORT METHODS
##############################################################################
=head2

    SUBROUTINE     getReports
    
    PURPOSE
        
        RETURN AN ARRAY OF REPORT HASHES FOR THIS USER

sub getReports
{
    my $self        =   shift;
    $self->logDebug("Common::getReport()");
    
        my $json = $self->json();    

	#### VALIDATE USER USING SESSION ID	
	$self->logError("User not validated") and exit unless $self->validate();

	#### GET REPORTS    
    my $username = $json->{'username'};
    my $query = qq{SELECT * FROM report
WHERE username = '$username'};
    $self->logDebug("$query");
    my $reports = $self->db()->queryhasharray($query);    
    $self->logDebug("reports", $reports);
    $self->logDebug("reports", $reports);

	$reports = [] if not defined $reports;
    $self->logDebug("reports", $reports);
	
	return $reports;
}

=cut


=head2

    SUBROUTINE     updateReport
    
	PURPOSE

		ADD A REPORT TO THE report TABLE

=cut

sub updateReport {
	my $self		=	shift;
    my $json 			=	$self->json();

 	$self->logDebug("");

	#### REMOVE IF EXISTS ALREADY
	my $success = $self->_removeReport();
 	$self->logError("{ error: 'Could not remove report $json->{name} from report table") and exit if not defined $success and not $success;
 	
	$success = $self->_addReport();	
 	$self->logError("{ error: 'Could not update report $json->{name} to report table") and exit if not defined $success;
 	$self->logDebug("{ status: 'Updated report $json->{name} in report table");
}


=head2

    SUBROUTINE     addReport
    
	PURPOSE

		ADD A REPORT TO THE report TABLE

=cut

sub addReport {
	my $self		=	shift;
 	$self->logDebug("Common::addReport()");
    
    my $json 			=	$self->json();

	#### DO THE ADD
	my $success = $self->_addReport();
	
 	$self->logError("Could not add $json->{name} to workflow $json->{workflow}") and exit if not defined $success;
 	$self->logStatus("Added $json->{name} to workflow $json->{workflow}");
}




=head2

    SUBROUTINE     removeReport
    
	PURPOSE

		REMOVE A REPORT FROM THE report TABLE
        	
=cut

sub removeReport {
	my $self		=	shift;
    my $json 			=	$self->json();
    
	#### DO THE REMOVE
	my $success = $self->_removeReport();
	
 	$self->logError("Could not remove $json->{name} from workflow $json->{workflow}") and exit if not defined $success;
 	$self->logStatus("Removed $json->{name} from workflow $json->{workflow}");
}



=head2

    SUBROUTINE     _addReport
    
	PURPOSE

		ADD A REPORT TO THE report TABLE

=cut

sub _addReport {
	my $self		=	shift;
        my $cgi 			=	$self->cgi();
    my $json 			=	$self->json();

 	$self->logDebug("Common::_addReport()");

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "report";
	my $required_fields = ["username", "project", "workflow", "appname", "appnumber", "name"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	 	
	#### LATER: FIX THIS SO THAT THE DATE IS ADDED PROPERLY 
	$json->{datetime} = "NOW()";
	if ( $self->conf()->getKey('agua', 'DBTYPE') eq "SQLite" )
	{
		$json->{datetime} = "DATETIME('NOW');";
	}

	#### DO THE ADD
	return $self->_addToTable($table, $json, $required_fields);	
}



=head2

    SUBROUTINE     _removeReport
    
	PURPOSE

		REMOVE A REPORT FROM THE report TABLE
        	
=cut

sub _removeReport {
	my $self		=	shift;
        my $cgi 			=	$self->cgi();
    my $json 			=	$self->json();

 	$self->logDebug("Common::_removeReport()");

	#### SET TABLE AND REQUIRED FIELDS	
	my $table = "report";
	my $required_fields = ["username", "project", "workflow", "appname", "appnumber", "name"];

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($json, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;
	
	#### DO THE REMOVE
	return $self->_removeFromTable($table, $json, $required_fields);
}



1;