package Report;
=head2

		PACKAGE		Report
		
		PURPOSE
		
			THE Reports OBJECT PERFORMS THE FOLLOWING TASKS:
			
				1. RETURNS FILE AND DIRECTORY LIST OF A GIVEN PATH AS A
                
                    dojox.data.FileStore JSON OBJECT TO BE RENDERED USING
                    
                    FilePicker INSIDE dojox.dijit.Dialog
    

PROJECTS

cd C:\DATA\base\cgi-bin\Bioptic0.2.5

perl reports.cgi "mode=reports&sessionId=1228791394.7868.158&username=admin"


=cut

use strict;




require Exporter;
our @ISA = qw(Exporter Common);
our @EXPORT_OK = qw();
our $AUTOLOAD;

#### INTERNAL MODULES
use Util;
use Common;  # FOR AUTHENTICATION
use DBase::SQLite;


#### EXTERNAL MODULES
use File::Basename; # ALREADY IN PERL
use File::Copy;     # ALREADY IN PERL
use File::stat;     # ALREADY IN PERL
use Data::Dumper;   # ALREADY IN PERL
use Carp;           # ALREADY IN PERL


use JSON -support_by_pp;
use DBD::SQLite;

#### DOWNLOADED FROM CPAN
use File::Remove;
use File::Copy::Recursive;

#### SET SLOTS
our @DATA = qw(
	USERNAME
	SESSIONID
	JSON
    MODE
    DBOBJECT
	CGI    
    CONF
);
our $DATAHASH;
foreach my $key ( @DATA )	{	$DATAHASH->{lc($key)} = 1;	}

our $ROOT = 'admin';
our $DEFAULT_BYTES = 80;



=head2

	SUBROUTINE		new
	
	PURPOSE
	
		CREATE THE NEW self OBJECT AND INITIALISE IT, FIRST WITH DEFAULT 
		
		ARGUMENTS, THEN WITH PROVIDED ARGUMENTS

=cut


sub new
{
 	my $class 		=	shift;
	my $arguments 	=	shift;
   
	my $self = {};
    bless $self, $class;


    #### VALIDATE
    my $validated = $self->validate();
    $self->logDebug("Validated", $validated);
    if ( not $validated )
    {
        $self->logError("User session not validated");
        return;
    }




	#### CHECK CONF->FILEROOT IS PRESENT AND NOT EMPTY
	if ( not defined $arguments-> {CONF}
        or not $arguments-> {CONF}
        or not defined $arguments->{CONF}->{FILEROOT}
        or not $arguments->{CONF}->{FILEROOT}
    ) 
	{
		$self->logError("Conf->FILEROOT is not defined");
        return;
    }
	else
	{
		$self->{_conf} = $arguments->{CONF};
	}
	
	#### INITIALISE THE OBJECT'S ELEMENTS
	$self->initialise($arguments);

    return $self;
}



=head2

    SUBROUTINE     reports
    
    PURPOSE
        
        1. Return a list of reports for the user
        
        2. Each report has permissions
        
=cut

