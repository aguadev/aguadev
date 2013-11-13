use MooseX::Declare;
use Getopt::Simple;

use FindBin qw($Bin);
use lib "$Bin/../..";

class Agua::CLI::Workflow with (Agua::CLI::Logger, Agua::CLI::Timer) {
    use File::Path;
    use JSON;
    use Data::Dumper;
    use Agua::CLI::App;

    #### LOGGER
    has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
    has 'SHOWLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	0 	);  
    has 'PRINTLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	0 	);

    #### STORED LOGISTICS VARIABLES
    has 'owner'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => 'anonymous' );
    has 'project'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'name'	    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'number'	=> ( isa => 'Int|Undef', is => 'rw', required	=>	0	);
    has 'type'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{User-defined application type} );
    has 'description'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'notes'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'ordinal'	=> ( isa => 'Str|Undef', is => 'rw', default => undef, required => 0, documentation => q{Set order of appearance: 1, 2, ..., N} );
    has 'apps'	    => ( isa => 'ArrayRef[Agua::CLI::App]', is => 'rw', default => sub { [] } );
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
    has 'fields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['project', 'name', 'number', 'owner', 'description', 'notes', 'outputdir', 'field', 'value', 'wkfile', 'outputfile', 'cmdfile', 'start', 'stop', 'ordinal', 'from', 'to', 'status', 'started', 'stopped', 'duration', 'epochqueued', 'epochstarted', 'epochstopped', 'epochduration'] } );
    has 'savefields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['project', 'name', 'number', 'owner', 'description', 'notes', 'status', 'started', 'stopped', 'duration', 'locked'] } );
    has 'exportfields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['project', 'name', 'number', 'owner', 'description', 'notes', 'status', 'started', 'stopped', 'duration', 'provenance'] } );
    has 'inputfile' => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'wkfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'cmdfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'appfile'   => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'logfile'   => ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputdir'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'dbfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'dbtype'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'database'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'user'      => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'password'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'force'     => ( isa => 'Maybe', is => 'rw', required => 0 );
    #has 'db'  => ( isa => 'DBase::SQLite|DBase::MySQL', is => 'rw' );
    has 'logfh'     => ( isa => 'FileHandle', is => 'rw', required => 0 );
    has 'start'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'stop'	=> ( isa => 'Str', is => 'rw', required => 0 );

