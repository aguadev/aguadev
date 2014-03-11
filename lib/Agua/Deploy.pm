use MooseX::Declare;
use Method::Signatures::Simple;

=head2

PACKAGE		Deploy

PURPOSE

    1. INSTALL KEY AGUA DEPENDENCIES
    
    
=cut
use strict;
use warnings;
use Carp;

#### USE LIB FOR INHERITANCE
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";
use Data::Dumper;

class Agua::Deploy with Agua::Common {

#### USE LIB
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Conf::Yaml;
use Agua::Ops;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );

# Strings
has 's3bucket'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'opsfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'pmfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'package'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'version'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'privacy'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'repository'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'keyfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 			=> (
	is =>	'rw',
	isa => 'Conf::Yaml',
	default	=>	sub { Conf::Yaml->new( {} );	}
);
has 'ops' 	=> (
	is 		=>	'rw',
	isa 	=>	'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);

####/////}

method BUILD ($hash) {
	$self->logDebug("Agua::Deploy::BUILD()");
	#$self->logDebug("self", $self);
	$self->initialise();
}

method initialise {	
    my $conf 		= 	Conf::Yaml->new({inputfile=>"$Bin/../../conf/config.yaml"});
	
	#### SET CONF LOG
	$self->conf()->SHOWLOG($self->SHOWLOG());
	$self->conf()->PRINTLOG($self->PRINTLOG());	
}

method deploy {
	
    #### INSTALL BIOREPOSITORY
    $self->biorepo();
    
    #### INSTALL BIOAPPS
    $self->bioapps();
    
    #### INSTALL BIOAPPS
    $self->starcluster();
    
    #### INSTALL SUN GRID ENGINE
    $self->sge();

	#### INSTALL AGUA TESTS
	$self->aguatest();

print "\n\n\n";
print "************************       *************************\n";
print "***                Completed 'deploy'                ***\n";
print "************************       *************************\n";
print "\n\n\n";

	$self->logDebug("Completed $0");
}

#### OPSREPO
method biorepo {
    my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
    my $opspackage	= 	$self->conf()->getKey("agua", "OPSPACKAGE");
    my $owner		=	"agua";
    my $login		=	"agua";
    my $privacy		=	"public";
    my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
    my $basedir		= 	$self->conf()->getKey("agua", "INSTALLDIR");
    my $installdir 	= 	"$basedir/repos/public/$owner/$opsrepo";

	print "Installing opsrepo: $opsrepo\n";
    $self->logDebug("opsrepo", $opsrepo);
    $self->logDebug("owner", $owner);
    $self->logDebug("username", $username);
    $self->logDebug("installdir", $installdir);
    $self->logDebug("privacy", $privacy);

	#### SET VERSION
	my $version		=	$self->version();
	$self->logDebug("version", $version);

    #### CREATE PARENT DIR
    my $parentdir 	= 	"$basedir/repos/public";
    `mkdir -p $parentdir` if not -d $parentdir;
    print "Can't create parentdir: $parentdir" and exit if not -d $parentdir;

	my $pmfile	=	"$basedir/bin/install/resources/agua/$opsrepo.pm";
	my $opsdir	=	"$basedir/bin/install/resources/agua";

	my $ops	=	$self->setOps($owner, $login, $username, $opsrepo, $opspackage, $privacy, $installdir, $pmfile, $opsdir, $version);
	
	$ops->install();
}

method installApplication ($owner, $login, $username, $repository, $package, $privacy, $installdir, $pmfile, $opsdir, $version) {
	$self->logDebug("opsdir", $opsdir);

	my $ops	=	$self->setOps($owner, $login, $username, $repository, $package, $privacy, $installdir, $pmfile, $opsdir, $version);

	$ops->install();
}

method setOps ($owner, $login, $username, $repository, $package, $privacy, $installdir, $pmfile, $opsdir, $version) {
	$self->logDebug("owner", $owner);
	$self->logDebug("login", $login);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("privacy", $privacy);

	my $args	=	{
		owner		=>	$owner,
		login		=>	$login,
		repository	=>	$repository,
		username	=>	$username,
		package		=>	$package,
		version		=>	$version,
		opsdir		=>	$opsdir,
		token		=>	$self->token(),
		keyfile		=>	$self->keyfile(),
		password	=>	$self->password(),
		privacy		=>	$privacy,
		installdir	=>	$installdir,
		logfile 	=>	$self->logfile(),
		SHOWLOG		=>	$self->SHOWLOG(),
		PRINTLOG	=>	$self->PRINTLOG()
		,
		conf		=>	$self->conf()
	};
	#$self->logDebug("args", $args);
	
	my $ops	=	Agua::Ops->new($args);
	$self->logDebug("ops: $ops");

	return $ops;
}

method getVersions ($owner, $repository, $privacy) {
	$self->logDebug("owner", $owner);
	$self->logDebug("repository", $repository);
	$self->logDebug("privacy", $privacy);
	
	#### GET LATEST VERSION	
	my $ops 	= 	"$Bin/../logic/ops.pl";
	my $command = qq{$ops \\
$repository getRemoteTags $owner $repository $privacy
};
	$self->logDebug("command", $command);
	my $result = `$command`;	
	#$self->logDebug("result", $result);

	my $parser = JSON->new();
	my $tags = $parser->allow_nonref->decode($result);
	#$self->logDebug("tags", $tags);

	my $versions = [];
	foreach my $tag ( @$tags ) {
		push @$versions, $tag->{name};
	}
	$versions = $self->sortVersions($versions);
	#$self->logDebug("versions", $versions);

	#### SORT: FIRST TO LAST
	@$versions = reverse(@$versions);
	$self->logDebug("versions", $versions);
	
	return $versions;	
}

method sortVersions ($versions) {
	sub splitStringNumber () {
		my $string		=	shift;
		#$self->logDebug("string", $string);
		my $stringObject = {};
		($stringObject->{string}) = $string =~ /^([^\d^\.]+)/;
		($stringObject->{number}) = $string =~ /(\d+)$/;

		return $stringObject;
	}
	
	sub compareStringNumber () {
		my $a		=	shift;
		my $b		=	shift;
		#$self->logDebug("a", $a);
		#$self->logDebug("b", $b);

		if ( $a !~ /(\d+)$/ and $b !~ /(\d+)$/ ) {
			my $compare = lc($a) cmp lc($b);
			#$self->logDebug("compare", $compare);
			return $compare;
		}
		else {
			my $aObject = &splitStringNumber($a);
			my $bObject = &splitStringNumber($b);
			#$self->logDebug("Object", $aObject);
			#$self->logDebug("Object", $bObject);

			if ( $aObject->{string} ne $bObject->{string} ) {
				my $compare = lc($a) cmp lc($b);
				return (-1 * $compare);
			}
			else {
				#print "comparing numbers\n";	
				if ( not defined $aObject->{number} and not defined $bObject->{number} ) {
					return 0;
				}
				elsif ( $aObject->{number} and not defined $bObject->{number} ) {
					return 1;
				}
				elsif ( $bObject->{number} and not defined $aObject->{number} ) {
					return -1;
				}
				elsif ( $aObject->{number} > $bObject->{number} ) {
					#print "a is larger than a\n";
					return 1;
				}
				elsif ( $bObject->{number} > $aObject->{number} ) {
					#print "b is larger than a\n";
					return -1;
				}
				else {
					return 0;
				}
			}
		}
	}

	sub parseVersion {
		my $version 	=	shift;
	
		$version =~
			/^(\d+)\.(\d+)\.(\d+)(-alpha[\.\d]*|-beta[\.\d]*|-rc[\.\d]*)?(\+build[\.\d]*|\+[\.\d]*)?/;
	
		my $object = {};
		$object->{major} 	= $1;
		$object->{minor} 	= $2;
		$object->{patch} 	= $3;
		$object->{release} 	= $4;
		$object->{build}  	= $5;
		$object->{build} =~ s/\.+//g if defined $object->{build};
		$object->{release} =~ s/\.+//g if defined $object->{release};
		$object->{build} =~ s/^[\+\.]// if defined $object->{build};
		$object->{release} =~ s/^\-// if defined $object->{release};
	
		return $object;
	}

	sub versionSort {

		my $aVersion = &parseVersion($a);
		my $bVersion = &parseVersion($b);
		
		if ( $aVersion->{major} > $bVersion->{major} )	{ return 1 }
		elsif ( $bVersion->{major} > $aVersion->{major} ) { return -1 }
		if ( $aVersion->{minor} > $bVersion->{minor} )	{ return 1 }
		elsif ( $bVersion->{minor} > $aVersion->{minor} ) { return -1 }
		if ( $aVersion->{patch} > $bVersion->{patch} )	{ return 1 }
		elsif ( $bVersion->{patch} > $aVersion->{patch} ) { return -1 }
		if ( ! $aVersion->{release} and ! $bVersion->{release}
			and ! $aVersion->{build} and ! $bVersion->{build} )	{ return 0 }
		
		if ( $aVersion->{release} and ! $bVersion->{release} )	{ return -1 }
		if ( $bVersion->{release} and ! $aVersion->{release} )	{ return 1 }
		
		if ( $aVersion->{release} and $bVersion->{release} ) {
			{ return &compareStringNumber($aVersion->{release}, $bVersion->{release}) }
		}
		
		if ( $aVersion->{build} and ! $bVersion->{build} )	{ return 1 }
		if ( $bVersion->{build} and ! $aVersion->{build} )	{ return -1 }
		if ( $aVersion->{build} and $bVersion->{build} ) {
			return &compareStringNumber($aVersion->{build}, $bVersion->{build});
		}
		
		return 0;
	}
	
	@$versions = sort versionSort @$versions;
	
	return $versions;
}

method opsCommand ($owner, $username, $repository, $package, $privacy, $installdir, $version, $opsdir) {
	#### GET LATEST VERSION	
	my $ops 	= 	"$Bin/../logic/ops.pl";
	my $command = qq{$ops \\
$repository install \\
--owner $owner \\
--login $owner \\
--username $username \\
--repository $repository \\
--package $package \\
--privacy $privacy \\
--installdir $installdir \\
--logfile /tmp/agua-$repository.install.log \\
};
	$command .= "--version $version \\\n" if defined $version;
	$command .= "--opsdir $opsdir\n" if defined $opsdir;

	$self->logDebug("command", $command);

	return $command;
}

#### GENERIC PACKAGE
method install {
    my $installdir	= 	$self->installdir() || $self->conf()->getKey("agua", "INSTALLDIR");
	my $opsrepo 	= 	$self->opsrepo() || $self->conf()->getKey("agua", "OPSREPO");
	my $appsdir		= 	$self->conf()->getKey("agua", "APPSDIR");
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");

	#### GET OPSFILE AND PMFILE
	my $opsfile		=	$self->opsfile();
	$self->logDebug("opsfile", $opsfile);
	my $pmfile		=	$self->pmfile();
	$self->logDebug("pmfile", $pmfile);

	#### SET PACKAGE DETAILS
	my $package		=	$self->package();
	print "Deploy::install    package not defined. Exiting\n" and return if not defined $package;
	
	#### SET VARIABLES FROM OPS INFO
	my $login 		=	$self->login() || "agua";
	my $owner 		=	$self->owner();
	my $privacy		=	$self->privacy() || "public";
	my $repository 	=	$self->repository();
	$self->logDebug("login", $login);
	$self->logDebug("owner", $owner);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("repository", $repository);

	#### SET OPSDIR
	my $opsdir;
    my $basedir		= 	$self->conf()->getKey("agua", "INSTALLDIR");
	if ( defined $opsfile ) {
		($opsdir) =	$opsfile =~ /^(.+?)\/[^\/]+$/;
	}
	if ( not defined $opsfile ) {
		my $aguauser	= 	$self->conf()->getKey("agua", "AGUAUSER");
		$opsdir		=	"$installdir/repos/$privacy/$aguauser/$opsrepo/$aguauser/$package";		
	}
	$self->logDebug("opsdir", $opsdir);	
	
	#### SET VERSION
	my $version		=	$self->version();
	$self->logDebug("version", $version);

	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("login", $login);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);

	#### RESET INSTALLDIR
	$installdir = "$installdir/$appsdir/$package";
	
	return $self->installApplication($owner, $login, $username, $repository, $package, $privacy, $installdir, $pmfile, $opsdir, $version);	
}

