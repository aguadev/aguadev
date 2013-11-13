package Agua::Common::Admin;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Admin
	
	PURPOSE
	
		ADMIN METHODS FOR Agua::Common
		
=cut
use Data::Dumper;

=head2

    SUBROUTINE		getHeadings
    
    PURPOSE

        VALIDATE THE USER, DETERIMINE IF THEY ARE THE
		
		ADMIN USER, THEN SEND THE APPROPRIATE LIST OF
		
		ADMIN PANES
		
=cut

sub getAdminHeadings {
	my $self		=	shift;

    	my $json			=	$self->json();

	$self->logDebug("");

	#### VALIDATE    
    my $username = $json->{username};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### CHECK REQUESTOR
	print qq{ error: 'Agua::Common::Admin::getHeadings    Access denied to requestor: $json->{requestor}' } if defined $json->{requestor};
	
	my $headings = {
		leftPane => ["Packages", "Parameters", "Clusters", "Settings"],
		middlePane => ["Apps", "Parameters", "Aws"],
		rightPane => ["Parameters", "Apps", "Hub"]

		#leftPane => ["Apps"]
		#middlePane => ["Packages"]
		#leftPane => ["Hub"],
		#leftPane => ["Personal"],
		#middlePane => ["Personal"]
		#middlePane => ["Aws"]
		#leftPane => ["Aws"]
	};
	$self->logDebug("headings", $headings);
	
    return $headings;
}




1;