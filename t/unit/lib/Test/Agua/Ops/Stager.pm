use MooseX::Declare;
use Method::Signatures::Simple;

class Test::Agua::Ops::Stager with (Test::Agua::Common::Util,Test::Agua::Common::Package) extends Agua::Ops {


use Data::Dumper;
use Test::More;
use Test::DatabaseRow;
use Agua::DBaseFactory;
#use Agua::DBase::MySQL;
use Agua::Ops;
use Agua::Instance;
use Conf::Yaml;
use FindBin qw($Bin);

# Ints
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'logfile'       => ( isa => 'Str|Undef', is => 'rw' );

####////}}

method setUp () {
	#### SET LOG FILE
	my $logfile			=	"$Bin/outputs/incrementversion.log";
	$self->logfile($logfile);

	##### CREATE LOCAL REPOSITORY IN inputs DIRECTORY
	my $inputdir 	= 	"$Bin/inputs";
	my $repository	=	"testrepo";
	$self->setUpRepo($inputdir, $repository);
}

method cleanUp () {
	#### REMOVE inputs REPOSITORY
	my $inputdir 		= 	"$Bin/inputs";
	my $repository		=	"testrepo";
	$self->setUpRepo($inputdir, $repository);
	`rm -fr $inputdir/$repository`;
	
	#### REMOVE outputs REPOSITORY
	my $outputdir 		= 	"$Bin/outputs";
	$self->setUpRepo($outputdir, $repository);
	`rm -fr $outputdir/$repository`;
}

method testRunStager () {
	#### COPY OPSDIR AFRESH
	my $inputsdir	= "$Bin/inputs/repos";
	my $outputsdir	= "$Bin/outputs/repos";
	$self->setUpDirs($inputsdir, $outputsdir);

	#### SET LOG FILE
	my $logfile		=	"$Bin/outputs/runstager.log";
	$self->logfile($logfile);

	##### SET ARGUMENTS
	my $mode		=	"2-3";
	my $message		=	"TEST MULTILINE COMMIT MESSAGE - FIRST LINE
<EMPTY LINE>
<EMPTY LINE>
SECOND LINE
THIRD LINE
";
	
	my $version		=	"0.8.0-alpha+build.1";
	my $versiontype	=	undef;
	my $versionformat=	"semver";
	my $package		=	"biorepository";
	my $stagefile	=	"$outputsdir/private/syoung/biorepodev/stager.pm";
	my $branch		=	"master";
	my $outputdir	=	"$outputsdir/tmp";
	$self->logDebug("stagefile", $stagefile);	
	
	my $object = Agua::Ops->new({
		version     	=>  $version,
		versiontype     =>  $versiontype,
		versionformat   =>  $versionformat,
		branch          =>  $branch,
		package     	=>  $package,
		outputdir       =>  $outputdir,
		#versionfile     =>  $versionfile,
		#releasename     =>  $releasename,
		logfile     	=>   $logfile,
		showlog     	=>   $self->showlog(),
		printlog   		=>   $self->printlog()
	});

	$object->stageRepo($stagefile, $mode, $message);	
}

}   #### Test::Agua::Common::Package