use MooseX::Declare;
use Agua::CLI::Timer;
use Agua::CLI::Logger;
use Agua::CLI::Status;

class Agua::CLI::App with (Agua::CLI::Logger, Agua::CLI::Timer, Agua::CLI::Status) {
    use File::Path;
    use JSON;
    use Data::Dumper;
    use Agua::CLI::Parameter;

    #### PRE-DECLARE CLASS TYPES
    #subtype Agua::CLI::Parameter => as Object => where { $_->isa('Agua::CLI::Parameter') };
    #subtype 'Agua::CLI::Parameter' => as 'Agua::CLI::Parameter' => where {} => message {'here'};
    #enum 'RGB' => qw( red green blue );
    
    #### LOGGER
    has 'logfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);
    has 'SHOWLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	4 	);  
    has 'PRINTLOG'	=> ( isa => 'Int', is => 'rw', default 	=> 	5 	);

    ##### STORED VARIABLES
    has 'localonly'	=> ( isa => 'Bool|Undef', is => 'rw', default    => 0, documentation => q{Set to 1 if application should only be run locally, i.e., not executed on the cluster} );

    has 'owner'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => 'anonymous', documentation => q{Owner of this object} );
    has 'package'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'version'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'installdir'=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'name'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{Name of this object} );
    has 'type'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{User-defined application type} );
    has 'url'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{URL of application website} );
    has 'location'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'executor'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'description'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'notes'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'submit'	=> ( isa => 'Maybe', is => 'rw', default => undef );
    has 'parameters'=> ( isa => 'ArrayRef[Agua::CLI::Parameter]', is => 'rw', default => sub { [] } );
    has 'ordinal'	=> ( isa => 'Int|Undef', is => 'rw', default => undef, required => 0, documentation => q{Set order of appearance: 1, 2, ..., N} );
    has 'scrapefile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
    has 'stdoutfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
    has 'stderrfile'	=> ( isa => 'Str|Undef', is => 'rw', default => undef );
    
    #### STORED STATUS VARIABLES
    has 'status'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'locked'	    => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'queued'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'started'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'completed'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'duration'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'epochqueued'	=> ( isa => 'Maybe', is => 'rw', default => 0 );
    has 'epochstarted'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'epochstopped'  => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'epochduration'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'stagepid'	    => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'stagejobid'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'workflowpid'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );

    #### CONSTANTS
    has 'indent'    => ( isa => 'Int', is => 'ro', default => 15);
    
    #### TRANSIENT VARIABLES
    #has 'args'	    => ( isa => 'ArrayRef[Str|Int]', is => 'rw', required => 0 );
    has 'newname'	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'paramname'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'field'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'value'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'fields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['name', 'owner', 'package', 'version', 'installdir', 'type', 'location', 'executor', 'description', 'notes', 'url', 'ordinal', 'status', 'submit', 'appfile', 'field', 'value', 'cmdfile', 'inputfile', 'outputfile', 'paramname', 'scrapefile', 'stdoutfile', 'stderrfile', 'queued', 'started', 'completed', 'duration', 'stagepid', 'stagejobid', 'workflowpid'] } );
    has 'savefields'    => ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { ['name', 'owner', 'package', 'version', 'installdir', 'ordinal', 'status', 'queued', 'started', 'completed', 'duration', 'locked', 'type', 'location', 'executor', 'description', 'notes', 'submit', 'url', 'localonly', 'stdoutfile', 'stderrfile', 'stagepid', 'stagejobid', 'workflowpid'] } );
    has 'exportfields'    => ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { ['name', 'owner', 'package', 'version', 'installdir', 'ordinal', 'status', 'type', 'location', 'executor', 'description', 'notes', 'url', 'localonly', 'stdoutfile', 'stderrfile', 'queued', 'started', 'completed', 'duration', 'stagepid', 'stagejobid', 'workflowpid'] } );
    has 'appfields'    => ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { ['name', 'owner', 'package', 'version', 'installdir', 'ordinal', 'type', 'location', 'executor', 'description', 'notes', 'url', 'localonly'] } );
    has 'inputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'appfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'cmdfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputdir'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'dbfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'dbtype'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'database'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'user'      => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'password'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'force'     => ( isa => 'Maybe', is => 'rw', required => 0 );
    has 'logfh'     => ( isa => 'FileHandle', is => 'rw', required => 0 );
    
