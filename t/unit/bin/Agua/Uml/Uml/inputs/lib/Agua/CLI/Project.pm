use MooseX::Declare;
use Getopt::Simple;

use FindBin qw($Bin);
use lib "$Bin/../..";

class Agua::CLI::Project with (Agua::CLI::Logger, Agua::CLI::Timer) {
    use File::Path;
    use JSON;
    use Data::Dumper;
    use Agua::CLI::Workflow;
    use Agua::CLI::App;
    use Agua::CLI::Parameter;

    #### LOGGER
    has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
    has 'SHOWLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	0 	);  
    has 'PRINTLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	0 	);

    #### STORED LOGISTICS VARIABLES
    has 'owner'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => 'anonymous' );
    has 'project'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'name'	    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'number'	=> ( isa => 'Int|Undef', is => 'rw', required	=>	0	);
    has 'type'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{User-defined workflow type} );
    has 'description'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'notes'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'ordinal'	=> ( isa => 'Str|Undef', is => 'rw', default => undef, required => 0, documentation => q{Set order of appearance: 1, 2, ..., N} );
    has 'workflows'	    => ( isa => 'ArrayRef[Agua::CLI::Workflow]', is => 'rw', default => sub { [] } );
    has 'provenance'=> ( isa => 'Str|Undef', is => 'rw', required	=>	0, default => '');
    
    #### STORED STATUS VARIABLES
    has 'status'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'locked'	    => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'queued'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'started'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'stopped'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'duration'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'epochqueued'	=> ( isa => 'Maybe', is => 'rw', default => 0 );
    has 'epochstarted'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'epochstopped'  => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'epochduration'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
    
    #### CONSTANTS
    has 'indent'    => ( isa => 'Int', is => 'ro', default => 15);
    
    #### TRANSIENT VARIABLES
    has 'from'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'to'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'newname'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'appFile'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'field'	    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'value'	    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'fields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['name', 'number', 'owner', 'description', 'notes', 'outputdir', 'field', 'value', 'wkfile', 'outputfile', 'cmdfile', 'start', 'stop', 'ordinal', 'from', 'to', 'status', 'started', 'stopped', 'duration', 'epochqueued', 'epochstarted', 'epochstopped', 'epochduration'] } );
    has 'savefields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['name', 'number', 'owner', 'description', 'notes', 'status', 'started', 'stopped', 'duration', 'locked'] } );
    has 'exportfields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['name', 'number', 'owner', 'description', 'notes', 'status', 'started', 'stopped', 'duration', 'provenance'] } );
    has 'inputfile' => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'wkfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'cmdfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'workflowfile'   => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'logfile'   => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputdir'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'dbfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'dbtype'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'database'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'user'      => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'password'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'force'     => ( isa => 'Maybe', is => 'rw', required => 0 );
    has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
    has 'logfh'     => ( isa => 'FileHandle', is => 'rw', required => 0 );
    has 'start'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'stop'	=> ( isa => 'Str', is => 'rw', required => 0 );

