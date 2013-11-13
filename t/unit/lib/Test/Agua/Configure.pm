use MooseX::Declare;

=head2

PACKAGE		Configure

PURPOSE

    1. CONFIGURE THE Agua DATABASE
    
    2. CONFIGURE DATA AND APPLICATION PATHS AND SETTINGS
    
        E.G., PATHS TO BASIC EXECUTABLES IN CONF FILE:
        
        [applications]
        STARCLUSTERDEFAULT      /data/apps/starcluster/110202bal/bin/starcluster
        BOWTIE                  /data/apps/bowtie/0.12.2
        CASAVA                  /data/apps/casava/1.6.0/bin
        CROSSMATCH              /data/apps/crossmatch/0.990329/cross_match
        CUFFLINKS               /data/apps/cufflinks/0.8.2
        ...
    
=cut

our $DEBUG = 0;
#$DEBUG = 1;

use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/..";

class Test::Agua::Configure extends Agua::Configure with (Test::Agua::Common::Database, Test::Agua::Common::Util) {

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Test::More;
use Data::Dumper;
use Term::ReadKey;
use File::Copy::Recursive;

##### INTERNAL MODULES
use Conf::Simple;

# STRINGS
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'rootuser'		=> ( isa => 'Str|Undef', is => 'rw', default => 'root' );
has 'rootpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
# OBJECTS
has 'json'			=> ( isa => 'HashRef|Undef', is => 'rw', required => 0 );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new({ 	memory	=>	1	});	}
);

####/////}


method testEnableSsh {
	diag("Test enableSsh");
	
	my $originalfile 	= 	"$Bin/inputs/sshd_config";
	my $inputfile 		= 	"$Bin/outputs/sshd_config";
	my $logfile			=	"$Bin/outputs/enablessh.log";
	$self->logfile($logfile);
	
	#### COPY INPUT FILE
	$self->setUpFile($originalfile, $inputfile);
	
	my $sshconfig = Conf::Simple->new({
		separator 	=> " ",
		spacer 		=>	"\\s+",
		inputfile	=>	$inputfile,
		logfile		=>	$logfile,
		SHOWLOG		=>	4,
		PRINTLOG	=>	5
	});
	my $sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);
	
	#### OVERRIDE getSshConfigFile TO USE LOCAL SSH CONF FILE
	*getSshConfigFile = sub {
		return $inputfile;
	};  
	
	#### 1. CORRECT AUTHENTICATION
	
	#### SET VALUE AS 'no'
	$sshconfig->setKey("PasswordAuthentication", "no");
	
	#### SET USER
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	$self->username($adminuser);
	$self->logDebug("username", $self->username());
	
	#### RUN IT
	$self->enableSsh();
	
	#### VERIFY KEY
	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);
	ok($sshlogin eq "yes", "enableSsh    correct value for PasswordAuthentication");
	
	#
	##### 2. INCORRECT AUTHENTICATION
	#
	##### SET VALUE AS 'no'
	#$sshconfig->setKey("PasswordAuthentication", "no");
	#$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	#$self->logDebug("sshlogin", $sshlogin);
	#ok($sshlogin eq "no", "enableSsh    value reset to 'no'");
	#
	#
	##### SET USER AND RUN
	#$self->username("non-admin-user");
	#$self->logDebug("username", $self->username());
	#
	#my $pid = fork();
	#if ( not $pid ) {
	#	#### RUN IT
	#	#### NB: MUST FAIL AND DIE
	#	$<=$>=501;	# 0 is almost always OWNER root
	#	$(=$)=501;   # 0 is almost always GROUP wheel$< = 500;
	#	$self->enableSsh();
	#	exit;
	#}
	#else {
	#	sleep(1);
	#	#### VERIFY KEY
	#	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	#	$self->logDebug("sshlogin", $sshlogin);
	#	ok($sshlogin eq "no", "enableSsh    no change for incorrect authentication");
	#}
	
	#### 3. NO USERNAME - MUST RUN AS ROOT
	
	#### SET VALUE AS 'no'
	$sshconfig->setKey("PasswordAuthentication", "no");
	
	#### SET USER
	$self->username(undef);
	$self->logDebug("username", $self->username());
	
	#### RUN IT
	$self->enableSsh();
	
	#### VERIFY KEY
	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);
	ok($sshlogin eq "yes", "enableSsh    authenticates for root user");
}


