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
my $SHOWLOG = 3;
my $PRINTLOG = 3;
my $help;
GetOptions (
    'SHOWLOG=i'     => \$SHOWLOG,
    'PRINTLOG=i'    => \$PRINTLOG,
    'help'          => \$help
);

#### INTERNAL MODULES
use lib "../../lib";
use Conf::Yaml;

my $object = Conf::Yaml->new({
    SHOWLOG     =>  $SHOWLOG,
    PRINTLOG    =>  $PRINTLOG
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