#### BIOAPPS
method bioapps {
    my $installdir	= 	$self->conf()->getKey("agua", "INSTALLDIR");
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $repository	=	$self->conf()->getKey("agua", "APPSPACKAGE");
	my $package 	= 	$self->conf()->getKey("agua", "APPSPACKAGE");
	my $appsdir		= 	$self->conf()->getKey("agua", "APPSDIR");
	my $login		=	$self->login();
	my $owner		=	"agua";
	my $privacy		=	"public";
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/$privacy/$owner/$opsrepo/$owner/$package";
	my $pmfile		=	"$opsdir/bioapps.pm";

	#### SET VERSION
	my $version		=	$self->version();
	$self->logDebug("version", $version);

	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("pmfile", $pmfile);

	return $self->installApplication($owner, $login, $username, $repository, $package, $privacy, "$installdir/$appsdir/$package", $pmfile, $opsdir, $version);	
}

#### EMBOSS
method emboss {
	my $repository	=	"emboss";
	my $package 	= 	"emboss";
	my $login		=	$self->login();
	my $owner		=	"agua";
	my $privacy		=	"public";
    my $installdir	= 	$self->conf()->getKey("agua", "INSTALLDIR");
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $appsdir		= 	$self->conf()->getKey("agua", "APPSDIR");
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/$privacy/$owner/$opsrepo/$owner/$package";
	my $pmfile		=	"$opsdir/emboss.pm";

	#### SET VERSION
	my $version		=	$self->version();
	$self->logDebug("version", $version);

	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("pmfile", $pmfile);

	return $self->installApplication($owner, $login, $username, $repository, $package, $privacy, "$installdir/$appsdir/$package", $pmfile, $opsdir, $version);	
}