####//}}    
    
    method BUILD ($hash) { 
        #$self->logDebug("Workflow::BUILD()");    
        #$self->logDebug("file", $file);    

        #print Dumper $self;
        $self->initialise();
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
        $self->logDebug("Workflow::run(app)");

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
        my $apps = $self->apps();
        $self->logDebug("No. apps: "). scalar(@$apps) . "\n";
        
        my $start = $self->start();
        $start = 1 if not defined $start or $start =~ /^\s*$/;
        my $stop = $self->stop();
        $stop = scalar(@$apps) if not defined $stop or $stop =~ /^\s*$/;
        $stop = scalar(@$apps) if $stop > scalar(@$apps);
        $self->logDebug("start", $start);
        $self->logDebug("stop", $stop);
        
        #### SET STARTED
        $self->setStarted();
        $self->logDebug("starting workflow ")  . $self->name()  . "': " . $self->started() . "'\n";
        
        for ( my $i = $start - 1; $i < $stop; $i++ )
        {
            my $app = $$apps[$i];
            $self->logDebug("Running app '") . $app->name() . "'\n";
            $app->logfh($self->logfh());
            $app->outputdir($self->outputdir());
            my ($status, $label) = $app->run();
            #$self->logDebug("Agua::CLI::Workflow::run    completed", $status);
            #$self->logDebug("Agua::CLI::Workflow::run    label", $label) if defined $label;

            $self->logDebug("Application may not have completed successfully.\n\nApplication status: $status.\n\nPlease check the logfile", $logfile) if not $status or $status ne "completed";
            
            $self->logDebug("\nApplication status", $status)
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
        #$self->logDebug("App::loadCmd()");
        
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
            require Agua::CLI::App;
            my $app = Agua::CLI::App->new();
            $app->getopts();
            $app->_loadCmd($command);
            #$self->logDebug("app:");
            #print $app->toString(), "\n";
            $self->_addApp($app);
        }
        
        $self->_write();
        
        return 1;
    }

    method app() {
        #$self->logDebug("App::app()");
        $self->_loadFile() if $self->wkfile();
    
        require Agua::CLI::App;
        my $app = Agua::CLI::App->new();
        $app->getopts();
        #$self->logDebug("app:");
        #print $app->toString(), "\n";
        
        $self->logDebug("Please provide '--name' or '--ordinal' argument for app\n") and exit if not $app->name() and not $app->ordinal();

        #### GET THE PARAM FROM apps
        my $index;
        $index = $app->ordinal() - 1 if $app->ordinal();
        $index = $self->_appIndex($app) if not $app->ordinal();
        $self->logDebug("Can't find app among workflow's apps:"), $app->toString(), "\n\n" and exit if not defined $index;
        #$self->logDebug("index", $index);

        my $application = ${$self->apps()}[$index];
        $self->logDebug("Can't find app number ") . $index + 1 . "\n" and exit if not defined $application;
        #$self->logDebug("BEFORE getopts application:");
        #print $application->toString(), "\n";

        $application->getopts();
        #$self->logDebug("AFTER getopts application:");
        #print $application->toString(), "\n";

        my $command = shift @ARGV;
        #$self->logDebug("command", $command);

        my $return = $application->$command();

        $self->_write() if $self->inputfile();
        
        return $return;
    }

    method replace () {
        $self->logDebug("Agua::CLI::Workflow::replace()");
        
        $self->_loadFile() if defined $self->appfile() and $self->appfile();
        
        #$self->logDebug("BEFORE self->toString() :");
        #print $self->toString();

        #### DO PARAMETERS
        my $apps = $self->apps();
        my $params = [];
        foreach my $parameter ( @$apps )
        {
            $parameter->getopts();
            $parameter->replace();
        }
        #$self->logDebug("AFTER self->toString() :");
        #print $self->toString() ;

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
    }

    method loadApp ($app) {
        $self->logDebug("");        
        $self->_addApp($app);
        my $name = $app->name();
        $name = "unknown" if not defined $name;

        $self->_write();

        my $ordinal = $app->ordinal();
        $self->logDebug("Added app $ordinal: '$name'");
        
        return 1;
    }

    method addApp () {
        #$self->logDebug("Workflow::addApp()");
        
        #$self->initialise();
        
        #$self->logDebug("self:");
        #print $self->toString(), "\n";

        #$self->logDebug("No 'inputfile' (inputfile of app) argument") and exit if not defined $app->inputfile();
        #$self->logDebug("'inputfile' (inputfile of app) argument has no value") and exit if not $app->inputfile();

        my $inputfile = $self->inputfile();
        #$self->logDebug("inputfile", $inputfile);
        $self->_loadFile();
        #$self->logDebug("self->toString()");
        #print $self->toString(), "\n";

        my $appfile = $self->appfile();
        $self->logDebug("appfile not defined. Exiting") if not defined $appfile and not $appfile;
        #$self->logDebug("appfile", $appfile);
        my $app = Agua::CLI::App->new(
            appfile =>  $appfile
        );
        $app->getopts();
        $app->_loadFile();

        $self->_addApp($app);
        my $name = $app->name();
        $name = "unknown" if not defined $name;

        $self->_write();

        my $ordinal = $app->ordinal();
        $self->logDebug("Added app $ordinal: '$name'");
        
        return 1;
    }

    method _addApp ($app) {
        #$self->logDebug("Workflow::_addApp()");
    
        return $self->_insertApp($app, $app->ordinal() - 1)
            if $app->ordinal();
        
        #### INCREMENT ORDINAL AND SET ON THIS APP
        $app->ordinal(scalar(@{$self->apps()} + 1));
        
        push @{$self->apps()}, $app;

        $self->_numberApps();

        return scalar(@{$self->apps()});
    }

    method _insertApp ($app, $index) {
        #$self->logDebug("Workflow::_insertApp(app)");
        #$self->logDebug("app->toString(): "), $app->toString(), "\n";
        #$self->logDebug("index", $index);

        splice @{$self->apps}, $index, 0, $app;
        
        $self->_numberApps();
        
        return $index;
    }

    method moveApp () {
        $self->logDebug("Workflow::moveApp(app)");

        $self->_loadFile();

        my $from = $self->from();
        $self->logDebug("from not defined") and exit if not $from;
        $self->logDebug("from out of range (1 - "), scalar(@{$self->apps()}), ")\n" and exit if $from > scalar(@{$self->apps()});
        $self->logDebug("from out of range (1 - "), scalar(@{$self->apps()}), ")\n" and exit if $from < 1;
        

        my $to = $self->to();
        $self->logDebug("to not defined") and exit if not $to;
        $self->logDebug("to out of range (1 - "), scalar(@{$self->apps()}), ")\n" and exit if $to > scalar(@{$self->apps()});
        $self->logDebug("to out of range (1 - "), scalar(@{$self->apps()}), ")\n" and exit if $to < 1;

        #### RETURN IF 'FROM' IS 'TO'
        return 1 if $from == $to;

        #### OTHERWISE, MOVE APP
        my $app = splice @{$self->apps()}, $from - 1, 1;
        print $app->wiki();
        splice @{$self->apps}, $to - 1, 0, $app;
        $self->_numberApps();
        
        $self->_write();
        
        return 1;
    }


    method deleteApp () {
        #$self->logDebug("Workflow::deleteApp(app)");
        #$self->logDebug("app:");
        #print Dumper $app;

        my $inputfile = $self->inputfile;
        #$self->logDebug("self", $self);
        #$self->logDebug("inputfile", $inputfile);

        $self->_loadFile();
        #print $self->toString(), "\n";

        my $ordinal = $self->ordinal();
        #$self->logDebug("ordinal", $ordinal) if defined $ordinal;

        my $app = Agua::CLI::App->new(
            name    =>  $self->name(),
            ordinal =>  $self->ordinal()
        );
        $app->getopts();
#        $app->_loadFile();
        #$self->logDebug("app->toString()");
        #print $app->toString(), "\n";
        #$self->logDebug("app->ordinal(): "), $app->ordinal(), "\n";
    
        #my $ordinal = $app->ordinal();
        my $name;
        ($name, $ordinal) = $self->_deleteApp($app);
        $name = "name unknown" if not defined $name;
        #if defined $app->ordinal() and $app->ordinal();
        #$self->_deleteApp($app) if not defined $self->ordinal();
        #print $self->toJson(), "\n";

        $self->logDebug("Deleted app $ordinal", $name);

        $self->_write();
        
        return 1;
    }

    method _numberApps {
        for ( my $counter = 0; $counter < scalar(@{$self->apps()}); $counter++ )
        {
            my $app = ${$self->apps()}[$counter];
            $app->ordinal($counter + 1);
        }
    }

    method _deleteApp ($app) {
        #$self->logDebug("Workflow::_deleteApp(app)");

        my $index;
        $index = $self->ordinal() - 1 if $self->ordinal()
            and $self->ordinal() !~ /^\s*$/;
        $index = $self->_appIndex($app) if not defined $index;
        $self->logDebug("app not found", $app)
            and exit if not defined $index;

        $self->logDebug("app not found", $app)
            and return 0 if not defined $index;

        $self->logDebug("zero-index '$index' falls after the end of the apps array (length: "), scalar(@{$self->apps}), ")\n" and exit if $index > scalar(@{$self->apps}) - 1;
        my $name = @{$self->apps}[$index]->name();

        splice @{$self->apps}, $index, 1;

        #$self->_orderApps();

        $self->_numberApps();

        return $name, $index + 1;
    }

    method editApp ($app) {
        #$self->logDebug("Workflow::editApp(app)");
        #$self->logDebug("app:");
        #print Dumper $app;
        my $field = $self->field();
        $self->logDebug("field not defined")
            and exit if not defined $field;

        my $inputfile = $self->inputfile;
        #$self->logDebug("self", $self);
        #$self->logDebug("inputfile", $inputfile);

        $self->_loadFile();
        #print $self->toJson(), "\n";
        
        $self->_editApp($app);
        #print $self->toJson(), "\n";

        #$self->_orderApps();
        #print $self->toJson(), "\n";
        
        $self->_write();
    }

    method _editApp ($app) {
        #$self->logDebug("Workflow::editApp(app)");
        #$self->logDebug("app:");
        #print Dumper $app;

        $app->edit();
        #print $self->toJson(), "\n";

        $self->_write();
    }

    method desc () {
        $self->logDebug("Workflow::desc()");
        $self->_loadFile();
        
        print $self->toString() and exit if not defined $self->field();
        my $field = $self->field();
        print $self->toJson(), "\n";
        print "$field: " , $self->$field(), "\n";

        return 1;
    }

    method wiki () {
        #$self->logDebug("Workflow::wiki()");
        $self->_loadFile() if $self->wkfile();

        print $self->_wiki();

        return 1;
    }


    method _wiki () {
        #$self->logDebug("Workflow::_wiki()");
        my $wiki = '';
        $wiki .= "\nWorkflow:\t" . $self->name() . "\n";
        $wiki .= "\t" . $self->status() if $self->status();
        $wiki .= "Started: " . $self->started() . "\n" if $self->started();
        $wiki .= "Stopped: " . $self->stopped() . "\n" if $self->stopped();
        $wiki .= "Duration: " . $self->duration() . "\n" if $self->duration();
        $wiki .= "Status: " . $self->status() . "\n" if $self->status();
        $wiki .= "\n" if $self->started();
        
        #### DO APPS
        my $apps = $self->apps();
        foreach my $app ( @$apps )
        {
            $wiki .= $app->_wiki();
        }
        
        return $wiki;
    }



    method initialise () {
        #$self->logDebug("Agua::CLI::Workflow::initialise()");

        $self->owner("anonymous") if not defined $self->owner();
        $self->inputfile($self->wkfile()) if defined $self->wkfile() and $self->wkfile();
        #$self->logDebug("self->wkfile: "), $self->wkfile(), "\n";
        #$self->logDebug("self->inputfile: "), $self->inputfile(), "\n";
        
        $self->logDebug("inputfile must end in '.wk' or '.work'") and exit
            if defined $self->inputfile()
            and $self->inputfile()
            and not $self->inputfile() =~ /\.wk$/
            and not $self->inputfile() =~ /\.work$/;

        $self->logDebug("outputfile must end in '.wk'") and exit
            if defined $self->outputfile()
            and $self->outputfile()
            and not $self->outputfile() =~ /\.wk$/
            and not $self->outputfile() =~ /\.work$/;
    }

    method getopts () {
        #$self->logDebug("Agua::CLI::Workflow::getopts()");
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

    method edit () {
        #$self->logDebug("Workflow::edit()");
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
        $self->logDebug("Agua::CLI::Workflow::edit    field $field not valid") and exit if not $present;

        $self->$field($value);
        #$self->logDebug("field $field: "), $self->$field(), "\n";
        
        #$self->logDebug("self:");
        #print Dumper $self;

        $self->outputfile($self->inputfile());
        $self->_write();
    }
    
    method create () {
        #$self->logDebug("Workflow::create()");
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
        #$self->logDebug("Workflow::copy()");
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
            #$self->logDebug("field", $field);
            next if ref($self->$field) eq "ARRAY";
            $hash->{$field} = $self->$field();
        }

        #### DO PARAMETERS
        my $apps = $self->apps();
        my $applications = [];
        foreach my $app ( @$apps )
        {
            push @$applications, $app->exportData();
        }
        #$self->logDebug("apps:");
        #print Dumper $apps;

        $hash->{apps} = $applications;
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

        #### DO APPS
        my $apps = $self->apps();
        my $applications = [];
        foreach my $app ( @$apps )
        {
            push @$applications, $app->exportData();
        }
        #$self->logDebug("apps:");
        #print Dumper $apps;

        $hash->{apps} = $applications;
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
        
    method _appIndex ($app) {
        #$self->logDebug("Workflow::_appIndex(app)");
        #$self->logDebug("app:");
        #print $app->toString();

        my $counter = 0;
        foreach my $currentname ( @{$self->apps} )
        {
            if ( $app->name() eq $currentname->name() )
            {
                return $counter;
            }
            $counter++;
        }

        return;
    }
    method _write($outputfile) {
        $self->logDebug("Agua::CLI::Workflow::_write(outputfile)");
        #$self->logDebug("outputfile", $outputfile) if defined $outputfile;
        
        $outputfile = $self->outputfile if not defined $outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;

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
        #$self->logDebug("Workflow::_loadFile()");

        my $inputfile = $self->inputfile();
        $self->logDebug("inputfile not specified") and exit if not defined $inputfile;
        $self->logDebug("Can't find inputfile", $inputfile) and exit if not -f $inputfile;
        
        #$self->logDebug("inputfile", $inputfile);
        $/ = undef;
        open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
        my $contents = <FILE>;
        close(FILE) or die "Can't close inputfile: $inputfile\n";
        $/ = "\n";
    
        my $jsonParser = JSON->new();
    	my $object = $jsonParser->decode($contents);

        #$self->logDebug("object:");
        #print Dumper $object;
        #exit;

        my $fields = $self->fields();
        foreach my $field ( @$fields )
        {
            if ( exists $object->{$field} )
            {
                $self->$field($object->{$field});
            }
        }

        #### CREATE APPS
        my $apps = [];
        foreach my $appHash ( @{$object->{apps}} )
        {
            #$self->logDebug("appHash:");
            #print Dumper $appHash;

            my $application = Agua::CLI::App->new();
            $application->fromHash($appHash);
            push @$apps, $application;
        }   
        #$self->logDebug("apps:");
        #print Dumper $apps;

        $self->apps($apps);
        
        $self->initialise();
    }

    method _loadDb () {
        $self->logDebug("Workflow::_loadDb()");

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
        
        $self->logDebug("Printing to outputfile: $outputfile");
        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$export\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method _toExport () {
        my $hash = $self->exportData();
        #foreach my $field ( @{$self->exportfields()} )
        #{
        #    #$self->logDebug("field '$field' value: "), $self->$field(), "\n";
        #    if ( ref($self->$field) ne "ARRAY" )
        #    {
        #        $hash->{$field} = $self->$field();
        #    }
        #}

        #### DO PARAMETERS
        my $apps = $self->apps();
        my $applications = [];
        foreach my $app ( @$apps )
        {
            push @$applications, $app->exportData();
        }
        #$self->logDebug("apps:");
        #print Dumper $apps;

        $hash->{apps} = $applications;

        my $jsonParser = JSON->new();
    	my $json = $jsonParser->pretty->indent->encode($hash);
        return $json;    
    }

    method _toString () {
        my $json = $self->toJson() . "\n";
        my $output = "\n\nWorkflow:\n";
        foreach my $field ( @{$self->savefields()} )
        {
            next if not defined $self->$field() or $self->$field() =~ /^\s*$/;
            $output .= $self->_indentSecond($field, $self->$field(), $self->indent()) . "\n";
        }
        #$output .= "\nApps:\n";
        foreach my $app ( @{$self->apps()} )
        {
            #print Dumper $app;
            $output .= "\t" . $app->toString() . "\n"; 
        }
        
        #$self->logDebug("output", $output);
        return $output;
    }
    
    method _orderApps () {
    #### REDUNDANT: DEPRECATE LATER
        #$self->logDebug("Workflow::_orderApps()");
    
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
    
        my $apps = $self->apps;
        @$apps = sort ordinalOrAbc @$apps;
        $self->apps($apps);
    }
}


