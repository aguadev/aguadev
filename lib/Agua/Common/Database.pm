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
has 'db'                => ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );

sub setDbh {
	my $self		=	shift;
	my $args		=	shift;

	$self->logNote("args", $args);	
	
	my $database 	=	$args->{database} || $self->database();
	my $user 		=	$args->{user};
	my $password 	=	$args->{password};
	my $dbtype 		=	$args->{dbtype};
	my $dbfile 		=	$args->{dbfile};

	my $logfile = $self->logfile();
	my $showlog = $self->showlog();
	my $printlog = $self->printlog();

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
			showlog		=>	$showlog,
			printlog	=>	$printlog,
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




sub _updateTable {
=head2

	SUBROUTINE		_updateTable
	
	PURPOSE

		UPDATE ONE OR MORE ENTRIES IN A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. HASH CONTAINING OBJECT TO BE UPDATED

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut
	my $self		=	shift;
	my $table		=	shift;
	my $hash		=	shift;
	my $required_fields		=	shift;
	my $set_hash	=	shift;
	my $set_fields	=	shift;
 	$self->logNote("Common::_updateTable(table, hash, required_fields, set_fields)");
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("set_hash not defined") and return if not defined $set_hash;
    $self->logError("set_fields not defined") and return if not defined $set_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### GET WHERE
	my $where = $self->db()->where($hash, $required_fields);

	#### GET SET
	my $set = $self->db()->set($set_hash, $set_fields);
	$self->logError("set values not defined") and return if not defined $set;

	##### UPDATE TABLE
	my $query = qq{UPDATE $table $set $where};           
	$self->logNote("$query");
	my $result = $self->db()->do($query);
	$self->logNote("result", $result);
}

sub _addToTable {
=head2

	SUBROUTINE		_addToTable
	
	PURPOSE

		ADD AN ENTRY TO A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut

	my $self			=	shift;
	my $table			=	shift;
	my $hash			=	shift;
	my $required_fields	=	shift;
	my $inserted_fields	=	shift;
	
	#### CHECK FOR ERRORS
    $self->logError("hash not defined for table: $table") and return if not defined $hash;
    $self->logError("required_fields not defined for table: $table") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("table '$table' undefined values: @$not_defined") and return if @$not_defined;

	#### GET ALL FIELDS BY DEFAULT IF INSERTED FIELDS NOT DEFINED
	$inserted_fields = $self->db()->fields($table) if not defined $inserted_fields;

	$self->logError("table '$table' fields not defined") and return if not defined $inserted_fields;
	my $fields_csv = join ",", @$inserted_fields;
	
	##### INSERT INTO TABLE
	my $values_csv = $self->db()->fieldsToCsv($inserted_fields, $hash);
	my $query = qq{INSERT INTO $table ($fields_csv)
VALUES ($values_csv)};           
	$self->logDebug("$query");
	my $result = $self->db()->do($query);
	$self->logDebug("result", $result);
	
	return $result;
}

sub _removeFromTable {
=head2

	SUBROUTINE		_removeFromTable
	
	PURPOSE

		REMOVE AN ENTRY FROM A TABLE
        
	INPUTS
		
		1. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
		
		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. NAME OF TABLE      
=cut

	my $self		=	shift;	
	my $table		=	shift;
	my $hash		=	shift;
	my $required_fields		=	shift;
 	
    #### CHECK INPUTS
    $self->logError("hash not defined") and return if not defined $hash;
    $self->logError("required_fields not defined") and return if not defined $required_fields;
    $self->logError("table not defined") and return if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->db()->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and return if @$not_defined;

	#### DO DELETE 
	my $where = $self->db()->where($hash, $required_fields);
	my $query = qq{DELETE FROM $table
$where};
	$self->logNote("\n$query");
	my $result = $self->db()->do($query);
	$self->logDebug("result", $result);		;
	
	return 1 if defined $result;
	return 0;
}


sub arrayToArrayhash {
=head2

    SUBROUTINE:     arrayToArrayhash
    
    PURPOSE:

        CONVERT AN ARRAY INTO AN ARRAYHASH, E.G.:
		
		{
			key1 : [ entry1, entry2 ],
			key2 : [ ... ]
			...
		}

=cut

	my $self		=	shift;
	my $array 		=	shift;
	my $key			=	shift;
	
	#$self->logNote("Common::arrayToArrayhash(array, key)");
	#$self->logNote("array: @$array");
	#$self->logNote("key", $key);

	my $arrayhash = {};
	for my $entry ( @$array )
	{
		if ( not defined $entry->{$key} )
		{
			$self->logNote("entry->{$key} not defined in entry. Returning.");
			return;
		}
		$arrayhash->{$entry->{$key}} = [] if not exists $arrayhash->{$entry->{$key}};
		push @{$arrayhash->{$entry->{$key}}}, $entry;		
	}
	
	#$self->logNote("returning arrayhash", $arrayhash);
	return $arrayhash;
}

1;