####//}}

    method BUILD ($hash) { 
        $self->initialise();
    }

    method initialise () {
        $self->owner("anonymous") if not defined $self->owner();
        $self->inputfile($self->appfile()) if defined $self->appfile() and $self->appfile();
        $self->logDebug("inputfile must end in '.app'") and exit
            if defined $self->inputfile()
            and $self->inputfile()
            and not $self->inputfile() =~ /\.app$/;

        $self->logDebug("outputfile must end in '.app'") and exit
            if defined $self->outputfile()
            and $self->outputfile()
            and not $self->outputfile() =~ /\.app$/;
        
        #### SET DEFAULT DESCRIPTION AND NOTES (MYSQL 'TEXT' FIELDS)
        #$self->logDebug("self->description", $self->description());
        #$self->logDebug("self->notes", $self->notes());
        $self->description('') if not defined $self->description();
        $self->notes('') if not defined $self->notes();

    }

    method getopts () {
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
        
        #$self->logDebug("self->location(): "), $self->location(), "\n" if defined $self->location();
        
        foreach my $key ( keys %$switch )
        {
            #$self->logDebug("key", $key);
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
        $self->locked(1);
        $self->logDebug("Locked application '"), $self->name(), "'\n";
        #$self->logDebug("self->locked: "), $self->locked(), "\n";
    }

    method unlock {
        $self->locked(0);
        $self->logDebug("Unlocked application '"), $self->name(), "'\n";
        #$self->logDebug("self->locked: "), $self->locked(), "\n";
    }

    method run() {
        #$self->logDebug("App::run(app)");
        $self->logDebug("No location for app. Exiting") if not $self->location();
        
#        $self->logDebug("Application "), $self->ordinal(), " is locked: ", $self->name(), "\n"              if $self->locked();
        return "locked" if $self->locked();
        
        #### WRITE BKP FILE
        my $bkpfile = '';
        $bkpfile .= $self->outputdir() . "/" if $self->outputdir();
        $bkpfile .= $self->ordinal() . "-" . $self->name() . ".app.bkp";
        $self->outputfile($bkpfile);
        $self->_write();

        my $command = $self->_command();
        $self->logDebug("Running application "). $self->ordinal(). ": " . $self->name() . "\n\n";
        $self->logDebug("$command\n");        

        #### LOG COMMAND
        my $section = "[app " . $self->ordinal() . " " . $self->name() . "]\n";
        $self->logDebug($section);
        $self->logDebug();
        $self->logDebug($self->toString() . "\n");
        $self->logDebug("Command:\n\n" . $command . "\n\n\n");

        #### SET STARTED
        $self->setStarted();
        $self->logDebug("started application '"). $self->name() . "': " . $self->started(). "\n";
        #$self->logDebug("wiki:");
        #$self->wiki();

        #### RUN COMMAND
        my $output = `$command`;
        $self->logDebug("output", $output);
        
        #### LOG OUTPUT
        $self->logDebug("Output:\n\n" . $output);
        $self->logDebug("\n\n");

        #### COLLECT APPLICATION COMPLETION SIGNAL
        my $label = '';
        my $status = 'unknown';
        my $sublabels = '';
        my $message = '';
        
        if ( $output =~ /---\[status\s+(\S+):\s+(\S+)\s*(\S*)\]/ms )
        {
            $label = $1;
            $status = $2;
            $sublabels = $3;
            $message = "Job label '$label' completion status: $status";
            $message .= " $sublabels" if defined $sublabels and $sublabels;
            $message .= "\n\n";
            $self->logDebug($message);
        }

        #### SET STATUS
        $self->status($status) if defined $status;
        $self->status("unknown") if not defined $status;
        
        #### SET completed
        $self->setcompleted();
        
        #### SET DURATION
        $self->setDuration();

        $self->logDebug("wiki:");
        $self->wiki();
    
        $self->logDebug("#FINISHED '") . $self->name() . "': " . $self->completed() . ", duration: " . $self->duration() . "\n";
    
        return $self->status();
    }

    method command () {
        print $self->_command(), "\n";
    }
    
    method _command () {
        #### GENERATE RUN COMMAND
        $self->_orderParams();
        my $command = '';
        $command .= $self->executor() . "\\\n" if $self->executor;
        $command .= $self->location() . " \\\n";
        foreach my $parameter ( @{$self->parameters()} )
        {
            next if not defined $parameter->argument() or not $parameter->argument();
            $command .= " " . $parameter->argument() if $parameter->argument();
            $command .= " " . $parameter->value() if $parameter->value();
            $command .= " \\\n";
        }
        $command =~ s/\\\s*$//;
        
        return $command;
    }
    
    method param() {
        $self->logDebug("App::param()");
        $self->_loadFile() if $self->appfile();

        require Agua::CLI::Parameter;
        my $param = Agua::CLI::Parameter->new();
        $param->getopts();
        #$self->logDebug("param:");
        #print $param->toString(), "\n";
        
        #### GET THE PARAM FROM params
        my $index = $self->_paramIndex($param);
        $self->logDebug("Can't find parameter among workflow's parameters:"), $param->toString(), "\n\n" and exit if not defined $index;
        #$self->logDebug("index", $index);
        
        my $parameter = ${$self->parameters()}[$index];       
        $parameter->getopts();
        #$self->logDebug("parameter:");
        #print $parameter->toString(), "\n";

        my $command = shift @ARGV;
        #$self->logDebug("command", $command);

        $parameter->$command();
        #$self->logDebug("parameter:");
        #print $parameter->toString(), "\n";

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
        
        return 1;
    }

    method replace () {
        $self->logDebug("Agua::CLI::App::replace()");
        
        $self->_loadFile() if defined $self->appfile() and $self->appfile();
        
        $self->logDebug("BEFORE self->toString() :");
        print $self->toString();

        #### DO PARAMETERS
        my $parameters = $self->parameters();
        my $params = [];
        foreach my $parameter ( @$parameters )
        {
            $parameter->getopts();
            $parameter->replace();
        }

        $self->logDebug("AFTER self->toString() :");
        print $self->toString() ;

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
        
        return 1;
    }

    method loadCmd () {
        $self->logDebug("App::loadCmd()");

        $self->logDebug("self:");
        print $self->toString(), "\n";

        my $cmdfile = $self->cmdfile();
        open(FILE, $cmdfile) or die "Can't open cmdfile: $cmdfile\n";
        $/ = undef;
        my $content = <FILE>;
        close(FILE) or die "Can't close cmdfile: $cmdfile\n";
        $/ = "\n";
        $content =~ s/,\\\n/,/gms;
        
        $self->_loadCmd($content);
    }
    
    method _loadCmd ($content) {
        #$self->logDebug("App::_loadCmd()");

        my @lines = split "\n", $content;
        #$self->logDebug("lines: @lines");
        
        my $location = shift @lines;
        #$self->logDebug("location", $location);
        #$location =~ s/\s*\\s*$//;
        $location =~ s/^\s+//;
        $location =~ s/\s+$//;
        $location =~ s/\\$//;
        
        $self->location($location);
#$self->logDebug("location", $location);

        $self->logDebug("location is empty. Exiting")
            and exit if not $self->location();
        if ( not $self->name() )
        {
            my ($name) = $location =~ /([^\/^\\]+)$/;
            $self->name($name);
        }
        $self->logDebug("name is empty. Exiting")
            and exit if not $self->name();

        my $ordinal = scalar(@{$self->parameters()}) + 1;
        foreach my $line ( @lines )
        {
            next if $line =~ /^#/ or $line =~ /^>/
                or $line =~ /^rem/ or $line =~ /^\s*$/;
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            $line =~ s/\\$//;
    
            my ($argument, $value) = $line =~ /^(\S+)\s*(.*)$/;
            my $param = $argument;
            $param =~ s/^\-+// if $param;
            #$self->logDebug("param", $param);
            #$self->logDebug("value", $value);

            my $parameter = Agua::CLI::Parameter->new(
                param   =>  $param,
                argument   =>  $argument,
                value   =>  $value,
                ordinal =>  $ordinal
            );
            
            $self->_addParam($parameter);
            
            $ordinal++;
        }
        $self->_orderParams();

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
        
        return 1;
    }
    method loadScrape () {
        #### CONVERT SCRAPE OF '--help' OUTPUT OF APPLICATION TO PARAMS LIST
        my $scrapefile = $self->scrapefile();
        #$self->logDebug("scrapefile", $scrapefile);

        open(FILE, $scrapefile) or die "Can't open scrapefile: $scrapefile\n";
        $/ = undef;
        my $content = <FILE>;
        close(FILE) or die "Can't close scrapefile: $scrapefile\n";
        $/ = "\n";
        $content =~ s/,\\\n/,/gms;
        
        $self->_loadScrape($content);
    }
    
    method _loadScrape ($content) {
        #$self->logDebug("App::_loadScrape(content)");
        #$self->logDebug("content", $content);

        my @lines = split "\n", $content;
        my ($argument, $long, $value);
        my $ordinal = 1;
        foreach my $line ( @lines )
        {
            next if $line =~ /^#/ or $line =~ /^>/
                or $line =~ /^rem/ or $line =~ /^\s*$/;
            $line =~ s/\s+$//;
            $line =~ s/\\$//;
            #$self->logDebug("line", $line);
    
            $line =~ s/://g;
            if ( $line =~ /^\s*(\-{1,2}\S+)\s+(\-{2}\S+\s+)?(.+)$/ ) {

                if ( defined $argument ) {
                    $argument = $long if defined $long;
                    my $param = $argument;
                    $param =~ s/^\-+// if $param;
                    #$self->logDebug("param", $param);
                    #$self->logDebug("value", $value);
                    
                    my $parameter = Agua::CLI::Parameter->new(
                        param   =>  $param,
                        argument =>  $argument,
                        value   =>  $value,
                        ordinal =>  $ordinal
                    );
                    
                    $self->_addParam($parameter);
                    
                    $ordinal++;
                }

                #$self->logDebug("argument", $argument) if defined $argument;
                #$self->logDebug("long", $long) if defined $long;
                #$self->logDebug("value", $value) if defined $value;

                $argument   =   $1;
                $long       =   $2;
                $value      =   $3;
                $value =~ s/^\s+// if defined $value;
                $value =~ s/\s+$// if defined $value;
                $long =~ s/\s+$// if defined $long;
            }
            else
            {
                $line =~ s/^\s+//g;
                $line =~ s/\s+$//g;
                $value .= " $line";
            }
        }

        $self->_orderParams();

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
        
        return 1;
    }

    method descParam ($parameter) {
        $self->logDebug("App::desc()");
        $self->_loadFile();
        
        my $output = "\n";
        my $parameters = $self->parameters();
        foreach my $parameter ( @$parameters )
        {
            $output .= $parameter->_toString() . "\n";
        }
        $self->logDebug("$output");
    }


    method loadParam ($args) {
        use Agua::CLI::Parameter;
        my $parameter = Agua::CLI::Parameter->new($args);
        #$self->logDebug("self", $self) if $args->{name} eq "filename";
  

        $self->_addParam($parameter);
        $self->_orderParams();
        #$self->logDebug("self", $self);
        
        $self->_write() if $self->appfile();
    }
    
    method addParam () {
        $self->logDebug("App::addParam()");

        use Agua::CLI::Parameter;
        my $parameter = Agua::CLI::Parameter->new();
        $parameter->getopts();
        $parameter->_loadFile if $parameter->paramfile();
        
        my $inputfile = $self->inputfile();
        #$self->logDebug("self", $self);
        #$self->logDebug("inputfile", $inputfile);

        $self->_loadFile() if $self->appfile();
        #print $self->toJson(), "\n";
        
        $self->_deleteParam($parameter);
        #print $self->toJson(), "\n";

        $self->_addParam($parameter);
        print $self->toString(), "\n";

        $self->_orderParams();
        #print $self->toJson(), "\n";
        
        $self->_write() if $self->appfile();
    }

    method _addParam ($parameter) {
        #$self->logDebug("parameter", $parameter);
        #$self->logDebug("self:");
        #print $self->toString(), "\n";

        #$self->logDebug("parameters:");
        #foreach my $parameter ( @{$self->parameters()} )
        #{
        #    print $parameter->toString(), "\n";
        #}

        push @{$self->parameters()}, $parameter;
    }

    method deleteParam () {
        $self->logDebug("App::deleteParam()");
        
        my $inputfile = $self->inputfile;

        $self->_loadFile() if $self->appfile();
        
        my $parameter = Agua::CLI::Parameter->new(
            param       =>  $self->paramname(),
            ordinal     =>  $self->ordinal()
        );
        
        $self->_deleteParam($parameter);

        $self->_write() if $self->appfile();
    }

    method _deleteParam ($parameter) {
        $self->logDebug("App::_deleteParam(parameter)");

        my $index;
        $index = $self->ordinal() - 1 if $self->ordinal()
            and $self->ordinal() !~ /^\s*$/;
        $index = $self->_paramIndex($parameter) if not defined $index;
        $self->logDebug("index", $index) if defined $index;

        return if not defined $index;
        
        splice @{$self->parameters}, $index, 1;

        $self->_orderParams();
    }

    method editParam ($parameter) {
        $self->logDebug("App::editParam(parameter)");
        
        $self->logDebug("parameter name (--param) not defined")
            and exit if not $parameter->param();

        $self->logDebug("parameter->param(): "). $parameter->param(). "\n";
        $self->logDebug("parameter->field(): "). $parameter->field(). "\n";
        $self->logDebug("parameter->value(): "). $parameter->value(). "\n";
        print $parameter->toString();

        my $inputfile = $self->inputfile;
        $self->logDebug("inputfile", $inputfile);

        $self->_loadFile();
        print $self->toJson(), "\n";
        
        my $index = $self->_paramIndex($parameter);
        $self->logDebug("index", $index);

        $self->_editParam(${$self->parameters()}[$index], $parameter->field(), $parameter->value());
        #print $self->toJson(), "\n";

        $self->_orderParams();
        #print $self->toJson(), "\n";
        
        $self->logDebug("Doing self->_write()");
        $self->_write();
    }

    method _editParam ($parameter, $field, $value) {

        $self->logDebug("(parameter, field, value)");
        $self->logDebug("field", $field);
        $self->logDebug("value", $value);
        $self->logDebug("BEFORE parameter->toString()");
        print $parameter->toString(), "\n";
        $parameter->edit($field, $value);
        $self->logDebug("AFTER parameter->toString()");
        print $self->toString(), "\n";
        $self->_write();
    }

    method desc () {
        $self->logDebug("App::desc()");
        $self->_loadFile() if $self->inputfile();
        
        print $self->toString() and exit if not defined $self->field();
        my $field = $self->field();
        
        print $self->toJson(), "\n";
        
        $self->logDebug("field", $field);
        $self->logDebug("$field: ") , $self->$field(), "\n";
    }

 
    method wiki () {
        $self->_loadFile() if $self->appfile();

        my $wiki = $self->_wiki();
        print $wiki;
        
        return 1;
    }


    method _wiki () {
        #$self->logDebug("Workflow::_wiki()");
        my $wiki = '';
        $wiki .= "\n\tApplication";
        $wiki .= "\t" . $self->ordinal() if $self->ordinal();
        $wiki .= "\t" . $self->name . "\n";
        $wiki .= "\t" . $self->location . "\n";
        $wiki .= "\tstatus: " . $self->status() . "\n" if $self->status();
        $wiki .= "\tlocked: " . $self->locked() . "\n" if $self->locked() !~ /^\s*$/;
        $wiki .= "\tstarted: " . $self->started() . "\n" if $self->started();
        $wiki .= "\tcompleted: " . $self->completed() . "\n" if $self->completed();
        $wiki .= "\tduration: " . $self->duration() . "\n" if $self->duration();
        $wiki .= "\n" if $self->started() . "\n";
        $wiki .= "\n";
        
        
        return $wiki;
    }


    method edit () {
        #$self->logDebug("App::edit()");
        #$self->logDebug("self->toString():");
        #print $self->toString(), "\n";

        my $field = $self->field();
        my $value = $self->value();
        
        $self->_loadFile() if $self->inputfile();
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
        $self->logDebug("Agua::CLI::App::edit    field $field not valid") and exit if not $present;

        $self->$field($value);
        #$self->logDebug("Edited field '$field' value: "), $self->$field(), "\n";        
        #$self->logDebug("self:");
        #print $self->toString();

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
        
        return 1;
    }
    
    method create () {
        $self->logDebug("App::create()");

        my $outputfile = $self->outputfile;
        $self->_confirm("Outputfile already exists. Overwrite?") if -f $outputfile and not defined $self->force();

        $self->_write();        
    }

    method copy () {
        $self->logDebug("App::copy()");
        
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

        #### DO APPS
        my $parameters = $self->parameters();
        my $params = [];
        foreach my $parameter ( @$parameters )
        {
            push @$params, $parameter->_exportParam();
        }
        
        $hash->{parameters} = $params;
        return $hash;
    }
    
    method fromHash($hash) { 
        my $meta = $self->meta();

        foreach my $field ( keys %$hash )
        {
            my $value = $hash->{$field};
            #$self->logDebug("field $field value", $value);
            next if ref($self->$field) eq "ARRAY";
            
            my $attr = $meta->get_attribute($field);
            my $attribute_type  = $attr->{isa};
            $value = 0 if not $value and $attribute_type =~ /Int/;
            #$self->logDebug("'$field' attribute_type: $attribute_type and value: '$value'");
            
            $self->$field($value);
        }

        #### DO PARAMETERS
        my $paramHashes = $hash->{parameters};
        my $parameters = [];
        foreach my $paramHash ( @$paramHashes )
        {
            push @$parameters, Agua::CLI::Parameter->new($paramHash);
        }
        $self->parameters($parameters);

        return $self;
    }

    method toJson {
        my $hash = $self->_toExportHash($self->savefields());
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
    
    method _paramIndex ($parameter) {
        my $counter = 0;
        foreach my $currentparam ( @{$self->parameters()} )
        {
            if ( $parameter->param() eq $currentparam->param() )
            {
                return $counter;
            }
            $counter++;
        }

        return;
    }

    method _orderParams () {

        sub ordinalOrAbc (){
            #### ORDER BY ordinal IF PRESENT
            #my $aa = $a->ordinal();
            #my $bb = $b->ordinal();
            return $a->ordinal() <=> $b->ordinal()
                if defined $a->ordinal() and defined $b->ordinal()
                and $a->ordinal() and $b->ordinal();
                
            #### OTHERWISE BY ALPHABET
            #my $AA = $a->param();
            #my $BB = $b->param();
            #$self->logDebug("AA", $AA);
            #$self->logDebug("BB", $BB);
            return $a->param() cmp $b->param();
        }

        my $parameters = $self->parameters;
        @$parameters = sort ordinalOrAbc @$parameters;
        $self->parameters($parameters);
    }
    
    method _write($outputfile) {
        #$self->logDebug("Agua::CLI::App::_write(outputfile)");
        #$self->logDebug("outputfile", $outputfile) if defined $outputfile;
        
        $outputfile = $self->outputfile if not defined $outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;
        #$self->logDebug("outputfile", $outputfile);

        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/\\]+$/;
        File::Path::mkpath($basedir) if defined $basedir and not -d $basedir;

        my $json = $self->toJson();
        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$json\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method exportApp($outputfile) {
        #$self->logDebug("");
        #$self->logDebug("outputfile", $outputfile);
        $outputfile = $self->outputfile if not defined $outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;

        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/^\\]+$/;
        File::Path::mkpath($basedir) if defined $basedir and not -d $basedir;

        my $hash = $self->_toExportHash($self->appfields());

        my $jsonParser = JSON->new();
    	my $json = $jsonParser->pretty->indent->encode($hash);

        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$json\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }
    
    method read {
        return $self->_loadFile();
    }
    
    method _loadFile () {
        #$self->logDebug("App::_loadFile()");

        my $inputfile = $self->inputfile;
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
        
        #$self->logDebug("'BEFORE exists' self->toString():");
        #$self->toString();
        my $fields = $self->fields();
        foreach my $field ( @$fields )
        {
            if ( exists $object->{$field} and $object->{$field} )
            {
                $self->$field($object->{$field});
            }
        }
        #$self->logDebug("'AFTER exists' self->toString():");
        #$self->toString();
        
        #### CREATE PARAMETERS
        my $parameters = $self->parameters() || [];
        foreach my $paramHash ( @{$object->{parameters}} )
        {
        #$self->logDebug("paramHash:");
        #print Dumper $paramHash;
            my $parameter = Agua::CLI::Parameter->new();
            $parameter->fromHash($paramHash);
        #$self->logDebug("parameter->toString():");
        #print $parameter->toString();

            push @$parameters, $parameter;
        }
        $self->parameters($parameters);

        #$self->logDebug("self:");
        #print Dumper $self;
    }

    method _loadDb () {
        $self->logDebug("App::_loadDb()");

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
        $self->logError("error: 'Cannot create $dbtype database object: $!' ") and exit if not defined $self->db();
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

    method _toString () {
        my $json = $self->toJson() . "\n";
        my $output = "\n  Application:\n";
        foreach my $field ( @{$self->savefields()} )
        {
            next if not defined $self->$field() or $self->$field() =~ /^\s*$/;
            $output .= "  " . $self->_indentSecond($field, $self->$field(), $self->indent()) . "\n";
        }
        $output .= "\n    Parameters:\n";
        
        my $params;
        @$params = @{$self->parameters()};

        sub abcParams (){
            #### ORDER BY ALPHABET
            return $a->{param} cmp $b->{param};
        }
        @$params = sort abcParams @$params;

        foreach my $param ( @$params )
        {
            $output .= "    ". $self->_indentSecond($param->param(), $param->value(), undef) . "\n";
            #$output .= "\t" . $param->param(); 
            #$output .= "\t" . $param->value() if defined $param->value();
            #$output .= "\n"; 
        }
        
        return $output;
    }
}
