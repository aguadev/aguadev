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
use Conf::Agua;

# Booleans
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );

# Strings
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'dumpfile'		=> ( isa => 'Str|Undef', is => 'rw' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'user'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'password'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

# Objects
has 'db'			=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 			=> (
	is =>	'rw',
	isa => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####/////}

method BUILD ($hash) {
	#$self->logDebug("Agua::Deploy::BUILD()");
	$self->logDebug("self", $self);
	$self->initialise();
}

method initialise {	

    my $conf 		= 	Conf::Agua->new({inputfile=>"$Bin/../../conf/default.conf"});

	
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
	$self->tests();

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

    #### CREATE PARENT DIR
    my $parentdir 	= 	"$basedir/repos/public";
    `mkdir -p $parentdir` if not -d $parentdir;
    print "Can't create parentdir: $parentdir" and exit if not -d $parentdir;

    return $self->installApplication($owner, $username, $opsrepo, $opspackage, $privacy, $installdir, undef);
}

method installApplication ($owner, $username, $repository, $package, $privacy, $installdir, $opsdir) {
	my $versions 	=	$self->getVersions($owner, $repository, $privacy);
	my $version = shift @$versions;
	my $command = $self->opsCommand($owner, $username, $repository, $package, $privacy, $installdir, $version, $opsdir);
	print `$command`;
}

method getVersions ($owner, $repository, $privacy) {
	#### GET LATEST VERSION	
	my $ops 	= 	"$Bin/../logic/ops.pl";
	my $command = qq{$ops \\
$repository getRemoteTags $owner $repository $privacy
};
	$self->logDebug("command", $command);
	my $result = `$command`;	
	$self->logDebug("result", $result);

	my $parser = JSON->new();
	my $tags = $parser->decode($result);
	#print "Agua::Installer::getVersions    tags: \n";
	#print Dumper $tags;
	
	my $versions = [];
	foreach my $tag ( @$tags ) {
		push @$versions, $tag->{name};
	}
	$self->logDebug("versions", $versions);
	$versions = $self->sortVersions($versions);
	$self->logDebug("POST-sortVersions    versions", $versions);
	
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
				return $compare;
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
		$object->{build} =~ s/^\+// if defined $object->{build};
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

#### BIOAPPS
method bioapps {
    my $installdir	= 	$self->conf()->getKey("agua", "INSTALLDIR");
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $repository	=	$self->conf()->getKey("agua", "APPSPACKAGE");
	my $package 	= 	$self->conf()->getKey("agua", "APPSPACKAGE");
	my $owner		=	"agua";
	my $privacy		=	"public";
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/public/$owner/$opsrepo/$owner/$package";
	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);

	return $self->installApplication($owner, $username, $repository, $package, $privacy, "$installdir/$package", $opsdir);	
}

#### STARCLUSTER
method starcluster {
    my $installdir	= 	$self->conf()->getKey("agua", "INSTALLDIR");
	$self->logDebug("installdir", $installdir);

	require Conf::Agua;
	my $conf 		= 	Conf::Agua->new({inputfile=>"$Bin/../../conf/default.conf"});
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $repository	=	"StarCluster";
	my $package 	= 	"starcluster";
	my $owner		=	"agua";
	my $privacy		=	"public";
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/public/$owner/$opsrepo/$owner/starcluster";
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);

	return $self->installApplication($owner, $username, $repository, $package, $privacy, "$installdir/apps/starcluster", $opsdir);	
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
	my $installdir = $self->conf()->getKey('agua', 'INSTALLDIR');
	$self->logDebug("installdir", $installdir);
	my $tarfile = "$installdir/bin/scripts/resources/sge/sge6.tar.gz";
	
	my $command = "cd $targetdir; tar xvfz $tarfile\n";
	$self->logDebug("command", $command);
	`$command`;
}



#### AGUA TESTS
method tests {
    my $basedir		= 	$self->conf()->getKey("agua", "INSTALLDIR");
	my $installdir 	= 	"$basedir/t";
	my $opsrepo 	= 	$self->conf()->getKey("agua", "OPSREPO");
	my $repository	=	"aguatest";
	my $package 	= 	"aguatest";
	my $owner		=	"agua";
	my $privacy		=	"public";
	my $username 	= 	$self->conf()->getKey("agua", "ADMINUSER");
	my $opsdir 		=	"$installdir/repos/public/$owner/$opsrepo/$owner/$package";
	$self->logDebug("basedir", $basedir);
	$self->logDebug("installdir", $installdir);
	$self->logDebug("repository", $repository);
	$self->logDebug("package", $package);
	$self->logDebug("owner", $owner);
	$self->logDebug("username", $username);
	$self->logDebug("privacy", $privacy);
	$self->logDebug("opsdir", $opsdir);

	return $self->installApplication($owner, $username, $repository, $package, $privacy, $installdir, $opsdir);	
	
}

}



