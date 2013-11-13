use MooseX::Declare;
=head2

	PACKAGE		Agua::DBase::MySQL
	
    VERSION:        0.01

    PURPOSE
  
        1. UTILITY FUNCTIONS TO ACCESS A MYSQL DATABASE

=cut 

use strict;
use warnings;
use Carp;

#### INTERNAL MODULES
use FindBin qw($Bin);
use lib "$Bin/../../";
use Agua::DBase;

class Agua::DBase::MySQL extends Agua::DBase with Agua::Common::Logger {

#### EXTERNAL MODULES
use DBI;
use DBD::mysql;
use POSIX;
use Data::Dumper;

# Ints
has 'SHOWLOG'	=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'	=>  ( isa => 'Int', is => 'rw', default => 2 );

# Strings
has 'dbtype'	=> ( isa => 'Str|Undef', is => 'ro', default => 'mysql' );
has 'database'	=> ( isa => 'Str', is => 'rw', default => '' );

# Objects
has 'dbh'		=> ( isa => 'Any', is => 'rw', default => '' );
has 'parent'	=> ( isa => 'Any', is => 'rw', default => undef );

#has 'user'		=> ( isa => 'Str', is => 'rw', default => '' );
#has 'password'	=> ( isa => 'Str', is => 'rw', default => '' );

####////}}}

method BUILD ($args) {
	$self->initialise($args);
}

method initialise ($args) {
	my $database 	=	$args->{database};
	my $user 		=	$args->{user};
	my $password 	=	$args->{password};

	my $parent 		=	$args->{parent};
	$self->logDebug("ref parent", ref $parent);

	#### CONNECT TO DATABASE
	$database = $self->database() if not $database;
	$database = "mysql" if not $database;
	$user = $self->user() if not defined $user or not $user;
	$password = $self->password() if not defined $password or not $password;
	
	die "Agua::DBase::MySQL::initialise    user not defined\n" if not defined $user;
	die "Agua::DBase::MySQL::initialise    password not defined\n" if not defined $password;
	
	my $dsn = "DBI:mysql:$database;mysql_local_infile=1";

	#$self->logNote("self", $self);
	$self->logNote("user", $user);
	$self->logNote("password not defined or empty") if not defined $password or not $password;
	$self->logNote("database", $database);
	$self->logNote("dsn", $dsn);
	
    my $dbh = DBI->connect($dsn, $user, $password, { 'PrintError' => 1, 'RaiseError' => 0 });
	$self->logNote("dbh", $dbh);
	#$self->logDebug("dbh", $dbh);
	
	return if not defined $dbh;

	$self->dbh($dbh);
}


method showTables () {
	$self->logNote("");
	return if not defined $self->dbh();
	my $query = "show tables";
	return $self->queryarray($query);
}

method querytwoDarray ($query) {    
#### RETURN AN ARRAY OF HASHES
	$self->logNote("");

	#### GET FIELDS 
    my ($fieldstring) = $query =~ /^SELECT (.+) FROM/i;
    $fieldstring =~ s/\s+//g;
    my $fields;
    if ( $fieldstring =~ /^\*$/ )
    {
        $self->logNote("Field string is '*'");
        my ($table) = $query =~ /FROM\s+(\S+)/i;
        $self->logNote("query", $query);
        $self->logNote("table", $table);
        $fields = $self->fields($table);
    }
    else
    {
        @$fields = split ",", $fieldstring;
        
    }

	my $twoDarray;
    my $response = $self->dbh()->selectall_arrayref($query);
    foreach( @$response )
    {
		my $hash; 
        foreach my $i (0..$#$_)
        {
           $hash->{$fields->[$i]} = $_->[$i];
        }

        my $array = [];
        foreach my $field ( @$fields )
        {
    		push @$array, $hash->{$field};
        }

		push @$twoDarray, $array;
    }
	return $twoDarray;
}


method tableFieldHasEntry ($table, $field) {
=head2

	SUBROUTINE		tableFieldHasEntry
	
	PURPOSE
	
		CHECK IF THERE ARE ANY ENTRIES FOR THE GIVEN FIELD IN
		
		THE TABLE (I.E., MUST BE NON-EMPTY AND NON-NULL). IF NONE
		
		EXIST, RETURN ZERO. OTHERWISE, RETURN 1.
		
=cut
	return if not defined $table or not $table;
	return if not defined $field or not $field;
	my $hasTable = hasTable($self->dbh(), $table);
	if ( not $hasTable )	{	return 0;	}
	
	my $query = qq{SELECT COUNT(*) FROM $table WHERE $field!='' OR $field IS NOT NULL};
	my $count = simple_query($self->dbh(), $query);
	if ( not defined $count )	{	$count = 0;	}
	
	if ( $count == 0 )	{	return 0;	}
	
	return 1;
}

method hasTable ($table) {
=head2

	SUBROUTINE		hasTable
	
	PURPOSE
	
		1. CHECK IF A TABLE EXISTS IN THE DATABASE
		
		2. RETURN 1 IF EXISTS, RETURN ZERO IF OTHERWISE
		
=cut
	return if not defined $table or not $table;

	my $tables = $self->showTables();
	return 0 if not defined $tables;
	for ( my $i = 0; $i < @$tables; $i++ )
	{
		return 1 if $table =~ /^$$tables[$i]$/;
	}
	
	return 0;
}

method updateFulltext ($table, $fulltext, $fields) {
#### UPDATE THE FULLTEXT INDEX OF A TABLE	
	if ( not defined $self->dbh() or not defined $table or not defined $fulltext or not defined $fields )	{	return;	}

    $| = 1;
	if ( tableHasIndex($self->dbh(), $table, $fulltext) )
	{
		dropIndex($self->dbh(), $table, $fulltext);
	}
	
	my $query = qq{ALTER TABLE $table ADD FULLTEXT $fulltext ($fields)};
	my $success = do_query($self->dbh(), $query);
	return $success;
}


method tableHasIndex ($table, $index) {
#### RETURN 1 IF THE NAME IS AMONG THE LIST OF A TABLE'S INDICES 
	my $indices = indices($self->dbh(), $table);
	if ( not defined $indices )	{	return 0;	}
	
	for ( my $i = 0; $i < @$indices; $i++ )
	{
		if ( $$indices[$i] =~ /^$index$/ )	{	return 1;	}
	}
	
	return 0;
}


method indices ($table) {
#### RETURN A LIST OF A TABLE'S INDICES 
    my $query = qq{SHOW CREATE TABLE $table};
	my $result = simple_query($self->dbh(), $query);

	#### FORMAT:
	# PRIMARY KEY  (`collectionid`,`collectionaccession`,`collectionversion`),
	# FULLTEXT KEY `collectionannotation` (`targetannotation`,`targetsource`,`targetid`)
	#) TYPE=MyISAM |

	my @lines = split "\n", $result;
	my $indices;
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		$lines[$i] =~ /^\s*\S+\s+KEY\s+`(\w+)`\s+\(/;
		if ( defined $1 )	{	push @$indices, $1;	}
	}

	return $indices;	
}


method dropIndex ($table, $index) {
#### RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS
    my $query = qq{DROP INDEX $index ON $table};
	my $success = do_query($self->dbh(), $query);
	return $success;	
}


method tsvToHash ($tsvline, $fields) {
#### RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS
	my $hash;
	my @elements = split "\t", $tsvline;
	my @fields_array = split "," , $fields;
	for ( my $i = 0; $i < $#fields_array + 1; $i++ )
	{
		my $element = $elements[$i];
		$$hash{$fields_array[$i]} = $element;
	}
	
	return $hash;
}


method do ($query) {
#### RETURN 1 IF COMMAND WAS SUCCESSFUL, OTHERWISE RETURN 0	
	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR
	my $success = $self->dbh()->do($query); ### or warn "Query failed: $DBI::errstr ($DBI::err)\n";
	$self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR

	return 1 if $success;
	return 0;
}

	
method query ($query) {
#### RETURN A SINGLE, SCALAR QUERY RESULT
    my $sth = $self->dbh()->prepare($query);
	$sth->execute;
    return $sth->fetchrow;
}

method queryarray ($query) {
#### RETURN AN ARRAY OF SCALARS
	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR	
    my $sth = $self->dbh()->prepare($query);
    $self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
	$sth->execute;
	
	my $array;
    my $result = 0;
	while ( defined $result )
    {
        $result = $sth->fetchrow;
        if ( defined $result )	{	push @$array, $result;	}
    }
    
	return $array;
}

method queryhash ($query) {
#### RETURN A HASH    

$self->logCaller("query: $query");

	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR	
    my $sth = $self->dbh()->prepare($query);
    $self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
	$sth->execute;
	
    return $sth->fetchrow_hashref;
}

method queryhasharray ($query) {
#### RETURN AN ARRAY OF HASHES
	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR
    my $sth = $self->dbh()->prepare($query);
	$sth->execute;
	$self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
	my $hasharray;
	while ( my $hash = $sth->fetchrow_hashref )	{	push @$hasharray, $hash;	}
	
	return $hasharray;
}

method tableEmpty ($table) {
#### RETURN 1 IF TABLE IS EMPTY, OTHERWISE RETURN 0
	my $query = qq{SELECT * FROM $table LIMIT 1};
    my $sth = $self->dbh()->prepare($query);
    $sth->execute;
    my $result = $sth->fetchrow;
    
    if ( $result )  {   return 0;   };
    return 1;
}

method fields ($table) {
#### RETURN AN ARRAY OF THE TABLES FIELDS OR '' IF NOT DEFINED
	#$self->logCaller("table: $table");
	#$self->logDebug("self->dbh", $self->dbh());
    my $sth = $self->dbh()->prepare("SELECT * FROM $table LIMIT 1") or die "Can't prepare field names query!\n";
    $sth->execute or die "Can't execute field names query!\n";
    my $fields;
    $fields = $sth->{NAME};

    return $fields;   
}

method hasField ($table, $field) {
#### CHECK IF A TABLE HAS A PARTICULAR FIELD
	my $hasTable = hasTable($self->dbh(), $table);
	if ( not $hasTable )	{	return 0;	}
	
	my $fields = fieldsToArray($self->dbh(), $table);
	if ( not defined $fields )	{	return 0;	}
	
	for ( my $i = 0; $i < @$fields; $i++ )
	{
		if ( $$fields[$i] =~ /^$field$/ )	{	return 1;	}
	}
	
	return 0;
}



method fieldsToArray ($table) {
=head2

	SUBROUTINE		fieldsToArray
	
	PURPOSE
	
		CHECK IF THERE ARE ANY ENTRIES FOR THE GIVEN FIELD IN
		
		THE TABLE (I.E., MUST BE NON-EMPTY AND NON-NULL). IF NONE
		
		EXIST, RETURN ZERO. OTHERWISE, RETURN 1.
		
=cut
	my $query = qq{SHOW CREATE TABLE $table};
	my $result = $self->query($query);

	#### FORMAT:
	# PRIMARY KEY  (`collectionid`,`collectionaccession`,`collectionversion`),
	# FULLTEXT KEY `collectionannotation` (`targetannotation`,`targetsource`,`targetid`)
	#) TYPE=MyISAM |

	my @lines = split "\n", $result;
	my $fields;
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		$lines[$i] =~ s/^\s*\S+\s+KEY\s+.+$//;
		if ( defined $1 )	{	push @$fields, $1;	}
	}

	return $fields;	
}

method fieldsToInsert ($fieldstring, $hash, $table) {
=head2

	SUBROUTINE		fieldsToInsert
	
	PURPOSE
	
		CREATE AN INSERT QUERY .TSV LINE (FOR LOAD) BASED ON THE FIELDS
		
		AND THE HASH, MAKING DEFINED WHEN A FIELD key IS 
		
		NOT PRESENT IN THE HASH

=cut 

	$fieldstring =~ s/\s//g;
	#### SET THE ARRAY OF TABLE FIELDS
	my $fields;
    @$fields = split ",", $fieldstring;
	
	#### CHECK VALUES ARE THERE
	if ( not defined $table or not $table )
	{
		die "Database::fieldsToInsert(fields, hash, table). Table not defined or empty. Exiting...\n";
	}
	if ( not @$fields)
	{
		die "Database::fieldsToInsert(fields, hash, table). Fields is empty. Exiting...\n";
	}
	if ( not defined $hash )
	{
		die "Database::fieldsToInsert(fields, hash, table). Hash is empty. Exiting...\n";
	}

	#### START insert
    my $insert = 'INSERT INTO $table (\n';

	#### DO THE FIELD NAMES
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        $insert .= "\t" . $$fields[$i]. ",\n";        
    }
	$insert .= ")\n";

	#### DO THE FIELD VALUES
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        no warnings;
        my $value = $$hash{$$fields[$i]} ? $$hash{$$fields[$i]} : '';
		$value =~ s/'/\\'/g;        
		$value =~ s/\\\\\\'/\\'/g;
        $insert .= "\t$value,\n";        
        use warnings;        
    }
       
