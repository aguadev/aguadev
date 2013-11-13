#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     version

PURPOSE

    1. UPDATE THE VERSION NUMBER, PRE-RELEASE LABEL OR BUILD IN
    
        THE VERSION FILE ACCORDING TO THE PROVIDED UPDATE TYPE
        
    2. PRINT THE USER-SUPPLIED DESCRIPTION TO THE VERSION FILE 
    
    3. ADD THE DATETIME TO THE VERSION FILE
    
    4. ADD A TAG USING THE WHOLE VERSION AND DESCRIPTION

INPUT

    1. BASE DIR OF git REPOSITORY
    
    2. UPDATE TYPE: major, minor, patch OR build

    3. (OPTIONAL) RELEASE NAME

    3. DESCRIPTION OF VERSION

OUTPUT

    1. UPDATED VERSION FILE IN BASE DIR OF git REPOSITORY
    
    2. GIT COMMITTED TAG CONTAINING WHOLE VERSION AND DESCRIPTION

NOTES

    ONLY USE THIS APPLICATION IF YOU WANT TO CREATE A NEW TAG TO RELEASE
    
    BUG FIXES (PATCH), NEW FEATURES (MINOR VERSION) OR API-RELATED CHANGES
    
    {MAJOR VERSION), OR TO MARK A PRE-RELEASE VERSION (RELEASE) OR A SMALL 
    
    INCREMENTAL IMPROVEMENT ON ANY OF THE ABOVE (BUILD).
    
    IF NONE OF THE ABOVE APPLY, DO NOT USE THIS APPLICATION. INSTEAD, TRACK
    
    CHANGES WITH 'git log' USING THE COMMIT ITERATION COUNTER, BUILD ID AND COMMENTS.
    
USAGE

sudo ./version.pl <--repodir String> (<--version String> | <--versiontype String>) \
 <description String> [--versionfile String] [--releasename String] [--help]

 --repodir       :  Name of folder where the .git directory is located
 --description   :  Description of the changes in this version
 --versiontype   :  Name of application
 --versionfile   :  Location of version file (default: <repodir>/VERSION)
 --releasename   :  Create packages inside RELEASE dir in this folder
 --branch        :  Name of the git branch to be versioned (default: master)
 --versionformat :  'numeric' (not yet implemented) or 'semver' for Semantic Versioning (default: semver)
 --help          :  Print help info

EXAMPLES

./version.pl \ 
 --versiontype build \
 --repodir /home/syoung/0.6.0 \
 --versionfile bin/scripts/resources/VERSION \
 --releasename /home/syoung

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
use Agua::Ops;

#### GET OPTIONS
my $branch          =   "master";
my $login;
my $version;
my $versionformat   =   "semver";
my $description;
my $versiontype;
my $repodir;
my $releasename;
my $versionfile;
my $help;
GetOptions (
    'branch=s'          =>  \$branch,
    'version=s'         =>  \$version,
    'login=s'           =>  \$login,
    'versionformat=s'   =>  \$versionformat,
    'versiontype=s'     =>  \$versiontype,
    'description=s'     =>  \$description,
    'repodir=s'         =>  \$repodir,
    'versionfile=s'     =>  \$versionfile,
    'releasename=s'     =>  \$releasename,
    'help'              =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "version.pl    repodir not defined\n" and exit if not defined $repodir;
print "version.pl    description not defined\n" and exit if not defined $description;
print "version.pl    versiontype must be 'major', 'minor', 'patch' or 'build'\n" and exit if defined $versiontype and not $versiontype =~ /^(major|minor|patch|release|build)$/;
print "version.pl    releasename must be 'alpha', 'beta', or 'rc'\n" and exit if defined $releasename and not $releasename =~ /^(alpha|beta|rc)$/;

#### SET DEFAULT VERSION FILE
$versionfile = "$repodir/VERSION" if not defined $versionfile;

#### SET LOG
my $logfile = "/tmp/agua-version.log";
my $SHOWLOG     =   2;
my $PRINTLOG    =   5;

my $object = Agua::Ops->new({
    logfile     =>   $logfile,
    SHOWLOG     =>   $SHOWLOG,
    PRINTLOG    =>   $PRINTLOG,
    
    login       =>  $login
});

#### SET VERSION IF DEFINED
if ( defined $version ) {
    my ($result, $error) = $object->setVersion($versionformat, $repodir, $versionfile, $branch, $version, $description);
    print "\n\n$error\n\n" and exit if not $result;
    print "\nCreated new version: $version\n\n";
}
#### OTHERWISE, INCREMENT VERSION
else {
    my $newversion = $object->incrementVersion($versionformat, $versiontype, $repodir, $versionfile, $releasename, $description, $branch);
    print "\n\nFailed to create version: $newversion (NB: must be later than existing versions). Please see usage ($0 -h)\n\n" and exit if not defined $newversion;
    print "\nNew version: $newversion\n\n";
}


sub usage {
    print `perldoc $0`;
    exit;
}