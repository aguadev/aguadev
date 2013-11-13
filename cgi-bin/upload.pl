#!/usr/bin/perl

#### DEBUG
my $DEBUG = 0;
$DEBUG = 1;

use FCGI; # Imports the library; required line

=head2

	APPLICATION 	upload.cgi
	
	PURPOSE
	
		1. SAVE FILE CONTENTS TO TEMPORARY FILE
		
		2. TRANSFER FILE TO USER HOME DIRECTORY
            
            (LATER: USE SETUID RELAY)
		
	USAGE

		./upload.cgi < transfer-data-in-mime-format.txt

	NOTES
	
		TEMP UPLOAD DIR MUST HAVE THE FOLLOWING PERMISSIONS:

		chmod 0777 uploads

=cut

use strict;

#### EXTERNAL MODULES
use FindBin qw($Bin);
use File::Copy;

#### USE LIBS
use lib "$Bin/lib";

#### INTERNAL MODULES
use Agua::Upload;

#### SET LOG
my $SHOWLOG     = 4;
my $PRINTLOG    = 4;

my $logfile     = "/tmp/agua-upload.log";
#warn "logfile: $logfile\n";

#### GET CONF
use Conf::Yaml;
my $conf = Conf::Yaml->new(
	inputfile	=>	"$Bin/conf/config.yaml",
	backup		=>	1,
    logfile     =>  $logfile,
    SHOWLOG     =>  2,
    PRINTLOG    =>  4
);

my $object = Agua::Upload ->new({
	conf	    =>	$conf,
    logfile     =>  $logfile,
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG    
});

# Response loop
while (FCGI::accept >= 0) {

#### PRINT HEADER FOR DEBUGGING ONLY
print "Content-type: text/html\n\n";

##### SET whoami
#my $whoami = chomp(`whoami`);
#print "whoami: $whoami\n";
#$object->whoami($whoami);

#### RUN UPLOAD
$object->upload();

}

#exit(0);


####################################################################
#####################           SUBROUTINES      ###################
####################################################################

