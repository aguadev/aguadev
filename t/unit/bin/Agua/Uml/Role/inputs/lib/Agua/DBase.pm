use MooseX::Declare;
=head2

	PACKAGE		Agua::DBase
	
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

class Agua::DBase {

# STRINGS
has 'sqlite'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'dbfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'dbtype'	=> ( isa => 'Str|Undef', is => 'ro', default => '' );

#### EXTERNAL MODULES
use DBI;
use DBD::mysql;
use POSIX;
use Data::Dumper;

##///}

sub timestamp {
    my $self		=	shift;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp = sprintf
		"%4d-%02d-%02d %02d:%02d:%02d",
		$year+1900,$mon+1,$mday,$hour,$min,$sec;	
		
	return $timestamp;
}

=head2

	SUBROUTINE		set
	
	PURPOSE
	
		CREATE A 'SET ...' LINE FOR ONE OR MORE FIELD VALUES
		
	INPUTS
		
		1. HASH OF TABLE field KEY-VALUE PAIRS 

		2. ARRAY OF FIELDS TO BE USED
		
=cut 

method set ($hash, $fields) {
	return if not defined $hash or not defined $fields or not @$fields;
	
	my $set = '';
	my $now = $self->now();
	foreach my $field ( @$fields ) {
        if ( $field eq "datetime" ) {
			$set .= "datetime = $now,\n";
		}
		else {
			my $value = $$hash{$field} ? $$hash{$field} : '';
			$set .= qq{$field = '$value',\n};
		}
    }
	$set =~ s/,\s+$/\n/;
	
	return if not $set;

	$set = "SET " . $set;
	
    return $set;
}
    

  

=head2

	SUBROUTINE		where
	
	PURPOSE
	
		CREATE A 'WHERE ...' LINE FOR ONE OR MORE FIELD VALUES
		
	INPUTS
		
		1. HASH OF TABLE field KEY-VALUE PAIRS 

