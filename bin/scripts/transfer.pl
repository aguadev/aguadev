#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     transfer

PURPOSE

    TRANSFER ALL OF THE FILES AND VERSION OF ONE REPOSITORY
    
    TO ANOTHER.
    
    E.G., FROM DEVELOPMENT TO PRODUCTION:
        
        1. SET DEVELOPMENT VERSION AND ARCHIVE
        
        2. CLEAN PRODUCTION FILES
        
        3. COPY DEVELOPMENT ARCHIVE FILES TO PRODUCTION
        
        4. SET PRODUCTION VERSION IDENTICAL TO DEVELOPMENT VERSION

INPUT

    1. LOCATION OF SOURCE git REPOSITORY DIRECTORY
    
    2. VERSIONTYPE: major, minor, patch OR build, **OR** VERSION

    3. DESCRIPTION OF VERSION

    4. RELEASE DIRECTORY TO PRINT ARCHIVE FILE

    5. LOCATION OF TARGET git REPOSITORY DIRECTORY
    

OUTPUT

    1. UPDATED VERSION FILE IN SOURCE REPOSITORY (E.G., DEVELOPMENT REPO)
    
    2. GIT COMMITTED TAG CONTAINING VERSION IN SOURCE REPOSITORY
    
    3. BOTH 1 AND 2 IN TARGET REPOSITORY (E.G., PRODUCTION REPO)

NOTES

    ONLY USE THIS APPLICATION IF YOU WANT TO CREATE A NEW TAG TO RELEASE
    
    BUG FIXES (PATCH), NEW FEATURES (MINOR VERSION) OR API-RELATED CHANGES
    
    {MAJOR VERSION), OR TO MARK A PRE-RELEASE VERSION (RELEASE) OR A SMALL 
    
    INCREMENTAL IMPROVEMENT ON ANY OF THE ABOVE (BUILD).
    
    IF NONE OF THE ABOVE APPLY, DO NOT USE THIS APPLICATION. INSTEAD, TRACK
    
    CHANGES WITH 'git log' USING THE COMMIT ITERATION COUNTER, BUILD ID AND COMMENTS.
    
USAGE

sudo ./transfer.pl <--sourcerepo String> (<--version String> | <--versiontype String>) \
 <description String> [--versionfile String] [--outputdir String] [--help]

 --sourcerepo    :  Location of source git repository
 --targetrepo    :  Location of target git repository
 --description   :  Description of the changes in this version
 --versiontype   :  Increment version type (major|minor|patch|build|release)
 --versionfile   :  Location of version file (default: <sourcerepo>/VERSION)
 --releasename   :  Release type (alpha|beta|rc)
 --outputdir    :  Create packages inside RELEASE dir in this folder
 --branch        :  Name of the git branch to be versioned (default: master)
 --versionformat :  'numeric' (not yet implemented) or 'semver' for Semantic Versioning (default: semver)
 --help          :  Print help info

EXAMPLES

./version.pl \ 
 --versiontype build \
 --sourcerepo /home/syoung/0.6.0 \
 --versionfile bin/scripts/resources/VERSION \
 --outputdir /home/syoung

=cut

#### FLUSH BUFFER
$| = 1;

#### USE LIB
use FindBin qw($Bin);

use lib "$Bin/../../lib";
use lib "$Bin/../../lib/external/lib/perl5";
use lib "$Bin/../../lib/external/lib/perl5";

#### EXTERNAL MODULES
use Getopt::Long;
use Data::Dumper;

#### INTERNAL MODULES
#use Agua::Ops;
#use Conf::Yaml;