#### Return a list of reports for the user
sub reports
{
    my $self        =   shift;

    #### PRINT HEADER 
	print "Content-type: text/html\n\n";

    $self->logDebug("");
    

    #### GET DATABASE OBJECT
    my $db = $self->{_db};

    #### GET USER NAME, SESSION ID AND PATH FROM CGI OBJECT
    my $username = $self->cgiParam("username");

    #### GET THE PROJECTS OWNED BY THIS USER
    $self->logDebug("Doing USER PROJECTS...");
    my $query = qq{SELECT * FROM reports WHERE owner = '$username'};
    $self->logDebug("$query");
    my $user_reports = $db->queryhasharray($query);    
    $self->logObject("User Reports", $user_reports);

    #### SET RIGHTS
    foreach my $report ( @$user_reports )
    {
        $report->{rights} = $report->{ownerrights};
    }


    ####
    #
    #   GENERATE LIST OF SOURCES (READABLE SHARED PROJECTS, SOME OF WHICH MAY BE WRITEABLE)
    #
    #    .schema groups
    #    CREATE TABLE groups
    #    (
    #            owner                   VARCHAR(20),
    #            groupname               VARCHAR(20),
    #            name                    VARCHAR(20),
    #            type                    VARCHAR(50),
    #    
    #            PRIMARY KEY (owner, groupname, name, type)
    #    );
    #    
    #    
    #    1. GET OWNER AND GROUP OF ANY GROUPS THE USER BELONGS TO
    #    select owner, group from groupmember where name='admin';
    #    syoung|bioinfo
    #    syoung|nextgen
    #
    #    2. GET THE NAMES OF ANY PROJECTS IN THE GROUPS THE USER BELONGS TO
    #    select name from groupmember where owner = 'syoung' and groupname = 'bioinfo' and type='report';
    #    Report1
    #    
    #    select name from groupmember where owner = 'syoung' and groupname = 'nextgen' and type='report';
    #    Report2
    #    
    #    PUSH TO ARRAY AND HASH FOR CHECKING IN WORLD-READABLE IF ALREADY USED
    #    
    #    
    #    3. GET THE PERMISSIONS AND LOCATIONS OF ANY SHARED PROJECTS IN THE USER'S GROUPS
    #
    #    .schema reports
    #    CREATE TABLE reports
    #    (
    #            report                 VARCHAR(20),
    #            owner                   VARCHAR(20),
    #            ownerrights             INT(1),
    #            grouprights             INT(1),
    #            worldrights             INT(1),
    #            location                TEXT,
    #    
    #            PRIMARY KEY (report, owner, ownerrights, grouprights, worldrights, loca
    #    tion)
    #    );
    #    
    #    select * from reports where owner = 'syoung' and report = 'Report1';
    #    Report1|syoung|7|5|1|syoung/Report1
    #    
    #    select * from reports where owner = 'syoung' and report = 'Report2';
    #    Report2|syoung|7|5|1|syoung/Report2
    #    
    #    


    #   1. GET OWNER AND GROUP OF ANY GROUPS THE USER BELONGS TO
    $query = qq{select owner, groupname from groupmember where name = '$username'};
    $self->logDebug("$query");
    my $ownergroups = $db->queryhasharray($query);
    $self->logObject("Ownergroups", $ownergroups);

    my $owner_reports;         #### ARRAY
    my $used_owner_reports;    #### HASH 
    
    foreach my $hash( @$ownergroups )
    {
        my $owner = $hash->{owner};
        my $group = $hash->{groupname};

        #   2. GET THE NAMES OF ANY PROJECTS IN THE GROUPS THE USER BELONGS TO
        $query = qq{select name from groupmember where owner = '$owner' and groupname = '$group' and type='report'};
        $self->logDebug("$query");
        my $queryarray = $db->queryarray($query);
        foreach my $report ( @$queryarray )
        {
            $hash->{report} = $report;
            push @$owner_reports, $hash;

            #### PUSH TO 'USED OWNER PROJECTS' FOR CHECKING IN WORLD-READABLE LIST LATER
            $used_owner_reports->{"$owner-$report"} = 1;
        }
    }
    
    $self->logObject("Owner reports", $owner_reports);
    
    
    $self->logObject("Used owner reports hash", $used_owner_reports);

    #   3. GET THE PERMISSIONS AND LOCATIONS OF ANY SHARED PROJECTS IN THE USER'S GROUPS
    my $sources;
    for my $owner_report ( @$owner_reports )
    {
        my $owner = $owner_report->{owner};
        my $report = $owner_report->{report};
        
        my $query = qq{select * from reports where owner = '$owner' and report = '$report'};
        $self->logDebug("$query");
        my $hash = $db->queryhash($query);
        $hash->{rights} = $hash->{grouprights};
        push @$sources, $hash;
    }


    ####
    #
    #   GENERATE LIST OF WORLD READABLE SOURCES (SOME OF WHICH MAY HAVE APPEARED
    #
    #   AMONG THE READABLE SHARED PROJECTS LIST ABOVE)
    #
    #    select * from reports where worldrights >= 1;
    #  
    #    Report1|syoung|7|5|1|syoung/Report1
    #    Report2|syoung|7|5|1|syoung/Report2
    #    Report0|admin|7|5|1|admin/Report0
    #    Report1|admin|7|5|1|admin/Report1
    #
    #

    $query = qq{select * from reports where worldrights >= 1 and owner != "$username"};
    my $world_sources = $db->queryhasharray($query);
    for my $world_source ( @$world_sources )
    {
        $self->logObject("world_source", $world_source);
        my $key = "$world_source->{owner}-$world_source->{report}";
        #$self->logDebug("key", $key);
        if ( exists $used_owner_reports->{$key} )
        {
            $self->logDebug("Already exists. Skipping.");
            next;
        }
        else
        {
            $self->logDebug("Does not already exist. Adding to 'sources'.");
            $world_source->{rights} = $world_source->{worldrights};

            push @$sources, $world_source;
        }
    }

    #### GENERATE PROJECTS JSON
    my $reports;
    $reports->{reports} = $user_reports;
    $reports->{sources} = $sources;
    my $jsonObject = JSON->new();
    #no warnings;
    my $json = $jsonObject->objToJson($reports, {pretty => 1, indent => 4});
    #use warnings;
    
    print $json;
    
    #### RETURN ON COMPLETION
    return;    
}






