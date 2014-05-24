use MooseX::Declare;

class Test::Agua::Common::File with (Agua::Common::Base,
	Agua::Common::File,
	Agua::Common::Logger,
	Agua::Common::Database,
	Agua::Common::Transport,
	Agua::Common::Util,
	Test::Agua::Common::Database,
	Test::Agua::Common::Util) {

#### EXTERNAL MODULES
use Data::Dumper;
use Test::More;
use FindBin qw($Bin);

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Conf::Yaml;

# Ints
has 'log'	=> ( isa => 'Int', 		is => 'rw', default	=> 	2);
has 'printlog'	=> ( isa => 'Int', 		is => 'rw', default	=> 	5);

# Strings
has 'requestor'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testdatabase'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testuser'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'testpassword'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( backup	=>	1 );	}
);

####///}}}

method BUILD ($hash) {
}

method testFileJson {

    $self->prepareTestDatabase();
	
	$self->setTestDbh();

	#### CREATE source TABLE
	my $query = qq{CREATE TABLE source (
username varchar(30) NOT NULL,
name varchar(30) NOT NULL,
description text,
location varchar(255) NOT NULL,
PRIMARY KEY (username,name))};
	$self->db()->do($query);	
	
	#### INPUT LARGE FILES ARE ON /data VOLUME
	my $datavolume 	=	$self->conf()->getKey("bioapps", "DATAVOLUME");
	$self->logDebug("datavolume", $datavolume);
	my $binarydata	=	$self->conf()->getKey("applications:$datavolume", "BINARYDATA");
	$self->logDebug("binarydata", $binarydata);

	my $inputdir = $binarydata;
	$query = qq{INSERT INTO source
VALUES (
	'admin',
	'testbinary',
	'Test binary files',
	'$inputdir'
)};
	$self->db()->do($query);	
	
	my $files = $self->listFiles($inputdir);
	foreach my $file ( @$files ) {
		my $filepath = "$inputdir/$file";
		my $filejson = $self->fileJson($filepath, $filepath, $filepath);
		$self->logDebug("filejson", $filejson);
		ok($filejson =~ /"sample": "Binary&nbsp;file"/, "fileJson    sample contains 'Binary file'");
	}
}

method testCheckEbwt {
	#### INPUT LARGE FILES ARE ON /data VOLUME
	my $datavolume 		=	$self->conf()->getKey("bioapps", "DATAVOLUME");
	my $bowtiesource	=	$self->conf()->getKey("applications:$datavolume", "BOWTIESOURCE");
	$self->logDebug("bowtiesource", $bowtiesource);
	my $binarydata	=	$self->conf()->getKey("applications:$datavolume", "BINARYDATA");
	$self->logDebug("binarydata", $binarydata);

	my $filepath = "$binarydata/chr22.1.ebwt";
	my $headerfile = "$bowtiesource/ebwt.h";
	$self->checkEbwt($filepath, $headerfile);
	
}




}   #### Test::Agua::Common::File