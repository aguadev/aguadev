#!/usr/bin/perl -w
use strict;

my $DEBUG = 0;
$DEBUG = 1;

=head2

APPLICATION     build

PURPOSE

	Run the Agua build procedure:
	
		1. CREATE BUILD PROFILE
		
		2. REMOVE nls FILES
		
		3. MOVE LARGE DIRECTORIES AND jslib DIR
		
		4. RUN THE BUILD
		
		5. COPY BUILD TO build FOLDER
		
		6. REPLACE nls FILES
		
		7. RESTORE LARGE DIRECTORIES AND jslib DIR

INPUT

    1. BUILD NUMBER

OUTPUT

    1. AGUA BUILD IN builds DIRECTORY

USAGE

sudo ./build.pl <--build Int> [--help]

 --build    :  Build number

EXAMPLES

./build.pl  --build 022

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
my $configfile = "$Bin/../../conf/config.yaml";
my $logfile = "/tmp/agua-build.log";
my $conf = Conf::Yaml->new(
    memory      =>  1,
    inputfile	=>	$configfile,
    showlog     =>  2,
    printlog    =>  2,
    logfile     =>  $logfile
);
my $installdir = $conf->getKey("agua", "INSTALLDIR");
my $dojo		= $conf->getKey("agua", "DOJO");
print "installdir: $installdir\n";
print "dojo: $dojo\n";

#### GET OPTIONS
my $build;
my $help;
GetOptions (
    'build=s'          =>  \$build
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

print "build.pl    build not defined\n" and exit if not defined $build;

#### 1. CREATE BUILD PROFILE
my $command = qq{$installdir/bin/scripts/buildConfig.pl --inputdir $installdir/html/plugins \\
--outputfile $installdir/html/$dojo/util/buildscripts/profiles/agua_all.profile.js \\
--name "../agua_all.js" \\
--exclude dojo,dijit,dojox
};
runCommand($command);

#### 2. MOVE nls FILES
runCommand("mv $installdir/html/$dojo/dojo/nls/_en-us.js $installdir/html/$dojo/dojo/nls/_en-us.js.bkp");
runCommand("mv $installdir/html/$dojo/dijit/nls/en-us.js $installdir/html/$dojo/dijit/nls/en-us.js.bkp");
runCommand("mv $installdir/html/$dojo/dojo/nls/_en-gb.js  $installdir/html/$dojo/dojo/nls/_en-gb.js.bkp");

#### MOVE reload.js FILES
runCommand("mv $installdir/html/plugins/core/reload.js  $installdir/html/plugins/core/reload.js.bkp");
runCommand("mv $installdir/html/plugins/folders/reload.js  $installdir/html/plugins/folders/reload.js.bkp");
runCommand("mv $installdir/html/plugins/workflow/reload.js  $installdir/html/plugins/workflow/reload.js.bkp");

#### 3. MOVE LARGE DIRECTORIES AND jslib DIR
runCommand("sudo mkdir /jbrowse-safe");
runCommand("sudo mv $installdir/html/plugins/view/jbrowse/jslib /jbrowse-safe/jslib");
runCommand("sudo mv $installdir/html/plugins/view/jbrowse/users /jbrowse-safe/users");
runCommand("sudo mv $installdir/html/plugins/view/jbrowse/species /jbrowse-safe/species");

#### 4. RUN THE BUILD
my $builddir = "$installdir/html/$dojo/util/buildscripts";
chdir($builddir);
my $buildcommand = qq{java -classpath ../shrinksafe/js.jar:../shrinksafe/shrinksafe.jar org.mozilla.javascript.tools.shell.Main build.js profile=agua_all action=release cssOptimize=comments.keepLines releaseDir=../../../builds/$build-agua_all version="0.6" > $installdir/html/builds/$build-agua_all.build.txt
};
print "build command:\n\n$buildcommand\n\n";
runCommand($buildcommand);
    ###release:  Build is in directory: ../../../builds/$build-agua_all/dojo
    ###Build time: 526.962 seconds

#### 5. COPY BUILD TO build FOLDER
runCommand("cp $installdir/html/builds/$build-agua_all/dojo/agua_all.js $installdir/html/build/agua_all.js");
runCommand("cp $installdir/html/builds/$build-agua_all/dojo/agua_all.js.uncompressed.js $installdir/html/build/agua_all.js.uncompressed.js");

#### 6. REPLACE nls FILES
print "build.pl    Replacing nslfile\n";
runCommand("mv $installdir/html/$dojo/dojo/nls/_en-us.js.bkp $installdir/html/$dojo/dojo/nls/_en-us.js");
runCommand("mv $installdir/html/$dojo/dijit/nls/en-us.js.bkp $installdir/html/$dojo/dijit/nls/en-us.js");
runCommand("mv $installdir/html/$dojo/dojo/nls/_en-gb.js.bkp  $installdir/html/$dojo/dojo/nls/_en-gb.js");

#### RESTORE reload.js FILES
runCommand("mv $installdir/html/plugins/core/reload.js.bkp $installdir/html/plugins/core/reload.js");
runCommand("mv $installdir/html/plugins/folders/reload.js.bkp $installdir/html/plugins/folders/reload.js");
runCommand("mv $installdir/html/plugins/workflow/reload.js.bkp $installdir/html/plugins/workflow/reload.js");

#### 7. RESTORE LARGE DIRECTORIES AND jslib DIR
print "build.pl    Restoring jslib, users, species from /jbrowse-safe\n";
runCommand("sudo mv /jbrowse-safe/jslib $installdir/html/plugins/view/jbrowse/jslib");
runCommand("sudo mv /jbrowse-safe/users $installdir/html/plugins/view/jbrowse/users");
runCommand("sudo mv /jbrowse-safe/species $installdir/html/plugins/view/jbrowse/species");

######################## SUBROUTINES #####################

sub usage {
    print `perldoc $0`;
    exit;
}

sub runCommand {
	my $command 	=	shift;
	print "build command: $command\n";
	`$command`;
}