=head2

    SUBROUTINE:     reportRights
    
    PURPOSE:
    
        1. Check the rights of a user to access another user's report

=cut
#### Check the rights of a user to access another user's report
sub reportRights
{
    my $self        =   shift;    
    my $owner       =   shift;
    my $report     =   shift;
    my $username    =   shift;
    
    my $db = $self->{_db};

    #### GET GROUP NAME FOR PROJECT
    my $query = qq{SELECT groupname from groupmember where owner = '$owner' and name = '$report' and type = 'report'};
    $self->logDebug("$query");
    my $group = $db->query($query);
    if ( not defined $group )
    {
        return;
    }
    
    #### CONFIRM THAT USER BELONGS TO THIS GROUP
    $query = qq{SELECT * FROM groupmember WHERE groupname = '$group' AND owner = '$owner' AND name = '$username' AND type = 'user'};
    $self->logDebug("$query");
    my $access = $db->query($query);
    $self->logDebug("Access", $access);
    if ( not defined $access )
    {
        return;
    }

    #### MAKE SURE THAT THE GROUP PRIVILEGES ALLOW ACCESS
    $query = qq{SELECT grouprights FROM reports WHERE owner = '$owner' AND report = '$report'};
    $self->logDebug("$query");
    my $rights = $db->query($query);
    $self->logDebug("Rights", $rights);
    if ( not defined $rights or not $rights )
    {
        return;
    }

    return $rights;
}




