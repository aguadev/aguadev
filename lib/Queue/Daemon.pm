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

class Queue::Daemon with (Logger, Exchange, Agua::Common::Util) {

#####////}}}}}

# Integers
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'time'			=>  ( isa => 'Int', is => 'rw' );
has 'timeout'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'novaclient'	=> ( isa => 'Openstack::Nova', is => 'rw', lazy	=>	1, builder	=>	"setNovaClient" );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw'	);

# Objects
has 'modules'		=> ( isa => 'HashRef|Undef', is => 'rw', lazy	=>	1, builder	=>	"setModules" );
has 'lastsent'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=>	0 );
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'lastreceived'	=>  ( isa => 'HashRef|Undef', is => 'rw' );

use FindBin qw($Bin);
use Test::More;

use TryCatch;
use Data::Dumper;

#####////}}}}}

method BUILD ($args) {
	
	#### SET SLOTS
	$self->setSlots($args);

	#### INITIALISE
	$self->initialise($args);
}

method initialise ($args) {

	#### SET SLOTS
	$self->setSlots($args);

	#### SET LISTENER
	$self->receiveFanout();
}

method setModules {
	$self->logDebug("");
    my $modulestring = $self->conf()->getKey("agua", "MODULES");
    my @modulenames = split ",", $modulestring;
	#$modulestring = "Agua::Deploy";    
	#$modulestring = "Agua::Workflow";    
	#$modulestring 	=	"Queue::Monitor";
	$self->logDebug("modulestring", $modulestring);
	$self->logDebug("self->log()", $self->log());

    my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");

	my $modules	=	{};
    foreach my $modulename ( @modulenames ) {
        my $modulepath = $modulename;
        $modulepath =~ s/::/\//g;
        my $location    = "$installdir/lib/$modulepath.pm";
        #print "location: $location\n";
        my $class       = "$modulename";
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $self->conf(),
            log     =>  $self->log(),
            printlog    =>  $self->printlog()
        });
        print "object: $object\n";
        
        $modules->{$modulename} = $object;
    }
	$self->modules($modules);

    return $modules; 
}

method receiveFanout {
	$self->logDebug("");
    $|++;
    
	my $connection	=	$self->newSocketConnection();
    my $channel = $connection->open_channel();
    my $exchange	=	"chat";
    $channel->declare_exchange(
        exchange	=>	$exchange,
        type		=>	'fanout',
    );
    
    my $result = $channel->declare_queue( exclusive => 1, );
    my $queuename = $result->{method_frame}->{queue};
    $channel->bind_queue(
        exchange	=>	$exchange,
        queue		=>	$queuename,
    );
    
    print " [*] $queuename. Waiting for fanout\n";
    
	no warnings;
	my $handler	= *handleFanout;
	use warnings;
	my $this	=	$self;
    $channel->consume(
        on_consume => sub {
			my $var = shift;
			my $body = $var->{body}->{payload};
			print " [x] Queue::Daemon::receiveFanout    Incoming message\n";
			&$handler($this, $body);
		},
        queue => $queuename,
        no_ack => 1,
    );
    
    AnyEvent->condvar->recv;    
}

method timedOut {
	$self->time(time) if not defined $self->time();
	my $time	=	$self->time();
	$self->logDebug("time", $time);
	my $currenttime	=	time;
	my $timeout	=	$self->timeout();
	$self->logDebug("timeout", $timeout);
	$self->logDebug("time", $time);
	$self->logDebug("currenttime", $currenttime);
	$self->logDebug("currenttime - time", $currenttime - $time);
	
	return 0 if $currenttime - $time < $timeout;
	
	#### TIMEOUT lastsent AND lastreceived
	$self->logDebug("Cancelling lastsent AND lastreceived");
	$self->lastsent({});
	$self->lastreceived({});
	
	return 1;
}

method handleFanout ($json) {	
	$self->logDebug();

    #### GET DATA
    my $data = $self->parseJson($json);
	$self->notifyError("mode not defined") and return if not defined $data;

	if ( is_deeply($data, $self->lastreceived()) ) {
		$self->logDebug("Duplicate query. Ignoring", $data);
		return if not $self->timedOut();
	}
	#$self->logDebug("data", $data);

	#### VERIFY TYPE IS request
	my $sendtype	=	$data->{sendtype};
	#$self->logDebug("sendtype", $sendtype);
	$self->logDebug("Type is '$sendtype'. Returning") and return if $sendtype ne "request";
	
	#### GET MODE
	my $mode	=	$data->{mode};
	$self->logDebug("mode", $mode);
    if ( not defined $mode ) {
		$self->notifyError($data, "mode not defined");
		return;
	}
	elsif ( $mode eq "" ) {
		$self->notifyError($data, "mode is empty");
		return;
	}	
	$self->logDebug("mode is sendSocket. Quitting") and return if $mode eq "sendSocket";

	if ( defined $self->lastsent() ) {
		$self->logDebug("Checking for match with self->lastsent()");
		$self->logDebug("data", $data);
		$self->logDebug("self->lastsent()", $self->lastsent());

		return if Test::More::eq_hash($data, $self->lastsent());
    }
	$self->lastsent($data);

	if ( defined $data->{processid} and $data->{processid} eq $$ ) {
		$self->logDebug("processid matches self. Ignoring");
		return;
	}	
	
    #### SET WHOAMI
    my $whoami = `whoami`;
    chomp($whoami);
    $data->{whoami} = $whoami;
    
    #### SET REQUIRED INPUTS
	no warnings;
    my $required = qw(whoami username mode module);
    use warnings;
	
    ##### CLEAN INPUTS
    #$self->cleanInputs($data, $required);
    #
    ##### CHECK INPUTS
    #$self->checkInputs($data, $required);

	#### SET object FROM MODULES
	my $modules	=	$self->modules();
	my $object	=   $self->getObject($modules, $data);
	#$self->logDebug("object", $object);
	$self->notifyError($data, "failed to create object") and return if not defined $object;

    #### VERIFY MODULE SUPPORTS MODE
    $self->notifyError($data, "mode not supported: $mode") and return if not $object->can($mode);
	#print "{ error: 'mode not supported: $mode' }" and return if not $object->can($mode);
    
	#### CHECK HOSTNAME
	if ( defined $data->{hostname} and $data->{hostname} ne "" ) {
		$self->logDebug("Checking hostname matches '$data->{hostname}'");
		my $hostname	=	$self->getHostname();
		if ( $hostname ne $data->{hostname} ) {
		    $self->notifyError($data, "data->{hostname} '$data->{hostname}' failed to match hostname '$hostname'");
			return;
		}
		
		$self->logDebug("hostname matches data->{hostname}: $hostname");
	}
	
    #### RUN QUERY
	try {
		no strict;
		$object->$mode();
		use strict;
	}
	catch ($error) {
	    $self->notifyError($data, "failed to run mode '$mode': $error");
	}
    
	#### HANDLE ANY EXIT CALLS IN THE MODULES    
    EXITLABEL: { warn "EXIT\n"; };
}

