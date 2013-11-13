use MooseX::Declare;

=head2

	PACKAGE		Agua::OpsInfo
	
	PURPOSE
	
		READ AND WRITE INFORMATION FROM/INTO *.ops FILE

		OPS (Open Package Schema) is a resource description format for installing software applications and data packages. OPS is implemented as a JSON *.ops file containing the following key-value pairs  (values are scalars unless otherwise noted):

name				name of application or data package to be installed
type:           	package type - application, data, reference, workflow, etc.
version:        	identifier for this version
history:        	array of previous versions

opsfile        		URL of github or private git repository providing this *.ops file
installfile    		git URL of fabric/ops deployment file
installtype    		ops, fabric, shell, etc.
licensefile    		repository location of licence file
resources			array of application-specific installation resources (e.g., tsvfiles, appfiles, EC2 snapshots, etc.)

authors         	array of author objects
email          		author's email address
keywords       		array of keywords relating to the package
description    		description of the package
website        		URL of website for package
publications    	array of paper/abstract/etc. objects
organisations   	array of organisation objects
ISA            		hash of experiment information conforming to ISA standard
acknowledgements 	array of organisation objects
citations      		array of paper/abstract/etc. objects
meta           		hash of additional metadata


The complete contents of the *.ops file are available as variables of the OpsInfo object inside *.pm so the installer can access important information required to install the application. The 'resources' entry in the *.ops file serves as a convenient store for all application-specific installation information.

For more details, see: http://www.aguadev.org


EXAMPLE INSTALL FILE:

em /agua/0.6/repos/biorepository/syoung/fastqc.ops

{
    "name":           "fastqc",
    "version":        "0.9.3",
    "build":          "",
    "type":           "application",
    "source":         "url",
    "type":           "http",
    "description":    "A quality control tool for high throughput sequence data",
    "website":       "http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc",
    "opsfile":        "https://api.github.com/repos/syoung/biorepository/syoung/fastqc/fastqc.ops",
    "parameterfile":  "https://api.github.com/repos/syoung/biorepository/syoung/fastqc/fastqc.params",
    "installfile":    "https://api.github.com/repos/syoung/biorepository/syoung/fastqc/fastqc.pm",
    "licensefile":    "https://api.github.com/repos/syoung/biorepository/syoung/fastqc/LICENSE",
    "readmefile":     "https://api.github.com/repos/syoung/biorepository/syoung/fastqc/README",
    "installparams": [
        {
            "name":         "version",
            "argument":     "",
            "ordinal":      "",
            "description":  "software version (can be letters and numbers)",
            "default":      "0.9.3"
        },
        {
            "name":           "installdir",
            "argument":       "",
            "ordinal":        "",
            "description":    "Full path to install directory (final path: 'installdir/version'",
            "default":        "/usr/local/src/fastqc"
        }
    ],
    "installtype":    "ops",
    "author":         [],
    "publication":    [],
    "organisation":   [],
    "ISA":            {},
    "acknowledgements": [],
    "citations":      []
}



=cut

class Agua::OpsInfo extends Conf::Json with (Agua::Common::Logger) {
use FindBin qw($Bin);
use lib "$Bin/..";

#### EXTERNAL MODULES
use Data::Dumper;
use JSON;

# Ints
has 'SHOWLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	5 	);  
has 'PRINTLOG'		=> ( isa => 'Int', is => 'rw', default 	=> 	5 	);

# Strings
has 'package'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'type'			=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'version'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'history'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

has 'installtype'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0, default	=>	'ops'	);
has 'opsfile'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'installfile'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'licensefile'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'readmefile'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

has 'description'	=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);
has 'website'		=> ( isa => 'Str|Undef', is => 'rw', required	=> 	0	);

# Objects
has 'authors'		=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);
has 'publications'	=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);
has 'organisations'	=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);
has 'ISA'			=> ( isa => 'HashRef|Undef', is => 'rw', required	=> 	0	);
has 'acknowledgements'=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);
has 'citations'		=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);
has 'resources'		=> ( isa => 'HashRef|Undef', is => 'rw', required	=> 	0	);
has 'keywords'		=> ( isa => 'ArrayRef|Undef', is => 'rw', required	=> 	0	);

has 'savefields'	=> ( isa => 'ArrayRef|Undef', is => 'rw', default => sub { ['package', 'version', 'type', 'version', 'history', 'installtype', 'opsfile', 'installfile', 'licensefile', 'readmefile', 'description', 'website', 'authors', 'publications', 'organisations', 'ISA', 'acknowledgements', 'citations']	});

####/////}}}}

=head2

	SUBROUTINE		BUILD
	
	PURPOSE

		GET AND VALIDATE INPUTS, AND INITIALISE OBJECT

=cut

method BUILD ($hash) {
	$self->initialise();
}

method initialise () {
	##### OPEN inputfile IF DEFINED
	$self->parseFile($self->inputfile()) if $self->inputfile();
}

method parseFile ($inputfile) {
	#$self->logDebug("inputfile", $inputfile);
	$self->inputfile($inputfile);
	open(FILE, $inputfile) or die "Can't open inputfile: $inputfile\n";
	my $temp = $/;
	$/ = undef;
	my $contents = <FILE>;
	close(FILE) or die "Can't close inputfile: $inputfile\n";
	
	my $parser = JSON->new();
	my $opshash = $parser->decode($contents);
	#$self->logDebug("opshash", $opshash);
	return $self->parseOps($opshash);
}

method parseOps ($opshash) {
	#$self->logDebug("opshash", $opshash);

	foreach my $key ( %$opshash ) {
		$self->$key($opshash->{$key}) if $self->can($key);
	}
	
	return 1;
}

method set ($key, $value) {
	$self->logNote("key", $key);
	$self->logNote("value", $value);
	$self->logWarning("key is null") and return if not defined $key;
	$self->logWarning("value is null") and return if not defined $value;

	$self->logDebug("not a supported attribute: $key") and return 0 if not $self->isKey($key);	

	$self->$key($value);
	return $self->insertKey($key, $value, undef);
}

method isKey ($key) {
	return 0 if not defined $key;
	foreach my $field ( @{$self->savefields} ) {
		return 1 if $field eq $key;
	}
	
	return 0;
	
}

method get ($key) {
	return $self->$key() if $self->can($key);
	return;
}

method generate {
	my $file = $self->outputfile();
	$file = $self->inputfile() if not defined $file;
	$self->logWarning("file not defined") if not defined $file;

	my %option_type_map = (
		'Bool'     => undef,
		'Str'      => '',
		'Int'      => undef,
		'Num'      => undef,
		'ArrayRef' => [],
		'HashRef'  => {},
		'Maybe'    => undef
	);

	my $meta = Agua::OpsInfo->meta();
	my $fields = $self->savefields();
	@$fields = reverse (@$fields);
	foreach my $field ( @$fields ) {
		#$self->logDebug("field", $field);
		my $attr = $meta->get_attribute($field);
		my $attribute_type  = $attr->{isa};
		$attribute_type =~ s/\|.+$// if defined $attribute_type;
		#$self->logDebug("attribute_type", $attribute_type);
		my $value = $option_type_map{$attribute_type};
		#$self->logDebug("value", $value);

		$self->insertKey($field, $value, undef);	
	}
	
	$self->write($file);
}


}

