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

class Queue::Daemon with (Logger, Agua::Common::Util) {

#####////}}}}}

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

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

	$modulestring = "Agua::Workflow";    
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
    
    my $conn = Net::RabbitFoot->new()->load_xml_spec()->connect(
        host => 'localhost',
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
		
			print " [x] $body\n";
			&$handler($this, $modules, $body);
		},
        queue => $queue_name,
        no_ack => 1,
    );
    
    AnyEvent->condvar->recv;    
}

method parseJson ($json) {
	$self->logDebug("json", $json);
    
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

    #### GET DATA
    my $data = $self->parseJson($json);
	$self->logDebug("data", $data);
	return if not defined $data;
    
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
    
    my $object  =   $self->getObject($modules, $data);
	my $mode	=	$data->{mode};
	$self->logDebug("mode", $mode);
    
    #### CHECK OBJECT 'CAN' mode
    print "{ error: 'mode not supported: $mode' }" and return if not $object->can($mode);
    
    #### RUN QUERY
    no strict;
    $object->$mode();
    use strict;
    
    #### DEBUG INFO
    my $endtime = time();
    #warn "total: " . ($endtime - $begintime) . "\n";
    
    EXITLABEL: { warn "EXIT\n"; };
}

method getObject ($modules, $data) {

    #### GET MODE
    my $mode = $data->{mode};
    #warn "$mode $whoami $cnt\n";
    return if not defined $mode;
    
    #### GET USERNAME
    my $username = $data->{username};
    print "{ error: 'username not defined' }" and return if not defined $username;
    
    #### GET MODULE
    my $module = $data->{module};
    
    #### SET LOGFILE
    my $logfile     =   "$Bin/log/$username.$module.log";
    $self->conf()->logfile($logfile);
    
    #### GET OBJECT
    my $object = $modules->{$module};
    print "{ error: 'module not supported: $module' }" and return if not defined $object;
    
    #### SET OBJECT LOGFILE AND INITIALISE
    $object->logfile($logfile);
    $object->initialise($data);

	return $object;
}





}
