use MooseX::Declare;
#use Getopt::Simple;
 
class Agua::CLI::Parameter with (Agua::CLI::Logger) {
    
    use File::Path;
    use JSON;
    #use DBaseFactory;
    use Data::Dumper;

    #### LOGGER
    has 'SHOWLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	4 	);  
    has 'PRINTLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	5 	);
    has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=>	0	);

    #### RUN CONFIGURATION VARIABLES
    has 'locked'		=> ( isa => 'Int', is => 'rw', required	=>	0	);
    has 'param'	    	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 1, documentation => q{Name of the parameter}  );
    has 'owner'	    	=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => 'anonymous', documentation => q{Owner of this object} );
    has 'argument'		=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0 );
    has 'paramtype'	    => ( isa => 'Str', is => 'rw', default => '', required => 0, documentation => q{Three possible param types: input, resource or output} );
    has 'valuetype'	    => ( isa => 'Str', is => 'rw', default => '', required => 0, documentation => q{Possible types: file, files, directory, directories, integer, string or flag} );
    has 'category'		=> ( isa => 'Str', is => 'rw', default => '', required => 0, documentation => q{User-defined category for parameter to be used with input/output chaining} );
    has 'ordinal'		=> ( isa => 'Str|Undef', is => 'rw', default => undef, required => 0, documentation => q{Set order of appearance: 1, 2, ..., N} );
    has 'value'	    	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0 );
    has 'discretion'	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0, documentation => q{Three options: essential (e.g., file must be present), required, or optional} );
    has 'format'		=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0, documentation => q{File format, e.g., text, fasta, fastq} );
    has 'description'	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0 );
    
    #### CONSTANTS
    has 'indent'    	=> ( isa => 'Int', is => 'ro', default => 15);
    
    #### CHAINING VARIABLES
    has 'chained'	    => ( isa => 'Int|Undef', is => 'rw', default => 0 );
    has 'args'	    	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0 );
    has 'inputParams'	=> ( isa => 'Str', is => 'rw', default => '', required => 0 );
    has 'paramFunction'	=> ( isa => 'Str|Undef', is => 'rw', default => '', required => 0);

    #### TRANSIENT VARIABLES
    has 'newname'		=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'from'			=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'to'			=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'field'	    	=> ( isa => 'Str', is => 'rw', required => 0 );
    has 'fields'    	=> ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { ['param', 'paramtype', 'valuetype', 'category', 'ordinal', 'argument', 'value', 'discretion', 'format', 'description', 'args', 'inputParams', 'paramFunction', 'paramfile', 'newname', 'inputfile', 'outputfile', 'outputdir', 'from', 'to', 'field', 'ordinal', 'locked', 'chained'] } );
    has 'savefields'    => ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { ['param', 'paramtype', 'valuetype', 'category', 'ordinal', 'argument', 'value', 'discretion', 'format', 'description', 'args', 'inputParams', 'paramFunction', 'paramfile', 'locked', 'chained'] } );
    has 'exportfields'  => ( isa => 'ArrayRef[Str]', is => 'rw', default => sub { [ 'param', 'paramtype', 'valuetype', 'category', 'ordinal', 'argument', 'value', 'discretion', 'format', 'description', 'args', 'inputParams', 'paramFunction', 'locked', 'chained'] } );
    has 'paramfile'		=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'inputfile'		=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputfile'	=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputdir'		=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'location'		=> ( isa => 'Str|Undef', is => 'rw', required => 0 );

