package Agua::Common::Sharing;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::Sharing
	
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

sub getSharingHeadings {
	my $self		=	shift;

    	my $json			=	$self->json();

	#### VALIDATE    
    my $username = $json->{username};
	$self->logError("User $username not validated") and return unless $self->validate($username);

	#### CHECK REQUESTOR
	print qq{ error: 'Agua::Common::Sharing::getHeadings    Access denied to requestor: $json->{requestor}' } if defined $json->{requestor};
	
	my $headings = {
		leftPane => ["Access", "GroupProjects"],
		middlePane => ["Groups", "Sources", "GroupUsers"],
		rightPane => ["GroupSources", "Projects"]
	};

	#### ADD ADMIN TABS: Users
	if ( $self->isAdminUser($username))
	{
		push @{$headings->{rightPane}}, "Users";		
	}
	
    return $headings;
}




1;