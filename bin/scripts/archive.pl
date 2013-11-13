#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     archive

PURPOSE

    1. ARCHIVE AND PACKAGE A GIT REPOSITORY FOR DISTRIBUTION
    
INPUT

    1. BASE DIR OF git REPOSITORY
    
    2. OUTPUTDIR FOR PACKAGE
    
    
OUTPUT

    MYSQL DATABASE CONFIGURATION AND EDITED CONFIG FILE            

USAGE

sudo ./archive.pl \
    <--name String> <--repodir String> <--version String> \
    <--versionfile String> <--outputdir String> [--help]

--name          :   Name of application
--versionfile   :	Location of version file (default: <repodir>/VERSION)
--repodir       :	Location of repodir where the .git directory is located
--outputdir     :	Create packaged file inside <outputdir>/RELEASE directory
--help          :   Print help info

EXAMPLES

./archive.pl \ 
 --name agua \ 
 --repodir /home/syoung/0.7.2 \
 --versionfile bin/scripts/resources/VERSION \
 --outputdir /home/syoung

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);

use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
use Agua::Configure;
use Agua::DBaseFactory;
use Conf;

#### GET OPTIONS
my $name;
my $repodir;
my $versionfile;
my $outputdir;
my $help;
GetOptions (
    'name=s'        => \$name,
    'repodir=s'     => \$repodir,
    'versionfile=s' => \$versionfile,
    'outputdir=s'   => \$outputdir,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "archive.pl    name not defined\n" and exit if not defined $name;
print "archive.pl    repodir not defined\n" and exit if not defined $repodir;
print "archive.pl    outputdir not defined\n" and exit if not defined $outputdir;
$versionfile = "$repodir/VERSION" if not defined $versionfile;

open(FILE, $versionfile) or die "Can't open versionfile: $versionfile\n";
my $version = <FILE>;
close(FILE) or die "Can't close versionfile: $versionfile\n";

#### 1. GET THE COMMIT COUNT
print "archive.pl   repodir is a file\n" and exit if -f $repodir;
chdir($repodir) or die "Can't chdir to repodir: $repodir\n";

#### 2. GET THE SHORT SHA KEY AS THE BUILD ID
chdir($repodir) or die "Can't chdir to repodir: $repodir\n";
my $buildid = `git rev-parse --short HEAD`;
$buildid =~ s/\s+//g;

#### 3. CREATE THE RELEASE DIR AND VERSION SUBDIR
print "archive.pl   outputdir is a file\n" and exit if -f $outputdir;
`mkdir -p $outputdir` if not -d $outputdir;
print "archive.pl    Can't create outputdir: $outputdir\n"
    and exit if not -d $outputdir;

#### 5. CREATE PACKAGE
my $archive = "git archive --format=tar --prefix=$name/ HEAD | gzip > $outputdir/$name.$version-$buildid.tar.gz";
print "$archive\n";
print `$archive`;

sub usage {
    print `perldoc $0`;
    exit;
}