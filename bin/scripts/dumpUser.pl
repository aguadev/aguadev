#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     dumpUser

PURPOSE

	GENERATE DEFAULT CREATE TABLE SQL AND DATA INSERT DUMP FILES

USAGE

sudo ./dumpUser.pl <--db String> [--help]

 --db           :  Name of database (default: agua)
 --tables       :  Comma-separated list of "table:where" pairs
                   (default 'where': "username='admin'")
 --outputdir    :  Name of database (default: agua)

EXAMPLES

./dumpUser.pl  --db 022

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);

use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Conf::Yaml;

#### GET CONF
#### SET LOG
my $showlog		=	2;
my $printlog	=	5;
my $configfile 	= "$Bin/../../conf/config.yaml";
my $logfile 	= "$Bin/../../log/dumpuser.log";
my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);

#### GET OPTIONS
my $database 	= 	"agua";
my $ignore		=	"diffs,report";
my $username	=	"agua";
my $tables		=	"ami,cluster,clustervars,feature,source";
my $outputfile 	= 	"$Bin/../sql/dump/$database.dump";
my $help;
GetOptions (
    'database=s'    =>  \$database,
    'tables=s'    	=>  \$tables,
    'ignore=s'    	=>  \$ignore,
    'username=s'    =>  \$username,
    'outputfile=s'  =>  \$outputfile
) 	or die "No options specified. Try '--help'\n";
usage() if defined $help;

my ($user, $password) = setUserPassword($conf, $username);

#### SET OUTPUTDIR
my ($outputdir, $filename) = 	$outputfile =~ /^(.+?)\/([^\/]+)$/;

#### SET TABLES ARRAY
my $tablearray;
@$tablearray = split ",", $tables;

#### DEBUG
#@$tablearray = reverse(@$tablearray);

#### CREATE OUTPUT DIR
`mkdir -p $outputdir` if not -d $outputdir;
print "dumpUser.pl    Can't create outputdir: $outputdir\n" and exit if not -d $outputdir;

#### WRITE CREATE OPTION FILE
my $createfile = "$outputdir/create.cnf";
my $createdumpfile = "$outputdir/create-$filename";
my $create = qq{
[client]
user=$user
password=$password

[mysqldump]
no-data
result-file=$createdumpfile};
my @ignored = split ",", $ignore;
foreach my $ignore ( @ignored ) {
	$create .= qq{\nignore-table=$database.$ignore};
}

print "dumpUser.pl    Printing createfile: $createfile\n" if $DEBUG;
open(CREATE, ">$createfile") or die "Can't open createfile: $createfile\n";
print CREATE $create;
close(CREATE) or die "Can't close createfile: $createfile\n";

#### GENERATE CREATE DUMP FILE
my $dumpcreate = "mysqldump --defaults-extra-file=$createfile $database";
print "dumpUser.pl    command: $dumpcreate\n";
`$dumpcreate`;

#### CLEAN UP
my $rm = "rm -fr $createfile";
print "$rm\n" if $DEBUG;
`$rm`;

my $insertdumpfile = "$outputdir/insert-$filename";
my $command = "echo '#### INSERT TABLES ' > $insertdumpfile";
print "dumpUser.pl    command: $command\n" if $DEBUG;
`$command`;

foreach my $table ( @$tablearray ) {
	$table =~ /^([^:]+):*(.*)$/;
	my $tablename 	= $1;
	my $where		= $2 || "";
	$where = "username='$username'" if not $where;

	my $subfile = createInsertFile($outputdir, $database, $tablename, $where);
	#print "subfile: $subfile\n";
	my $cat = "cat $subfile >> $insertdumpfile";
	print "dumpUser.pl    $cat\n" if $DEBUG;
	`$cat`;

	my $rm = "rm -fr $subfile";
	print "dumpUser.pl    $rm\n" if $DEBUG;
	`$rm`;
}

#### CONCAT TO CREATE agua.dump
my $concat = "cat $createdumpfile $insertdumpfile > $outputfile";
print "dumpUser.pl    command: $concat\n";
`$concat`;

print "dumpUser.pl    Completed    ", `date`;

######################## SUBROUTINES #####################

sub createInsertFile {
	my $outputdir	=	shift;
	my $database	=	shift;
	my $tablename	=	shift;
	my $where		=	shift;
	
	#### WRITE INSERT OPTION FILE
	my $insertfile = "$outputdir/insert-$tablename.cnf";
	my $insertdumpfile = "$outputdir/insert-$tablename.dump";
	#print "insertfile: $insertfile\n";
	#print "insertdumpfile: $insertdumpfile\n";
	$where = qq{where="$where"} if $where;
	
	my $insert = qq{
	[client]
	user=$user
	password=$password
	
	[mysqldump]
	no-create-info
	compact
	skip-add-drop-table
	skip-extended-insert
	skip-quote-names
	$where
	result-file=$insertdumpfile
	};
	
	print "dumpUser.pl    insert: $insert\n" if $DEBUG;
	print "dumpUser.pl    Printing insertfile: $insertfile\n" if $DEBUG;
	open(INSERT, ">$insertfile") or die "Can't open insertfile: $insertfile\n";
	print INSERT $insert;
	close(INSERT) or die "Can't close insertfile: $insertfile\n";
	
	#### GENERATE INSERT DUMP FILE
	my $dumpinsert = "mysqldump --defaults-extra-file=$insertfile $database $tablename";
	print "dumpUser.pl    command: $dumpinsert\n";
	`$dumpinsert`;

	#### CLEAN UP
	my $command = "rm -fr $insertfile";
	print "$command\n" if $DEBUG;
	`$command`;
	
	return $insertdumpfile;
}

sub setUserPassword {
	my $conf		=	shift;
	my $username	=	shift;
	
	my $testuser 	=	$conf->getKey("database", "TESTUSER");
	my ($user, $password);
	if ( $testuser eq $username ) {
		$user = $conf->getKey("database", "TESTUSER");
		$password = $conf->getKey("database", "TESTPASSWORD");
	}
	else {
		$user = $conf->getKey("database", "USER");
		$password = $conf->getKey("database", "PASSWORD");
	}
print "dumpUser.pl    user not defined\n" and exit if not defined $user;
print "dumpUser.pl    password not defined\n" and exit if not defined $password;

	return ($user, $password);	
}

sub usage {
    print `perldoc $0`;
    exit;
}