#### GET OPTIONS
my $branch          =   "master";
my $repository;
my $version;
my $versionformat   =   "semver";
my $description;
my $versiontype;
my $sourcerepo;
my $targetrepo;
my $outputdir;
my $releasename;
my $versionfile;
my $help;
GetOptions (
    'branch=s'          =>  \$branch,
    'version=s'         =>  \$version,
    'repository=s'      =>  \$repository,
    'versionformat=s'   =>  \$versionformat,
    'versiontype=s'     =>  \$versiontype,
    'description=s'     =>  \$description,
    'sourcerepo=s'      =>  \$sourcerepo,
    'targetrepo=s'      =>  \$targetrepo,
    'versionfile=s'     =>  \$versionfile,
    'outputdir=s'       =>  \$outputdir,
    'releasename=s'     =>  \$releasename,
    'help'              =>  \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "version.pl    repository not defined\n" and exit if not defined $repository;
print "version.pl    sourcerepo not defined\n" and exit if not defined $sourcerepo;
print "version.pl    targetrepo not defined\n" and exit if not defined $targetrepo;
print "version.pl    description not defined\n" and exit if not defined $description;
print "version.pl    versiontype must be 'major'O, 'minor', 'patch' or 'build'\n" and exit if defined $versiontype and not $versiontype =~ /^(major|minor|patch|release|build)$/;
print "version.pl    releasename must be 'alpha', 'beta', or 'rc'\n" and exit if defined $releasename and not $releasename =~ /^(alpha|beta|rc)$/;

#### SET DEFAULT VERSION FILE
$versionfile = "$sourcerepo/VERSION" if not defined $versionfile;

#### 1. CREATE VERSION AND RELEASE
my $versionexec = "$Bin/version.pl";
my $versioncommand = qq{$versionexec \\
--repodir $sourcerepo \\
--desc "$description" \\
};
$versioncommand .= qq{--version $version \\\n} if defined $version;
$versioncommand .= qq{--versiontype $versiontype \\\n} if defined $versiontype;
print "versioncommand:  $versioncommand\n";

my $output;
$output = `$versioncommand`;
print "output:  $output\n";
($version) = $output =~ /version:\s+(\S+)\s*$/ if not defined $version;
print "version:  $version\n";

my $archiveexec = "$Bin/archive.pl";
my $archivecommand = qq{$archiveexec \\
 --name $repository \\
 --repodir $sourcerepo \\
 --outputdir $outputdir &> /tmp/transfer.out};
print "archivecommand:  $archivecommand\n";

$output = `$archivecommand`;
print "output:  $output\n";
my ($repofile) = $output =~ /\s+(\S+)\s*$/;
print "repofile:  $repofile\n";

#### 2. EXPAND ARCHIVE AND COPY TO PRODUCTION REPO
my $commands = [
    #### EXPAND ARCHIVE
    "rm -fr /tmp/$repository.*.tar.gz",
    "cp $repofile /tmp",
    "cd /tmp; rm -fr /tmp/$repository",
    "#### Doing tar xvfz $repository.*.tar.gz",
    "cd /tmp; tar xvfz $repository.*.tar.gz &> /dev/null",
    #"rm -fr /tmp/$repository.*.tar.gz",
    
    #### COPY TO PRODUCTION AND COMMIT CHANGES
    "rm -fr $targetrepo/*",
    "cp -pr /tmp/$repository/* $targetrepo",
    "cd $targetrepo; if [ ! -d .git ]; then git init; fi; git add .",
    "cd $targetrepo; git commit -a -m \"$description\"",
];
runCommands($commands);

#### 3. CREATE NEW PRODUCTION VERSION AND PUSH
$versioncommand = qq{$versionexec \\
--repodir $targetrepo \\
--desc "$description" \\
--version $version \\\n};
print "versioncommand:  $versioncommand\n";
print `$versioncommand`;

print "transfer.pl    repofile: $repofile\n";
print "transfer.pl    version: $version\n";

######################## SUBROUTINES #####################

sub runCommands {
    my $commands 	=	shift;
    
    foreach my $command ( @$commands )
    {
    	print "transfer.pl    command: $command\n";		
    	print `$command` or die("Error with command: $command\n$!, Stopped");
    }
}

sub usage {
    print `perldoc $0`;
    exit;
}