####///}}}
    
    method BUILD($hash) { 
        #$self->logDebug("Parameter::BUILD()");    
        $self->initialise();
    }
    
    method initialise () {
        $self->owner("anonymous") if not defined $self->owner();
        $self->inputfile($self->paramfile()) if defined $self->paramfile() and $self->paramfile();
        #$self->logDebug("self->inputfile(): "), $self->inputfile(), "\n";
        $self->logDebug("inputfile must end in '.param'") and exit
            if defined $self->inputfile()
            and $self->inputfile()
            and not $self->inputfile() =~ /\.param$/;

        $self->logDebug("outputfile must end in '.param'") and exit
            if defined $self->outputfile()
            and $self->outputfile()
            and not $self->outputfile() =~ /\.param$/;
    }
    
    method getopts () {
        #$self->logDebug("Agua::CLI::Parameter::getopts()");
        #$self->logDebug("Agua::CLI::Parameter::getopts    ARGV: @ARGV");
        my @temp = @ARGV;
        my $arguments = $self->arguments();
        #$self->logDebug("Agua::CLI::Parameter::getopts    arguments: ");
        #print Dumper $arguments;
        my $olderr;
        open $olderr, ">&STDERR";	
        open(STDERR, ">/dev/null") or die "Can't redirect STDERR to /dev/null\n";
        my $options = Getopt::Simple->new();
        $options->getOptions($arguments, "Usage: blah blah"); 
        open STDERR, ">&", $olderr;
        #$self->logDebug("options->{switch}:");
        #print Dumper $options->{switch};
        my $switch = $options->{switch};
        
        foreach my $key ( keys %$switch )
        {
            #$self->logDebug("key: $key and value: "), $switch->{$key}, "\n";
            $self->$key($switch->{$key}) if defined $switch->{$key};
        }

        $self->initialise();

        @ARGV = @temp;
    }


    method arguments() {
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
        my $arguments = {};
        foreach my $attribute_name ( @$attributes )
        {
            my $attr = $meta->get_attribute($attribute_name);
            my $attribute_type  = $attr->{isa};
            #$self->logDebug("attribute_name '$attribute_name' attribute_type", $attribute_type);
            
            $attribute_type =~ s/\|.+$//;
            $arguments -> {$attribute_name} = {  type => $option_type_map{$attribute_type}  };
        }
        #$self->logDebug("arguments", $arguments);
        
        return $arguments;
    }



    method desc () {
        $self->logDebug("Parameter::desc()");
        $self->_loadFile();
        
        print $self->toString(), and exit if not defined $self->field();
        my $field = $self->field();
        
        print $self->toJson(), "\n";
        
        $self->logDebug("field", $field);
        $self->logDebug("$field: ") , $self->$field(), "\n";
    }

    method edit () {
        $self->logDebug("Agua::CLI::Parameter::edit()");
        $self->logDebug("self->toString() :");
        print $self->toString() ;
        
        my $field = $self->field();
        my $value = $self->value();
        
        $self->_loadFile() if $self->inputfile();
        my $present = 0;
        #$self->logDebug("field: **$field**");
        #$self->logDebug("value: **$value**");
        foreach my $currentfield ( @{$self->savefields()} )
        {
            #$self->logDebug("currentfield: **$currentfield**");
            $present = 1 if $field eq $currentfield;
            last if $field eq $currentfield;
        }
        #$self->logDebug("present", $present);
        $self->logDebug("Agua::CLI::Parameter::edit    field $field not valid") and exit if not $present;

        $self->$field($value);
        #$self->logDebug("self->toString() :");
        #print Dumper $self->toString() ;

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();

		return 1;
    }

    method replace () {
        $self->logDebug("Parameter::replace()");
        
        my $from = $self->from();
        my $to = $self->to();
        $self->logDebug("from", $from);
        $self->logDebug("to", $to);
        $self->logDebug("No. fields: ") . scalar(@{$self->fields()}) . "\n";

        $self->_loadFile() if defined $self->paramfile() and $self->paramfile();
        
        $self->logDebug("BEFORE self->toString() :");
        print $self->toString();
        my $value = $self->value();
        $value =~ s/$from/$to/g;
        $self->value($value);

        $self->logDebug("AFTER self->toString() :");
        print $self->toString() ;

        $self->outputfile($self->inputfile());
        $self->_write() if $self->outputfile();
    }
    

    method create () {
        $self->logDebug("Parameter::create()");

        my $outputfile = $self->outputfile;
        $self->_confirm("Outputfile already exists. Overwrite?") if -f $outputfile and not defined $self->force();

        $self->_write();        
    }

    method copy () {
        #$self->logDebug("Parameter::copy()");
        
        $self->_loadFile();
        #$self->logDebug("self->toString()");
        #print $self->toString(), "\n";

        #$self->logDebug("self->getopts()");
        $self->getopts();
        
        $self->param($self->newname());    

        my $outputfile = $self->outputfile;
        $self->_confirm("Outputfile already exists. Overwrite?") if -f $outputfile;

        $self->_write();        
    }

    method toHash() {
        my $hash;
        foreach my $field ( @{$self->savefields()} )
        {
            #$self->logDebug("field", $field);
            next if ref($self->$field) eq "ARRAY";
            $hash->{$field} = $self->$field();
        }

        return $hash;
    }

    method _exportParam() {
        my $hash;
        foreach my $field ( @{$self->exportfields()} )
        {
            next if ref($self->$field) eq "ARRAY";
            $hash->{$field} = $self->$field();
        }

        return $hash;
    }
    
    method fromHash(HashRef $hash) {        
        foreach my $field ( keys %$hash )
        {
            my $value = $hash->{$field};
            next if ref($self->$field) eq "ARRAY";
            $self->$field($value);
        }

        return $self;
    }

    method _toExportHash ($fields) {
        my $hash;
        foreach my $field ( @$fields )
        {
            next if ref($self->$field) eq "ARRAY";
            $hash->{$field} = $self->$field();
        }

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

    method _indentSecond ($first, $second, $indent?) {
        $indent = $self->indent() if not defined $indent;
        my $spaces = " " x ($indent - length($first));
        return $first . $spaces . $second;
    }
    
    method _write() {
        my $json = $self->toJson();
        #$self->logDebug("json:");
        #print Dumper  $json;

        my $outputfile = $self->outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;
        #$self->logDebug("outputfile", $outputfile);
        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/\\]+$/;
        File::Path::mkpath($basedir) if not -d $basedir;

        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$json\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method _loadFile () {
        #$self->logDebug("Parameter::_loadFile()");
        #$self->logDebug("self->toString()");
        #print $self->toString(), "\n";
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
        
        my $fields = $self->fields();
        foreach my $field ( @$fields )
        {
            if ( exists $object->{$field} )
            {
                $self->$field($object->{$field});
            }
        }
        
        $self->initialise();
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
        my $output = "\n  Parameter:\n";
        foreach my $field ( @{$self->fields()} )
        {
            next if not defined $self->$field() or $self->$field() =~ /^\s*$/;
            $output .= "  " . $self->_indentSecond($field, $self->$field(), $self->indent()) . "\n";
        }
        
        return $output;
    }    
}