####//}}    
    
    method BUILD ($hash) { 
        $self->logDebug("Project::BUILD()");    
        $self->initialise();
    }

    method initialise () {
        $self->logDebug("");
        $self->owner("anonymous") if not defined $self->owner();
        $self->inputfile($self->wkfile()) if defined $self->wkfile() and $self->wkfile();
        
        $self->logDebug("inputfile must end in '.proj'") and exit
            if $self->inputfile()
            and not $self->inputfile() =~ /\.proj$/;

        $self->logDebug("outputfile must end in '.proj'") and exit
            if $self->outputfile()
            and not $self->outputfile() =~ /\.proj$/;
        
        $self->read();
    }

    method getopts () {
        #$self->logDebug("Agua::CLI::Project::getopts()");
        my @temp = @ARGV;
        my $args = $self->args();

        my $olderr;
        open $olderr, ">&STDERR";	
        open(STDERR, ">/dev/null") or die "Can't redirect STDERR to /dev/null\n";
        my $options = Getopt::Simple->new();
        $options->getOptions($args, "Usage: blah blah"); 
        open STDERR, ">&", $olderr;

        #$self->logDebug("options->{switch}:");
        #print Dumper $options->{switch};
        my $switch = $options->{switch};
        foreach my $key ( keys %$switch )
        {
            $self->$key($switch->{$key}) if defined $switch->{$key};
        }

        @ARGV = @temp;
        $self->initialise();
    }


    method args() {
        my $meta = $self->meta();

        my %option_type_map = (
            'Bool'     => '!',
            'Str'      => '=s',
            'Int'      => '=i',
            'Num'      => '=f',
            'ArrayRef' => '=s@',
            'HashRef'  => '=s%',
            'Maybe'    => ''
        );
        
        my $attributes = $self->fields();
        my $args = {};
        foreach my $attribute_name ( @$attributes )
        {
            my $attr = $meta->get_attribute($attribute_name);
            my $attribute_type  = $attr->{isa};
            #$self->logDebug("attribute_type", $attribute_type);
            
            $attribute_type =~ s/\|.+$//;
            $args -> {$attribute_name} = {  type => $option_type_map{$attribute_type}  };
        }
        #$self->logDebug("args", $args);
        
        return $args;
    }

    method lock {
        $self->_loadFile() if $self->inputfile();
        $self->locked(1);
        
        $self->logDebug("Locked workflow '"), $self->name(), "'\n";
#        $self->logDebug("self->locked: "), $self->locked(), "\n";
    }

    method unlock {
        $self->_loadFile() if $self->inputfile();
        $self->locked(0);
        $self->logDebug("Unlocked workflow '"), $self->name(), "'\n";
        #$self->logDebug("self->locked: "), $self->locked(), "\n";
    }

    method run() {
        $self->logDebug("Project::run(app)");

        $self->_loadFile();
        #$self->logDebug("self->toString(): "), $self->toString(), "\n";
        $self->logDebug("outputdir not defined. Exiting") and exit if not defined $self->outputdir();

        #### WRITE BKP FILE
        my $bkpfile = '';
        $bkpfile .= $self->outputdir() . "/" if $self->outputdir();
        $bkpfile .= $self->name() . ".wk.bkp";
        $self->outputfile($bkpfile);
        $self->_write();
    
        #### START LOGGER IF NOT STARTED
        my $logfile = $self->setLogFile();
        if ( not $self->logfh() )
        {
            my $logfh;
            open($logfh, ">$logfile") or die "Can't open logfile: $logfile\n";
            $self->logfh($logfh);
        }
        
        #### DO LOGGING
        my $section = "[workflow ". $self->name() . "]\n";
        $self->logDebug($section);
        $self->logDebug();
        $self->logDebug($self->_wiki() . "\n\n");

        #### RUN APPS
        my $workflows = $self->workflows();
        $self->logDebug("No. workflows: "). scalar(@$workflows) . "\n";
        
        my $start = $self->start();
        $start = 1 if not defined $start or $start =~ /^\s*$/;
        my $stop = $self->stop();
        $stop = scalar(@$workflows) if not defined $stop or $stop =~ /^\s*$/;
        $stop = scalar(@$workflows) if $stop > scalar(@$workflows);
        $self->logDebug("start", $start);
        $self->logDebug("stop", $stop);
        
        #### SET STARTED
        $self->setStarted();
        $self->logDebug("starting workflow ")  . $self->name()  . "': " . $self->started() . "'\n";
        
        for ( my $i = $start - 1; $i < $stop; $i++ )
        {
            my $workflow = $$workflows[$i];
            $self->logDebug("Running app '") . $workflow->name() . "'\n";
            $workflow->logfh($self->logfh());
            $workflow->outputdir($self->outputdir());
            my ($status, $label) = $workflow->run();
            #$self->logDebug("Agua::CLI::Project::run    completed", $status);
            #$self->logDebug("Agua::CLI::Project::run    label", $label) if defined $label;

            $self->logDebug("Workflow may not have completed successfully.\n\nWorkflow status: $status.\n\nPlease check the logfile", $logfile) if not $status or $status ne "completed";
            
            $self->logDebug("\nWorkflow status", $status)
                and last if $status ne "completed";
        }

        #### SET STOPPED
        $self->setStopped();
        $self->logDebug("ending workflow '")  . $self->name()  . "': " . $self->started() . "\n";
        
        #### SET DURATION
        $self->setDuration();
        
        #### END LOG
        $self->logDebug("\nCompleted workflow " . $self->name() . "\n");
        $self->logDebug();
        
        $self->outputfile($self->inputfile());
        $self->_write();
        
        return 1;
    }

    method setLogFile () {
        return $self->logfile() if $self->logfile();
        my $logfile = '';
        $logfile .= $self->outputdir() . "/" if $self->outputdir();
        $logfile .= $self->name() . ".wk.log";
        if ( -f $logfile )
        {
            my $counter = 1;
            my $log = "$logfile.$counter";
            while ( -f $log )
            {
                $counter++;
                $log = "$logfile.$counter";
            }
            `mv $logfile $log`;
        }
        $self->logfile($logfile);
    }
    
    method loadCmd () {
        #$self->logDebug("Workflow::loadCmd()");
        
        $self->_loadFile();

        my $cmdfile = $self->cmdfile();
        open(FILE, $cmdfile) or die "Can't open cmdfile: $cmdfile\n";
        $/ = undef;
        my $content = <FILE>;
        close(FILE) or die "Can't close cmdfile: $cmdfile\n";
        $/ = "\n";
        $content =~ s/,\\\n/,/gms;

        my @commands = split "\n\n", $content;
        foreach my $command ( @commands )
        {
            next if $command =~ /^\s*$/;
            require Agua::CLI::Workflow;
            my $workflow = Agua::CLI::Workflow->new();
            $workflow->getopts();
            $workflow->_loadCmd($command);
            #$self->logDebug("app:");
            #print $workflow->toString(), "\n";
            $self->_addWorkflow($workflow);
        }
        
        $self->_write();
        
        return 1;
    }

    method app() {
        $self->logDebug("Workflow::app()");
   
=HEAD2
        $self->_loadFile() if $self->wkfile();
    
        require Agua::CLI::Workflow;
        my $workflow = Agua::CLI::Workflow->new();
        $workflow->getopts();
        #$self->logDebug("app:");
        #print $workflow->toString(), "\n";
        
        $self->logDebug("Please provide '--name' or '--ordinal' argument for app\n") and exit if not $workflow->name() and not $workflow->ordinal();

        #### GET THE PARAM FROM workflows
        my $index;
        $index = $workflow->ordinal() - 1 if $workflow->ordinal();
        $index = $self->_appIndex($workflow) if not $workflow->ordinal();
        $self->logDebug("Can't find app among workflow's workflows:"), $workflow->toString(), "\n\n" and exit if not defined $index;
        #$self->logDebug("index", $index);

        my $workflow = ${$self->workflows()}[$index];
        $self->logDebug("Can't find app number ") . $index + 1 . "\n" and exit if not defined $workflow;
        #$self->logDebug("BEFORE getopts workflow:");
        #print $workflow->toString(), "\n";

        $workflow->getopts();
        #$self->logDebug("AFTER getopts workflow:");
        #print $workflow->toString(), "\n";

        my $command = shift @ARGV;
        #$self->logDebug("command", $command);

        my $return = $workflow->$command();

        $self->_write() if $self->inputfile();
        
        return $return;
        
        
=cut

    }

    method replace () {
        $self->logDebug("Agua::CLI::Project::replace()");
        
        $self->_loadFile() if defined $self->workflowfile() and $self->workflowfile();
        
        #$self->logDebug("BEFORE self->toString() :");
        #print $self->toString();

        #### DO PARAMETERS
        my $workflows = $self->workflows();
        my $params = [];
        foreach my $parameter ( @$workflows )
        {
            $parameter->getopts();
            $parameter->replace();
        }
        #$self->logDebug("AFTER self->toString() :");
        #print $self->toString() ;

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
    }

    method loadWorkflow ($workflow) {
        $self->logDebug("");        
        $self->_addWorkflow($workflow);
        my $name = $workflow->name();
        $name = "unknown" if not defined $name;

        $self->_write();

        my $ordinal = $workflow->ordinal();
        $self->logDebug("Added app $ordinal: '$name'");
        
        return 1;
    }

    method addWorkflow ($workflowfile) {
        $self->logDebug("workflowfile", $workflowfile);
        
        #### INITIALISE PROJECT FROM FILE
        $self->_loadFile();
        #$self->logDebug("self->toString()");
        #print $self->toString(), "\n";

        $self->logDebug("workflowfile not defined. Exiting") if not defined $workflowfile and not $workflowfile;

        my $workflow = Agua::CLI::Workflow->new(
            inputfile =>  $workflowfile
        );
        $workflow->getopts();
        $workflow->_loadFile();

        $self->logCritical("workflow->name() not defined") and exit if not defined $workflow->name();

        $self->_addWorkflow($workflow);

        return 1;
    }

    method _addWorkflow ($workflowobject) {
        #$self->logDebug("Project::_addWorkflow()");
    
        return $self->_insertWorkflow($workflowobject, $workflowobject->ordinal() - 1)
            if $workflowobject->ordinal();
        
        #### INCREMENT ORDINAL AND SET ON THIS APP
        $workflowobject->ordinal(scalar(@{$self->workflows()} + 1));
        
        push @{$self->workflows()}, $workflowobject;

        $self->_numberWorkflows();

        #### WRITE TO PROJECT FILE
        $self->_write();
        
        #### CREATE WORKFLOW FILE
        my $workflowname    = $workflowobject->name();
        my $workflownumber  = $workflowobject->number();
        my $projectfile     = $self->outputfile();
        $projectfile        = $self->inputfile() if not defined $projectfile;
        my ($projectdir)    = $projectfile =~ /^(.+?)\/[^\/]+$/;
        my $workflowfile = "$projectdir/$workflownumber-$workflowname.work";
        $self->logDebug("workflowfile", $workflowfile);
        `rm -fr $workflowfile`;
        $workflowobject->export($workflowfile);

        return scalar(@{$self->workflows()});
    }

    method _insertWorkflow ($workflow, $index) {
        #$self->logDebug("Project::_insertWorkflow(app)");
        #$self->logDebug("app->toString(): "), $workflow->toString(), "\n";
        #$self->logDebug("index", $index);

        splice @{$self->workflows}, $index, 0, $workflow;
        
        $self->_numberWorkflows();
        
        return $index;
    }

    method moveWorkflow () {
        $self->logDebug("Project::moveWorkflow(app)");

        $self->_loadFile();

        my $from = $self->from();
        $self->logDebug("from not defined") and exit if not $from;
        $self->logDebug("from out of range (1 - "), scalar(@{$self->workflows()}), ")\n" and exit if $from > scalar(@{$self->workflows()});
        $self->logDebug("from out of range (1 - "), scalar(@{$self->workflows()}), ")\n" and exit if $from < 1;
        

        my $to = $self->to();
        $self->logDebug("to not defined") and exit if not $to;
        $self->logDebug("to out of range (1 - "), scalar(@{$self->workflows()}), ")\n" and exit if $to > scalar(@{$self->workflows()});
        $self->logDebug("to out of range (1 - "), scalar(@{$self->workflows()}), ")\n" and exit if $to < 1;

        #### RETURN IF 'FROM' IS 'TO'
        return 1 if $from == $to;

        #### OTHERWISE, MOVE APP
        my $workflow = splice @{$self->workflows()}, $from - 1, 1;
        print $workflow->wiki();
        splice @{$self->workflows}, $to - 1, 0, $workflow;
        $self->_numberWorkflows();
        
        $self->_write();
        
        return 1;
    }


    method deleteWorkflow () {
        #$self->logDebug("Project::deleteWorkflow(app)");
        #$self->logDebug("app:");
        #print Dumper $workflow;

        my $inputfile = $self->inputfile;
        #$self->logDebug("self", $self);
        #$self->logDebug("inputfile", $inputfile);

        $self->_loadFile();
        #print $self->toString(), "\n";

        my $ordinal = $self->ordinal();
        #$self->logDebug("ordinal", $ordinal) if defined $ordinal;

        my $workflow = Agua::CLI::Workflow->new(
            name    =>  $self->name(),
            ordinal =>  $self->ordinal()
        );
        $workflow->getopts();
#        $workflow->_loadFile();
        #$self->logDebug("app->toString()");
        #print $workflow->toString(), "\n";
        #$self->logDebug("app->ordinal(): "), $workflow->ordinal(), "\n";
    
        #my $ordinal = $workflow->ordinal();
        my $name;
        ($name, $ordinal) = $self->_deleteWorkflow($workflow);
        $name = "name unknown" if not defined $name;
        #if defined $workflow->ordinal() and $workflow->ordinal();
        #$self->_deleteWorkflow($workflow) if not defined $self->ordinal();
        #print $self->toJson(), "\n";

        $self->logDebug("Deleted app $ordinal", $name);

        $self->_write();
        
        return 1;
    }

    method _numberWorkflows {
        for ( my $counter = 0; $counter < scalar(@{$self->workflows()}); $counter++ )
        {
            my $workflow = ${$self->workflows()}[$counter];
            $workflow->ordinal($counter + 1);
        }
    }

    method _deleteWorkflow ($workflow) {
        #$self->logDebug("Project::_deleteWorkflow(app)");

        my $index;
        $index = $self->ordinal() - 1 if $self->ordinal()
            and $self->ordinal() !~ /^\s*$/;
        $index = $self->_appIndex($workflow) if not defined $index;
        $self->logDebug("app not found", $workflow)
            and exit if not defined $index;

        $self->logDebug("app not found", $workflow)
            and return 0 if not defined $index;

        $self->logDebug("zero-index '$index' falls after the end of the workflows array (length: "), scalar(@{$self->workflows}), ")\n" and exit if $index > scalar(@{$self->workflows}) - 1;
        my $name = @{$self->workflows}[$index]->name();

        splice @{$self->workflows}, $index, 1;

        #$self->_orderWorkflows();

        $self->_numberWorkflows();

        return $name, $index + 1;
    }

    method editWorkflow ($workflow) {
        #$self->logDebug("Project::editWorkflow(app)");
        #$self->logDebug("app:");
        #print Dumper $workflow;
        my $field = $self->field();
        $self->logDebug("field not defined")
            and exit if not defined $field;

        my $inputfile = $self->inputfile;
        #$self->logDebug("self", $self);
        #$self->logDebug("inputfile", $inputfile);

        $self->_loadFile();
        #print $self->toJson(), "\n";
        
        $self->_editWorkflow($workflow);
        #print $self->toJson(), "\n";

        #$self->_orderWorkflows();
        #print $self->toJson(), "\n";
        
        $self->_write();
    }

    method _editWorkflow ($workflow) {
        #$self->logDebug("Project::editWorkflow(app)");
        #$self->logDebug("app:");
        #print Dumper $workflow;

        $workflow->edit();
        #print $self->toJson(), "\n";

        $self->_write();
    }

    method desc () {
        $self->logDebug("Project::desc()");
        $self->_loadFile();
        
        print $self->toString() and exit if not defined $self->field();
        my $field = $self->field();
        print $self->toJson(), "\n";
        print "$field: " , $self->$field(), "\n";

        return 1;
    }

    method wiki () {
        #$self->logDebug("Project::wiki()");
        $self->_loadFile() if $self->wkfile();

        print $self->_wiki();

        return 1;
    }


    method _wiki () {
        #$self->logDebug("Project::_wiki()");
        my $wiki = '';
        $wiki .= "\nProject:\t" . $self->name() . "\n";
        $wiki .= "\t" . $self->status() if $self->status();
        $wiki .= "Started: " . $self->started() . "\n" if $self->started();
        $wiki .= "Stopped: " . $self->stopped() . "\n" if $self->stopped();
        $wiki .= "Duration: " . $self->duration() . "\n" if $self->duration();
        $wiki .= "Status: " . $self->status() . "\n" if $self->status();
        $wiki .= "\n" if $self->started();
        
        #### DO APPS
        my $workflows = $self->workflows();
        foreach my $workflow ( @$workflows )
        {
            $wiki .= $workflow->_wiki();
        }
        
        return $wiki;
    }



    method edit () {
        #$self->logDebug("Project::edit()");
        #$self->logDebug("self->toString():");
        #print $self->toString(), "\n";

        #### IN CASE workflow IS PART OF project
        $self->getopts();
        
        my $field = $self->field();
        my $value = $self->value();
        #$self->logDebug("field is not supported. Exiting") if not $self->field();
        #$self->logDebug("field: **$field**");
        #$self->logDebug("value: **$value**");

        $self->_loadFile() if defined $self->inputfile();
        
        my $present = 0;
        #$self->logDebug("field: **$field**");
        #$self->logDebug("value: **$value**");
        foreach my $currentfield ( @{$self->fields()} )
        {
            #$self->logDebug("currentfield: **$currentfield**");
            $present = 1 if $field eq $currentfield;
            last if $field eq $currentfield;
        }
        #$self->logDebug("present", $present);
        $self->logDebug("Agua::CLI::Project::edit    field $field not valid") and exit if not $present;

        $self->$field($value);
        #$self->logDebug("field $field: "), $self->$field(), "\n";
        
        #$self->logDebug("self:");
        #print Dumper $self;

        $self->outputfile($self->inputfile());
        $self->_write();
    }
    
    method create () {
        #$self->logDebug("Project::create()");
        my $inputfile = $self->inputfile;
        $self->logDebug("inputfile must end in '.wk'") and exit
            if not $inputfile =~ /\.wk$/;
        $self->logDebug("inputfile not defined") and exit
            if not defined $inputfile
            or not $inputfile;
        
        my $name = $self->name;
        $self->logDebug("Please supply 'name' argument") and exit if not $self->name();
        
        $self->_confirm("Outputfile already exists. Overwrite?") if -f $inputfile and not defined $self->force();

        $self->getopts();
        if ( not $self->name() )
        {
            my ($name) = $self->inputfile() =~ /([^\/^\\]+)\.wk/;
            $self->name($name);
        }
        
        $self->_write();        
   
        $self->logDebug("Created workflow ");
        $self->logDebug("self->name: '" . $self->name() . "'") if $self->name();
        $self->logDebug(": " . $self->inputfile() . "\n\n");
    }

    method copy () {
        #$self->logDebug("Project::copy()");
        $self->_loadFile();
        $self->name($self->newname());

        my $outputfile = $self->outputfile;
        $self->_confirm("Outputfile already exists. Overwrite?") if -f $outputfile and not defined $self->force();

        $self->_write();        
    }

    method _toExportHash ($fields) {
        #$self->logCaller("");
        #$self->logDebug("fields: @$fields");

        my $hash;
        foreach my $field ( @$fields )
        {
            next if ref($self->$field) eq "ARRAY";
            $hash->{$field} = $self->$field();
        }

        #### DO WORKFLOWS
        my $workflows = $self->workflows();
        my $workflowsdata = [];
        foreach my $workflow ( @$workflows )
        {
            push @$workflowsdata, $workflow->exportData();
        }
        #$self->logDebug("workflowsdata:");
        #print Dumper $workflowsdata;

        $hash->{workflows} = $workflowsdata;
        return $hash;
    }
    
    method toHash() {
        my $hash;
        #$self->logDebug("self->started(): "), $self->started(), "\n";
        foreach my $field ( @{$self->savefields()} )
        {
            #$self->logDebug("field '$field' value: "), $self->$field(), "\n";
            if ( ref($self->$field) ne "ARRAY" )
            {
                $hash->{$field} = $self->$field();
            }
        }

        #### DO WORKFLOWS
        #### DO WORKFLOWS
        my $workflows = $self->workflows();
        my $workflowsdata = [];
        foreach my $workflow ( @$workflows )
        {
            push @$workflowsdata, $workflow->exportData();
        }
        #$self->logDebug("workflowsdata:");
        #print Dumper $workflowsdata;

        $hash->{workflows} = $workflowsdata;
        return $hash;
    }
    
    method toJson() {
        my $hash = $self->toHash();
        my $jsonParser = JSON->new();
    	my $json = $jsonParser->pretty->indent->encode($hash);
        return $json;    
    }
    
    method exportData {
        return $self->_toExportHash($self->exportfields());
    }

    method _indentSecond ($first, $second, $indent) {
        $indent = $self->indent() if not defined $indent;
        my $spaces = " " x ($indent - length($first));
        return $first . $spaces . $second;
    }
        
    method _appIndex ($workflow) {
        #$self->logDebug("Project::_appIndex(app)");
        #$self->logDebug("app:");
        #print $workflow->toString();

        my $counter = 0;
        foreach my $currentname ( @{$self->workflows} )
        {
            if ( $workflow->name() eq $currentname->name() )
            {
                return $counter;
            }
            $counter++;
        }

        return;
    }
    
    method _write() {
        my $outputfile = $self->outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;
        $self->logDebug("outputfile", $outputfile);

        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/^\\]+$/;
        File::Path::mkpath($basedir) if defined $basedir and not -d $basedir;

        my $json = $self->toJson();        
        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$json\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method read () {
        $self->_loadFile();
    }
    
    method _loadFile () {
        $self->logDebug("");
        my $inputfile = $self->inputfile();
        $self->logDebug("inputfile not specified") and exit if not defined $inputfile;
        return if not -f $inputfile;
        
        #$self->logDebug("inputfile", $inputfile);
        $/ = undef;
        open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
        my $contents = <FILE>;
        close(FILE) or die "Can't close inputfile: $inputfile\n";
        $/ = "\n";
    
        my $jsonParser = JSON->new();
    	my $projectobject = $jsonParser->decode($contents);
        
        my $workflowdatas = $projectobject->{workflows};
        $self->logDebug("No. workflowdatas", scalar(@$workflowdatas));

        delete $projectobject->{workflows};
        $self->logDebug("projectobject", $projectobject);
        my $fields = $self->fields();
        foreach my $field ( @$fields )
        {
            if ( exists $projectobject->{$field} )
            {
                $self->$field($projectobject->{$field});
            }
        }

        my $workflows = [];
        foreach my $workflowdata ( @$workflowdatas )
        {
            my $appdatas = $workflowdata->{apps};
            delete $workflowdata->{apps};
            
            my $workflow = Agua::CLI::Workflow->new($workflowdata);
            my $apps = [];
            foreach my $appdata ( @$appdatas ) {
                my $paramdatas = $appdata->{parameters};
                delete $appdata->{parameters};
                $self->logDebug("appdata", $appdata);
                
                my $app = Agua::CLI::App->new($appdata);
                my $params = [];
                foreach my $paramdata ( @$paramdatas ) {
                    my $param = Agua::CLI::Parameter->new($paramdata);
                    push @$params, $param;
                }
                $app->parameters($params);
                
                push @$apps, $app;
            }

            $workflow->apps($apps);

            push @$workflows, $workflow;
        }   

        $self->logDebug("FINAL no. workflows", scalar(@$workflows));
        $self->workflows($workflows);
    }

    method getWorkflowFiles ($directory) {
        $self->logDebug("directory", $directory);
        sub by_number {
            
            my ($aa) = $a =~ /^(\d+)/; 
            my ($bb) = $b =~ /^(\d+)/; 
            return $aa <=> $bb;
        }

        #### LOAD WORKFLOWS
        my $workflowfiles = $self->getFiles($directory);
        for ( my $i = 0; $i < @$workflowfiles; $i++ ) {
            if ( $$workflowfiles[$i] !~ /\.work$/ ) {
                splice @$workflowfiles, $i, 1;
                $i--;
            }
        }

        $self->logDebug("BEFORE SORT workflowfiles", $workflowfiles);        
        $workflowfiles = $self->sortWorkflowFiles($workflowfiles);
        $self->logDebug("AFTER SORT workflowfiles", $workflowfiles);        

        return $workflowfiles;
    }
    
    method sortWorkflowFiles ($workflowfiles) {
        $self->logDebug("workflowfiles", $workflowfiles);        
        my $by_number  = sub {
            my ($aa) = $a =~ /^(\d+)/; 
            my ($bb) = $b =~ /^(\d+)/; 
            return $aa <=> $bb;
        };

        @$workflowfiles = sort $by_number @$workflowfiles;

        return $workflowfiles;        
    }
    
    method _loadDb () {
        $self->logDebug("Project::_loadDb()");

        my $dbtype = $self->dbtype();
        $self->logDebug("dbtype not defined. Exiting") and exit if not defined $dbtype;
        $self->db(
            DBaseFactory->new(
            $dbtype,
                {
                    DBFILE	    =>	$self->dbfile(),
                    DATABASE    =>	$self->database(),
                    USER        =>  $self->user(),
                    PASSWORD    =>  $self->password()
                }
            )
        );
        $self->logDebug("error: 'Cannot create $dbtype database object: $!' ") and exit if not defined $self->db();
        $self->logDebug("self->db: "), $self->db(), "\n";
        
    }

    method _confirm ($message){
	
        $message = "Please input Y to continue, N to quit" if not defined $message;
        $/ = "\n";
        print "$message\n";
        my $input = <STDIN>;
        while ( $input !~ /^Y$/i and $input !~ /^N$/i )
        {
            print "$message\n";
            $input = <STDIN>;
        }	
        if ( $input =~ /^N$/i )	{	exit;	}
        else {	return;	}
    }    

    method toString (){
        return $self->_toString();
        #$self->logDebug("$output");
    }

    method export($outputfile) {
        $self->logDebug("");
        #$self->logDebug("outputfile", $outputfile) if defined $outputfile;
        
        $outputfile = $self->outputfile if not defined $outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;

        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/^\\]+$/;
        File::Path::mkpath($basedir) if defined $basedir and not -d $basedir;

        my $export = $self->_toExport();        
        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$export\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method _toExport () {
        my $hash;
        foreach my $field ( @{$self->exportfields()} )
        {
            #$self->logDebug("field '$field' value: "), $self->$field(), "\n";
            if ( ref($self->$field) ne "ARRAY" )
            {
                $hash->{$field} = $self->$field();
            }
        }

        #### DO WORKFLOWS
        my $workflows = $self->workflows();
        my $workflowsdata = [];
        foreach my $workflow ( @$workflows )
        {
            push @$workflowsdata, $workflow->exportData();
        }
        #$self->logDebug("workflowsdata:");
        #print Dumper $workflowsdata;

        $hash->{workflows} = $workflowsdata;

        my $jsonParser = JSON->new();
    	my $json = $jsonParser->pretty->indent->encode($hash);
        return $json;    
    }

    method _toString () {
        my $json = $self->toJson() . "\n";
        my $output = "\n\nProject:\n";
        foreach my $field ( @{$self->savefields()} )
        {
            next if not defined $self->$field() or $self->$field() =~ /^\s*$/;
            $output .= $self->_indentSecond($field, $self->$field(), $self->indent()) . "\n";
        }
        #$output .= "\nWorkflows:\n";
        foreach my $workflow ( @{$self->workflows()} )
        {
            #print Dumper $workflow;
            $output .= "\t" . $workflow->toString() . "\n"; 
        }
        
        #$self->logDebug("output", $output);
        return $output;
    }
    
    method _orderWorkflows () {
    #### REDUNDANT: DEPRECATE LATER
        #$self->logDebug("Project::_orderWorkflows()");
    
        sub ordinalOrAbc (){
            #### ORDER BY ordinal IF PRESENT
            #my $aa = $a->ordinal();
            #my $bb = $b->ordinal();
            return $a->ordinal() <=> $b->ordinal()
                if defined $a->ordinal() and defined $b->ordinal()
                and $a->ordinal() and $b->ordinal();
                
            #### OTHERWISE BY ALPHABET
            #my $AA = $a->name();
            #my $BB = $b->name();
            #$self->logDebug("AA", $AA);
            #$self->logDebug("BB", $BB);
            return $a->name() cmp $b->name();
        }
    
        my $workflows = $self->workflows;
        @$workflows = sort ordinalOrAbc @$workflows;
        $self->workflows($workflows);
    }
    
    method getDirs ($directory) {
        my $dirs = $self->listFiles($directory);
        
        for ( my $i = 0; $i < @$dirs; $i++ ) {
            if ( $$dirs[$i] =~ /^\.+$/ ) {
                splice @$dirs, $i, 1;
                $i--;
            }
            my $filepath = "$directory/$$dirs[$i]";
            if ( not -d $filepath ) {
                splice @$dirs, $i, 1;
                $i--;
            }
        }
        
        return $dirs;	
    }

    method getFiles ($directory) {
        my $files = $self->listFiles($directory);
        
        for ( my $i = 0; $i < @$files; $i++ ) {
            if ( $$files[$i] =~ /^\.+$/ ) {
                splice @$files, $i, 1;
                $i--;
            }
            my $filepath = "$directory/$$files[$i]";
            if ( not -f $filepath ) {
                splice @$files, $i, 1;
                $i--;
            }
        }
        
        return $files;	
    }

    method listFiles ($directory) {
        opendir(DIR, $directory) or die "Can't open directory: $directory\n" and exit;
        my $files;
        @$files = readdir(DIR);
        closedir(DIR) or die "Can't close directory: $directory";
    
        return $files;
    }

    
}


