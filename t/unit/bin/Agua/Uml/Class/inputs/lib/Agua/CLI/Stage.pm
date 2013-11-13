use MooseX::Declare;
use Moose::Util::TypeConstraints;
use MooseX::LogDispatch;
use MooseX::Getopt;

class Stage with (MooseX::Getopt, MooseX::LogDispatch) extends App {
    
    use File::Path;
    use JSON;
    use DBaseFactory;
    use Data::Dumper;
    use ParameterX;

    #### PRE-DECLARE CLASS TYPES
    #subtype ParameterX => as Object => where { $_->isa('ParameterX') };
    #subtype 'ParameterX' => as 'ParameterX' => where {} => message {'here'};
     #enum 'RGB' => qw( red green blue );

    ##### STORED VARIABLES
    has 'owner'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, default => 'anonymous' );
    has 'name'	    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'type'	    => ( isa => 'Str|Undef', is => 'rw', required => 0, documentation => q{User-defined application type} );
    has 'location'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'submit'	=> ( isa => 'Maybe', is => 'rw', default => 0 );
    has 'executor'	=> ( isa => 'Str|Undef', is => 'rw', default => 0 );
    has 'cluster'	=> ( isa => 'Str|Undef', is => 'rw', default => 0 );
    has 'description'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'notes'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
    has 'parameters'	=> ( isa => 'ArrayRef[ParameterX]', is => 'rw', default => sub { [] } );
    
    #### TRANSIENT VARIABLES
    has 'newname'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'param'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'field'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'value'	    => ( isa => 'Str', is => 'rw', required => 0 );
    has 'fields'    => ( isa => 'ArrayRef[Str|Undef]', is => 'rw', default => sub { ['owner', 'name', 'type', 'location', 'submit', 'executor', 'cluster', 'description', 'notes'] } );
    has 'inputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'outputfile'=> ( isa => 'Str|Undef', is => 'rw', required => 0, default => '' );
    has 'dbfile'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'dbtype'    => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'database'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'user'      => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'password'  => ( isa => 'Str|Undef', is => 'rw', required => 0 );
    has 'force'     => ( isa => 'Maybe', is => 'rw', required => 0 );
    #has 'db'  => ( isa => 'DBase::SQLite|DBase::MySQL', is => 'rw' );

