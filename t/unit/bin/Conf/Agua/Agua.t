#!/usr/bin/perl -w

=head3 B<APPLICATION>     Agua.t
	
	PURPOSE

		1. DRIVE TESTS OF Conf::Agua

        2. SUPPORT TESTS OF MODULES THAT USE Conf::Agua BY PROVIDING
        
            A NON-WRITING setKey THAT ALLOWS THE OVERRIDING OF CONF FILE
            
            -PROVIDED VALUES WITHOUT AFFECTING THE CONF FILE (REQUIRES
            
            SETTING THE BOOLEAN VARIABLE memory TO 1 (DEFAULT: 0) )
            
=cut

use strict;

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More qw(no_plan);
use Test::File::Contents;
use File::Compare;
use File::Copy "cp";
use FindBin qw($Bin);

#### USE LIBS
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
BEGIN
{
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
}

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/default.conf";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

#### INTERNAL MODULES
use Test::Conf::Agua;

### TEST CONF
my $object = Test::Conf::Agua->new(
	backup		    =>	0
);

#### TESTS OF Conf::Agua
$object->testGetKey();
$object->testSetKey();

#### NON-WRITING setKey
$object->testWriteToMemory();

#### CLEAN UP
`rm -fr $Bin/outputs/*`;
