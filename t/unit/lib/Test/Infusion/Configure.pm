package Test::Illumina::WGS::Util::Configure ;

=pod

PACKAGE		Test::Illumina::WGS::Util::Configure 

PURPOSE		TEST CLASS Illumina::WGS::Util::Configure 

=cut

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../../../../../../lib";

#### INTERNAL MODULES
use Illumina::WGS::Util::Configure;
use Test::Common;
use Util;
use base qw(Illumina::WGS::Util::Configure Test::Common Util);

use Test::More;

####/////}}}
sub testCreateTestDb {
	my $self		=	shift;
	diag("createTestDb");

	#### GET OPTIONS
	my $dumpfile    = 	"$Bin/inputs/sql/dump/agua.dump";
	my $sqldir		= 	"$Bin/inputs/sql";
	my $mode        = 	"config";
	my $dbtype		=	"MySQL";
	my $testdatabase=	"test_1_2_3";
	my $configfile  = 	"$Bin/inputs/config.yaml";
	my $logfile     = 	"$Bin/outputs/log/saffron-config.log";
	#my $SHOWLOG     =    2;
	#my $PRINTLOG    =    2;
	my $SHOWLOG     =    $self->SHOWLOG();
	my $PRINTLOG    =    $self->PRINTLOG();
	my $help;
	
	my $conf = Conf::Yaml->new({
		memory      =>  1,
		configfile  =>  $configfile,
		backup      =>  1,
		SHOWLOG     =>  2,
		PRINTLOG    =>  2,
		logfile     =>  $logfile
	});

	$self->initialise({
		conf        =>  $conf,
		mode        =>  $mode,
		dbtype    	=>  $dbtype,
		testdatabase=>  $testdatabase,
		configfile  =>  $configfile,
		logfile     =>  $logfile,
		dumpfile    =>  $dumpfile,
		SHOWLOG     =>  $SHOWLOG,
		PRINTLOG    =>  $PRINTLOG,
		errortype	=>	"text"
	});
	
	ok($self->createTestDb(), "createTestDb");
	
	
	$self->db()->dropDatabase($testdatabase);
}