		2. ARRAY OF FIELDS TO BE USED
		
=cut 

method where ($hash, $fields) {

	return if not defined $hash or not defined $fields or not @$fields;
	
	my $where = '';
    for ( my $i = 0; $i < @$fields; $i++ )
    {
        my $value = $$hash{$$fields[$i]} ? $$hash{$$fields[$i]} : '';
		$value =~ s/'/\\'/g;
		$where .= qq{WHERE $$fields[$i] = '$value'\n} if $i == 0;
		$where .= qq{AND $$fields[$i] = '$value'\n} if $i != 0;
    }

    return $where;
}

method insert ($hash, $fields) {
    my $insert = '';
    foreach my $field  ( @$fields ) {
		if ( $field eq "datetime" ) {
			my $now = $self->now();
			$insert .= "$now, ";
		}
		else {
			no warnings;
			my $value = $$hash{$field} ? $$hash{$field} : '';
			$value =~ s/'/\\'/g;        
			$value =~ s/\\\\\\'/\\'/g;
			$insert .= "'$value', ";        
			use warnings;        
		}
    }
    $insert =~ s/,\s+$//;
	
    return $insert;	
}
method inTable ($table, $hash, $fields) {
    $self->logError("table not defined") and exit if not defined $table;
    $self->logError("hash not defined") and exit if not defined $hash;
    $self->logError("fields not defined") and exit if not defined $fields;

	$self->logCaller("");
	
	#### GET WHERE
	my $where = $self->where($hash, $fields);
	my $query = qq{SELECT 1 FROM $table $where};
	$self->logDebug("query", $query);
	my $result = $self->query($query);
	$self->logDebug("result", $result);
	
	return 0 if not defined $result;
	return 1;
}

method _updateTable ($table, $hash, $required_fields, $set_hash, $set_fields) {
    $self->logError("hash not defined") and exit if not defined $hash;
    $self->logError("required_fields not defined") and exit if not defined $required_fields;
    $self->logError("set_hash not defined") and exit if not defined $set_hash;
    $self->logError("set_fields not defined") and exit if not defined $set_fields;
    $self->logError("table not defined") and exit if not defined $table;

	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### GET WHERE
	my $where = $self->where($hash, $required_fields);

	#### GET SET
	my $set = $self->set($set_hash, $set_fields);
	$self->logError("set values not defined") and exit if not defined $set;

	##### UPDATE TABLE
	my $query = qq{UPDATE $table $set $where};           
	$self->logNote("$query");
	my $result = $self->do($query);
	$self->logNote("UPDATE result", $result);

	return 0 if not defined $result;
	return 1;
}


method _addToTable ($table, $hash, $required_fields, $inserted_fields) {
=head2

	SUBROUTINE		_addToTable
	
	PURPOSE

		ADD AN ENTRY TO A TABLE
        
	INPUTS
		
		1. NAME OF TABLE      

		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
        
=cut

	#### CHECK FOR ERRORS
    $self->logError("hash not defined") and exit if not defined $hash;
    $self->logError("required_fields not defined") and exit if not defined $required_fields;
    $self->logError("table not defined") and exit if not defined $table;
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### GET ALL FIELDS BY DEFAULT IF INSERTED FIELDS NOT DEFINED
	$inserted_fields = $self->fields($table) if not defined $inserted_fields;

	$self->logError("fields not defined") and exit if not defined $inserted_fields;
	my $fields_csv = join ",", @$inserted_fields;
	##### INSERT INTO TABLE
	my $values_csv = $self->fieldsToCsv($inserted_fields, $hash);
	my $query = qq{INSERT INTO $table ($fields_csv)
VALUES ($values_csv)};           
	$self->logDebug("$query");
	my $result = $self->do($query);
	$self->logDebug("INSERT result", $result);
	
	return $result;
}

method _removeFromTable ($table, $hash, $required_fields) {
=head2

	SUBROUTINE		_removeFromTable
	
	PURPOSE

		REMOVE AN ENTRY FROM A TABLE
        
	INPUTS
		
		1. HASH CONTAINING TABLE FIELD KEY-VALUE PAIRS
		
		2. ARRAY OF KEY FIELDS THAT MUST BE DEFINED 

		3. NAME OF TABLE      
=cut

    #### CHECK INPUTS
    $self->logError("hash not defined") and exit if not defined $hash;
    $self->logError("required_fields not defined") and exit if not defined $required_fields;
    $self->logError("table not defined") and exit if not defined $table;
	
	#### CHECK REQUIRED FIELDS ARE DEFINED
	my $not_defined = $self->notDefined($hash, $required_fields);
    $self->logError("undefined values: @$not_defined") and exit if @$not_defined;

	#### DO DELETE 
	my $where = $self->where($hash, $required_fields);
	my $query = qq{DELETE FROM $table
$where};
	$self->logNote("\n$query");
	my $result = $self->do($query);
	$self->logNote("DELETE result", $result);		;
	
	return 1 if defined $result;
	return 0;
}

=head2

	SUBROUTINE		notDefined
	
	PURPOSE
	
		RETURN A HASH OF UNDEFINED FIELD KEY-PAIRS IN A HASH
		
	INPUTS
		
		1. HASH OF TABLE field KEY-VALUE PAIRS 

		2. ARRAY OF FIELDS TO BE USED
		
=cut 

method notDefined ($hash, $fields) {
	return [] if not defined $hash or not defined $fields or not @$fields;
	
	my $notDefined = [];
    for ( my $i = 0; $i < @$fields; $i++ ) {
        push( @$notDefined, $$fields[$i]) if not defined $$hash{$$fields[$i]};
    }

    return $notDefined;
}
    
=head2

	SUBROUTINE		make_defined
	
	PURPOSE
	
		RETURN '' IF NOT DEFINED

=cut 

method make_defined ($input) {    
    return '' if not defined $input;    
    return $input;
}

=head2

	SUBROUTINE		query
	
	PURPOSE
	
		RETURN A SINGLE QUERY RESULT
		
=cut

sub query {}
=head2

	SUBROUTINE		hasField
	
	PURPOSE
	
		CHECK IF A TABLE HAS A PARTICULAR FIELD
		
=cut

sub hasField {}
=head2

	SUBROUTINE		fieldsToArray
	
	PURPOSE
	
