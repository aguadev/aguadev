#!/usr/bin/perl -w
use strict;

=head2

APPLICATION     uml

PURPOSE

	1. GENERATE TABLES OF ROLE-BASED METHOD INHERITANCE
	
		HIERARCHIES THAT CAN BE USED TO CREATE UML DIAGRAMS
	
NOTES

		1. ASSUMES MOOSE CLASS SYNTAX A LA 'MooseX::Declare'
		
		2. ROLE USAGE AND INHERITANCE LISTS CAN BE ON SEPARATE
		
			LINES OR JOINED TOGETHER, E.G.,
						
			class Agua::StarCluster with (Agua::Common::Aws,
				Agua::Common::Base,
				Agua::Common::Balancer,
				Agua::Common::Cluster,
				Agua::Common::SGE,
            
            AND
                
			class Agua::StarCluster with (Agua::Common::Aws, Agua::Common::Base, Agua::Common::Balancer, Agua::Common::Cluster, ...

				
		3. FOLLOW CALLS TO A ROLE THROUGH ALL OTHER ROLES USED BY THE CLASS:
		
            class A USES role B
            
            role B CALLS role C
            
            --> class A CALLS role C

USAGE

./uml.pl               \
 <--mode String>       \
 [--sourcefile String] \
 [--targetfile String] \
 [--sourcedir String]  \
 [--targetdir String]  \
 [--outputfile String] \
 [--help]

 --mode          :   Defines the scope of the UML hierarachy:
	roleUser     : specified user (targetfile) of the Role (sourcefile)
	roleUsers    : all users of a Role (sourcefile)
	allRoleUsers : all users in the targetdir of all Roles in sourcedir
	userRoles    : specified user (targetfile) of all Roles in sourcedir
 --sourcefile : File containing a single Role
 --targetfile : File containing a single Role-using Class
 --sourcedir  : Directory containing one or more sourcefiles
                (all files in subdirs will also be included)
 --targetdir  : Directory containing one or more targetfiles
                (all files in subdirs will also be included)
 --urlprefix     :   Prefix to URL
 --help          :   Print help info


EXAMPLES

ONE ROLE, ONE USER:
 ./uml.pl \
 --sourcefile /agua/lib/Agua/Common/Cluster.pm \
 --targetfile /agua/lib/Agua \
 --outputfile /agua/log/one-to-one-uml.tsv \
 --mode roleUser

ONE ROLE, MANY USERS:
 ./uml.pl \
 --sourcefile /agua/lib/Agua/Common/Cluster.pm \
 --targetdir /agua/lib/Agua \
 --outputfile /agua/log/one-to-many-uml.tsv \
 --mode roleUsers

MANY ROLES, ONE USER:
 ./uml.pl \
 --sourcedir /agua/lib/Agua \
 --targetfile /agua/lib/Agua/Workflow.pm \
 --outputfile /agua/log/many-to-one-uml.tsv \
 --mode allRoleUsers

MANY ROLES, MANY USERS:
 ./uml.pl \
 --sourcedir /agua/lib/Agua \
 --targetdir /agua/lib/Agua \
 --outputfile /agua/log/many-to-many-uml.tsv \
 --mode userRoles

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;

#### INTERNAL MODULES
use Agua::Uml;

#### GET OPTIONS
my $logfile 		= 	"/tmp/uml.log";
my $SHOWLOG     	=   2;
my $PRINTLOG    	=   5;
my $mode;
my $sourcefile;
my $targetfile;
my $sourcedir;
my $targetdir;
my $outputfile;
my $help;
GetOptions (
    'mode=s'        =>  \$mode,
    'sourcefile=s'  =>  \$sourcefile,
    'targetfile=s'  =>  \$targetfile,
	'sourcedir=s'   =>  \$sourcedir,
    'targetdir=s'   =>  \$targetdir,
    'outputfile=s'  =>  \$outputfile,
    'logfile=s'     =>  \$logfile,
    'SHOWLOG=s'     =>  \$SHOWLOG,
    'PRINTLOG=s'    =>  \$PRINTLOG,
    'help'          =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;


my $object = Agua::Uml->new({
    sourcefile     	=>  $sourcefile,
    targetfile     	=>  $targetfile,
    sourcedir     	=>  $sourcedir,
    targetdir       =>  $targetdir,
    outputfile      =>  $outputfile,
    logfile     	=>  $logfile,
    SHOWLOG     	=>  $SHOWLOG,
    PRINTLOG   		=>  $PRINTLOG
});

$object->$mode();

######################## SUBROUTINES #####################

sub usage {
    print `perldoc $0`;
    exit;
}