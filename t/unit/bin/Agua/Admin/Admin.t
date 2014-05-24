#!/usr/bin/perl -w

use Test::More  tests => 22;
use Getopt::Long;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";

BEGIN
{
  use Cwd qw(abs_path);
  use File::Basename;
  push (@INC,dirname(abs_path($0)).'/../lib');
	print "abs_path: ", abs_path($0), "\n";
    my $installdir = $ENV{'installdir'} || "/agua";
    unshift(@INC, "$installdir/lib");
    unshift(@INC, "$installdir/lib/external/lib/perl5");
    unshift(@INC, "$installdir//apps/perl/5.18.2/lib/5.18.2");
}

#### CREATE OUTPUTS DIR
my $outputsdir = "$Bin/outputs";
`mkdir -p $outputsdir` if not -d $outputsdir;

#### INTERNAL MODULES
use lib "/aguadev/t/unit/lib";
use Test::Agua::Common::Admin;
use Conf::Yaml;

#### SET CONF FILE
my $installdir  =   $ENV{'installdir'} || "/agua";
my $configfile  =   "$installdir/conf/config.yaml";

#### SET $Bin
$Bin =~ s/^.+t\/bin/$installdir\/t\/bin/;

my $logfile = "$Bin/outputs/testuser.admin.log";

#### GET OPTIONS
my $log = 3;
my $printlog = 3;
my $help;
GetOptions (
    'log=i'     => \$log,
    'printlog=i'    => \$printlog,
    'help'          => \$help
) or die "No options specified. Try '--help'\n";
usage() if defined $help;

my $conf = Conf::Yaml->new(
	inputfile	=>	$configfile,
	memory		=>	1,
	backup		=>	1,
	separator	=>	"\t",
	spacer		=>	"\\s\+",
    logfile     =>  $logfile,
    log     =>  2,
    printlog    =>  2
);

#### SET DUMPFILE
my $dumpfile    =   "$Bin/../../../dump/create.dump";

my $object = new Test::Agua::Common::Admin (
    database    =>  "testuser",
    dumpfile    =>  $dumpfile,
    conf        =>  $conf,
    json        =>  {
        username    =>  'syoung',
    	sessionId	=>	"1234567890.1234.123"
    },
    username    =>  "testuser",
    project     =>  "Project1",
    workflow    =>  "Workflow1",
    logfile     =>  $logfile,
    log			=>	$log,
    printlog    =>  $printlog
);

my $json = {
    owner		=>	'testuser',
    groupname	=>	'analysis',
    groupwrite	=>	0,
    groupcopy	=>	1,
    groupview	=>	1,
    worldwrite	=>	0,
    worldcopy	=>	0,
    worldview	=>	0
};
$object->testAddRemoveAccess($json);

$json = {
    username	=>	"testuser",
    groupname	=>	"analysis",
    description	=>	"Analysis group",
    notes		=>	"Analysts and PIs only"
};
$object->testAddRemoveGroup($json);


#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
#                                    SUBROUTINES
#:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sub usage {
    print `perldoc $0`;
}


__END__

GETACCESS

perl -U admin.cgi < t/admin-getAccess.json 
{"username":"admin","sessionId":"1228791394.7868.158","mode":"getAccess"}


GETUSERS

perl -U admin.cgi < t/admin-getUsers.json
{"username":"admin","sessionId":"1228791394.7868.158","mode":"getUsers"}


LOGIN

perl -U admin.cgi < t/admin-login-admin.json 
{"mode":"login","username":"admin","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login.json 
{"mode":"login","username":"syoung","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login-wrong.json 
{"mode":"login","username":"syoung","password":"xxxxxxx"}

perl -U admin.cgi < t/admin-login-singlequote.json 
{'mode':'login','username':'syoung','password':'xxxxxxx'}