		CHECK IF THERE ARE ANY ENTRIES FOR THE GIVEN FIELD IN
		
		THE TABLE (I.E., MUST BE NON-EMPTY AND NON-NULL). IF NONE
		
		EXIST, RETURN ZERO. OTHERWISE, RETURN 1.
		
=cut

sub tableFieldHasEntry {}
=head2

	SUBROUTINE		hasTable
	
	PURPOSE
	
		1. CHECK IF A TABLE EXISTS IN THE DATABASE
		
		2. RETURN 1 IF EXISTS, RETURN ZERO IF OTHERWISE
		
=cut

sub hasTable {}
=head2

	SUBROUTINE		updateFulltext
	
	PURPOSE
	
        UPDATE THE FULLTEXT INDEX OF A TABLE

=cut 
	
sub updateFulltext {}
=head2

	SUBROUTINE		tableHasIndex
	
	PURPOSE
	
		RETURN 1 IF THE NAME IS AMONG THE LIST OF A TABLE'S INDICES 

=cut 

sub tableHasIndex {}
=head2

	SUBROUTINE		indices
	
	PURPOSE
	
		RETURN A LIST OF A TABLE'S INDICES 

=cut 

sub indices {}
=head2

	SUBROUTINE		dropIndex
	
	PURPOSE
	
		RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS

=cut 

sub dropIndex {}
=head2

	SUBROUTINE		tsvToHash
	
	PURPOSE
	
		RETURN A HASH FROM A TSV LINE AND ORDERED LIST OF FIELDS

=cut 

sub tsvToHash {}
=head2

	SUBROUTINE		query
	
	PURPOSE
	
		RETURN AN ARRAY OF SCALARS

=cut 

sub do {}
=head2

	SUBROUTINE		queryarray
	
	PURPOSE
	
		RETURN AN ARRAY OF SCALARS

=cut 

sub queryarray {}
=head2

	SUBROUTINE		queryhash
	
	PURPOSE
	
		RETURN A HASH

=cut 

sub queryhash {}
=head2

	SUBROUTINE		queryhasharray
	
	PURPOSE
	
		RETURN AN ARRAY OF HASHES

=cut 

sub queryhasharray {}
=head2

	SUBROUTINE		tableEmpty
	
	PURPOSE
	
		RETURN 1 IF TABLE IS EMPTY

=cut 

sub tableEmpty {}
=head2

	SUBROUTINE		sql2fields
	
	PURPOSE
	
		RETURN LIST OF FIELDS FROM AN SQL FILE

=cut 

sub sql2fields {}
=head2

	SUBROUTINE		fieldsToInsert
	
	PURPOSE
	
		CREATE AN INSERT QUERY .TSV LINE (FOR LOAD) BASED ON THE FIELDS
		
		AND THE HASH, MAKING DEFINED WHEN A FIELD key IS 
		
		NOT PRESENT IN THE HASH

=cut 

sub fieldsToInsert {}
=head2

	SUBROUTINE		fieldsToTsv
	
	PURPOSE
	
		CREATE A .TSV LINE (FOR LOAD) BASED ON THE FIELDS
		
		AND THE HASH, MAKING DEFINED WHEN A FIELD key IS 
		
		NOT PRESENT IN THE HASH

=cut 

sub fieldsToTsv {}
=head2

	SUBROUTINE		load
	
	PURPOSE
	
		RETURN '' IF NOT DEFINED

=cut 

sub load {}
=head2

	SUBROUTINE		loadNoDups
	
	PURPOSE
	
		LOAD DATA FROM FILE INTO TABLE AND IGNORE DUPLICATES

=cut 

sub loadNoDups {}
=head2

	SUBROUTINE		fieldPresent
	
	PURPOSE
	
		RETURN '' IF NOT DEFINED

=cut 

sub fieldPresent {}
=head2

	SUBROUTINE		fields
	
	PURPOSE
	
		RETURN '' IF NOT DEFINED

=cut 

sub fields {}
=head2

	SUBROUTINE		createDatabase
	
	PURPOSE
	
        CREATE DATABASE IF NOT EXISTS

=cut 

sub createDatabase {}

} #### END

