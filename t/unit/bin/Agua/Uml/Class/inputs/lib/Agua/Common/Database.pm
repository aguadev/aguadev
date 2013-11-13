package Agua::Common::Database;
use Moose::Role;

=head2

	PACKAGE		Agua::Common::Util
	
	PURPOSE
	
		UTILITY METHODS FOR Agua::Common
		
=cut
#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../../";
use Term::ReadKey;
use Agua::DBaseFactory;

use Data::Dumper;

has 'database'	=> ( isa => 'Str|Undef', is => 'rw' );

sub setDbh {
	my $self		=	shift;
	my $args		=	shift;

	$self->logNote("args", $args);	
	
	my $database 	=	$args->{database};
	my $user 		=	$args->{user};
	my $password 	=	$args->{password};
	my $dbtype 		=	$args->{dbtype};
	my $dbfile 		=	$args->{dbfile};

	my $logfile = $self->logfile();
	my $SHOWLOG = $self->SHOWLOG();
	my $PRINTLOG = $self->PRINTLOG();

	$self->logNote("AFTER database", $database);
	$self->logNote("AFTER dbtype", $dbtype);
	$self->logNote("AFTER user", $user);
	#$self->logNote("AFTER password", $password);
	
	$dbfile 	=	$self->conf()->getKey('database', 'DBFILE') if not defined $dbfile;
	$dbtype 	=	$self->conf()->getKey('database', 'DBTYPE') if not defined $dbtype;
	if ( $self->can('isTestUser') and $self->isTestUser() ) {
		$user 		=	$self->conf()->getKey('database', 'TESTUSER') if not defined $user;
		$password 	=	$self->conf()->getKey('database', 'TESTPASSWORD') if not defined $password;
		$database	=	$self->conf()->getKey('database', 'TESTDATABASE') if not defined $database;
	}
	else {
		$user 		=	$self->conf()->getKey('database', 'USER') if not defined $user;
		$password 	=	$self->conf()->getKey('database', 'PASSWORD') if not defined $password;
		$database	=	$self->conf()->getKey('database', 'DATABASE') if not defined $database;
	}
	
	$self->logNote("AFTER database", $database);
	$self->logNote("AFTER dbtype", $dbtype);
	$self->logNote("AFTER user", $user);
	#$self->logNote("AFTER password", $password);
	
	$self->logError("dbtype not defined") and return if not $dbtype;
	$self->logError("user not defined") and return if not $user;
	$self->logError("password not defined") and return if not $password;
	$self->logError("database not defined") and return if not $database;

	#### SET DATABASE IF PROVIDED IN JSON
	if ( $self->can('json') ) {
		my $json = $self->json();
		$database = $json->{database} if defined $json and defined $json->{database} and $json->{database};
	}

	$self->logNote("FINAL database", $database);
	$self->logNote("FINAL dbtype", $dbtype);
	$self->logNote("FINAL user", $user);
	#$self->logNote("FINAL password", $password);

	##### CREATE DB OBJECT USING DBASE FACTORY
	my $db = 	Agua::DBaseFactory->new(
		$dbtype,
		{
			dbfile		=>	$dbfile,
			database	=>	$database,
			user        =>  $user,
			password    =>  $password,
			logfile		=>	$logfile,
			SHOWLOG		=>	$SHOWLOG,
			PRINTLOG	=>	$PRINTLOG,
			parent		=>	$self
		}
	) or print qq{ error: 'Agua::Database::setDbh    Cannot create database object $database: $!' } and return;
	$self->logError("db not defined") and return if not defined $db;

	$self->db($db);	

	return $db;
}

sub grantPrivileges {
	my $self			=	shift;
	my $tempfile		=	shift;
	my $rootpassword 	= 	shift;
    my $database       	=   shift;
    my $user       		=   shift;
    my $password   		=   shift;
    my $privileges 		=   shift;
    my $host   			=   shift;
	$self->logError("tempfile not defined") and return if not defined $tempfile;
	$self->logError("rootpassword not defined") and return if not defined $rootpassword;
	$self->logError("database not defined") and return if not defined $database;
	$self->logError("user not defined") and return if not defined $user;
	$self->logError("password not defined") and return if not defined $password;
	$self->logError("privileges not defined") and return if not defined $privileges;
	$self->logError("host not defined") and return if not defined $host;

	#### CREATE DATABASE AND Agua USER AND PASSWORD
    $self->logNote("tempfile", $tempfile);
	my $create = qq{
USE mysql;
GRANT ALL PRIVILEGES ON $database.* TO $user\@localhost IDENTIFIED BY '$password';	
FLUSH PRIVILEGES;};
	`echo "$create" > $tempfile`;
	my $command = "mysql -u root -p$rootpassword < $tempfile";
	$self->logNote("$command");
	print `$command`;
	`rm -fr $tempfile`;
}

sub inputRootPassword {
	my $self	=	shift;
	
    #### MASK TYPING FOR PASSWORD INPUT
    ReadMode 2;
	my $rootpassword = $self->inputValue("Root password (will not appear on screen)");

    #### UNMASK TYPING
    ReadMode 0;

	$self->rootpassword($rootpassword);

	return $rootpassword;
}

sub inputValue {
	my $self		=	shift;
	my $message		=	shift;
	my $default		=	shift; 

	$self->logError("message is not defined") and return if not defined $message;
	$default = '' if not defined $default;
	$self->logDebug("$message [$default]: ");
	print "$message [$default]: ";

	my $input = '';
    while ( $input =~ /^\s*$/ )
    {
        $input = <STDIN>;
        $input =~ s/\s+//g;
		$default = $input if $input;
		print "\n" and return $default if $default;
        $self->logDebug("$message [$default]: ");
		print "$message [$default]: ";
    }
}




1;