    return $insert;
}



method fieldsToTsv ($fields, $hash) {
=head2

	SUBROUTINE		fieldsToTsv
	
	PURPOSE
	
		CREATE A .TSV LINE (FOR LOAD) BASED ON THE FIELDS
		
		AND THE HASH, MAKING DEFINED WHEN A FIELD key IS 
		
		NOT PRESENT IN THE HASH

=cut 

    my $tsvline = '';

    for ( my $i = 0; $i < @$fields; $i++ )
    {
        my $value = $$hash{$$fields[$i]} ? $$hash{$$fields[$i]} : '';
		$value =~ s/'/\\'/g;        
		$value =~ s/\\\\\\'/\\'/g;
        $tsvline .= "$value\t";
    }
    $tsvline .= "\n";

    return $tsvline;
}
    

method fieldsToCsv ($fields, $hash) {
=head2

	SUBROUTINE		fieldsToCsv
	
	PURPOSE
	
		CREATE A .CSV LINE FOR TABLE INSERTS USING ''
		
		WHEN NO KEY VALUE IS PRESENT IN THE INPUT HASH
		
	INPUTS
		
		1. COMMA-SEPARATED fields
		
		2. HASH OF TABLE field KEY-VALUE PAIRS 

=cut
    my $csvline = '';
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        no warnings;
        my $value = defined $$hash{$$fields[$i]} ? $$hash{$$fields[$i]} : '';
		$value =~ s/'/\\'/g;
		$value =~ s/\\\\\\'/\\'/g;
		$self->logNote("value", $value);

		$value = "'$value'," if $value !~ /^NOW\(\)$/i and $value !~ /^DATETIME\('NOW'\)$/i;
		$value = "$value," if $value =~ /^NOW\(\)$/i or $value =~ /^DATETIME\('NOW'\)$/i;
        use warnings;
        
        $csvline .= $value;
    }
	$csvline =~ s/,$//;
    
    return $csvline;
}
    