####//}}
    
    method BUILD ($hash) { 
        print "Stage::BUILD    Stage::BUILD()\n";    
        $self->owner("anonymous") if not defined $self->owner();
        print "Stage::BUILD    force is defined: ", $self->force(), "\n" if defined $self->force();
        print "Stage::BUILD    submit is defined: ", $self->submit(), "\n" if defined $self->submit();
    }

    method addParam (ParameterX $parameter) {
        #print "Stage::addParam    Stage::addParam(parameter)\n";
        #print "Stage::addParam    parameter:\n";
        #print Dumper $parameter;

        my $inputfile = $self->inputfile;
        #print "Stage::addParam    self: $self\n";
        #print "Stage::addParam    inputfile: $inputfile\n";

        $self->load();
        #print $self->toJson(), "\n";
        
        $self->_addParam($parameter);
        #print $self->toJson(), "\n";

        $self->_orderParams();
        #print $self->toJson(), "\n";
        
        $self->_write();
    }

    method _addParam (ParameterX $parameter) {
        #print "Stage::_addParam    Stage::_addParam()\n";
        push @{$self->parameters}, $parameter;
    }

    method deleteParam (ParameterX $parameter) {
        #print "Stage::deleteParam    Stage::deleteParam(parameter)\n";
        #print "Stage::deleteParam    parameter:\n";
        #print Dumper $parameter;

        my $inputfile = $self->inputfile;
        #print "Stage::deleteParam    self: $self\n";
        #print "Stage::deleteParam    inputfile: $inputfile\n";

        $self->load();
        #print $self->toJson(), "\n";
        
        $self->_deleteParam($parameter);
        #print $self->toJson(), "\n";

        $self->_orderParams();
        #print $self->toJson(), "\n";
        
        $self->_write();
    }

    method _deleteParam (ParameterX $parameter) {
        #print "Stage::_deleteParam    Stage::_deleteParam(parameter)\n";
        #print "Stage::_deleteParam    parameter->param(): ", $parameter->param(), "\n";

        my $counter = 0;
        #print "Stage::_deleteParam    BEFORE number parameters: ", scalar(@{$self->parameters()}), "\n";
        foreach my $currentparam ( @{$self->parameters} )
        {
            #print "Stage::_deleteParam    currentparam->param(): ", $currentparam->param(), "\n";
            
            if ( $parameter->param() eq $currentparam->param() )
            {
                splice @{$self->parameters}, $counter, 1;
                #print "Stage::_deleteParam    AFTER number parameters: ", scalar(@{$self->parameters()}), "\n";
                return;
            }
            $counter++;
        }

        print "Stage::_deleteParam    parameter not found: ", $parameter->param(), "\n";    
    }

    method _orderParams () {
        #print "Stage::_orderParam    Stage::_orderParams()\n";

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
            #print "Stage::_orderParam    AA: $AA\n";
            #print "Stage::_orderParam    BB: $BB\n";
            return $a->param() cmp $b->param();
        }

        my $parameters = $self->parameters;
        @$parameters = sort ordinalOrAbc @$parameters;
        $self->parameters($parameters);
    }
    
    method loadDb () {
        print "Stage::loadDb    Stage::loadDb()\n";

        my $dbtype = $self->dbtype();
        print "Stage::loadDb    dbtype not defined. Exiting\n" and exit if not defined $dbtype;
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
        print "error: 'Cannot create $dbtype database object: $!' " and exit if not defined $self->db();
        print "Stage::new    self->db: ", $self->db(), "\n";
        
    }

    method create () {
        print "Stage::create    Stage::create()\n";
        my $outputfile = $self->outputfile;
        $self->confirm("Outputfile already exists. Overwrite?") if -f $outputfile and not defined $self->force();

        $self->_write();        
    }

    method copy () {
        print "Stage::copy    Stage::copy()\n";
        
        $self->load();
        $self->name($self->newname());

        my $outputfile = $self->outputfile;
        $self->confirm("Outputfile already exists. Overwrite?") if -f $outputfile and not defined $self->force();

        $self->_write();        
    }

    method toHash() {
        my $hash;
        foreach my $field ( @{$self->fields} )
        {
            if ( ref($self->$field) ne "ARRAY" )
            {
                $hash->{$field} = $self->$field();
            }
        }

        #### DO PARAMETERS
        my $parameters = $self->parameters();
        my $params = [];
        foreach my $parameter ( @$parameters )
        {
            push @$params, $parameter->toHash();
        }
        #print "Stage::toHash    params:\n";
        #print Dumper $params;
        
        $hash->{parameters} = $params;
        return $hash;
    }
    
    method toJson() {
        my $hash = $self->toHash();
        my $jsonParser = JSON->new();
    	my $json = $jsonParser->objToJson($hash, {pretty => 1, indent => 4});
        return $json;    
    }
    
    method _write() {
        
        my $json = $self->toJson();

        my $outputfile = $self->outputfile;
        $outputfile = $self->inputfile if not defined $outputfile or not $outputfile;
        my ($basedir) = $outputfile =~ /^(.+)(\/|\\)[^\/\\]+$/;
        File::Path::mkpath($basedir) if not -d $basedir;

        open(OUT, ">$outputfile") or die "Can't open outputfile: $outputfile\n";
        print OUT "$json\n";
        close(OUT) or die "Can't close outputfile: $outputfile\n";
    }

    method load () {
        print "Stage::load    Stage::load()\n";

        my $inputfile = $self->inputfile;
        print "Stage::load    inputfile: $inputfile\n";
        $/ = undef;
        open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
        my $contents = <FILE>;
        close(FILE) or die "Can't close inputfile: $inputfile\n";
        $/ = "\n";
    
        my $jsonParser = JSON->new();
    	my $object = $jsonParser->decode($contents);
        #print "Stage::load    object:\n";
        #print Dumper $object;
        
        my $fields = $self->fields();
        foreach my $field ( @$fields )
        {
            if ( exists $object->{$field} )
            {
                $self->$field($object->{$field});
            }
        }

        #### CREATE PARAMETERS
        my $parameters = [];
        foreach my $param ( @{$object->{parameters}} )
        {
            my $parameter = ParameterX->new();
            $parameter->fromHash($param);
            push @$parameters, $parameter;
        }
        $self->parameters($parameters);

        #print "Stage::load    self:\n";
        #print Dumper $self;
    }

    method desc () {
        print "Stage::desc    Stage::desc()\n";
        $self->load();
        
        print $self->toString(), and exit if not defined $self->field();
        my $field = $self->field();
        
        print $self->toJson(), "\n";
        
        print "Stage::desc    field: $field\n";
        print "$field: " , $self->$field(), "\n";
    }  


    method edit () {
        print "Stage::edit    Stage::edit()\n";

        my $field = $self->field();
        my $value = $self->value();
        
        $self->load();
        my $present = 0;
        #print "Stage::edit    field: **$field**\n";
        #print "Stage::edit    value: **$value**\n";
        foreach my $currentfield ( @{$self->fields} )
        {
            #print "Stage::edit    currentfield: **$currentfield**\n";
            $present = 1 if $field eq $currentfield;
            last if $field eq $currentfield;
        }
        print "Stage::edit    present: $present\n";
        $self->logDebug("Stage::edit    field $field not valid") and exit if not $present;

        $self->$field($value);
        
        #print "Stage::edit    self:\n";
        #print Dumper $self;

        $self->outputfile($self->inputfile());
        $self->_write();
    }
    
    method confirm (Str $message){
	
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

    method toString {
        my $output = $self->_toString();
        print "$output\n";
    }

    method _toString {
        my $json = $self->toJson() . "\n";
        my $output = '';
        foreach my $field ( @{$self->fields()} )
        {
            next if not defined $self->$field() or $self->$field() =~ /^\s*$/;
            $output .= $field . "\t" . $self->$field . "\n";
        }
        $output .= "Parameters:\n";
        foreach my $parameter ( @{$self->parameters()} )
        {
            $output .= "\t" . $parameter->param() . "\n"; 
        }
        
        return $output;
    }
}
