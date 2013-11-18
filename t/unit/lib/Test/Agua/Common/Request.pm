use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Agua::Common::Request with (Agua::Common::Base,
	Agua::Common::Logger,
	Agua::Common::Request,
	Agua::Common::Util,
	Agua::Common::Privileges,
	Agua::Common::Database,
	Test::Agua::Common::Database) {

use Test::More;
use FindBin qw($Bin);
use Conf::Yaml;
use JSON;

# STRINGS
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'validated'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'sessionid'		=>  ( isa => 'Str|Undef', is => 'rw' );

# OBJECTS
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is 		=>	'rw',
	isa 	=> 	'Conf::Yaml|Conf::Yaml'
);


#####/////}}}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
	$self->logDebug("args", $args);

	#$self->
}

method testGetQueries {
	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	$self->logDebug("installdir", $installdir);
	my $query	=	$self->getFileContents("$installdir/bin/sql/query.sql");
	$self->logDebug("query", $query);
	$self->db()->do($query);
	
	#### LOAD DATA
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("query", "$Bin/inputs/tsv/query.tsv");
	
	my $queries		=	$self->getQueries();
	$self->logDebug("queries", $queries);

	my $expected = $self->getFileContents("$Bin/inputs/json/query.json");
	$self->logDebug("expected", $expected);

	#### SET JSON PARSER
	my $jsonparser = JSON->new();
	$expected = $jsonparser->allow_nonref->decode($expected);
	$self->logDebug("expected", $expected);
	
	is_deeply($expected, $queries, "Queries match");
}

method testAddQuery {

	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### SET JSON PARSER
	my $jsonparser = JSON->new();

	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	#$self->logDebug("installdir", $installdir);
	my $query	=	$self->getFileContents("$installdir/bin/sql/query.sql");
	#$self->logDebug("query", $query);
	$self->db()->do($query);
	
	#### LOAD DATA
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("query", "$Bin/inputs/tsv/query.tsv");

	#### SUCCESS
	my $addquery = $self->getFileContents("$Bin/inputs/json/addquery.json");
	$self->logDebug("addquery", $addquery);
	my $data 	=	$jsonparser->allow_nonref->decode($addquery);
	$self->logDebug("data", $data);
	my ($success, $error)	=	$self->_addQuery($data);
	$self->logDebug("success", $success);
	ok($success == 1, "_addQuery success");

	#### CONFIRM ROWS
	my $expectedjson = $self->getFileContents("$Bin/inputs/json/addqueryexpected.json");
	my $expected	=	$jsonparser->allow_nonref->decode($expectedjson);
	$self->logDebug("expected", $expected);
	my $queries		=	$self->getQueries();
	$self->logDebug("queries", $queries);
	is_deeply($expected, $queries, "_addQuery confirm rows");
	
	#### LOAD DATA
	$self->db()->do("DELETE FROM query");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("query", "$Bin/inputs/tsv/twoqueries.tsv");
	
	#### FAIL ON DUPLICATE DATA
	($success, $error)	=	$self->_addQuery($data);
	$self->logDebug("success", $success);	
	ok($success == 0, "_addQuery duplicate data failure");
	
	#### FAIL ON EMPTY DATA
	($success, $error)	=	$self->_addQuery([]);
	$self->logDebug("success", $success);
	
	ok($success == 0, "_addQuery empty data failure");
}

method testRemoveQuery {

	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### SET JSON PARSER
	my $jsonparser = JSON->new();

	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	#$self->logDebug("installdir", $installdir);
	my $query	=	$self->getFileContents("$installdir/bin/sql/query.sql");
	#$self->logDebug("query", $query);
	$self->db()->do($query);
	
	#### FAIL ON EMPTY DATA
	my ($success, $error)	=	$self->_removeQuery({});
	$self->logDebug("success", $success);	
	ok($success == 0, "_removeQuery empty data failure");

	#### LOAD DATA
	$self->db()->do("DELETE FROM query");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("query", "$Bin/inputs/tsv/query.tsv");
	
	#### FAIL ON ABSENT DATA
	my $before		=	$self->getQueries();
	$self->logDebug("before", $before);
	my $removequery = $self->getFileContents("$Bin/inputs/json/removequery.json");
	$self->logDebug("removequery", $removequery);
	my $data 	=	$jsonparser->allow_nonref->decode($removequery);
	$self->logDebug("data", $data);
	($success, $error)	=	$self->_removeQuery($data);
	$self->logDebug("success", $success);
	ok($success == 1, "_removeQuery success but no remove due to absent data");
	my $after		=	$self->getQueries();
	$self->logDebug("after", $after);
	is_deeply($before, $after, "_removeQuery rows not removed");		
	
	#### LOAD DATA
	$self->db()->do("DELETE FROM query");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("query", "$Bin/inputs/tsv/twoqueries.tsv");
	
	#### SUCCESS
	($success, $error)	=	$self->_removeQuery($data);
	$self->logDebug("success", $success);	
	ok($success == 1, "_removeQuery success");

	#### CONFIRM REMOVED ROWS
	my $expectedjson = $self->getFileContents("$Bin/inputs/json/removequeryexpected.json");
	my $expected	=	$jsonparser->allow_nonref->decode($expectedjson);
	$self->logDebug("expected", $expected);
	
	my $queries		=	$self->getQueries();
	$self->logDebug("queries", $queries);

	is_deeply($expected, $queries, "_removeQuery confirmed removed rows");
}