method testDisableSsh {
	diag("Test disableSsh");
	
	my $originalfile 	= 	"$Bin/inputs/sshd_config";
	my $inputfile 		= 	"$Bin/outputs/sshd_config";
	my $logfile			=	"$Bin/outputs/disablessh.log";
	$self->logfile($logfile);
	
	#### COPY INPUT FILE
	$self->setUpFile($originalfile, $inputfile);
	
	my $sshconfig = Conf::Simple->new({
		separator 	=> " ",
		spacer 		=>	"\\s+",
		inputfile	=>	$inputfile,
		logfile		=>	$logfile,
		SHOWLOG		=>	4,
		PRINTLOG	=>	5
	});
	my $sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);

	#### OVERRIDE getSshConfigFile TO USE LOCAL SSH CONF FILE
	no warnings;
	*getSshConfigFile = sub {
		return $inputfile;
	};
	use warnings;

	#### 1. CORRECT AUTHENTICATION

	#### SET VALUE AS 'yes'
	$sshconfig->setKey("PasswordAuthentication", "yes");

	#### SET USER
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	$self->username($adminuser);
	$self->logDebug("username", $self->username());

	#### RUN IT
	$self->disableSsh();
	
	#### VERIFY KEY
	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);
	ok($sshlogin eq "no", "disableSsh    correct value for PasswordAuthentication");
	

	##### 2. INCORRECT AUTHENTICATION
	#
	##### SET VALUE AS 'yes'
	#$sshconfig->setKey("PasswordAuthentication", "yes");
	#$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	#$self->logDebug("sshlogin", $sshlogin);
	#ok($sshlogin eq "yes", "disableSsh    value reset to 'yes'");
	#
	##### SET USER AND RUN
	#$self->username("non-admin-user");
	#$self->logDebug("username", $self->username());
	#
	#my $pid = fork();
	#if ( not $pid ) {
	#	#### RUN IT
	#	#### NB: MUST DIE
	#	$<=$>=501;	# 0 is almost always OWNER root
	#	$(=$)=501;   # 0 is almost always GROUP wheel$< = 500;
	#	$self->disableSsh();
	#}
	#else {
	#	sleep(1);
	#	#### VERIFY KEY
	#	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	#	$self->logDebug("sshlogin", $sshlogin);
	#	ok($sshlogin eq "yes", "disableSsh    no change for incorrect authentication");
	#}

	#### 3. NO USERNAME - MUST RUN AS ROOT

	#### SET VALUE AS 'yes'
	$sshconfig->setKey("PasswordAuthentication", "yes");

	#### SET USER
	$self->username(undef);
	$self->logDebug("username", $self->username());

	#### RUN IT
	$self->disableSsh();
	
	#### VERIFY KEY
	$sshlogin = $sshconfig->getKey("PasswordAuthentication");
	$self->logDebug("sshlogin", $sshlogin);
	ok($sshlogin eq "no", "enableSsh    authenticates for root user");
}




method config {
	### ADD aguatest USER AND DIRECTORY
	$self->_addUser($self->json()->{data});
	
	#### COPY TEST PROJECTS AND WORKFLOWS TO agua USER
	$self->copyTestdirs("aguatest", "$Bin/../../nethome/aguatest/agua");
}

method copyTestdirs($username, $sourcedir) {
	my $targetdir	=	$self->getFileroot($username);		
	$self->logDebug("Test::Agua::Configure::copyTestdirs(sourcedir)");
	$self->logDebug("sourcedir", $sourcedir);
	$self->logDebug("targetdir", $targetdir);

	my $success = File::Copy::Recursive::rcopy($sourcedir, $targetdir);
	$self->logDebug("success", $success);
	
	`chown -R $username:www-data $targetdir`;
}


} #### Test::Agua::Configure