sub testCreateTables {
	my $self		=	shift;
	diag("createTables");

	#### GET OPTIONS
	my $dumpfile    = 	"$Bin/inputs/dump/agua.dump";
	my $sqldir		= 	"$Bin/inputs/db/sql";
	my $user		=	"testuser";
	my $password	=	"testpassword";
	my $mode        = 	"config";
	my $dbtype		=	"MySQL";
	my $testdatabase=	"test_1_2_3";
	my $configfile  = 	"$Bin/inputs/config.yaml";
	my $logfile     = 	"$Bin/outputs/log/saffron-config.log";
	my $SHOWLOG     =    $self->SHOWLOG();
	my $PRINTLOG    =    $self->PRINTLOG();
	my $help;
	
	my $conf = Conf::Yaml->new({
		memory      =>  1,
		configfile  =>  $configfile,
		backup      =>  1,
		SHOWLOG     =>  2,
		PRINTLOG    =>  2,
		logfile     =>  $logfile
	});

	$self->initialise({
		conf        =>  $conf,
		mode        =>  $mode,
		dbtype    	=>  $dbtype,
		testdatabase=>  $testdatabase,
		configfile  =>  $configfile,
		logfile     =>  $logfile,
		dumpfile    =>  $dumpfile,
		SHOWLOG     =>  $SHOWLOG,
		PRINTLOG    =>  $PRINTLOG,
		errortype	=>	"text"
	});
	
	#### CREATE EMPTY TEST DATABASE
	$self->testdatabase($testdatabase);
	$self->createTestDb();
	
	#### SET TEST USER
	my $testuser = $self->conf()->getKey("test", "TESTUSER");
	my $testpassword = $self->conf()->getKey("test", "TESTPASSWORD");
	$self->logDebug("testuser", $testuser);
	$self->logDebug("testpassword", $testpassword);
	$self->logDebug("testdatabase", $testdatabase);
	$self->testuser($testuser);
	$self->testpassword($testpassword);	
	$self->setTestUser();
	
	#### SET DATABASE HANDLE
	$self->_setDbh({
		user		=>	$testuser,
		password	=>	$testpassword,
		database	=>	$testdatabase,
		dbtype		=>	$self->dbtype,
		logfile		=>	$self->logfile(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG(),
		parent		=>	$self
	});
	
	#### GET EXPECTED TABLES	
	my $sqlfiles 	=	$self->getFiles($sqldir);
	@$sqlfiles 	= 	sort @$sqlfiles;

	#### GET TABLES TO BE LOADED FIRST
	my $firsttables = $self->firsttables();
	$self->logDebug("firststables", $firsttables);
	my $firstfiles = [];
	foreach my $firsttable ( @$firsttables ) {
		push @$firstfiles, "$firsttable.sql";
	}
	$self->logDebug("AFTER firstfiles", $firstfiles);
	$self->logDebug("AFTER firststables", $firsttables);

	#### ORDER FILES
	$sqlfiles	=	$self->_orderFiles($sqlfiles, $firstfiles);
	$self->logDebug("sqlfiles", $sqlfiles);

	#### CREATE TABLES
	$self->_createTables($sqldir, $sqlfiles);

	#### GET EXPECTED TABLE LIST
	my $expected = [];
	foreach my $file ( @$sqlfiles ) {
		my ($tablename) = $file =~ /^(.+?)\.sql/;
		push @$expected, $tablename;
	}
	$self->logDebug("expected", $expected);

	#### GET ACTUAL TABLE LIST
	my $actual 	= 	$self->db()->showTables();
	@$actual 	= 	sort @$actual;
	$actual 	= 	$self->_orderFiles($actual, $firsttables);
	$self->logDebug("actual", $actual);

	#### CHECK ALL TABLES WERE LOADED
	is_deeply($actual, $expected, "createTables    table list");
}

sub testLoadTsvFiles {
	my $self		=	shift;
	diag("createTestDb");

	#### GET OPTIONS
	my $sqldir		= 	"$Bin/inputs/db/sql";
	my $mode        = 	"config";
	my $dbtype		=	"MySQL";
	my $testdatabase=	"test_1_2_3";
	my $configfile  = 	"$Bin/inputs/config.yaml";
	my $logfile     = 	"$Bin/outputs/log/saffron-config.log";
	my $SHOWLOG     =    $self->SHOWLOG();
	my $PRINTLOG    =    $self->PRINTLOG();
	my $help;
	
	my $conf = Conf::Yaml->new({
		memory      =>  1,
		configfile  =>  $configfile,
		backup      =>  1,
		SHOWLOG     =>  2,
		PRINTLOG    =>  2,
		logfile     =>  $logfile
	});

	$self->initialise({
		conf        =>  $conf,
		mode        =>  $mode,
		dbtype    	=>  $dbtype,
		testdatabase=>  $testdatabase,
		configfile  =>  $configfile,
		logfile     =>  $logfile,
		SHOWLOG     =>  $SHOWLOG,
		PRINTLOG    =>  $PRINTLOG,
		errortype	=>	"text"
	});

	#### CREATE EMPTY TEST DATABASE
	$self->testdatabase($testdatabase);
	$self->createTestDb();
	
	#### SET TEST USER
	my $testuser = $self->conf()->getKey("test", "TESTUSER");
	my $testpassword = $self->conf()->getKey("test", "TESTPASSWORD");
	$self->logDebug("testuser", $testuser);
	$self->logDebug("testpassword", $testpassword);
	$self->logDebug("testdatabase", $testdatabase);
	$self->testuser($testuser);
	$self->testpassword($testpassword);	
	$self->setTestUser();
	
	#### SET DATABASE HANDLE
	$self->_setDbh({
		user		=>	$testuser,
		password	=>	$testpassword,
		database	=>	$testdatabase,
		dbtype		=>	$self->dbtype,
		logfile		=>	$self->logfile(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG(),
		parent		=>	$self
	});
	
	#### GET SQL FILES
	my $sqlfiles 	=	$self->getFiles($sqldir);
	@$sqlfiles 	= 	sort @$sqlfiles;

	#### GET TABLES TO BE LOADED FIRST
	my $firsttables = $self->firsttables();
	$self->logDebug("firststables", $firsttables);
	my $firstfiles = [];
	foreach my $firsttable ( @$firsttables ) {
		push @$firstfiles, "$firsttable.sql";
	}
	#$self->logDebug("AFTER firstfiles", $firstfiles);
	#$self->logDebug("AFTER firststables", $firsttables);

	#### ORDER FILES
	$sqlfiles	=	$self->_orderFiles($sqlfiles, $firstfiles);
	$self->logDebug("sqlfiles", $sqlfiles);

	#### CREATE TABLES
	$self->_createTables($sqldir, $sqlfiles);
	
	#### GET TSV FILES
	my $tsvdir = $sqldir;
	$tsvdir =~ s/[^\/]+$//;
	$tsvdir .= "tsv";	
	$self->logDebug("tsvdir", $tsvdir);
	my $tsvfiles 	=	$self->getFiles($tsvdir);
	$tsvfiles = $self->filterByRegex($tsvfiles, "\.tsv\$");
	@$tsvfiles 	= 	sort @$tsvfiles;
	$self->logDebug("tsvfiles", $tsvfiles);
	
	#### GET TABLES TO BE LOADED FIRST
	$firstfiles = [];
	foreach my $firsttable ( @$firsttables ) {
		push @$firstfiles, "$firsttable.tsv";
	}
	#$self->logDebug("AFTER firstfiles", $firstfiles);
	#$self->logDebug("AFTER firststables", $firsttables);
	
	#### ORDER FILES
	$tsvfiles	=	$self->_orderFiles($tsvfiles, $firstfiles);
	$self->logDebug("tsvfiles", $tsvfiles);
	
	#### TEST LOAD TSV FILES
	$self->_loadTsvFiles($tsvdir, $tsvfiles);


	#### VERIFY TABLE CONTENT
	foreach my $tsvfile ( @$tsvfiles ) {
		my ($table) = $tsvfile =~ /^(.+?)\.tsv$/;	
		diag("Test loaded $table");
		#next if not $table eq "flowcell_lane_qc";
				
		$self->checkTsvLines($table, "$tsvdir/$tsvfile", "loadTsvFiles    $table values");
	}

	#### CLEAN UP
	$self->db()->dropDatabase($testdatabase);
}



#### Illumina::WGS::Util::Configure 

1;