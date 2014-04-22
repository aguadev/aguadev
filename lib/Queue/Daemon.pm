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

class Queue::Daemon with (Logger, Agua::Common::Exchange, Agua::Common::Util) {

#####////}}}}}

# Integers
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'novaclient'	=> ( isa => 'Openstack::Nova', is => 'rw', lazy	=>	1, builder	=>	"setNovaClient" );
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );

use FindBin qw($Bin);
use Test::More;

use TryCatch;

#####////}}}}}

method BUILD ($args) {
	
	#### SET SLOTS
	$self->setSlots($args);

	#### INITIALISE
	$self->initialise($args);
}

method initialise ($args) {
	#### LOAD MODULES
	my $modules = $self->loadModules();

	#### SET LISTENER
	$self->setListener($modules);
}

method loadModules {
    my $modules;
    my $installdir = $self->conf()->getKey("agua", "INSTALLDIR");
    my $modulestring = $self->conf()->getKey("agua", "MODULES");
	#$self->logDebug("modulestring", $modulestring);

	$modulestring = "Agua::Deploy";    
	#$modulestring = "Agua::Workflow";    
	#print "modulestring: $modulestring\n";

    my @modulenames = split ",", $modulestring;
    foreach my $modulename ( @modulenames) {
        my $modulepath = $modulename;
        $modulepath =~ s/::/\//g;
        my $location    = "$installdir/lib/$modulepath.pm";
#        print "location: $location\n";
        my $class       = "$modulename";
        eval("use $class");
    
        my $object = $class->new({
            conf        =>  $self->conf(),
            showlog     =>  $self->showlog(),
            printlog    =>  $self->printlog()
        });
        print "object: $object\n";
        
        $modules->{$modulename} = $object;
    }

    return $modules; 
}

method setListener ($modules) {

    $|++;
    use AnyEvent;
    use Net::RabbitFoot;
    
	my $host	=	$self->conf()->getKey("queue:masterip", undef);
	$self->logDebug("host", $host);
	$host = "localhost" if not defined $host;
	
    my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host => $host,
        port => 5672,
        user => 'guest',
        pass => 'guest',
        vhost => '/',
    );
    
    my $channel = $conn->open_channel();
    
    $channel->declare_exchange(
        #exchange => 'logs',
        exchange => 'chat',
        type => 'fanout',
    );
    
    my $result = $channel->declare_queue( exclusive => 1, );
    
    my $queue_name = $result->{method_frame}->{queue};
    
    $channel->bind_queue(
        #exchange => 'logs',
        exchange => 'chat',
        queue => $queue_name,
    );
    
    print " [*] Waiting for logs. To exit press CTRL-C\n";
    
	no warnings;
	my $handler	= *handleInput;
	use warnings;
	my $this	=	$self;
    $channel->consume(
        on_consume => sub {
			my $var = shift;
			my $body = $var->{body}->{payload};
		
			#print " [x] $body\n";
			print " [x] Incoming message\n";
			&$handler($this, $modules, $body);
		},
        queue => $queue_name,
        no_ack => 1,
    );
    
    AnyEvent->condvar->recv;    
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

method handleInput ($modules, $json) {
	
	$self->logDebug();
    #### GET DATA
    my $data = $self->parseJson($json);
	#$self->logDebug("data", $data);
	return if not defined $data;
    
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

	my $object	=   $self->getObject($modules, $data);
	#$self->logDebug("object", $object);
	$self->notifyError($data, "failed to create object") and return if not defined $object;

	#### GET MODE
	my $mode	=	$data->{mode};
	$self->logDebug("mode", $mode);
    $self->notifyError($data, "mode not defined") and return if not defined $mode;
    
    #### VERIFY MODULE SUPPORTS MODE
    $self->notifyError($data, "mode not supported: $mode") and return if not $object->can($mode);
	#print "{ error: 'mode not supported: $mode' }" and return if not $object->can($mode);
    
	
    #### RUN QUERY
	try {
		no strict;
		$object->$mode();
		use strict;
	}
	catch {
	    $self->notifyError($data, "failed to run mode '$mode'");
	}
    
	#### HANDLE ANY EXIT CALLS IN THE MODULES    
    EXITLABEL: { warn "EXIT\n"; };
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
		
		#### SET LOGFILE
		my $logfile     =   $self->setLogFile($username, $module);
		$self->conf()->logfile($logfile);
		
		#### GET OBJECT
		my $object = $modules->{$module};
		print "{ error: 'module not supported: $module' }" and return if not defined $object;
		
		#### SET OBJECT LOGFILE AND INITIALISE
		$object->logfile($logfile);
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