#=head2
#
#    SUBROUTINE:     cgiParam
#    
#    PURPOSE:    Return the value of the input CGI parameter
#
#=cut
#
#sub cgiParam
#{
#    my $self    =   shift;
#    my $param   =   shift;
#    
#    if ( not defined $self->{_cgi} )
#    {
#        return;
#    }
#    
#    return $self->{_cgi}->{$param}[0];
#}
#
#
#
#=head2
#
#    SUBROUTINE:     confParam
#    
#    PURPOSE:    Return the value of the input CONF parameter
#
#=cut
#
#sub confParam
#{
#    my $self    =   shift;
#    my $param   =   shift;
#    
#    if ( not defined $self->{_conf} )
#    {
#        return;
#    }
#    
#    return $self->{_conf}->{$param};
#}
#
#
#
#=head2
#
#	SUBROUTINE		initialise
#	
#	PURPOSE
#
#		INITIALISE THE self OBJECT:
#			
#			1. LOAD THE DATABASE, USER AND PASSWORD FROM THE ARGUMENTS
#			
#			2. FILL OUT %VARIABLES% IN XML AND LOAD XML
#			
#			3. LOAD THE ARGUMENTS
#
#=cut
#
#sub initialise
#{
#    my $self		=	shift;
#	my $arguments	=	shift;
#
#    #### SET DEFAULT 'ROOT' USER
#    $self->value('root', $ROOT);
#	
#    #### SET DEFAULT BYTES (TO BE seeked FROM FILE FOR SAMPLE)
#    $self->value('bytes', $DEFAULT_BYTES);
#
#    #### VALIDATE USER-PROVIDED ARGUMENTS
#	($arguments) = $self->validate_arguments($arguments, $DATAHASH);	
#    
#	#### LOAD THE USER-PROVIDED ARGUMENTS
#	foreach my $key ( keys %$arguments )
#	{		
#		#### LOAD THE KEY-VALUE PAIR
#		$self->value($key, $arguments->{$key});
#	}
#}
#
#
#=head2
#
#	SUBROUTINE		value
#	
#	PURPOSE
#
#		SET A PARAMETER OF THE self OBJECT TO A GIVEN value
#
#    INPUT
#    
#        1. parameter TO BE SET
#		
#		2. value TO BE SET TO
#    
#    OUTPUT
#    
#        1. THE SET parameter INSIDE THE self OBJECT
#		
#=cut
#
#sub value
#{
#    my $self		=	shift;
#	my $parameter	=	shift;
#	my $value		=	shift;
#
#	$parameter = lc($parameter);
#	
#
#    if ( defined $value)
#	{	
#		$self->{"_$parameter"} = $value;
#	}
#}
#
#=head2
#
#	SUBROUTINE		validate_arguments
#
#	PURPOSE
#	
#		VALIDATE USER-INPUT ARGUMENTS BASED ON
#		
#		THE HARD-CODED LIST OF VALID ARGUMENTS
#		
#		IN THE data ARRAY
#=cut
#
#sub validate_arguments
#{
#	my $self		=	shift;
#	my $arguments	=	shift;
#	my $DATAHASH	=	shift;
#	
#	my $hash;
#	foreach my $argument ( keys %$arguments )
#	{
#		if ( $self->is_valid($argument, $DATAHASH) )
#		{
#			$hash->{$argument} = $arguments->{$argument};
#		}
#		else
#		{
#			warn "'$argument' is not a known parameter\n";
#		}
#	}
#	
#	return $hash;
#}
#
#
#=head2
#
#	SUBROUTINE		is_valid
#
#	PURPOSE
#	
#		VERIFY THAT AN ARGUMENT IS AMONGST THE LIST OF
#		
#		ELEMENTS IN THE GLOBAL '$DATAHASH' HASH REF
#		
#=cut
#
#sub is_valid
#{
#	my $self		=	shift;
#	my $argument	=	shift;
#	my $DATAHASH	=	shift;
#	
#	#### REMOVE LEADING UNDERLINE, IF PRESENT
#	$argument =~ s/^_//;
#	
#	#### CHECK IF ARGUMENT FOUND IN '$DATAHASH'
#	if ( exists $DATAHASH->{lc($argument)} )
#	{
#		return 1;
#	}
#	
#	return 0;
#}
#
#
#
#
#
#=head2
#
#	SUBROUTINE		AUTOLOAD
#
#	PURPOSE
#	
#		AUTOMATICALLY DO 'set_' OR 'get_' FUNCTIONS IF THE
#		
#		SUBROUTINES ARE NOT DEFINED.
#
#=cut
#
#sub AUTOLOAD {
#    my ($self, $newvalue) = @_;
#
#
#    my ($operation, $attribute) = ($AUTOLOAD =~ /(get|set)(_\w+)$/);
#	
#	
#
#    # Is this a legal method name?
#    unless($operation && $attribute) {
#        croak "Method name $AUTOLOAD is not in the recognized form (get|set)_attribute\n";
#    }
#    unless( exists $self->{$attribute} or $self->is_valid($attribute) )
#	{
#        #croak "No such attribute '$attribute' exists in the class ", ref($self);
#		return;
#    }
#
#    # Turn off strict references to enable "magic" AUTOLOAD speedup
#    no strict 'refs';
#
#    # AUTOLOAD accessors
#    if($operation eq 'get') {
#        # define subroutine
#        *{$AUTOLOAD} = sub { shift->{$attribute} };
#
#    # AUTOLOAD mutators
#    }elsif($operation eq 'set') {
#        # define subroutine4
#		
#        *{$AUTOLOAD} = sub { shift->{$attribute} = shift; };
#
#        # set the new attribute value
#        $self->{$attribute} = $newvalue;
#    }
#
#    # Turn strict references back on
#    use strict 'refs';
#
#    # return the attribute value
#    return $self->{$attribute};
#}
#
#
## When an object is no longer being used, this will be automatically called
## and will adjust the count of existing objects
#sub DESTROY {
#    my($self) = @_;
#
#	#if ( defined $self->{_databasehandle} )
#	#{
#	#	my $dbh =  $self->{_databasehandle};
#	#	$dbh->disconnect();
#	#}
#
##    my($self) = @_;
#}
#


1;


