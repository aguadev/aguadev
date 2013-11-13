package Agua::Common::Cloud;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Cloud
	
	PURPOSE
	
		ADMIN METHODS FOR Agua::Common
	
=cut

use Data::Dumper;

=head2

    SUBROUTINE		getCloudHeadings
    
    PURPOSE

		RETURN A LIST OF CLOUD PANES
		
=cut

sub getCloudHeadings {
	my $self		=	shift;

    	my $json			=	$self->json();

	$self->logDebug("");

	#### VALIDATE    
    my $username = $json->{username};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### CHECK REQUESTOR
	print qq{ error: 'Agua::Common::Cloud::getHeadings    Access denied to requestor: $json->{requestor}' } if defined $json->{requestor};
	
	my $headings = {
		leftPane => ["Settings", "Clusters"],
		middlePane => ["Ami", "Aws"],
		rightPane => ["Hub"]
	};
	$self->logDebug("headings", $headings);
	
    return $headings;
}




1;