#### STARCLUSTER
method starcluster {
    my $installdir	= 	$self->conf()->getKey("agua", "INSTALLDIR");
	$self->logDebug("installdir", $installdir);

	require Conf::Yaml;
	my $conf 		= 	Conf::Yaml->new({inputfile=>"$Bin/../../conf/config.yaml"});
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $login		=	$self->login();
	my $repository	=	"StarCluster";
	my $package 	= 	"starcluster";
	my $owner		=	"agua";
	my $privacy		=	"public";
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/public/$owner/$opsrepo/$owner/$package";
	my $pmfile		=	"$opsdir/bioapps.pm";

	#### SET VERSION
	my $version		=	$self->version();
	$self->logDebug("version", $version);

	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);
	$self->logDebug("pmfile", $pmfile);

	return $self->installApplication($owner, $login, $username, $repository, $package, $privacy, "$installdir/apps/starcluster", $pmfile, $opsdir, $version);	
}


#### SUN GRID ENGINE
method sge {
	print "Agua::Installer::sge    Installing SGE\n";

	#### SET SGE ROOT	
	my $sgeroot = $self->conf()->getKey('cluster', 'SGEROOT');
	$self->logDebug("sgeroot", $sgeroot);

	#### RETURN IF SGE ROOT EXISTS
	if ( -d $sgeroot ) {
		print "Agua::Installer::sge    SGE root already present. Skipping install.\n";
		return;
	}

	#### SET TARGET DIR
	my ($targetdir) = $sgeroot =~ /^(.+)\/[^\/]+$/;
	
	#### SET SOURCE
	my $sourcefile	=	"sge6.tar.gz";
	my $s3bucket	=	$self->conf()->getKey("agua", "S3BUCKET");
	my $source = "$s3bucket/$sourcefile";
	$self->logDebug("source", $source);
	
	#### INSTALL
	my $command = "cd $targetdir; wget --no-check-certificate $source; tar xvfz $sourcefile\n";
	$self->logDebug("command", $command);
	`$command`;
}



}