method fieldPresent ($table, $field) {
#### RETURN 1 IF FIELD PRESENT, 0 OTHERWISE
	my $sth = $self->dbh()->prepare("SELECT * FROM $table") or die "Can't prepare statement!\n";
	$sth->execute or die "Can't execute statement!\n";
	my $fieldPresent = 0;
	my @fields = @{$sth->{NAME}};
	for ( my $i = 0; $i < $#fields + 1; $i++ )
	{
		if ( $fields[$i] =~ /^$field$/ )	{	$fieldPresent = 1;	}	
	}
	
	return $fieldPresent;
}


method _requiredFields ($table) {
#### RETURN AN ARRAY OF THE TABLES FIELDS OR '' IF NOT DEFINED
	return if not defined $table or not $table;
	my $structure = $self->getStructure($table);
	my $_requiredFields = [];
	foreach my $field ( @$structure )
	{
		push @$_requiredFields, $field->{f_name} if $field->{f_nullable} == 0 
	}
    return $_requiredFields;   
}

method getStructure ($table) {	
=head2

	SUBROUTINE		getStructure
	
	PURPOSE
	
		RETURN A HASH ARRAY OF THE TABLE'S FIELD DETAILS, E.G.:

		[
			{
			  'f_name' => 'username',
			  'f_autoinc' => 0,
			  'f_pri_key' => 1,
			  'f_nullable' => 0,
			  'f_length' => 30,
			  'f_type' => 'varchar'
			},
			...
		]

		
=cut
	my $query = "SELECT * FROM $table";
	my $sth 	=	$self->dbh()->prepare($query) or die "Can't prepare statement!\n";
	die "Error: " . $self->dbh()->errstr . "\n" unless ($sth);
	die "Error: " . $sth->errstr . "\n" unless ($sth->execute);
	#my $output = $self->query($query);

	my $names         = $sth->{'NAME'};
	my $type          = $sth->{'mysql_type_name'};
	my $length        = $sth->{'mysql_length'};
	my $is_nullable   = $sth->{'NULLABLE'};
	my $is_pri_key    = $sth->{'mysql_is_pri_key'};
	my $is_autoinc    = $sth->{'mysql_is_auto_increment'};
	
	my $structure;	
	@$structure = map {
	   { 
		  f_name      => $names->[$_],
		  f_type      => $type->[$_],
		  f_length    => $length->[$_], 
		  f_nullable  => $is_nullable->[$_] ? 1 : 0,
		  f_pri_key   => $is_pri_key->[$_]  ? 1 : 0,
		  f_autoinc   => $is_autoinc->[$_]  ? 1 : 0,
	   };
	} (0..$#{$names});
	return $structure;
}

method load ($table, $file, $extra) {
#### LOAD DATA FROM .TSV FILE INTO TABLE
	my $query = qq{LOAD DATA INFILE '$file' INTO TABLE $table};
    if ( defined $extra )   {   $query .= " $extra";    }
	$self->logNote("Query", $query);

	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR
	my $count = $self->dbh()->do($query) or warn "Query failed: $DBI::errstr ($DBI::err)\n";
	if ( not $count ) {   print "Agua::DBase::MySQL    DID NOT LOAD!\n";    }
	$self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
}




method loadNoDups ($table, $file) {
#### LOAD DATA FROM FILE INTO TABLE AND IGNORE DUPLICATES

	#### LOAD DATA INTO TABLE
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR
	my $count = $self->dbh()->do($query) or warn "Query failed: $DBI::errstr ($DBI::err)\n";
	if ( not $count ) {   print "Agua::DBase::MySQL    DID NOT LOAD!\n";    }
	$self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
}



method createDatabaseQuery ($database) {
#### CREATE DATABASE BY QUERY IF NOT EXISTS
	my $query = qq{CREATE DATABASE $database};
	my $result = $self->do($query);
	
	return 0 if not defined $result;
	return 1;
}

=head2 create database REMOTE CALL

	SUBROUTINE		createDatabase
	
	PURPOSE
	
        CREATE DATABASE IF NOT EXISTS
=cut

method createDatabase ($database) {
	my $user		=	$self->user();
	my $password	=	$self->password();
	$self->logNote("database", $database);
	$self->logNote("user", $user);
	$self->logNote("password not defined or empty") if not defined $password or not $password;

    my $drh = DBI->install_driver("mysql");
	my $remotecall = $drh->func('createdb', $database, 'localhost', $user, $password, 'admin');
	$self->logNote("remotecall", $remotecall);

    return $remotecall;
}

method useDatabase ($database) {
#### USE DATABASE IF EXISTS

print "Agua::DBase::MySQL::useDatabase    database: $database\n";

	my $query = qq{USE $database};
	my $result = $self->do($query);
	
	return 0 if not defined $result;
	return 1;
}


method isDatabase ($database) {
#### RETURN 1 IF A DATABASE EXISTS WITH THE GIVEN NAME, OTHERWISE RETURN 0
	my $user = $self->user();
	my $password = $self->password();
	die "Agua::DBase::MySQL::isDatabase    user not defined\n" if not defined $user;
	die "Agua::DBase::MySQL::isDatabase    password not defined\n" if not defined $password;
	
	my $dsn = "DBI:mysql:information_schema";

	$self->logNote("user", $user);
	$self->logNote("password not defined or empty") if not defined $password or not $password;
	
    my $dbh = DBI->connect($dsn, $user, $password, { 'PrintError' => 1, 'RaiseError' => 0 });
	$self->logNote("dbh", $dbh);
	
	my $query = qq{SHOW DATABASES};
	$dbh->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR	
    my $sth = $dbh->prepare($query);
    $dbh->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
	$sth->execute;
	
	my $array;
    my $result = 0;
	while ( defined $result )
    {
        $result = $sth->fetchrow;
		return 1 if defined $result and $result eq $database;
    }

	return 0;
}

method isTable ($table) {
#### RETURN 1 IF A TABLE EXISTS IN THE DATABASE, OTHERWISE RETURN 0
	$self->logNote("(table)");
	$self->logNote("table", $table);

	my $query = qq{SHOW TABLES};
	my $tables = $self->queryarray($query);
	$self->logNote("tables: @$tables");
	for my $tablename ( @$tables )	{	return 1 if $tablename eq $table; }

	return 0;
}




method dropDatabaseQuery ($database) {
	return 1 if not $self->isDatabase($database);
	my $query = qq{DROP DATABASE $database};
	my $result = $self->do($query);

	return 0 if not defined $result;	
	return 1;
}

method dropDatabase ($database) {
	my $user		=	$self->user();
	my $password	=	$self->password();
	$self->logNote("database", $database);
	$self->logNote("user", $user);
	$self->logNote("password not defined or empty") if not defined $password or not $password;

    my $drh = DBI->install_driver("mysql");
	my $remotecall = $drh->func('dropdb', $database, 'localhost', $user, $password, 'admin');
	$self->logNote("remotecall", $remotecall);

    return $remotecall;
}

method isReservedWord ($word) {
	my @reserved_words = qw(
		ACCESSIBLE
		ALTER
		AS
		BEFORE
		BINARY
		BY
		CASE
		CHARACTER
		COLUMN
		CONTINUE
		CROSS
		CURRENT_TIMESTAMP
		DATABASE
		DAY_MICROSECOND
		DEC
		DEFAULT
		DESC
		DISTINCT
		DOUBLE
		EACH
		ENCLOSED
		EXIT
		FETCH
		FLOAT8
		FOREIGN
		GRANT
		HIGH_PRIORITY
		HOUR_SECOND
		IN
		INNER
		INSERT
		INT2
		INT8
		INTO
		JOIN
		KILL
		LEFT
		LINEAR
		LOCALTIME
		LONG
		LOOP
		MATCH
		MEDIUMTEXT
		MINUTE_SECOND
		NATURAL
		NULL
		OPTIMIZE
		OR
		OUTER
		PRIMARY
		RANGE
		READ_WRITE
		REGEXP
		REPEAT
		RESTRICT
		RIGHT
		SCHEMAS
		SENSITIVE
		SHOW
		SPECIFIC
		SQLSTATE
		SQL_CALC_FOUND_ROWS
		STARTING
		TERMINATED
		TINYINT
		TRAILING
		UNDO
		UNLOCK
		USAGE
		UTC_DATE
		VALUES
		VARCHARACTER
		WHERE
		WRITE
		ZEROFILL
		ALL
		AND
		ASENSITIVE
		BIGINT
		BOTH
		CASCADE
		CHAR
		COLLATE
		CONSTRAINT
		CREATE
		CURRENT_TIME
		CURSOR
		DAY_HOUR
		DAY_SECOND
		DECLARE
		DELETE
		DETERMINISTIC
		DIV
		DUAL
		ELSEIF
		EXISTS
		FALSE
		FLOAT4
		FORCE
		FULLTEXT
		HAVING
		HOUR_MINUTE
		IGNORE
		INFILE
		INSENSITIVE
		INT1
		INT4
		INTERVAL
		ITERATE
		KEYS
		LEAVE
		LIMIT
		LOAD
		LOCK
		LONGTEXT
		MASTER_SSL_VERIFY_SERVER_CERT
		MEDIUMINT
		MINUTE_MICROSECOND
		MODIFIES
		NO_WRITE_TO_BINLOG
		ON
		OPTIONALLY
		OUT
		PRECISION
		PURGE
		READS
		REFERENCES
		RENAME
		REQUIRE
		REVOKE
		SCHEMA
		SELECT
		SET
		SPATIAL
		SQLEXCEPTION
		SQL_BIG_RESULT
		SSL
		TABLE
		TINYBLOB
		TO
		TRUE
		UNIQUE
		UPDATE
		USING
		UTC_TIMESTAMP
		VARCHAR
		WHEN
		WITH
		YEAR_MONTH
		ADD
		ANALYZE
		ASC
		BETWEEN
		BLOB
		CALL
		CHANGE
		CHECK
		CONDITION
		CONVERT
		CURRENT_DATE
		CURRENT_USER
		DATABASES
		DAY_MINUTE
		DECIMAL
		DELAYED
		DESCRIBE
		DISTINCTROW
		DROP
		ELSE
		ESCAPED
		EXPLAIN
		FLOAT
		FOR
		FROM
		GROUP
		HOUR_MICROSECOND
		IF
		INDEX
		INOUT
		INT
		INT3
		INTEGER
		IS
		KEY
		LEADING
		LIKE
		LINES
		LOCALTIMESTAMP
		LONGBLOB
		LOW_PRIORITY
		MEDIUMBLOB
		MIDDLEINT
		MOD
		NOT
		NUMERIC
		OPTION
		ORDER
		OUTFILE
		PROCEDURE
		READ
		REAL
		RELEASE
		REPLACE
		RETURN
		RLIKE
		SECOND_MICROSECOND
		SEPARATOR
		SMALLINT
		SQL
		SQLWARNING
		SQL_SMALL_RESULT
		STRAIGHT_JOIN
		THEN
		TINYTEXT
		TRIGGER
		UNION
		UNSIGNED
		USE
		UTC_TIME
		VARBINARY
		VARYING
		WHILE
		XOR);
	
	for my $reserved_word ( @reserved_words )
	{
		return 1 if $reserved_word eq $word;
	}
	
	return 0;
}

method now {
	return "NOW()";
}


} #### END