method testGetDownloads {
	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	$self->logDebug("installdir", $installdir);
	my $query	=	$self->getFileContents("$installdir/bin/sql/download.sql");
	$self->logDebug("query", $query);
	$self->db()->do($query);
	
	#### LOAD DATA
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("download", "$Bin/inputs/tsv/download.tsv");
	
	my $downloads		=	$self->getDownloads();
	$self->logDebug("downloads", $downloads);

	my $expected = $self->getFileContents("$Bin/inputs/json/download.json");
	#$self->logDebug("expected", $expected);

	#### SET JSON PARSER
	my $jsonparser = JSON->new();
	$expected = $jsonparser->allow_nonref->decode($expected);
	$self->logDebug("expected", $expected);
	
	is_deeply($expected, $downloads, "Downloads match");
}

method testAddDownload {

	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### SET JSON PARSER
	my $jsonparser = JSON->new();

	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	#$self->logDebug("installdir", $installdir);
	my $download	=	$self->getFileContents("$installdir/bin/sql/download.sql");
	#$self->logDebug("download", $download);
	$self->db()->do($download);
	
	#### SHOULD SUCCEED	

	#### LOAD DATA
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("download", "$Bin/inputs/tsv/download.tsv");

	my $adddownload = $self->getFileContents("$Bin/inputs/json/adddownload.json");
	$self->logDebug("adddownload", $adddownload);

	my $data 	=	$jsonparser->allow_nonref->decode($adddownload);
	$self->logDebug("data", $data);
	
	my ($success, $error)	=	$self->_addDownload($data);
	$self->logDebug("success", $success);
	ok($success == 1, "_addDownload success");
	
	#### CONFIRM ROWS
	my $expectedjson = $self->getFileContents("$Bin/inputs/json/adddownloadexpected.json");
	#$self->logDebug("expectedjson", $expectedjson);
	my $expected	=	$jsonparser->allow_nonref->decode($expectedjson);
	$self->logDebug("expected", $expected);
	my $downloads		=	$self->getDownloads();
	$self->logDebug("downloads", $downloads);
	is_deeply($expected, $downloads, "_addQuery confirm rows");
	
	#### LOAD DATA
	$self->db()->do("DELETE FROM download");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("download", "$Bin/inputs/tsv/twodownloads.tsv");
	
	#### FAIL ON DUPLICATE DATA
	($success, $error)	=	$self->_addDownload($data);
	$self->logDebug("success", $success);	
	ok($success == 0, "_addQuery duplicate data failure");
	
	#### FAIL ON EMPTY DATA
	($success, $error)	=	$self->_addDownload({});
	$self->logDebug("success", $success);
	ok($success == 0, "_addQuery empty data failure");
}

method testRemoveDownload {

	##### PREPARE TEST DB
	$self->database($self->conf()->getKey("database", "TESTDATABASE"));
	$self->sessionid($self->conf()->getKey("database", "TESTSESSIONID"));
	$self->username($self->conf()->getKey("database", "TESTUSER"));
	$self->prepareTestDatabase();
	
	#### SET JSON PARSER
	my $jsonparser = JSON->new();

	#### CREATE TABLE
	my $installdir	=	$self->conf()->getKey("agua", "INSTALLDIR");
	#$self->logDebug("installdir", $installdir);
	my $download	=	$self->getFileContents("$installdir/bin/sql/download.sql");
	#$self->logDebug("download", $download);
	$self->db()->do($download);
	
	#### FAIL ON EMPTY DATA
	my ($success, $error)	=	$self->_removeDownload({});
	$self->logDebug("success", $success);	
	ok($success == 0, "_removeDownload empty data failure");
	
	#### LOAD DATA
	$self->db()->do("DELETE FROM download");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("download", "$Bin/inputs/tsv/download.tsv");
	
	#### FAIL ON ABSENT DATA
	my $before		=	$self->getDownloads();
	$self->logDebug("before", $before);
	my $removedownload = $self->getFileContents("$Bin/inputs/json/removedownload.json");
	$self->logDebug("removedownload", $removedownload);
	my $data 	=	$jsonparser->allow_nonref->decode($removedownload);
	$self->logDebug("data", $data);
	($success, $error)	=	$self->_removeDownload($data);
	$self->logDebug("success", $success);
	ok($success == 1, "_removeDownload success but no remove due to absent data");

	#### CONFIRM ROWS
	my $after		=	$self->getDownloads();
	$self->logDebug("after", $after);
	is_deeply($before, $after, "_removeDownload rows not removed");
	
	#### LOAD DATA
	$self->db()->do("DELETE FROM download");
	$self->logDebug("Bin", $Bin);
	$self->loadTsvFile("download", "$Bin/inputs/tsv/twodownloads.tsv");
	
	#### SUCCESS
	($success, $error)	=	$self->_removeDownload($data);
	$self->logDebug("success", $success);	
	ok($success == 1, "_removeDownload success");

	#### CONFIRM REMOVED ROWS
	my $expectedjson = $self->getFileContents("$Bin/inputs/json/removedownloadexpected.json");
	my $expected	=	$jsonparser->allow_nonref->decode($expectedjson);
	$self->logDebug("expected", $expected);
	
	my $downloads		=	$self->getDownloads();
	$self->logDebug("downloads", $downloads);

	is_deeply($expected, $downloads, "_removeDownload confirmed removed rows");
}


}	####	Agua::Login::Common
