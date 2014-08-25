use MooseX::Declare;

=head2

NOTES

	Use SSH to parse logs and execute commands on remote nodes
	
TO DO

	Use queues to communicate between master and nodes:
	
		WORKERS REPORT STATUS TO MANAGER
	
		MANAGER DIRECTS WORKERS TO:
		
			- DEPLOY APPS
			
			- PROVIDE WORKFLOW STATUS
			
			- STOP/START WORKFLOWS

=cut

use strict;
use warnings;

class Queue::Monitor with (Logger, Exchange, Agua::Common::Database, Agua::Common::Timer) {

#####////}}}}}

use Agua::DBase;

# Integers
has 'log'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);  
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2	);
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 60 );

# Strings
has 'database'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );
has 'command'	=> ( isa => 'Str|Undef', is => 'rw'	);
has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw'	);
has 'arch'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0 );

# Objects
has 'conf'		=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'jsonparser'=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser" );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required	=>	0 );

use FindBin qw($Bin);
use Test::More;
use Data::Dumper;

#####////}}}}}

method initialise ($hash) {
	#### SET SLOTS
	$self->setSlots($hash);
	$self->logDebug("AFTER self->setSlots()");
}

method monitor {

	$self->logDebug("");
	
	while ( 1 ) {
		#### SEND 'HEARTBEAT' NODE STATUS INFO
		$self->logDebug("DOING self->heartbeat");
		$self->heartbeat();

		$self->logDebug("DOING self->checkWorker");
		$self->checkWorker();

		my $sleep	=	$self->sleep();
		print "Queue::Monitor::monitor    Sleeping $sleep seconds before checkWorker\n";
		sleep($sleep);
	}	
}

#### HEARTBEAT
method heartbeat {
	
	my $time		=	$self->getMysqlTime();
	my $host		=	$self->getHostName();
	my $ipaddress	=	$self->getIpAddress();
	$self->logDebug("ipaddress", $ipaddress);

	my $arch	=	$self->getArch();
	if ( $arch eq "ubuntu" ) {
		`if [ ! -f /usr/bin/mpstat ]; then  apt-get install -y sysstat; fi`;
	}
	elsif ( $arch eq "centos" ) {
		`if [ ! -f /usr/bin/mpstat ]; then  yum install -y sysstat; fi`;
	}
	
	my $cpu		=	$self->getCpu();
	#$self->logDebug("cpu", $cpu);
	
	my $io		=	$self->getIo();
	#$self->logDebug("io", $io);
	
	my $disk		=	$self->getDisk();
	#$self->logDebug("disk", $disk);

	my $memory		=	$self->getMemory();
	#$self->logDebug("memory", $memory);
		
	my $data	=	{
		queue		=>	"update.host.status",
		host		=>	$host,
		ipaddress	=>	$ipaddress,
		cpu			=>	$cpu,
		io			=>	$io,
		disk		=>	$disk,
		memory		=>	$memory,
		time		=>	$time,
		mode		=>	"updateHeartbeat"
	};
	#$self->logDebug("data", $data);
	
	$self->sendTask($data);
}

method getIpAddress {
	my $ipaddress	=	`facter ipaddress`;
	$ipaddress		=~ 	s/\s+$//;
	$self->logDebug("ipaddress", $ipaddress);
	
	return $ipaddress;
}

method getHostName {
	my $hostname	=	`facter hostname`;
	$hostname		=~ 	s/\s+$//;
	$self->logDebug("hostname", $hostname);
	
	return $hostname;
}

method getArch {
	my $arch = $self->arch();
	return $arch if defined $arch;
	
	$arch 	= 	"linux";
	my $command = "uname -a";
    my $output = `$command`;
	#$self->logDebug("output", $output);
	
    #### Linux ip-10-126-30-178 2.6.32-305-ec2 #9-Ubuntu SMP Thu Apr 15 08:05:38 UTC 2010 x86_64 GNU/Linux
    $arch	=	 "ubuntu" if $output =~ /ubuntu/i;
    #### Linux ip-10-127-158-202 2.6.21.7-2.fc8xen #1 SMP Fri Feb 15 12:34:28 EST 2008 x86_64 x86_64 x86_64 GNU/Linux
    $arch	=	 "centos" if $output =~ /fc\d+/;
    $arch	=	 "centos" if $output =~ /\.el\d+\./;
	$arch	=	 "debian" if $output =~ /debian/i;
	$arch	=	 "freebsd" if $output =~ /freebsd/i;
	$arch	=	 "osx" if $output =~ /darwin/i;

	$self->arch($arch);
    $self->logDebug("FINAL arch", $arch);
	
	return $arch;
}

method getIo {
	return `iostat`;
}

method getCpu {
	return `mpstat`;
}

method getDisk {
	return `df -ah`;
}

method getMemory {
	return `sar -r 1 1`;
}
#### CHECK WORKER
method checkWorker {
	my $name		=	"worker";
	my $logfile		=	"/var/log/upstart/$name.log";
	
	$self->logDebug("logfile", $logfile);
	print "Returning. Can't find logfile: $logfile\n" and return if not -f $logfile;

	my $command		=	"tail $logfile";
	$self->logDebug("command", $command);
	my $log	=	`$command`;
	$self->logDebug("log", $log);
	if ( $log =~	/Heartbeat lost/msi ) {
		print "HEARTBEAT LOST. Doing restartUpstart($name, $logfile)\n";
		$self->logDebug("HEARTBEAT LOST    Doing restartUpstart($name, $logfile)");	
		$self->restartUpstart($name, $logfile);
	}
}

method restartUpstart ($name, $logfile) {
	$self->logDebug("name", $name);
	$self->logDebug("logfile", $logfile);

	my $command		=	qq{ps aux | grep "perl /usr/bin/$name"};
	$self->logDebug("ps command", $command);
	my $output	=	`$command`;
	#$self->logDebug("output", $output);
	my $processes;
	@$processes	=	split "\n", $output;
	#$self->logDebug("processes", $processes);
	foreach my $process ( @$processes ) {
		#$self->logDebug("process", $process);
		my ($pid)	=	$process	=~	/^\S+\s+(\S+)/;
		my $command	=	"kill -9 $pid";
		$self->logDebug("KILL command", $command);
		`$command`;
	}
	
	#### REMOVE LOG FILE
	$command	=	"rm -fr $logfile";
	$self->logDebug("DELETE command", $command);
	`$command`;
	
	#### RESTART UPSTART PROCESS
	$command	=	"service $name restart";
	$self->logDebug("RESTART command", $command);
	`$command`;
	
	$self->logDebug("END");
}



}

