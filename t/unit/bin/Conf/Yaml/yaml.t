#!/usr/bin/perl -w

#### TEST Conf/Yaml.pm

#### EXTERNAL MODULES
use Test::More  tests => 28;
use Getopt::Long;
use FindBin qw($Bin);

#### USE LIBS
use lib "$Bin/../../../lib";
use lib "$Bin/../../../../lib";

#### GET OPTIONS
my $log = 3;
my $printlog = 3;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
);

#### INTERNAL MODULES
use lib "../../lib";
use Conf::Yaml;

my $object = Conf::Yaml->new({
    log			=>	$log,
    printlog    =>  $printlog
});

#### TEST LOAD FILE
$object->testRead();

#### TEST GET KEY
$object->testGetKey();

#### TEST SET KEY
$object->testSetKey();

#### TEST READ FROM MEMORY
$object->testReadFromMemory();

#### TEST WRITE TO MEMORY
$object->testWriteToMemory();

#### SATISFY Agua::Common::Logger::logError CALL TO EXITLABEL
no warnings;
EXITLABEL : {};
use warnings;

