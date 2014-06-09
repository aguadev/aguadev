use Moose::Util::TypeConstraints;
use MooseX::Declare;
use Method::Signatures::Modifiers;

class Test::Agua::Deploy extends Agua::Deploy with (Agua::Common::Logger, Agua::Common::Util, Test::Agua::Common::Util) {

use Data::Dumper;
use Test::More;
use FindBin qw($Bin);
use JSON;

# STRINGS
has 'dumpfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'username'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'password'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=>  ( isa => 'Str|Undef', is => 'rw' );
has 'requestor'		=> 	( isa => 'Str|Undef', is => 'rw' );

# OBJECTS
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is 		=>	'rw',
	isa 	=> 	'Conf::Yaml|Undef'
);

#####/////}}}}}

method BUILD ($args) {
	if ( defined $args ) {
		foreach my $arg ( $args ) {
			$self->$arg($args->{$arg}) if $self->can($arg);
		}
	}
	$self->logDebug("args", $args);
}

method testGetSkelSubs {
	diag("getSubs");
	
	my $methods	=	"perl,git,make";
	my $expected	=	[
		"perlInstall",
		"gitInstall",
		"makeInstall",
	];
	
	my $subs	=	$self->getSkelSubs($methods);
	
	is_deeply($expected, $subs, "subroutines: @$subs");
}

method testGetSkelTemplate {
	diag("getSkelTemplate");

	#### SET installdir
	my $installdir = $self->conf()->setKey("agua", "INSTALLDIR", "$Bin/inputs/skel");
	
	my $template	=	$self->getSkelTemplate();
	$self->logDebug("template", $template);
	ok($template	=~	/templates\/skel\.pm$/, "correct name");
	ok( -f $template, "template found");	
}

method testGetSkelPm {
	diag("getSkelPm");
	
}

method testGetSkelOps {
	diag("getSkelOps");
	
}

method testGetSkelTemplate {
	diag("getSkelTemplate");
	
}

method testSkel {
	diag("skel");
	
	#### CLEAR OUTPUT DIR
	my $targetdir	=	"$Bin/outputs/skel";
	`rm -fr $targetdir`;

	#### DIFF ACTUAL AND EXPECTED FOLDERS
	my $expecteddir	=	"$Bin/inputs/skel/repos/public/agua/biorepository/agua/testpackage";
	my $actualdir	=	"$Bin/outputs/skel/repos/public/agua/biorepository/agua/testpackage";

	*getSkelTargetDir = sub	{
		return "$actualdir";
	};

	#### SET installdir
	my $installdir = $self->conf()->setKey("agua", "INSTALLDIR", "$Bin/inputs/skel");
	
	#### SET package AND methods
	$self->package("testpackage");
	$self->methods("git,zip,make,perl");
	
	$self->skel();
	
	my $diff	=	$self->diff($actualdir, $expecteddir);
	$self->logDebug("diff", $diff);
	ok($diff, "pm and ops files");
}




}	####	Agua::Login::Common
