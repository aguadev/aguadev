use MooseX::Declare;

=head2

	PACKAGE		Test::Agua::StarCluster

    PURPOSE
    
        TEST Agua::StarCluster METHODS

=cut

class Test::Agua::StarCluster with (Test::Agua::Common::Util) extends Agua::StarCluster {

use FindBin qw($Bin);
use Test::More;

#### INTERNAL MODULES
use Agua::StarCluster::Instance;
use Agua::DBaseFactory;
use Conf::Yaml;
use Conf::StarCluster;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use Getopt::Simple;


has 'config'=> (
	is 		=>	'rw',
	isa 	=> 'Conf::StarCluster',
	default	=>	sub { Conf::StarCluster->new( backup =>	1, separator => "="	);	}
);
has 'clusterinstance'=> (
	is 		=>	'rw',
	isa 	=>	'Agua::StarCluster::Instance',
	default	=>	sub { Agua::StarCluster::Instance->new({}); }
);

has custom_fields => (
    traits     => [qw( Hash )],
    isa        => 'HashRef',
    builder    => '_build_custom_fields',
    handles    => {
        custom_field         => 'accessor',
        has_custom_field     => 'exists',
        custom_fields        => 'keys',
        has_custom_fields    => 'count',
        delete_custom_field  => 'delete',
    }
);
sub _build_custom_fields { {} }

has 'overridecounter' => ( isa => 'HashRef', is => 'rw', default => sub {{}} );

####/////}}

method BUILD ($hash) {
    $self->logDebug("");
}

#### BALANCER
method testTerminateBalancer {
	my $lines = $self->getTerminateBalancer(2704);
}

method testGetProcessPids {
	my $lines = $self->getData("processlines");
	my $pids = $self->getProcessPids($lines);
	my $expected = $self->getData("processpids");
	$self->logDebug("pids", $pids);
	$self->logDebug("expected", $expected);

	is_deeply($pids, $expected, "getProcessPids");
}

#### OVERRIDE
method testGetProcessTree {

	#### GET PROCESS TREE LINES
	my $lines = $self->getProcessTree(2704);
	$self->logDebug("lines", $lines);
	my $expected = $self->getData("processlines");
	$self->logDebug("expected", $expected);

	is_deeply($lines, $expected, "getProcessTree");
}

method getProcessTrees {
	return $self->getData("processtrees");
}


#### TEST LOAD
method testLoad {
	diag("load");
	$self->logDebug("DOING self->loadStarCluster('load')");
	my $clusterobject = $self->loadStarCluster("load");
	$self->logDebug("AFTER self->loadStarCluster('load')");	
	foreach my $slot ( keys %$clusterobject ) {
		next if not $self->can($slot);
		my $value = $self->$slot();
		#$self->logDebug("value", $value);
		ok($self->$slot() eq $clusterobject->{$slot}, "1st load: $slot is $clusterobject->{$slot}: $value");
	}

	##### CHANGE VALUES
	$clusterobject->{username} = "NOTtestuser";
	$clusterobject->{cluster} = "NOTtestcluster";
	$self = $self->load($clusterobject);
	foreach my $slot ( "username", "cluster" ) {
		next if not $self->can($slot);
		my $value = $self->$slot();
		ok($self->$slot() eq $clusterobject->{$slot}, "2nd load: $slot is $clusterobject->{$slot}: $value");
	}	
}

#### START CLUSTER
method testStartCluster {
	diag("startCluster");
#### 1. START CLUSTER AND RESTART BALANCER IF CLUSTER NOT RUNNING
#### 2. START BALANCER IF BALANCER NOT RUNNING 
	$self->logDebug("");

	$self->loadStarCluster("startcluster");

	$self->logDebug("DOING self->startCluster");	
	my $started = $self->startCluster();
	$self->logDebug("started", $started);
	ok($started, "StarCluster started");
}

method loadStarCluster ($testname) {
	$self->logError("self->keyfile() not defined") and exit if not defined $self->keyfile();
	$self->logError("self->amazonuserid() not defined") and exit if not defined $self->amazonuserid();
	$self->logError("self->awsaccesskeyid() not defined") and exit if not defined $self->awsaccesskeyid();
	$self->logError("self->awssecretaccesskey() not defined") and exit if not defined $self->awssecretaccesskey();

    #### SET DIRS
    my $sourcedir = "$Bin/inputs/starcluster";
    my $targetdir = "$Bin/outputs/$testname";
    $self->setUpDirs($sourcedir, $targetdir);    

	#### SET PRIVATE KEY AND PUBLIC CERT
	my $keyfile	=	$self->keyfile();
	$self->logDebug("keyfile", $keyfile);
	$self->privatekey($keyfile);
	$self->publiccert("$keyfile.pub");
	
	#### GET TEST USER
	my $username    =   $self->conf()->getKey("database", "TESTUSER");

	#### CREATE DUMMY KEYPAIR FILE
	my $keyname = "id_rsa-$username-key";
	my $outputdir = "$Bin/outputs/teststart/aguatest/.starcluster";
	my $keypairfile = "$outputdir/$keyname";
	`touch $keypairfile`;
	
	#### SET EXECUTABLE
	my $executable = "$Bin/outputs/$testname/starcluster";
	`chmod 755 $executable`;
	
	#### SET USER DIR
	$self->conf()->setKey('agua', 'USERDIR', "$Bin/outputs/nethome");

	#### SET SGE PORTS
	my $qmasterport	=	36321;
	my $execdport	=	36322;
	
	#### SET OUTPUT FILE
	my $outputfile	=	"$Bin/$testname/$testname.log";
	
	#### SET ARGS HASH
		my $hash = {
		username 		=>  $username,
		cluster			=>  "$username-testcluster",
		outputfile		=>  $outputfile,
		executable		=>  $executable,
		project			=>	"Project1",
		workflow		=>	"Workflow1",
		workflownumber	=>	1,
		start			=>	1,
		submit			=>	1,
        minnodes        =>  0,
        maxnodes        =>  1,
		running			=>	1,
        instancetype    =>  "t1.micro",
        instanceid    	=>  "ec2-1.1.1.1.compute-1.amazonaws.com",
        amiid           =>  "ami-11c67678",
        availzone       =>  "us-east-1a",
        description     =>  "test cluster",
        configfile      =>  "$Bin/outputs/$testname/starcluster.config",
        outputdir       =>  $outputdir,
		keypairfile		=>	$keypairfile,
		keyname			=>	$keyname,
		qmasterport		=>	$qmasterport,
		execdport		=>	$execdport
    };
		
    #### LOAD ARGS HASH
    $self->loadArgs($hash);

	return $hash;	
}

method testClear {
	diag("clear");

	#### LOAD STARCLUSTER
	$self->loadStarCluster("clear");
	
	#### CLEAR SLOTS
	$self->clear();

	#### GET ATTRIBUTES
	my $meta = Agua::StarCluster->meta();
	my $attributes;
	@$attributes = $meta->get_attribute_list();
	$self->logDebug("attributes", $attributes);

	#### RESET TO DEFAULT OR CLEAR ALL ATTRIBUTES
	foreach my $attribute ( @$attributes ) {
        next if $attribute eq "SHOWLOG";
        next if $attribute eq "PRINTLOG";
        next if $attribute eq "db";
		next if $attribute eq "custom_fields";
        
		my $attr = $meta->get_attribute($attribute);
		my $default 	= $attr->default;
		my $ref = ref $default;
		my $value 		= $attr->get_value($self);
		my $isa  		= $attr->{isa};
		$self->logDebug("$attribute: $isa value", $value);
		#next if not defined $value;

		if ( not defined $default ) {
			ok(!$value, "NO-DEFAULT $attribute value is empty");
		}
		else {
			if ( $ref eq "CODE" ) {
				is_deeply($value, &$default, "CODE $attribute value identical to default value");
			}
			else {
				is_deeply($value, $default, "$attribute value identical to default value");
			}
		}
		$self->logNote("CLEARED $attribute ($isa)", $attr->get_value($self));
	}
}

#### OVERRIDE
method overrideSequence ($method, $sequence) {
	$self->logDebug("method", $method);
	$self->logDebug("sequence", $sequence);

	#### SET ATTRIBUTES - SEQUENCE AND COUNTER
	my $attribute = "$method-sequence";
	my $counter = "$method-counter";
	$self->custom_field($attribute, $sequence);
	$self->custom_field($counter, 0);

	my $sub = sub {
		my $self	=	shift;
		$self->logDebug("method", $method);

		my $sequence = $self->custom_field($attribute);
		$self->logDebug("sequence", $sequence);

		my $count 	= $self->custom_field($counter);
		my $value 	= 	$$sequence[$count];
		$self->logDebug("counter $count value", $value);
		
		$count++;
		$self->custom_field($counter, $count);
	
		return $value;
	};

	{
		no warnings;
		no strict;
		*{$method} = $sub;
	}
}

method overrideMethod ($method, $sub) {
    $self->logDebug("method", $method);
    $self->logDebug("sub", $sub);
    $self->logDebug("self: $self");

	use Sub::Override;
	
	my $override = Sub::Override->new( $method => $sub );
  #print foo(); # prints 'overridden sub'
  #$override->restore;


	#override $method = sub { &$sub(@_) };

		
	#print "DOING self->$method\n";
	#$self->$method();
	#
	#$self->logDebug("DEBUG EXIT") and exit;
	
}








method getData ($key) {
	my $data	=	{
		processtrees	=>	qq{PPID   PID  PGID   SID TTY      TPGID STAT   UID   TIME COMMAND
    0     2     0     0 ?           -1 S        0   0:00 [kthreadd]
    2     3     0     0 ?           -1 S        0   0:00  \_ [ksoftirqd/0]
    2     4     0     0 ?           -1 S        0   0:00  \_ [kworker/0:0]
    2     5     0     0 ?           -1 S        0   0:00  \_ [kworker/u:0]
    2     6     0     0 ?           -1 S        0   0:00  \_ [migration/0]
    2     7     0     0 ?           -1 S<       0   0:00  \_ [cpuset]
    2     8     0     0 ?           -1 S<       0   0:00  \_ [khelper]
    2     9     0     0 ?           -1 S<       0   0:00  \_ [netns]
    2    10     0     0 ?           -1 S        0   0:00  \_ [xenwatch]
    2    11     0     0 ?           -1 S        0   0:00  \_ [xenbus]
    2    12     0     0 ?           -1 S        0   0:00  \_ [sync_supers]
    2    13     0     0 ?           -1 S        0   0:00  \_ [bdi-default]
    2    14     0     0 ?           -1 S<       0   0:00  \_ [kintegrityd]
    2    15     0     0 ?           -1 S<       0   0:00  \_ [kblockd]
    2    16     0     0 ?           -1 S<       0   0:00  \_ [ata_sff]
    2    17     0     0 ?           -1 S        0   0:00  \_ [khubd]
    2    18     0     0 ?           -1 S<       0   0:00  \_ [md]
    2    21     0     0 ?           -1 S        0   0:00  \_ [kworker/0:1]
    2    22     0     0 ?           -1 S        0   0:00  \_ [khungtaskd]
    2    23     0     0 ?           -1 S        0   0:00  \_ [kswapd0]
    2    24     0     0 ?           -1 SN       0   0:00  \_ [ksmd]
    2    25     0     0 ?           -1 S        0   0:00  \_ [fsnotify_mark]
    2    26     0     0 ?           -1 S        0   0:00  \_ [ecryptfs-kthrea]
    2    27     0     0 ?           -1 S<       0   0:00  \_ [crypto]
    2    35     0     0 ?           -1 S<       0   0:00  \_ [kthrotld]
    2    36     0     0 ?           -1 S        0   0:00  \_ [khvcd]
    2   167     0     0 ?           -1 S        0   0:00  \_ [jbd2/xvda1-8]
    2   168     0     0 ?           -1 S<       0   0:00  \_ [ext4-dio-unwrit]
    2   494     0     0 ?           -1 S<       0   0:00  \_ [rpciod]
    2   500     0     0 ?           -1 S<       0   0:00  \_ [nfsiod]
    2   522     0     0 ?           -1 S        0   0:00  \_ [kjournald]
    2   562     0     0 ?           -1 S        0   0:00  \_ [kjournald]
    2   856     0     0 ?           -1 S        0   0:00  \_ [flush-202:1]
    2  2509     0     0 ?           -1 S        0   0:00  \_ [lockd]
    2  2510     0     0 ?           -1 S<       0   0:00  \_ [nfsd4]
    2  2511     0     0 ?           -1 S<       0   0:00  \_ [nfsd4_callbacks]
    2  2512     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2513     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2514     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2515     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2516     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2517     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2518     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2519     0     0 ?           -1 S        0   0:00  \_ [nfsd]
    2  2867     0     0 ?           -1 S        0   0:00  \_ [kworker/u:2]
    0     1     1     1 ?           -1 Ss       0   0:00 /sbin/init
    1   255   252   252 ?           -1 S        0   0:00 upstart-udev-bridge --daemon
    1   259   259   259 ?           -1 Ss       0   0:00 udevd --daemon
  259   318   259   259 ?           -1 S        0   0:00  \_ udevd --daemon
  259   319   259   259 ?           -1 S        0   0:00  \_ udevd --daemon
    1   308   307   307 ?           -1 S        0   0:00 upstart-socket-bridge --daemon
    1   412   412   412 ?           -1 Ss       0   0:00 dhclient3 -e IF_METRIC=100 -pf /var/run/dhclient.eth0.pid -lf /var/lib/dhcp3/dhclient.eth0.leases -1 eth0
    1   490   490   490 ?           -1 Ss     108   0:00 rpc.statd -L
    1   517   517   517 ?           -1 Ss       0   0:00 /usr/sbin/sshd -D
  517  1553  1553  1553 ?           -1 Ss       0   0:00  \_ sshd: root\@pts/0    
 1553  1567  1567  1567 pts/0     3007 Ss       0   0:01  |   \_ -bash
 1567  3008  3007  1567 pts/0     3007 S+       0   0:20  |       \_ /usr/bin/perl ./workflow.pl
 3008  3154  3007  1567 pts/0     3007 R+       0   0:00  |           \_ ps axjf
  517  1812  1812  1812 ?           -1 Ss       0   0:00  \_ sshd: root\@pts/1    
 1812  1828  1828  1828 pts/1     2027 Ss       0   0:01      \_ -bash
 1828  2027  2027  1828 pts/1     2027 S+       0   0:00          \_ python /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config sshmaster admin-microcluster
 2027  2028  2027  1828 pts/1     2027 S+       0   0:00              \_ sh -c ssh -i /home/admin/.starcluster/id_rsa-admin-key root\@ec2-54-242-70-108.compute-1.amazonaws.com
 2028  2029  2027  1828 pts/1     2027 S+       0   0:00                  \_ ssh -i /home/admin/.starcluster/id_rsa-admin-key root\@ec2-54-242-70-108.compute-1.amazonaws.com
    1   524   495   495 ?           -1 Sl     101   0:00 rsyslogd -c5
    1   530   530   530 ?           -1 Ss     102   0:00 dbus-daemon --system --fork --activation=upstart
    1   537   537   537 ?           -1 Ss       0   0:00 rpc.idmapd
    1   588   588   588 tty4       588 Ss+      0   0:00 /sbin/getty -8 38400 tty4
    1   593   593   593 tty5       593 Ss+      0   0:00 /sbin/getty -8 38400 tty5
    1   598   598   598 tty2       598 Ss+      0   0:00 /sbin/getty -8 38400 tty2
    1   599   599   599 tty3       599 Ss+      0   0:00 /sbin/getty -8 38400 tty3
    1   605   605   605 tty6       605 Ss+      0   0:00 /sbin/getty -8 38400 tty6
    1   612   612   612 ?           -1 Ss       0   0:00 cron
    1   613   613   613 ?           -1 Ss       1   0:00 atd
    1   626   626   626 ?           -1 Ssl    109   0:00 /usr/sbin/mysqld
    1   828   817   817 ?           -1 S        0   0:06 /usr/bin/perl ./view.pl 
    1   868   817   817 ?           -1 S        0   0:06 /usr/bin/perl ./package.pl 
    1   869   817   817 ?           -1 S        0   0:03 /usr/bin/perl ./folders.pl 
    1   870   817   817 ?           -1 S        0   0:06 /usr/bin/perl ./sharing.pl 
    1   878   817   817 ?           -1 S        0   0:06 /usr/bin/perl ./admin.pl 
    1   883   817   817 ?           -1 S        0   0:13 /usr/bin/perl ./workflow.pl 
    1  1253  1253  1253 ?           -1 Ss       0   0:00 /usr/sbin/apache2 -k start
 1253  1256  1253  1253 ?           -1 S       33   0:00  \_ /usr/sbin/apache2 -k start
 1253  1258  1253  1253 ?           -1 S       33   0:00  \_ /usr/sbin/fcgi-pm -k start
 1258  1261  1253  1253 ?           -1 S        0   0:05  |   \_ /usr/bin/perl ./view.pl 
 1258  1262  1253  1253 ?           -1 S        0   0:06  |   \_ /usr/bin/perl ./package.pl 
 1258  1269  1253  1253 ?           -1 S        0   0:03  |   \_ /usr/bin/perl ./folders.pl 
 1258  1278  1253  1253 ?           -1 S        0   0:06  |   \_ /usr/bin/perl ./sharing.pl 
 1258  1279  1253  1253 ?           -1 S        0   0:06  |   \_ /usr/bin/perl ./admin.pl 
 1258  1280  1253  1253 ?           -1 S        0   0:13  |   \_ /usr/bin/perl ./workflow.pl 
 1253  1276  1253  1253 ?           -1 Sl      33   0:00  \_ /usr/sbin/apache2 -k start
 1253  1277  1253  1253 ?           -1 Sl      33   0:00  \_ /usr/sbin/apache2 -k start
    1  1273  1273  1273 tty1      1273 Ss+      0   0:00 /sbin/getty -8 38400 tty1
    1  2160  2160  2160 ?           -1 Ss     108   0:00 rpc.statd -L
    1  2253  2253  2253 ?           -1 Ss     108   0:00 rpc.statd -L
    1  2348  2348  2348 ?           -1 Ss     108   0:00 rpc.statd -L
    1  2439  2439  2439 ?           -1 Ss       0   0:00 rpcbind -w
    1  2443  2443  2443 ?           -1 Ss     108   0:00 rpc.statd -L
    1  2451  2451  2451 ?           -1 Ss     108   0:00 rpc.statd -L
    1  2523  2523  2523 ?           -1 Ss       0   0:00 /usr/sbin/rpc.mountd --port 32767 --manage-gids
    1  2704  1772  1567 pts/0     3007 S        0   0:00 sh -c export SGE_QMASTER_PORT=36401; export SGE_EXECD_PORT=36402; export SGE_ROOT=/opt/sge6; export SGE_CELL=admin-microcluster; export USERNAME=admin; export QUEUE=admin-Project1-Workflow1; export PROJECT=Project1; export WORKFLOW=Workflow1; /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master 
 2704  2705  1772  1567 pts/0     3007 Sl       0   0:03  \_ python /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master
    1  2851  1772  1567 pts/0     3007 S        0   0:00 sh -c export SGE_QMASTER_PORT=36401; export SGE_EXECD_PORT=36402; export SGE_ROOT=/opt/sge6; export SGE_CELL=admin-microcluster; export USERNAME=admin; export QUEUE=admin-Project1-Workflow1; export PROJECT=Project1; export WORKFLOW=Workflow1; /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master 
 2851  2852  1772  1567 pts/0     3007 Sl       0   0:03  \_ python /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master
},
		processlines	=>	[
			"    1  2704  1772  1567 pts/0     3007 S        0   0:00 sh -c export SGE_QMASTER_PORT=36401; export SGE_EXECD_PORT=36402; export SGE_ROOT=/opt/sge6; export SGE_CELL=admin-microcluster; export USERNAME=admin; export QUEUE=admin-Project1-Workflow1; export PROJECT=Project1; export WORKFLOW=Workflow1; /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master ",
			" 2704  2705  1772  1567 pts/0     3007 Sl       0   0:03  _ python /agua/apps/starcluster/bin/starcluster -c /home/admin/.starcluster/admin-microcluster.config bal admin-microcluster -m 1 -n 0 -i 30 -w 100 -s 30 --kill-master"
		],
		processpids		=>	["2704", "2705"]
	};

	return $data->{$key};
}


}	#### class Agua::StarCluster