method parseJson ($json) {
	$self->logDebug("");
	#$self->logDebug("json", $json);
    
    use JSON;
    my $jsonParser = JSON->new();
    my $data;
    try {
        $data = $jsonParser->allow_nonref->decode($json);    
        return $data;
    }
    catch {
		$self->logDebug("Message is not JSON: $json. Ignoring");
        print "Message is not JSON: $json. Ignoring\n";
		return undef;
    } 
}

method cleanInputs ($data, $keys) {
	$self->logDebug("data", $data);
	$self->logDebug("keys", $keys);
    $self->logDebug('{"error":"JSON not defined"}') and return if not defined $data;

    foreach my $key ( @$keys ) {
        $data->{$key} =~ s/;`//g;
        $data->{$key} =~ s/eval//g;
        $data->{$key} =~ s/system//g;
        $data->{$key} =~ s/exec//g;
    }
}

method checkInputs ($json, $keys) {
    print "{ 'error' : 'agua.pl	JSON not defined' }" and return if not defined $json;

    foreach my $key ( @$keys ) {
        print "{ 'error' : 'agua.pl	JSON not defined' }" and return if not defined $json->{$key};
    }
}

method getHostname {

	#### GET OPENSTACK HOST NAME
	#### E.G., split.v2-5.hd800-real-de2e4a8b-7034-4525-ab3e-33fc993797f8.novalocal
	my $hostname	=	$self->novaclient()->getMetaData("hostname");
	$hostname		=~	s/\.novalocal\s*$//;
	$self->logDebug("hostname", $hostname);
	
	#### OTHERWISE, GET LOCAL HOSTNAME
	if ( $hostname eq "" ) {
		$hostname	=	`hostname`;
		$hostname	=~	s/\s+$//g;
	}

	return $hostname;	
}

method getInternalIp {
	return	$self->novaclient()->getMetaData("local-ipv4");
}

method getExternalIp {
	return	$self->novaclient()->getMetaData("public-ipv4");
}

method updateIps {
	my $internalip	=	$self->getInternalIp();
	my $externalip	=	$self->getExternalIp();

	$self->conf()->setKey("queue:selfinternalip", $internalip);
	$self->conf()->setKey("queue:selfexternalip", $externalip);
}

method getObject ($modules, $data) {

	#$self->logDebug("modules", $modules);
	#$self->logDebug("data", $data);

	#try {

		#### GET MODE
		my $mode = $data->{mode};
		print "mode: $mode\n";
		return if not defined $mode;
		
		#### GET USERNAME
		my $username = $data->{username};
		print "{ error: 'username not defined' }" and return if not defined $username;
		
		#### GET MODULE
		my $module = $data->{module};
		
		##### SET LOGFILE
		#my $logfile;
		#$logfile	=	$self->logfile() if $self->can('logfile');
		#if ( not defined $logfile or $logfile eq "" ) {
		#	$self->logDebug("DOING self->setLogfile()");
		#	$logfile     =   $self->setLogFile($username, $module);
		#	$self->conf()->logfile($logfile) if defined $self->conf() and $self->conf()->can('logfile');
		#}

		#### GET OBJECT
		my $object = $modules->{$module};
		if ( not defined $object ) {
			$data->{error}	=	"module $module not supported or failed to run mode: $mode";
			$self->sendSocket($data);
			return;
		}
		
		#### SET OBJECT LOGFILE AND INITIALISE
		#$self->logDebug("Doing object->logfile");
		#$object->logfile($logfile) if $self->can('logfile');
#		$self->logDebug("Doing object->initialise");
		$object->initialise($data);
	
		return $object;
	#}
	#catch {
	#	return;
	#}
}

method setLogFile ($username, $module) {
	#### SET LOGFILE
	my $logfile =   "$Bin/../../log/$username.$module.log";
	$logfile	=~ 	s/::/-/g;
	
	return $logfile;
}



}
