use MooseX::Declare;
=head2

	PACKAGE		DBase::SQLite
	
    VERSION:        0.01

    PURPOSE
  
        1. UTILITY FUNCTIONS TO ACCESS AN SQLite DATABASE

=cut 

use strict;
use warnings;
use Carp;


class Agua::DBase::SQLite extends Agua::DBase {
	
#### EXTERNAL MODULES
use POSIX;
use Data::Dumper;
use DBI;
use DBD::SQLite;

has 'dbtype'	=> ( isa => 'Str|Undef', is => 'ro', default => 'sqlite' );
has 'dbh'		=> ( isa => 'Any', is => 'rw', default => '' );
has 'database'	=> ( isa => 'Str', is => 'rw', default => '' );
has 'sqlite'	=> ( isa => 'Str', is => 'rw', default => '' );
has 'dbfile'	=> ( isa => 'Str', is => 'rw', default => '' );
has 'user'		=> ( isa => 'Str', is => 'rw', default => '' );
has 'password'	=> ( isa => 'Str', is => 'rw', default => '' );

####///}}}


method BUILD ($hash) {
	$self->initialise($hash);
}

method initialise ($hash) {
	#### CONNECT TO DATABASE
	my $dbfile	=	$self->dbfile();
	die "SQLite database file not defined"if not defined $dbfile;
	
	my $dbh = DBI->connect("dbi:SQLite:$dbfile", '', '') || die "Can't open database file '$dbfile': $@\n";   	
	$self->dbh($dbh);
	
	return $self->dbh();
}

method dropTable ($table) {
=head2

	SUBROUTINE		dropTable
	
	PURPOSE
	
		DROP A TABLE 

=cut
    my $result = $self->dbh()->do( "DROP TABLE IF EXISTS $table" );
    $self->logDebug("Dropped table: $table, result", $result);
	return $result;
}

method createTable ($sqlfile) {

=head2

	SUBROUTINE		createTable
	
	PURPOSE
	
		CREATE A TABLE FROM AN .SQL FILE (I.E., CONTAINING "CREATE TABLE IF NOT EXISTS tablename...")

=cut
	$self->logDebug("self->dbh()", $self->dbh());
		
    #### CONVERT filePath AND destinationPath ON WINDOWS
    if ( $^O =~ /^MSWin32$/ )   {   $sqlfile =~ s/\//\\/g;  }

    open(FILE, $sqlfile) or die "Can't open sqlfile $sqlfile: $!\n";
    my $temp = $/;
    undef $/;
    my $sql = <FILE>;
    close(FILE);
    $/ = $temp;
    
    $self->logDebug("SQL", $sql);
    my $result = $self->dbh()->do($sql);
	$self->logDebug("Created table", $result);
	
	return $result;
}

method load ($table, $bsvfile) {
=head2

	SUBROUTINE		load
	
	PURPOSE
	
		LOAD A .TSV FILE INTO A TABLE:
        
            1. LOAD USING COMMAND: 'sqlite3 <dbfile> .import <bsvfile> <table>'

            2. WILL NOT WORK IF THERE ARE DUPLICATE LINES IN THE BSV FILE
            
=cut
    #### CONVERT filePath AND destinationPath ON WINDOWS
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/\//\\\\/g;  }

    #### CONVERT filePath AND destinationPath ON WINDOWS
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/([^\\])\\([^\\])/$1\\\\$2/g;  }
    
    my $dbfile = $self->dbfile();
	#my $start = time;	
	#$self->dbh()->do('BEGIN');
	#
	#open(FILE, $bsvfile) or die "Can't open .tsv file: $bsvfile\n";
	#my @rows;
	#while ( <FILE> )
	#{
	#	next if ( $_ =~ /^\s*$? /);
	#	
	#	my @elements = split "\t", $_;
	#	push @rows, \@elements;
	#}
	#close(FILE);
	#
	#my $sth = $self->dbh()->prepare( qq(INSERT INTO '$table' 
	#	('project', 'owner', 'ownerrights', 'grouprights', 'worldrights', 'location') values (?,?,?,?,?,?) ));
	#
	#$sth->execute($_->[0], $_->[1], $_->[2], $_->[3], $_->[4], $_->[5]) for @rows;
	#
	#$self->dbh()->do('COMMIT');
	#
# et: 5 seconds


    #my $command = qq{sqlite3 projects.dbl ".mode 'tabs' .import $bsvfile $table"};
    #my $command = qq{sqlite3 projects.dbl ".separator tabs; .import $bsvfile $table"};

	#### WORKS ONLY WITH BAR-SEPARATED ("|") VALUES
    my $command = qq{sqlite3 $dbfile ".import $bsvfile $table"};
	print "Command: $command\n";
	print `$command`, "\n";
    `$command`;

    #my $command = qq{sqlite3 exome ".import $bsvfile $table"};
    #$command =~ s/\\/\\\\/g;
    #my $query = qq{import '$bsvfile' $table};
    #$query =~ s/\\/\\\\/g;
    #$query =~ s/\\/\//g;
    #$query =~ s/\./\\\./g;
    #my $query = qq{LOAD DATA INFILE $bsvfile INTO TABLE $table};
    #my $result = $self->dbh()->do($query);
	#return $result;
}

method loadNoDups ($table, $bsvfile) {
=head2

	SUBROUTINE		loadNoDups
	
	PURPOSE
	
		LOAD A .TSV FILE INTO A TABLE:
        
            1. REMOVE DUPLICATE LINES FROM THE BSV FILE BEFORE LOADING
            
            2. LOAD USING COMMAND: 'sqlite3 <dbfile> .import <bsvfile> <table>'

            3. USES Tie::File:
            
                Tie::File  represents a regular text file as a Perl array. Each
                element in the array corresponds to a record in the file. The
                first line of the file is element 0 of the array; the second
                line is element 1, and so on.

                The file is not loaded into memory, so this will work even for
                gigantic files. Changes to the array are reflected in the file
                immediately.
                
=cut
    $self->logDebug("DBase::SQL:ite::loadNoDups(table, bsvfile)");
    $self->logDebug("table", $table);
	$self->logDebug("bsvfile", $bsvfile);
	
	#### GET RESOURCES    
    my $dbfile = $self->dbfile();my $sqlite = $self->sqlite();

    #### CONVERT FILEPATHS FROM WINDOWS TO LINUX
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/\\+/\//g;  }
    if ( $^O =~ /^MSWin32$/ )   {   $dbfile =~ s/\\+/\//g;  }
    if ( $^O =~ /^MSWin32$/ )   {   $sqlite =~ s/\\+/\//g;  }
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/\//\\\\/g;  }
    if ( $^O =~ /^MSWin32$/ )   {   $dbfile =~ s/\//\\\\/g;  }
    if ( $^O =~ /^MSWin32$/ )   {   $sqlite =~ s/\//\\\\/g;  }

    #### COPY BSV FILE TO TEMP FILE AND REMOVE DUPLICATES
    my $sortedfile = $bsvfile . "-sorted";
    my $nodupsfile = $bsvfile . "-nodups";

    use File::Sort;
    File::Sort::sort_file($bsvfile, $sortedfile) or die "Can't sort file $bsvfile or open sorted file for writing $sortedfile: $!\n";    

	my $keys = $self->primaryKeys($table);
	$self->logDebug("keys: @$keys");
	my $fields = $self->fields($table);
    $self->logDebug("fields: @$fields");
	
	#### CHECK FIELDS ARE DEFINED
	die "DBase::SQL:ite::loadNoDups    Fields not defined for table: $table\n" if not defined $fields;

	#### IF KEYS ARE DEFINED, CHECK IF THEY ARE IDENTICAL
	if ( defined $keys )
	{
		#### GET INDEX POSITIONS OF EACH KEY
		my $key_indices = [];
		foreach my $key ( @$keys )
		{
			my $found = 0;
			for ( my $i = 0; $i < @$fields; $i++ )
			{
				if ( $$fields[$i] eq $key )
				{
					push @$key_indices, $i;
					$found = 1;
					last;
				}
			}
			
			#### CHECK KEY EXISTS IN TABLE
			if ( not $found )
			{
				die "DBase::SQL:ite::loadNoDups    key $key not found in fields: @$fields\n";
			}
		}
		$self->logDebug("key indices: @$key_indices");

		#### MEMORY INTENSIVE (RATHER THAN PRINT FILE OF INDICES ONLY,
		#### SORT, AND THEN CHECK FOR ADJACENT DUPLICATES)
		my $already_seen;
		
		#### OTHERWISE, CHECK IF LINES ARE ABSOLUTELY IDENTICAL	
		open(FILE, $sortedfile) or die "DBase::SQL:ite::loadNoDups    Can't open input file: $sortedfile, error: $!\n";
		$/ = "\n";
		while ( <FILE> )
		{
			my @linefields = split "\\|", $_;
			my $keystring = '';
			foreach my $key_index ( @$key_indices )
			{
				$keystring .= $linefields[$key_index];
			}
			if ( exists $already_seen->{$keystring} )
			{
				#### DO NOTHING
			}
			else
			{
				$already_seen->{$keystring} = $_;
			}
		}
		close(FILE);

		#### PRINT UNIQUE KEY LINES TO NO DUPS FILE
		$self->logDebug("Printing nodups file...");
		open(OUTFILE, ">$nodupsfile") or die "Can't open output file: $nodupsfile, error: $!\n";
		foreach my $key ( keys %$already_seen )
		{
			print OUTFILE $already_seen->{$key};
		}
		close(OUTFILE);
		$self->logDebug("No dups file printed:\n\n$nodupsfile\n");
	}
	else
	{
		#### OTHERWISE, CHECK IF LINES ARE ABSOLUTELY IDENTICAL	
		open(FILE, $sortedfile) or die "Can't open input file: $sortedfile, error: $!\n";
		open(OUTFILE, ">$nodupsfile") or die "Can't open output file: $nodupsfile, error: $!\n";
		$/ = "\n";
		my $first_line = <FILE>;
		print OUTFILE $first_line;
		while ( my $next_line = <FILE> )
		{
			if ( $first_line ne $next_line )
			{
				$first_line = $next_line;
				print OUTFILE $next_line;
			}
			else
			{
			}
		}
		close(FILE);
		close(OUTFILE);
		print "DBase::SQL:ite::loadNoDups    No dups file printed:\n\n$nodupsfile\n\n";
	}

	#### WORKS ONLY WITH BAR-SEPARATED ("|") VALUES
    my $command = qq{$sqlite $dbfile ".import $nodupsfile $table"};
	$self->logDebug("command", $command);
	
	##### DEBUG -- CHECK COUNT -- DEBUG
	#my $count_command = qq{$sqlite $dbfile "select count(*) from diffs"};

    return `$command`;
}


method primaryKeys ($table) {
=head2

	SUBROUTINE		primaryKeys
	
	PURPOSE
	
		RETURN THE PRIMARY KEYS OF A TABLE IN THE DATABASE
            
=cut 

	#### MAKE SURE THE KEYS ARE UNIQUE
    my $query = qq{SELECT sql FROM sqlite_master WHERE tbl_name = '$table'};
    $self->logDebug("$query");
    my $content = $self->query($query);
    $self->logDebug("Content", $content);

	#### THIS ALSO WORKS
	#my $result = `sqlite3 $dbfile ".schema $table"`;

	#### PARSE RESULT INTO FIELDS
	my ($keystring) = $content =~ /\s*PRIMARY KEY\s*\((.+?)\)/msi;
	$keystring =~ s/\s+//g if defined $keystring;
	my $keys;
	@$keys = split ",", $keystring if defined $keystring;
	
	return $keys;	
}
	
method loadIgnore ($table, $bsvfile) {
=head2

	SUBROUTINE		loadIgnore
	
	PURPOSE
	
		LOAD A BAR-SEPARATED VALUES FILE INTO A TABLE:

            1. EXISTING RECORDS IN THE TARGET TABLE WILL BE UNAFFECTED

            2. NEW RECORDS WILL BE ADDED TO THE TARGET TABLE
            
            3. MAY NOT WORK WITH DUPLICATE RECORDS IN BSV FILE
            
=cut 
    #### CONVERT filePath AND destinationPath ON WINDOWS
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/\//\\\\/g;  }
    
    print "bsvfile: $bsvfile\n";
    my $dbfile = $self->dbfile();

    #### CREATE A TEMPORARY TABLE WITH THE SAME FIELDS AS THE TARGET TABLE
    my $query = qq{CREATE TEMP TABLE t_temp AS SELECT * FROM $table LIMIT 1};
    my $result = $self->do($query);
    if ( not $result )
    {
        die "Could not create temp table with query:\n$query\n";
    }
    $query = qq{DELETE FROM t_temp};
    $result = $self->do($query);
    if ( not $result )
    {
        die "Could not delete from temp table with query:\n$query\n";
    }


    #### IMPORT INTO TEMPORARY TABLE WITHOUT CONFLICTS BECAUSE IT IS EMPTY
	#### NB: WORKS ONLY WITH BAR-SEPARATED ("|") VALUES
    my $command = qq{sqlite3 $dbfile ".import $bsvfile $table"};
	print "$command\n";
	print `$command`, "\n";
    
    #### INSERT THE NEW RECORDS INTO THE MAIN TABLE USING AN INSERT OR IGNORE COMMAND
    $query = qq{INSERT OR IGNORE INTO $table SELECT * FROM t_temp};
    $result = $self->do($query);
    if ( not $result )
    {
        warn "Could not delete from temp table with query:\n$query\n";
    }
    
    return $result;
}




method loadReplace ($table, $bsvfile) {
=head2

	SUBROUTINE		loadReplace
	
	PURPOSE
	
		LOAD A BAR-SEPARATED VALUES FILE INTO A TABLE:

            1. EXISTING RECORDS IN THE TARGET TABLE WILL BE UNAFFECTED

            2. NEW RECORDS WILL BE ADDED TO THE TARGET TABLE
            
            3. MAY NOT WORK WITH DUPLICATE RECORDS IN BSV FILE
            
=cut 

    #### CONVERT filePath AND destinationPath ON WINDOWS
    if ( $^O =~ /^MSWin32$/ )   {   $bsvfile =~ s/\//\\\\/g;  }
    
    print "bsvfile: $bsvfile\n";
    my $dbfile = $self->dbfile();

    #### CREATE A TEMPORARY TABLE WITH THE SAME FIELDS AS THE TARGET TABLE
    my $query = qq{CREATE TEMP TABLE t_temp AS SELECT * FROM $table LIMIT 1};
    my $result = $self->do($query);
    if ( not $result )
    {
        die "Could not create temp table with query:\n$query\n";
    }
    $query = qq{DELETE FROM t_temp};
	
    $result = $self->do($query);
    if ( not $result )
    {
        die "Could not delete from temp table with query:\n$query\n";
    }


    #### IMPORT INTO TEMPORARY TABLE WITHOUT CONFLICTS BECAUSE IT IS EMPTY
	#### NB: WORKS ONLY WITH BAR-SEPARATED ("|") VALUES
    my $command = qq{sqlite3 $dbfile ".import $bsvfile $table"};
	print "Command:\n";
	print `$command`, "\n";
    
    #### INSERT THE NEW RECORDS INTO THE MAIN TABLE USING AN INSERT OR IGNORE COMMAND
    $query = qq{INSERT OR REPLACE INTO $table SELECT * FROM t_temp};
    $result = $self->do($query);
    if ( not $result )
    {
        warn "Could not delete from temp table with query:\n$query\n";
    }

    return $result;
}

method fields ($table) {
=head2

	SUBROUTINE		fields
	
	PURPOSE

		RETURN THE FIELDS OF A TABLE

=cut
	my $sth = $self->dbh()->prepare("SELECT * FROM $table") or die "Can't prepare statement!\n";
	$sth->execute or die "Can't execute statement!\n";
	my $hasField = 0;
	my @fields = @{$sth->{NAME}};

	return \@fields;

=head2
#
##	my $dbfile = $self->dbfile();
##
#    $self->logDebug("DBase::SQLite::fields(table)");
#    $self->logDebug("table", $table);
#    $self->logDebug("dbfile", $dbfile);
#
#    my $query = qq{SELECT sql FROM sqlite_master WHERE tbl_name = '$table'};
#    $self->logDebug("query", $query);
#    my $content = $self->query($query);
#	print "DBase::SQLite::fields    Returning because no content for table: $table following query: $query\n" and return if not defined $content or not $content;
#    $self->logDebug("content", $content);
#
#	#### THIS ALSO WORKS
#	#my $result = `sqlite3 $dbfile ".schema $table"`;
#
#	#### PARSE RESULT INTO FIELDS
#	$content =~ s/^\S*CREATE.+?\(\s*//msi;
#	$content =~ s/\s*PRIMARY KEY\s*.+$//msi;
#	
#	my @lines = split ",\\s*\\n", $content;
#
#    my $fields;
#	foreach my $line ( @lines )
#	{
#		$self->logDebug("line", $line);
#		push @$fields, $line =~ /^\s*(\S+)/;
#	}
#
#	return $fields;

=cut

}

method tsvlineToHash ($tsvline, $fields) {
=head2

	SUBROUTINE		tsvlineToHash
	
	PURPOSE
	
		RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS

=cut 

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
=head2

	SUBROUTINE		do
	
	PURPOSE
	
		RETURN 1 IF COMMAND WAS SUCCESSFUL, 0 OTHERWISE

=cut
	no warnings;
    return 1 if $self->dbh()->do($query);
	use warnings;
	return 0;
}


method query ($query) {
=head2

	SUBROUTINE		query
	
	PURPOSE
	
		RETURN A SINGLE QUERY RESULT
		
=cut
    $self->logDebug("DBase::SQLite::query(query)");
    $self->logDebug("query", $query);
    my $response = $self->dbh()->selectall_arrayref($query);
    $self->logDebug("response", $response);

    return $$response[0][0];
}


method queryarray ($query) {
=head2

	SUBROUTINE		queryarray
	
	PURPOSE
	
		RETURN AN ARRAY OF SCALARS

=cut
#	$self->dbh()->{RaiseError} = 0; # DISABLE TERMINATION ON ERROR	
#    my $sth = $self->dbh()->prepare($query);
#    $self->dbh()->{RaiseError} = 1; # ENABLE TERMINATION ON ERROR
	#$sth->execute;
	
	my $array;
    my $response = $self->dbh()->selectall_arrayref($query);
    foreach( @$response )
    {
        foreach my $i (0..$#$_)
        {
           push @$array, $_->[$i];
        }
    }
    
	return $array;
}



method queryhash ($query) {
=head2

	SUBROUTINE		queryhash
	
	PURPOSE
	
		RETURN A HASH

=cut
	$self->logDebug("()");my $hash;
	
	#### GET FIELDS 
	my ($table) = $query =~ /FROM\s+(\S+)/i;
	$self->logDebug("query", $query);
	$self->logDebug("table", $table);

    my ($fieldstring) = $query =~ /^SELECT\s+(.+)\s+FROM/ims;
	$self->logDebug("fieldstring", $fieldstring);
    #$fieldstring =~ s/\s+//g;
    $fieldstring =~ s/DISTINCT//ms;
    $self->logDebug("Fieldstring", $fieldstring);
    
    my $fields;
    if ( $fieldstring =~ /^\*$/ )
    {
        $self->logDebug("Field string is '*'");
        my ($table) = $query =~ /FROM\s+(\S+)/i;
        $self->logDebug("query", $query);
        $self->logDebug("table", $table);
        $fields = $self->fields($table);
    }
    else
    {
		$fieldstring =~ s/\s+//g;
        @$fields = split ",", $fieldstring;
    }
	print "DBase::SQLite::queryhash    fields not defined. Exiting\n" and return if not defined $fields;
	
	$self->logDebug("fields: @$fields");

    my $response = $self->dbh()->selectall_arrayref($query);
	my $line = $$response[0];
	return {} if not defined $line;
	
	for( my $i = 0; $i < @$line; $i++ )
	{
	   $hash->{$fields->[$i]} = $line->[$i];
	}
	
	$self->logDebug("hash", $hash);
	
	return $hash;
}

method queryhasharray ($query) {
=head2

	SUBROUTINE		queryhasharray
	
	PURPOSE
	
		RETURN AN ARRAY OF HASHES

=cut
	$self->logDebug("(query)");
	$self->logDebug("query", $query);    ;
	my $hasharray;

	#### GET FIELDS 
    my ($fieldstring) = $query =~ /^SELECT\s+(.+)\s+FROM/ims;
	$self->logDebug("fieldstring", $fieldstring);
    #$fieldstring =~ s/\s+//g;
    $fieldstring =~ s/DISTINCT//ms;
    $self->logDebug("Fieldstring", $fieldstring);
    
    my $fields;
    if ( $fieldstring =~ /^\*$/ )
    {
        $self->logDebug("Field string is '*'");
        my ($table) = $query =~ /FROM\s+(\S+)/i;
        $self->logDebug("query", $query);
        $self->logDebug("table", $table);
        $fields = $self->fields($table);
    }
    else
    {
        @$fields = split ",", $fieldstring;
    }
	#### HANDLE 'SELECT ... AS' 
	if ( $fieldstring =~ / AS /i )
	{
		foreach my $field ( @$fields )
		{
			#if ( $field =~ /^\s*\S+\s+AS\s+(\S+)\s*$/i ) 
			if ( $field =~ /\s+AS\s+(\S+)\s*$/i ) 
			{
				$field = $1;
				$field =~ s/'//g;
			}
			else
			{
			}
		}
	}
	else
	{
		foreach my $field ( @$fields )
		{		
			$field =~ s/\s+//g;
		}
	}
	$self->logDebug("$query");
    my $response = $self->dbh()->selectall_arrayref($query);
    foreach( @$response )
    {
		my $hash; 
        foreach my $i (0..$#$_)
        {
			#if ( not defined $_->[$i] )
			#{
			#	print "\$_->[$i] Not defined: $i\n";
			#}

			#if ( not defined $hash->{$fields->[$i]} )
			#{
			#	print "Not defined: $hash->{$fields->[$i]}\n";
			#}

           $hash->{$fields->[$i]} = $_->[$i];
        }
		push @$hasharray, $hash;
    }
#

#
#
	return $hasharray;
}




method querytwoDarray ($query) {
=head2

	SUBROUTINE		querytwoDarray
	
	PURPOSE
	
		RETURN AN ARRAY OF HASHES

=cut
	$self->logDebug("");my $twoDarray;

	#### GET FIELDS 
    my ($fieldstring) = $query =~ /^SELECT (.+) FROM/i;
    $fieldstring =~ s/\s+//g;
    my $fields;
    if ( $fieldstring =~ /^\*$/ )
    {
        $self->logDebug("Field string is '*'");
        my ($table) = $query =~ /FROM\s+(\S+)/i;
        $self->logDebug("query", $query);
        $self->logDebug("table", $table);
        $fields = $self->fields($table);
    }
    else
    {
        @$fields = split ",", $fieldstring;
        
    }
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
#

#
#
	return $twoDarray;
}

method showTables {
=head

    SUBROUTINE      showTables
    
    PURPOSE
    
        RETURN 

=cut

    $self->logDebug("()");
    my $query = qq{SELECT name FROM sqlite_master WHERE type = 'table')};
    my $tables = $self->queryarray($query);
    
    return $tables;
}


method tableEmpty ($table) {
=head2

	SUBROUTINE		tableEmpty
	
	PURPOSE
	
		RETURN 1 IF TABLE IS EMPTY

=cut 
    my $query = qq{SELECT * FROM $table LIMIT 1};
    my $sth = $self->dbh()->prepare($query);
    $sth->execute;
    my $result = $sth->fetchrow;
    
    if ( $result )  {   return 0;   };
    return 1;
}

method sqlToFields ($sqlfile) {
=head2

	SUBROUTINE		sqlToFields
	
	PURPOSE
	
		RETURN LIST OF FIELDS FROM AN SQL FILE

=cut 

	my $fields = '';

    open(FILE, $sqlfile) or die "Can't open sql file: $sqlfile\n";	
    $/ = "END OF FILE";
    my $contents = <FILE>;
	
	$contents =~ s/^.+?\(//ms;    
    $contents =~ s/\(.+?$//ms;
    $contents =~ s/PRIMARY KEY.+$//ims;
    $contents =~ s/KEY.+$//ims;
    $contents =~ s/\W+$//;
	my @lines = split "\n", $contents;
    for ( my $i = 0; $i < $#lines + 1; $i++ )
    {
        my $line = $lines[$i];
        if ( $line =~ /^\s*$/ or $line =~ /^\s+#/ )   {   next;   }
        $line =~ s/^\s*(\S+)\s+.+$/$1/;
        $fields .= $line . ",";
    }
    $fields =~ s/,$//;

	return $fields;
}



method fieldsInsert ($fields, $hash, $table) {
=head2

	SUBROUTINE		fieldsInsert
	
	PURPOSE
	
		CREATE AN INSERT QUERY .TSV LINE (FOR LOAD) BASED ON THE FIELDS
		
		AND THE HASH, MAKING DEFINED WHEN A FIELD key IS 
		
		NOT PRESENT IN THE HASH

=cut 

	$fields =~ s/\s//g;
	#### SET THE ARRAY OF TABLE FIELDS
    my @fieldarray = split ",", $fields;
	
	#### CHECK VALUES ARE THERE
	if ( not defined $table or not $table )
	{
		die "Database::fieldsInsert(fields, hash, table). Table not defined or empty. Exiting...\n";
	}
	if ( not @fieldarray)
	{
		die "Database::fieldsInsert(fields, hash, table). Fields is empty. Exiting...\n";
	}
	if ( not defined $hash )
	{
		die "Database::fieldsInsert(fields, hash, table). Hash is empty. Exiting...\n";
	}

	#### START insert
    my $insert = 'INSERT INTO $table (\n';

	#### DO THE FIELD NAMES
    for ( my $i = 0; $i < $#fieldarray + 1; $i++ )
    {
        $insert .= "\t" . $fieldarray[$i]. ",\n";        
    }
	$insert .= ")\n";

	#### DO THE FIELD VALUES
    for ( my $i = 0; $i < $#fieldarray + 1; $i++ )
    {
        no warnings;
        $self->logDebug("Field $fieldarray[$i]: " . makeDefined($$hash{$fieldarray[$i]}));
        $insert .= "\t" . makeDefined($$hash{$fieldarray[$i]}) . ",\n";        
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
    $self->logDebug("DBase::SQLite::fieldsToTsv(fields, hash)");
    $self->logDebug("fields", $fields);
    $self->logDebug("hash", $hash);

	if ( ref($fields) ne "" )
	{
		print "DBase::SQLite::fieldsToTsv    Fields not a scalar value (i.e., not a CSV string)\n";
		$self->logDebug("ref(fields): " . ref($fields));
		print "DBase::SQLite::fieldsToTsv    Quitting...\n";
		return;
	}
	$fields =~ s/\s//g;
    my $tsvline = '';

    my @fieldarray = split ",", $fields;
    for ( my $i = 0; $i < $#fieldarray + 1; $i++ )
    {
        my $value = $hash->{$fieldarray[$i]};
		$self->logDebug("\$hash->{$fieldarray[$i]} = value", $value);

        $value = '' if not defined $value;
        $tsvline .= $value;
        $tsvline .= "\t";
    }
    $tsvline =~ s/\s+$//;
    
    return $tsvline;
}
    


method makeDefined ($input) {
=head2

	SUBROUTINE		makeDefined
	
	PURPOSE
	
		RETURN '' IF NOT DEFINED

=cut 

    if ( not defined $input )   {   return '';  }
    return $input;
}
method createDatabase ($sqlitefile) {
=head2

	SUBROUTINE		createDatabase
	
	PURPOSE
	
        CREATE DATABASE IF NOT EXISTS

=cut 
    my $dbh = DBI->connect( "dbi:SQLite:$sqlitefile" ) || die "Cannot connect: $DBI::errstr";
    return $dbh();
}

method hasField ($table, $field) {
=head2

	SUBROUTINE		hasField
	
	PURPOSE
	
		RETURN 1 IF A TABLE HAS SUPPLIED FIELD, 0 OTHERWISE
		
=cut

	my $hasTable = hasTable($self->dbh(), $table);
	if ( not $hasTable )	{	return 0;	}
	my $fields = $self->fields($self->dbh(), $table);
#	print "Fields: @$fields\n";
	if ( not defined $fields )	{	return 0;	}
	
	for ( my $i = 0; $i < @$fields; $i++ )
	{
		if ( $$fields[$i] =~ /^$field$/ )	{	return 1;	}
	}
	
	return 0;
}

method fieldHasEntry ($table, $field) {
=head2

	SUBROUTINE		fieldHasEntry
	
	PURPOSE
	
		CHECK IF THERE ARE ANY ENTRIES FOR THE GIVEN FIELD IN
		
		THE TABLE (I.E., MUST BE NON-EMPTY AND NON-NULL). IF NONE
		
		EXIST, RETURN ZERO. OTHERWISE, RETURN 1.
		
=cut
	return if not defined $table or not $table;
	return if not defined $field or not $field;
	return 0 if not hasTable($self->dbh(), $table);

	my $query = qq{SELECT COUNT(*) FROM $table WHERE $field!='' OR $field IS NOT NULL};
	my $count = simple_query($self->dbh(), $query) || 0;

	return 0 if $count == 0;	
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
	my $query = qq{SELECT name FROM sqlite_master WHERE type = 'table'};
	my $tables = $self->queryarray($query);
	return 0 if not defined $tables;
	for ( my $i = 0; $i < @$tables; $i++ )
	{
		return 1 if $table =~ /^$$tables[$i]$/;
	}
	
	return 0;
}

method updateFulltext ($table, $fulltext, $fields) {    
=head2

	SUBROUTINE		updateFulltext
	
	PURPOSE
	
        UPDATE THE FULLTEXT INDEX OF A TABLE

=cut 
	return if not defined $self->dbh()
		or not defined $table
		or not defined $fulltext
		or not defined $fields;

    $| = 1;
	if ( hasIndex($self->dbh(), $table, $fulltext) )
	{
		print "Dropping index '$fulltext'\n";
		dropIndex($self->dbh(), $table, $fulltext);
	}
	
	my $query = qq{ALTER TABLE $table ADD FULLTEXT $fulltext ($fields)};
	print "$query\n";
	my $success = do_query($self->dbh(), $query);
	return $success;
}


method hasIndex ($table, $index) {
=head2

	SUBROUTINE		hasIndex
	
	PURPOSE
	
		RETURN 1 IF THE NAME IS AMONG THE LIST OF A TABLE'S INDICES 

=cutmy $indices = indices($self->dbh(), $table);
	if ( not defined $indices )	{	return 0;	}
	
	for ( my $i = 0; $i < @$indices; $i++ )
	{
		if ( $$indices[$i] =~ /^$index$/ )	{	return 1;	}
	}
	
	return 0;
}

method indices ($table) {
=head2

	SUBROUTINE		indices
	
	PURPOSE
	
		RETURN A LIST OF A TABLE'S INDICES 

=cut
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
=head2

	SUBROUTINE		dropIndex
	
	PURPOSE
	
		RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS

=cut
	my $query = qq{DROP INDEX $index ON $table};
	my $success = do_query($self->dbh(), $query);
	
	return $success;	
}






=head2

	SUBROUTINE		fields_arrayref
	
	PURPOSE
	
		CHECK IF THERE ARE ANY ENTRIES FOR THE GIVEN FIELD IN
		
		THE TABLE (I.E., MUST BE NON-EMPTY AND NON-NULL). IF NONE
		
		EXIST, RETURN ZERO. OTHERWISE, RETURN 1.
		
method fields_arrayref ($table) {
    my $self->dbh()		=	$self->dbh();		
	my $query = qq{.schema table};
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

=cut




}