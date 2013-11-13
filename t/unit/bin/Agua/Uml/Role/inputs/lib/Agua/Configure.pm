use MooseX::Declare;
use Method::Signatures::Simple;

=head2

PACKAGE		Configure

PURPOSE

    1. CONFIGURE THE Agua DATABASE
    
    2. CONFIGURE DATA AND APPLICATION PATHS AND SETTINGS
    
        E.G., PATHS TO BASIC EXECUTABLES IN CONF FILE:
        
        [applications]
        STARCLUSTER	      	/data/apps/starcluster/0.92.rc1/bin/starcluster
        BOWTIE              /data/apps/bowtie/0.12.2
        CASAVA              /data/apps/casava/1.6.0/bin
        CROSSMATCH          /data/apps/crossmatch/0.990329/cross_match
        CUFFLINKS           /data/apps/cufflinks/0.8.2
        ...
    
=cut
use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;

class Agua::Configure with Agua::Common {

#### USE LIB
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### EXTERNAL MODULES
use Data::Dumper;
use Term::ReadKey;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Conf::Agua;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'username'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'requestor'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'cluster'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testdatabase'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testuser'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'rootuser'		=> ( isa => 'Str|Undef', is => 'ro', default => 'root' );
has 'rootpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );


# Objects
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'aguadb'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'rootdb'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 			=> (
	is =>	'rw',
	isa => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####/////}

method BUILD ($hash) {
	#$self->logDebug("Agua::Configure::BUILD()");
	$self->logDebug("self", $self);
	$self->initialise();
}

method initialise {	
	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	my $json = $self->json();
	if ( $json )
	{
		foreach my $key ( keys %{$json} )
		{
			$self->logDebug("SETTING self->$key", $json->{$key}) if $self->can($key);
			$self->$key($json->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $json);

	#### SET CONF LOG
	$self->conf()->SHOWLOG($self->SHOWLOG());
	$self->conf()->PRINTLOG($self->PRINTLOG());	
}

method config {
	
	#### COPY DEFAULT CONFIG FILE
	$self->copyConf();
	
	#### SET UP MYSQL DATABASE AND DB USER
	$self->mysql();
	
	#### CONFIGURE CRON JOB TO MONITOR StarCluster LOAD BALANCER
	$self->cron();
	
	#### CREATE admin USER ACCOUNT ON FILESYSTEM AND IN Agua DATABASE
	$self->adminUser();
	
	#### EDIT /etc/fstab TO ENABLE REBOOT FOR MICRO INSTANCES
	$self->fixFstab();

print "\n\n\n";
print "************************************       ************************************\n";
print "*********                        Completed 'config'                   *********\n";
print "************************************       ************************************\n";
print "\n\n\n";

	$self->logDebug("Completed $0");
}

#### COPY CONFIG FILE
method copyConf {
#### COPY default.conf FILE FROM RESOURCES TO conf DIR
	my $confdir = "$Bin/../../conf";
	$self->logDebug("confdir", $confdir);
	my $resourcedir = "$Bin/resources/agua/conf";
	$self->logDebug("resourcedir", $resourcedir);
	my $sourcefile = "$resourcedir/default.conf";
	my $targetfile = "$confdir/default.conf";
	$self->backupFile($targetfile) if -f $targetfile;
	
	#### COPY
	my $command = "cp -f $sourcefile $targetfile";
	$self->logDebug("command", $command);
	`$command`;
}
#### SSH
method enableSsh {
#### ENABLE SSH PASSWORD LOGIN
	$self->logDebug("");

	#### VERIFY ADMIN OR root USER
	my $isadmin = $self->_isAdminOrRoot();
	$self->logDebug("isadmin", $isadmin);
	
	$self->logError("User is not root user") and exit if not $isadmin;

	#### SET KEY VALUE IN CONF FILE
	$self->conf()->setKey("agua", "SSHPASSWORDLOGIN", "YES");

	#### EDIT sshd_config TO ENABLE SSH
	$self->_enableSshPasswordLogin();
}

=head2

SUBROUTINE         admin

PURPOSE

	DISABLE SSH PASSWORD LOGIN

=cut

method disableSsh {
	$self->logDebug("");

	#### VERIFY ADMIN OR root USER
	$self->logError("User is not root user") and exit if not $self->_isAdminOrRoot();

	#### SET KEY VALUE IN CONF FILE
	$self->conf()->setKey("agua", "SSHPASSWORDLOGIN", "NO");
	
	#### EDIT sshd_config TO DISABLE SSH
	$self->_disableSshPasswordLogin();
}

method _isAdminOrRoot {
	my $username = $self->username() || '';
	$self->logDebug("username", $username);

	my $whoami = `whoami` || '';
	$whoami =~ s/\s+//;
	$self->logDebug("whoami", $whoami);

	my $user = $username;
	$user = $whoami if not defined $user or not $user;
	
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER") || '';
	$self->logDebug("adminuser", $adminuser);
	
	return 0 if $username ne $adminuser and $whoami ne "root";
	return 1;
}

#### ADMIN USER
method adminUser {
=head2

SUBROUTINE         admin

PURPOSE

	CREATE THE ADMIN USER LINUX ACCOUNT

=cut 

print "\n\n\n";
print "****************************************************************\n";
print "********      CREATE admin USER ACCOUNT ON SERVER      *********\n";
print "****************************************************************\n";
print "\n\n\n";

    #### ADMIN USERNAME
	my $username = $self->conf()->getKey("agua", "ADMINUSER");
	$username = $self->_inputValue("Admin username", $username);	
    $self->logError("username not defined") if not defined $username;
	
    #### ADMIN USERNAME
	my $firstname = "admin";
	$firstname = $self->_inputValue("Admin firstname", $firstname);	
    $self->logError("firstname not defined") if not defined $firstname;

    #### ADMIN USERNAME
	my $lastname = "admin";
	$lastname = $self->_inputValue("Admin lastname", $lastname);	
    $self->logError("lastname not defined") if not defined $lastname;

    #### ADMIN PASSWORD
	my $password = $self->_setAdminPassword();

    #### ADMIN EMAIL
	my $email = "";
	$email = $self->_inputValue("Admin email", $email);	
    $self->logError("email not defined") if not defined $email;
	
	my $object = {
		username	=>	$username,
		password	=>	$password,
		email		=>	$email,
		firstname	=>	$firstname,
		lastname	=>	$lastname
	};
    $self->logDebug("object", $object);

	$self->setDbh();

	### REMOVE OLD ADMIN USER ENTRY
	$self->_removeUser($object);
	
	#### ADD ADMIN USER TO AGUA DATABASE
	$self->_addUser($object);
	
	#### ADD LINUX ACCOUNT FOR ADMIN USER AND CREATE HOME DIRECTORY
	$self->_addLinuxUser($object);

print "\n\n\n";
print "****************************************************************\n";
print "*********    admin USER ACCOUNT SUCCESSFULLY CREATED   *********\n";
print "****************************************************************\n";
print "\n\n\n";

}

method _setAdminPassword {
$self->logDebug("Agua::Configure::_setAdminPassword()");

	#### MASK TYPING FOR PASSWORD INPUT
    ReadMode 2;

	my $password = '';
	my $minlength = 8;
	while ( length($password) < $minlength )
	{
		print "\n\nPlease input admin user password (Minimum $minlength characters)\n\n";
		$password = $self->_inputHiddenValue("Please input admin user password (will not appear on screen)", $password);	
	}

    #### UNMASK TYPING
    ReadMode 0;

	return $password;
}

#### TEST USER
method testUser {

print "\n\n\n";
print "*********************************************************************\n";
print "*************** CREATING AGUA TEST USER LINUX ACCOUNT ***************\n";
print "*********************************************************************\n";
print "\n\n\n";

    #### ADMIN USERNAME
	my $username 	= $self->conf()->getKey("database", "TESTUSER");
	my $firstname 	= "";
	my $lastname 	= "";
	my $email 		= "test\@trash.com";	
	my $object 		= {
		username	=>	$username,
		password	=>	"",
		email		=>	$email,
		firstname	=>	$firstname,
		lastname	=>	$lastname
	};
    $self->logDebug("object", $object);
	
	### REMOVE OLD AGUA TEST LINUX ACCOUNT
	$self->_removeLinuxUser($object);
	
	### ADD NEW AGUA TEST LINUX ACCOUNT AND CREATE DIRECTORY IF NOT EXISTS
	$self->_addLinuxUser($object);

print "\n\n\n";
print "*********************************************************************\n";
print "*********    AGUA TEST USER ACCOUNT SUCCESSFULLY CREATED    *********\n";
print "*********************************************************************\n";
print "\n\n\n";

}
#### SET CRON JOB
method cron {
=head2

	SUBROUTINE		cron
	
	PURPOSE

		INSERT INTO /etc/crontab COMMANDS TO BE RUN AUTOMATICALLY
		
		ACCORDING TO THE DESIRED TIMETABLE:
		
			1. checkBalancers.pl	-	VERIFY LOAD BALANCERS ARE
			
				RUNNING AND RESTART THEM IF THEY HAVE STOPPED. THIS
				
				TASK RUNS ONCE A MINUTE

	NOTES
	
		cat /etc/crontab
		# /etc/crontab: system-wide crontab
		# Unlike any other crontab you don't have to run the `crontab'
		# command to install the new version when you edit this file
		# and files in /etc/cron.d. These files also have username fields,
		# that none of the other crontabs do.
		
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		
		# m h dom mon dow user	command
		17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly
		25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
		47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
		52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )

=cut

	print "Running cron configuration\n";
	
	my $installdir = $self->conf()->getKey("agua", 'INSTALLDIR');	
	my $inserts	= [
		qq{* 20     * * *   root    MAILTO=""; $installdir/bin/scripts/checkBalancers.pl > /tmp/agua-loadbalancers.out}
];
	my $crontext = `crontab -l`;
	$crontext = `crontab -l` if $crontext =~ /No crontab for root/;

	#### REMOVE INSERTS IF ALREADY PRESENT	
	foreach my $insert ( @$inserts )
	{
		my $temp = $insert;
		$temp =~ s/\*/\\*/g;
		$temp =~ s/\$/\$/g;
		$temp =~ s/\-/\\-/g;
		$temp =~ s/\//\\\//g;
		$crontext =~ s/$temp//msg;
	}

	#### ADD INSERTS TO BOTTOM OF CRON LIST	
	$crontext =~ s/\s+$//;
	foreach my $insert ( @$inserts ) {	$crontext .= "\n$insert";	}
	$crontext .= "\n";
	
	`echo '$crontext' | crontab -`;
}

method _crontextFromFile ($crontab) {
	$crontab = "/etc/crontab" if not defined $crontab;
	$self->backupFile($crontab);
	my $temp = $/;
	$/ = undef;
	open(FILE, $crontab) or die "Can't open crontab: $crontab\n";
	my $crontext = <FILE>;
	close(FILE) or die "Can't close crontab: $crontab\n";
	$/ = $temp;

	return $crontext;
}

method _crontextToFile ($crontab, $crontext) {
	open(OUT, ">$crontab") or die "Can't open crontab: $crontab\n";
	print OUT $crontext;
	close(OUT) or die "Can't close crontab: $crontab\n";
}

=head2

SUBROUTINE         fixFstab

PURPOSE

	REMOVE A LINE ADDED TO /etc/fstab BY cloud-init THAT
	
	STOPS t1.micro INSTANCES FROM REBOOTING

=cut 

method fixFstab {
print "Fixing /etc/fstab to allow micro instance to reboot successfully\n";

my $file = "/etc/fstab";
open(FILE, $file) or die "Agua::Configure::fixFstab    Can't open file: $file\n";
my @lines = <FILE>;
close(FILE) or die "Can't close file: $file\n";
for ( my $i = 0; $i < $#lines + 1; $i++ )
{
    my $line = $lines[$i];
    next if $line =~ /^#/;
    if ( $line =~ /comment=cloudconfig/ )
    {
        splice @lines, $i, 1;
        $i--;
    }
}
open(OUT, ">$file") or die "Agua::Configure::fixFstab    Can't open file: $file\n";
foreach my $line ( @lines ) {   print OUT $line;    }
close(OUT) or die "Can't close file: $file\n";
}

#### MYSQL
method mysql {
=head2

SUBROUTINE         mysql

PURPOSE

	1. SET MYSQL ROOT PASSWORD (OPTIONAL)
	
	2. LOAD THE AGUA DATABASE (BACKS UP EXISTING DATA)
	
	3. CREATE AGUA MYSQL USER	

	4. CREATE TEST AGUA MYSQL USER	

=cut 

	$self->printMysqlWelcome();
	
    print qq{\n
Continuing with configuration. Please input values for the following items.
(Or hit RETURN to accept the [default_value])

}; 
    #### SET DATABASE NAME
    my $database        =   $self->setDatabase();

	#### CHECK TO RESET ROOTPASSWORD, OTHERWISE GET FROM CONF FILE
	$self->setMysqlRoot();

	#### RELOAD DATABASE
	return if not defined $self->reloadDatabase();
	
	#### OPTIONALLY RESET AGUA MYSQL USER AND PASSWORD    
	my ($user, $password) = $self->setAguaUser();
	
	#### CREATE TEST DATABASE
	$self->createTestDb();

	#### OPTIONALLY RESET TEST AGUA MYSQL USER AND PASSWORD    
	my ($testuser, $testpassword) = $self->setTestUser();

    #### PRINT CONFIRMATION THAT THE agua DATABASE HAS BEEN CREATED
	$self->printMysqlConfirmation($database, $user, $password);
}

method printMysqlWelcome {
		#### PRINT INFO
    print qq{\n
	Welcome to the Agua configuration utility (config.pl)
	
	You can use this application to:

	1. Set the root MySQL password (if not already set)

	2. Create a new Agua database (backs up existing data, loads data from dump file)

	3. Set the Agua MySQL user name and password

	4. Set the name and password for the Agua test MySQL user
	
\n};
	
	#### CHECK FOR QUIT
    print "\nExiting\n\n" and exit if not $self->yes("Type 'Y' to continue or 'N' to exit");
}

method printMysqlConfirmation ($database, $user, $password) {	
	my $configfile = $self->configfile();
	my $logfile = $self->logfile();
	my $timestamp = $self->db()->timestamp();
	print qq{
*******************************************************
MySQL configuration completed.

Please make a note of your MySQL access credentials:

\tDatabase:\t$database
\tUsername:\t$user
\tPassword:\t$password

You can test this on the command line:

\tmysql -u $user -p$password
\tUSE $database
\tSHOW TABLES

Your updated configuration file is here:

\t$configfile

This transaction has been recorded in the log:

\t$logfile

$timestamp
*******************************************************\n};
}

method setDbObject ($database, $user, $password) {
	$self->logDebug("database", $database);

   #### CREATE DB OBJECT USING DBASE FACTORY
    my $db = Agua::DBaseFactory->new( 'MySQL',
        {
			database	=>	$database,
            user      	=>  $user,
            password  	=>  $password,
			logfile		=>	$self->logfile(),
			SHOWLOG		=>	2,
			PRINTLOG	=>	2
        }
    ) or die "Can't create database object to create database: $database. $!\n";

	$self->db($db);
}

method setAguaUser () {
	my $database = $self->database();
	$self->logDebug("database not defined") and exit if not defined $database;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	$self->setDbObject($database, "root", $rootpassword) if not defined $self->db();

	#### GET CURRENT VALUES
    my $user		=   $self->user();
	$user 			=	$self->conf()->getKey("database", "USER") if not $user;
    my $password   	=   $self->password();
	$password		=	$self->conf()->getKey("database", "PASSWORD") if not $password;
	my $length 		= 	9;
	$password		=	$self->createRandomPassword($length) if not $password;

	#### Agua USER NAME
	print "\n";
	$user = $self->_inputValue("Agua MySQL user name", $user);	
    $self->logError("user not defined") if not defined $user;
        
    #### Agua USER PASSWORD
	$password = $self->_inputValue("Agua MySQL user password", $password);	
    $self->logError("password not defined") if not defined $password;

	#### SET Agua USER AND PASSWORD
	$self->_createDbUser($database, $user, $password);

	#### UPDATE CONF FILE
	my $oldmemory = $self->conf()->memory();
	$self->conf()->memory(0);
	$self->logDebug("self->conf()->memory()", $self->conf()->memory());
	$self->conf()->setKey("database", "USER", $user);
	$self->conf()->setKey("database", "PASSWORD", $password);
	$self->conf()->memory($oldmemory);
	
	#### UPDATE SLOTS
    $self->user($user);
    $self->password($password);

	return $user, $password;
}

method setDatabase () {
	my $database = $self->database() || $self->conf()->getKey("database", "DATABASE");
	$database = $self->_inputValue("Agua MySQL database name", $database);
    $self->logError("database not defined") if not defined $database;
	
    $self->database($database);
	$self->conf()->setKey("database", "DATABASE", $database);
	
	return $database;
}

method setMysqlRoot {
	#### PROMPT TO SET ROOT MYSQL PASSWORD
	print "\n";
	my $resetroot = qq{Do you want to reset the MySQL root password?
Type Y to reset or N to skip};

	my $rootpassword;
	if ( $self->yes($resetroot) ) {
		my $rootpassword = $self->_inputRootPassword();
		$self->logError("rootpassword not defined") and return if not defined $rootpassword;

		$self->_setRootPassword($rootpassword);
	}
	else {
		print "\nMySQL root password will not be changed.\n\n";
		my $rootpassword = $self->_inputRootPassword();
		$self->logError("rootpassword not defined") and return if not defined $rootpassword;
		$self->rootpassword($rootpassword);
	}
}

method _inputRootPassword () {
#### MASK TYPING FOR PASSWORD INPUT
    ReadMode 2;
	print "\n";
	my $rootpassword = $self->_inputValue("Please input the current MySQL root password\n(Will not appear on screen)", undef);	

    #### UNMASK TYPING
    ReadMode 0;
    $self->rootpassword($rootpassword);

	return $rootpassword;
}

method createRandomPassword ($length) {
	my $password = '';
	for ( my $i = 0; $i < $length; $i++ ) {
		my $random = int(rand(16)) + 1;
		my $hex = lc(sprintf("%01X", $random));
		$password .= "$hex";
	}
	return $password;
}

method _setRootPassword ($rootpassword) {
	#### RESTART MYSQL WITH  --skip-grant-tables

	print "Setting mysql root password...\n";
	#print "Agu::Configure::setRootPassword    rootpassword: $rootpassword\n";
	#my $stop = "/etc/init.d/mysql stop &> /dev/null";
	#my $stop = "service mysql stop &> /dev/null";
	my $stop = "/usr/bin/mysqladmin -u root -p$rootpassword shutdown &> /dev/null";
	print "Doing '/usr/bin/mysqladmin -u root -p shutdown'\n";
	print `$stop`;
	my $start = "sudo mysqld --skip-grant-tables &";
	print "$start\n";
	system($start);
	sleep(5);
	print "Completed\n";

	#### SET root USER PASSWORD
	my $sqlfile = FindBin::Real::Bin() . "/../sql/setRootPassword.sql";
	$self->logDebug("sqlfile", $sqlfile);
	my $create = qq{
UPDATE mysql.user SET Password=PASSWORD('$rootpassword') WHERE User='root'; 
FLUSH PRIVILEGES;
};
	$self->printToFile($sqlfile, $create);
	my $command = "mysql -u root < $sqlfile";
	$self->logDebug("command", $command);
	print "$command\n";
	print `$command`;
	`rm -fr $sqlfile`;

	#### SET self->rootpassword
	$self->rootpassword($rootpassword);
}

method _getRootPassword {
	my $rootpassword = $self->rootpassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	if ( not $rootpassword ) {
		$rootpassword = $self->_inputRootPassword();
		$self->rootpassword($rootpassword);
	}
	
	return $rootpassword;
}
method reloadDatabase () {
	my $database = $self->database() || $self->conf()->getKey("database", "DATABASE");
	$self->logDebug("database", $database);
	$self->logDebug("database not defined") and exit if not defined $database;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;

	#### SET DB OBJECT
	$self->setDbObject("mysql", "root", $rootpassword);
	
	my $overwrite = 1;
	if ( $self->db()->isDatabase($database) ) {
		$overwrite = $self->_checkOverwrite($database);
	}

	#### CREATE DATABASE 
	$self->_createDb($database) if $overwrite;

	#### POPULATE DATABASE WITH DUMP FILE
	$self->_loadDumpfile($database) if $overwrite;
}

method _checkOverwrite ($database) {
    my $rootuser       	=   $self->rootuser();
    my $rootpassword   	=   $self->rootpassword();

	my $warning = "Database '$database' exists already.\nPress 'Y' to overwrite it or 'N' to skip";
	return 0 if not $self->yes($warning);

	#### CREATE DUMPFILE OF AGUA DATABASE
	print "Doing dumpfile backup of current database: $database\n";
	my $dumpfile = $self->_dumpDb($database, $rootuser, $rootpassword, undef);

	#### DELETE DATABASE
	$self->db()->dropDatabase($database) or die "Can't drop database: $database. $!\n";

	$self->_printOverwriteReport($database, $dumpfile);
	
	return 1;
}

method _printOverwriteReport ($database, $dumpfile) {
	#### TIMESTAMP
	my $timestamp = $self->db()->timestamp();
	my $logfile = $self->logfile();
	my $report = qq{
*******************************************************
Successfully deleted database: $database

The tables and data in the existing database have been
saved here:

$dumpfile

This transaction has been recorded in the log:

\t$logfile

$timestamp
*******************************************************\n};
	print  $report;
	$self->logDebug("report: ", $report);
}

method _dropDatabase ($database) {
	$self->logDebug("database", $database);

	my $query = qq{DROP DATABASE $database};
	my $success = $self->db()->do($query);
	$self->logDebug("Drop database success", $success);
}

method _loadDumpfile ($database) {
	$self->logDebug("database", $database);
    my $rootpassword   	=   $self->rootpassword();
	my $dumpfile		=	$self->dumpfile();
	$self->logDebug("dumpfile", $dumpfile);
	my $command = "mysql -u root -p$rootpassword $database < $dumpfile";
	$self->logDebug("command", $command);
	print `$command`;
}

method setTestUser () {
	my $testdatabase = $self->testdatabase() || $self->conf()->getKey("database", "TESTDATABASE");
	$self->logDebug("testdatabase not defined") and exit if not defined $testdatabase;
	
	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	$self->setDbObject($testdatabase, "root", $rootpassword) if not defined $self->db();

	#### GET CURRENT VALUES
    my $testuser       	=   $self->testuser() || $self->conf()->getKey("database", "TESTUSER");
    my $testpassword   	=   $self->testpassword() || $self->conf()->getKey("database", "TESTPASSWORD");
	my $length 		= 9;
	$testpassword		=	$self->createRandomPassword($length) if not $testpassword;
	
    #### TEST USER NAME
	print "\n";
	$testuser = $self->_inputValue("Test MySQL username", $testuser);	
    
    #### TEST USER PASSWORD
	$testpassword = $self->_inputValue("Test MySQL user password", $testpassword);	

	#### SET Agua USER AND PASSWORD
	$self->_createDbUser($testdatabase, $testuser, $testpassword);

	#### UPDATE CONF FILE
	$self->conf()->setKey("database", "TESTUSER", $testuser);
	$self->conf()->setKey("database", "TESTPASSWORD", $testpassword);

	#### UPDATE SLOTS
    $self->testuser($testuser);
    $self->testpassword($testpassword);

	return $testuser, $testpassword;
}

method createTestDb () {
	my $testdatabase = $self->conf()->getKey("database", "TESTDATABASE");
	$self->logDebug("testdatabase", $testdatabase);
	$self->logDebug("testdatabase not defined") and exit if not defined $testdatabase;

	#### SET DB OBJECT
	my $rootpassword = $self->_getRootPassword();
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;

	#### SET DB OBJECT
	$self->setDbObject("mysql", "root", $rootpassword);
	
	print "\nChecking to see if test database already exists\n";
	print "\nTest database found\n" and return 1 if $self->db()->isDatabase($testdatabase);
	print "\nTest database not found. Creating test database\n";

	#### CREATE DATABASE 
	$self->_createDb($testdatabase);
}

method _createDb ($database) {
    my $rootpassword   	=   $self->rootpassword();
    my $user       		=   $self->user();
    my $password   		=   $self->password();
	print "Creating database: $database\n";

	#### CREATE DATABASE AND Agua USER AND PASSWORD
	my $sqlfile = FindBin::Real::Bin() . "/../sql/_createDb.sql";
    $self->logDebug("sqlfile", $sqlfile);
	my $create = qq{CREATE DATABASE $database;};
	$self->printToFile($sqlfile, $create);
	my $command = "mysql -u root -p$rootpassword < $sqlfile";
	$self->logDebug("$command");
	print `$command`;
	`rm -fr $sqlfile`;
	
	print "Created database: $database\n";
}

method _createDbUser ($database, $user, $password) {
    my $rootuser       	=   $self->rootuser();
    my $rootpassword   	=   $self->rootpassword();
	
	#### CREATE DATABASE AND Agua USER AND PASSWORD
	my $sqlfile = FindBin::Real::Bin() . "/../sql/_createDbUser.sql";
    $self->logDebug("sqlfile: $sqlfile");
	my $create = qq{
USE mysql;
GRANT SHOW DATABASES ON *.* TO '$user'\@'localhost' IDENTIFIED BY '$password';
GRANT ALL ON $database.* TO '$user'\@'localhost' IDENTIFIED BY '$password';	
FLUSH PRIVILEGES;};
	$self->printToFile($sqlfile, $create);
	my $command = "mysql -u $rootuser -p$rootpassword < $sqlfile";
	$self->logDebug("$command");
	print `$command`;
	
	#### CLEAN UP
	`rm -fr $sqlfile`;
}

method _getTimestamp ($database, $user, $password) {
	#### SET DB OBJECT
	$self->setDbObject($database, $user, $password) if not defined $self->db();

	my $timestamp = $self->db()->timestamp();
	$timestamp =~ s/\s+/-/g;
	return $timestamp;
}

method _dumpDb ($database, $user, $password, $dumpfile) {
	$self->logDebug("dumpfile", $dumpfile);

	#### PRINT DUMP COMMAND FILE
	my $timestamp = $self->_getTimestamp($database, $user, $password);
	
	$dumpfile = FindBin::Real::Bin() . "/../sql/dump/agua.$timestamp.dump" if not defined $dumpfile;
	my ($dumpdir) = $dumpfile =~ /^(.+)\/[^\/]+$/;
	$self->logDebug("dumpdir", $dumpdir);
	`mkdir -p $dumpdir` if not -d $dumpdir;
	print "Agua::Configure::_dumpDb    Can't create dumpdir: $dumpdir\n" if not -d $dumpdir;
	
	my $cmdfile = FindBin::Real::Bin() . "/../sql/dump/agua.$timestamp.cmd";
	$self->printToFile($cmdfile, "#!/bin/sh\n\nmysqldump -u $user -p$password $database > $dumpfile\n");

	#### DUMP CONTENTS OF Agua DATABASE TO FILE
	`chmod 755 $cmdfile`;
	print `$cmdfile`;
	`rm -fr $cmdfile`;

	return $dumpfile;
}

#### miscellaneous
method _inputValue ($message, $default) {
	$self->logError("message is not defined") if not defined $message;
	$default = '' if not defined $default;
	print "$message [$default]: ";

	my $input = '';
    while ( $input =~ /^\s*$/ )
    {
        $input = <STDIN>;
        $input =~ s/\s+//g;
		
		$default = $input if $input;
		print "\n" and return $default if $default;

        print "\n$message [$default]: ";
    }
}


method _inputHiddenValue ($message, $default) {
	$self->logDebug("Agua::Configure::inputHiddeValue(message, default)");
	$self->logDebug("message", $message);
	$self->logDebug("default", $default);
	
	$self->logError("Agua::Configure::_inputHiddenValue    message is not defined") if not defined $message;
	$default = '' if not defined $default;
	print "$message []: ";

	my $input = '';
    while ( $input =~ /^\s*$/ )
    {
        $input = <STDIN>;
        $input =~ s/\s+//g;
		$default = $input if $input;
		print "\n" and return $default if $default;

        print "\n$message []: ";
    }
}

method yes ($message) {
#### PROMPT THE USER TO ENTER 'Y' OR 'N'
	return if not defined $message;
	print "$message: ";
    my $max_times = 10;
	
	$/ = "\n";
	my $input = <STDIN>;
	my $counter = 0;
	while ( $input !~ /^Y$/i and $input !~ /^N$/i )
	{
		if ( $counter > $max_times ) { print "Exceeded 10 tries. Exiting...\n"; }
		print "$message: ";
		$input = <STDIN>;
		$counter++;
	}	

	if ( $input =~ /^N$/i )	{	return 0;	}
	else {	return 1;	}
}

method backupFile ($filename) {
	my $counter = 1;
	my $backupfile = "$filename.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$filename.$counter";
	}
	`cp $filename $backupfile`;
	
	$self->logError("Could not create backupfile: $backupfile") if not -f $backupfile;
	print "backupfile created: $backupfile\n";
}



method printToFile ($file, $text) {
	$self->logDebug("file", $file);
	#### PRINT TO FILE
	open(OUT, ">$file") or $self->logCaller() and $self->logCritical("Can't open file: $file") and exit;
	print OUT $text;
	close(OUT) or $self->logCaller() and $self->logCritical("Can't close file: $file") and exit;	
}

=head2 apps

    SUBROUTINE      apps
    
    PURPOSE
    
        CONFIGURE APPLICATIONS INTERACTIVELY:

            1. SET THE PATHS TO EXISTING APPLICATION ENTRIES
            
            2. ADD NEW APPLICATIONS
        
			3. DELETE APPLICATIONS

=cut

method apps {

	### PRINT APPLICATION PATHS        
    my $apps = $self->conf()->get("apps");
	
    print "Type Y to use the default application paths or type N to set application paths\n";
    return if yes("Type Y to use the default application paths or type N to set custom application paths");

    my $continue;
    while ( not defined $continue )
    {
        my $counter = 1;
        foreach my $app ( @$apps )
        {
            my @keys = keys %$app;
            my $key = $keys[0];
            print "$counter $key\t:\t$app->{$key}\n";
            $counter++;
        }
        
        $continue = input("Type application number or 'Q' for quit");
        
        if ( $continue !~ /^\d+$/ and $continue !~ /^q$/i )
        {
            print "\n**** Invalid input: $continue\n\n";
            $continue = undef;
            next;
        }
        
        ### CONTINUE MUST BE A NUMBER OR 'Q'
        if ( $continue =~ /^q$/i )
        {
            last;
        }
        else
        {
            my $app = $$apps[$continue - 1];
            if ( not defined $app )
            {
                print "No application entry for index: $continue\n";
            }
            else
            {
                my @keys = keys %$app;
                my $key = $keys[0];
                
                my $value = input("Enter path to $key [$app->{$key}]");
                $$apps[$continue - 1] = { $key => $value };    
            }
            
            $continue = undef;
        }
    }    
}

method getKey {
	my $key		=	$self->key();
	$self->logError("Agua::Configure::_getKey    key not defined (--key)") if not $key;
	my $value = $self->_getKey();
	print "$value\n";
}

method _getKey {
	my $key		=	$self->key();
	print "Agua::Configure::_getKey    key: $key\n";
	
	return $self->conf()->getValue($key);
}

    




}



