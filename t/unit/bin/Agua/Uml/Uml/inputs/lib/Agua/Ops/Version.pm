package Agua::Ops::Version;
use Moose::Role;
use Method::Signatures::Simple;
use JSON;

=head3	PACKAGE		Version
	
PURPOSE

    1. UPDATE THE VERSION NUMBER, PRE-RELEASE LABEL OR BUILD IN
    
        THE VERSION FILE ACCORDING TO THE PROVIDED UPDATE TYPE
        
    2. PRINT THE USER-SUPPLIED DESCRIPTION TO THE VERSION FILE 
    
    3. ADD THE DATETIME TO THE VERSION FILE
    
    4. ADD A TAG USING THE WHOLE VERSION AND DESCRIPTION

INPUT

    1. BASE DIR OF git REPOSITORY
    
    2. UPDATE TYPE: major, minor, patch OR build

    3. (OPTIONAL) RELEASE NAME

    3. DESCRIPTION OF VERSION
    
OUTPUT

    1. UPDATED VERSION FILE IN BASE DIR OF git REPOSITORY
    
    2. GIT COMMITTED TAG CONTAINING WHOLE VERSION AND DESCRIPTION

NOTES

    ONLY USE THIS APPLICATION IF YOU WANT TO CREATE A NEW TAG TO RELEASE
    
    BUG FIXES (PATCH), NEW FEATURES (MINOR VERSION) OR API-RELATED CHANGES
    
    {MAJOR VERSION), OR TO MARK A PRE-RELEASE VERSION (RELEASE) OR A SMALL 
    
    INCREMENTAL IMPROVEMENT ON ANY OF THE ABOVE (BUILD).
    
    IF NONE OF THE ABOVE APPLY, DO NOT USE THIS APPLICATION. INSTEAD, TRACK
    
    CHANGES WITH 'git log' USING THE COMMIT ITERATION COUNTER, BUILD ID AND COMMENTS.

LICENCE

This code is released under the MIT license, a copy of which should
be provided with the code.

=cut

use strict;
use warnings;

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Data::Dumper;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Agua::Ops;

#### Strings
has 'versionformat'	=> ( isa => 'Str', is  => 'rw',  default	=>	'semver'	);

#####////}}}}

#### SORT VERSIONS
method sortVersions ($versions) {
	$self->logCaller("");
	$self->logNote("BEFORE versions: @$versions");

	sub splitStringNumber () {
		my $string		=	shift;
		#print "splitStringNumber    string: $string\n";
		my $stringObject = {};
		($stringObject->{string}) = $string =~ /^([^\d^\.]+)/;
		($stringObject->{number}) = $string =~ /(\d+)$/;

		return $stringObject;
	}
	
	sub compareStringNumber () {
		my $a		=	shift;
		my $b		=	shift;
		#print "compareStringNumber    a: $a\n";
		#print "compareStringNumber    b: $b\n";

		if ( $a !~ /(\d+)$/ and $b !~ /(\d+)$/ ) {
			my $compare = lc($a) cmp lc($b);
			#print "compareStringNumber    compare: $compare\n";
			return $compare;
		}
		else {
			my $aObject = &splitStringNumber($a);
			my $bObject = &splitStringNumber($b);
			#print "aObject: $aObject\n";
			#print "bObject: $bObject\n";

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
		$object->{release} 	= '' if not defined $object->{release};
		$object->{build}  	= '' if not defined $object->{build};
	
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
			my $compare = &compareStringNumber($aVersion->{release}, $bVersion->{release});
			#print "compareStringNumber(aVersion->release, bVersion->release): $compare\n";
			return $compare if $compare != 0;
			return 0 if ! $aVersion->{build} and ! $bVersion->{build};
		}
		
		if ( $aVersion->{build} and ! $bVersion->{build} )	{ return 1 }
		if ( $bVersion->{build} and ! $aVersion->{build} )	{ return -1 }
		if ( $aVersion->{build} and $bVersion->{build} ) {
			return &compareStringNumber($aVersion->{build}, $bVersion->{build});
		}
		
		return 0;
	}
	
	@$versions = sort versionSort @$versions if defined $versions and scalar(@$versions) > 1;
	$self->logNote("AFTER versions @$versions");
	
	return $versions;
}

method higherVersion ($version1, $version2) {
#### BASIC NUMBER COMPARISON OR STRING/NUMBER COMPARISON

	$self->logDebug("PASSED version1", $version1);
	$self->logDebug("PASSED version2", $version2);
	
	if ( $version1 =~ /^\d+(\.\d+)?$/ and $version2 =~ /^\d+(\.\d+)?$/ ) {
		
		return 1 if $version1 > $version2;
		return 0;
	}
	
	my $comparison = &compareStringNumber($version1, $version2);

	return 1 if $comparison > 0;
	return 0;
}

method higherSemVer ($version1, $version2) {
	$self->logDebug("PASSED version1", $version1);
	$self->logDebug("PASSED version2", $version2);

	#### REMOVE ANYTHING AFTER +build.\d+
	$version1 =~ s/(build\.\d+)\..+$/$1/;
	$version2 =~ s/(build\.\d+)\..+$/$1/;
	#$self->logDebug("version1", $version1);
	#$self->logDebug("version2", $version2);
	
	return 0 if $version1 eq $version2;
	return 1 if defined $version1 and not defined $version2;
	return -1 if not defined $version1 and defined $version2;
	
	my $array = [ $version1, $version2 ];
	my @temp = @$array;
	my $sortedarray;
	if ( $#temp > 0 ) {
		$sortedarray = $self->sortVersions(\@temp);
	}
	elsif ( $#temp == 0 ) {
		$sortedarray = [$temp[0]];
	}
	$self->logDebug("array: @$array");
	$self->logDebug("sortedarray: @$sortedarray");
	
	if ( $self->arraysHaveSameOrder($array, $sortedarray) ) {
		$self->logDebug("returning -1");
		return -1;
	}
	else {
		$self->logDebug("returning 1");
		return 1;
	}
}

method arraysHaveSameOrder ($arrayA, $arrayB) {
	if ( scalar(@$arrayA) != scalar(@$arrayB) ) { return 0; }
	
	for (my $i = 0; $i < @$arrayA; $i++) {
		if ($$arrayA[$i] ne $$arrayB[$i]) { 
			return 0;
		}
	}
	return 1;
}


#### SET VERSION
method setVersion ($versionformat, $repodir, $versionfile, $branch, $version, $description) {
	$self->logDebug("");
	return $self->setSemVer($repodir, $versionfile, $branch, $version, $description) if $versionformat eq "semver";
	return $self->setNonSemVer($repodir, $versionfile, $branch, $version, $description);
}

method _setVersion($repodir, $versionfile, $branch, $version, $description) {
	$self->logCaller("");
	$self->logDebug("repodir", $repodir);
	$self->logDebug("versionfile", $versionfile);
	$self->logDebug("branch", $branch);
	$self->logDebug("version", $version);
	$self->logDebug("description", $description);

	#### WRITE VERSION FILE
	$self->printToFile($versionfile, $version);

	#### REMOVE LOCK IF PRESENT
	my $lockfile = "$repodir/.git/index.lock";
	`rm -fr $lockfile` if -f $lockfile;
	$self->logWarning(qq{Could not remove lockfile: $lockfile\nRun this command to commit: git commit -a -m "$description"}) if -f $lockfile;

	#### ADD CHANGED VERSION TO REPO
	$self->addToRepo();
	
	#### COMMIT CHANGES
	$self->commitToRepo("[$version] $description");

	return ($version, undef);
}

method getCurrentVersion ($repodir, $branch) {
	$self->logDebug("");

	#### GET CURRENT VERSION TAG
	$self->changeToRepo($repodir);
	my $command = "git describe --abbrev=0 --tag";
	$self->logDebug("command", $command);
	my ($version) = $self->runCommand($command);
	
	$self->logDebug("Returning current version", $version);
	return $version;
}

method setSemVer ($repodir, $versionfile, $branch, $version, $description) {
	$self->logDebug("version", $version);
	return if not $self->isSemVer($version);

	#### GET CURRENT VERSION
	my $currentversion = $self->getCurrentVersion($repodir, $branch);
	$self->logDebug("currentversion", $currentversion);
	
	my $error;
	($version, $error) = $self->validateSemVer($currentversion, $version);
	return (undef, $error) if not defined $version;

	#### SET VERSION
	return $self->_setVersion($repodir, $versionfile, $branch, $version, $description);
}

method setNonSemVer ($repodir, $versionfile, $branch, $version, $description) {
	#### GET CURRENT VERSION
	my $currentversion = $self->getCurrentVersion($repodir, $branch);
	#$self->logDebug("currentversion", $currentversion);	

	#### RETURN IF VERSIONS ARE THE SAME
	return if $version eq $currentversion;
	
	#### RETURN IF VERSION IS LOWER THAN THE CURRENT VERSION
	return if not $self->higherVersion($version, $currentversion);
	
	#### SET VERSION
	return $self->_setVersion($repodir, $versionfile, $branch, $version, $description);
}

method validateSemVer ($currentversion, $version) {
	if ( defined $currentversion and $currentversion) {
		#### REMOVE ANYTHING AFTER +build.\d+
		my $version1 = $version;
		my $version2 = $currentversion;
		$version1 =~ s/(build\.\d+)\..+$/$1/;
		$version2 =~ s/(build\.\d+)\..+$/$1/;
		$self->logDebug("version1", $version1);
		$self->logDebug("version2", $version2);

		#### RETURN IF VERSIONS ARE THE SAME
		return (undef, "Current version $currentversion is the same as specified version: $version") if $version1 eq $version2;
		
		#### RETURN IF VERSION IS LOWER THAN THE CURRENT VERSION
		$self->logDebug("self->higherSemVer($version1, $version2) ", $self->higherSemVer($version1, $version2));
		if ( $self->higherSemVer($version1, $version2) == 0 ) {
			return (undef, "Cannot set version because current version $currentversion is identical to specified version: $version");
		}
		elsif ( $self->higherSemVer($version1, $version2) < 0 ) {
			return (undef, "Cannot set version because current version $currentversion is higher than specified version: $version");
		}
	}

	return ($version, undef);	
}

method isSemVer ($version) {
	$self->logDebug("");
	
	#### PARSE OUT VERSIONS	
	my ($major, $minor, $patch, $release, $build) = $self->parseSemVer($version);
	#$self->logDebug("major", $major);
	#$self->logDebug("minor", $minor);
	#$self->logDebug("patch", $patch);
	#$self->logDebug("release", $release);
	#$self->logDebug("build", $build);

	return -1 if not defined $major or not $major;
	return -1 if not defined $minor or not $minor;
	return -1 if not defined $patch or not $patch;
	return -1 if not $release =~ /^(-alpha\.\d+|-beta\.\d+|-rc\.\d+)$/;
	return -1 if not $build =~ /^\+build\.\d+$/;	
	return 1;
}


#### INCREMENT VERSION
method incrementVersion ($versionformat, $versiontype, $repodir, $versionfile, $releasename, $description, $branch) {
	#### GET CURRENT VERSION
	my $currentversion = $self->getCurrentVersion($repodir, $branch);
	$self->logCritical("No current version found") and exit if not defined $currentversion or not $currentversion;

	#### INCREMENT VERSION	
	my $finalversion;
	if ( $versionformat eq "semver" ) {
		$finalversion = $self->incrementSemVer($currentversion, $versiontype, $releasename);
	}
	else {
		$self->logDebug("Cannot increment version because versionformat not supported: ", $versionformat);
	}
	$self->logDebug("finalversion", $finalversion);

	#### MAKE CHANGES IF VERSION IS DEFINED
	return $self->_setVersion($repodir, $versionfile, $branch, $finalversion, $description) if defined $finalversion;
	return;
}

method incrementSemVer ($currentversion, $versiontype, $releasename) {
#$self->logDebug("versiontype", $versiontype);
#$self->logDebug("releasename", $releasename);

	#### PARSE OUT VERSIONS	
	my ($major, $minor, $patch, $release, $build) = $self->parseSemVer($currentversion);
	$self->logDebug("major", $major);
	$self->logDebug("minor", $minor);
	$self->logDebug("patch", $patch);
	$self->logDebug("release", $release);
	$self->logDebug("build", $build);
	$self->logCritical("major version not defined in current version: $currentversion") and exit if not defined $major;
	$self->logCritical("minor version not defined in current version: $currentversion") and exit if not defined $minor;
	$self->logCritical("patch version not defined in current version: $currentversion") and exit if not defined $patch;

	#### SANITY CHECK
	if ( not defined $major ) {
		$self->logDebug("major version not defined");
		return;
	}

	if ( defined $releasename and $releasename ) {
		#### VERSION TYPE CANNOT release IF RELEASE NAME IS DEFINED
		if ( defined $versiontype and $versiontype eq "release" ) {
			$self->logWarning("versiontype cannot be 'release' if releasename is defined: $releasename");
			return;
		}

		#### VERSION TYPE MUST BE DEFINED IF RELEASE NAME IS DEFINED
		#### OK 		--versiontype major --releasename alpha		1.0.0 -> 2.0.0-alpha.1
		#### NOT OK		--releasename alpha				1.0.0  --XXXXX--> 1.0.0-alpha.1  !!!!!
		if ( not defined $versiontype and not $release ) {
			$self->logWarning("versiontype must be defined if releasename is defined");
			return;
		}
	
		#### MUST BE MAJOR, MINOR OR PATCH INCREMENT IF RELEASE NAME IS DEFINED AND NO RELEASE
		#### OK 		--versiontype major --releasename alpha	1.0.0 -> 2.0.0-alpha.1
		#### OK 		--versiontype build --releasename beta	1.0.0-alpha.1 ---> 1.0.0-beta.1+build1
		#### NOT OK 	--versiontype build --releasename alpha	1.0.0+build1 --XXX-> 1.0.0-alpha.1+build1
		#### NOT OK		--releasename alpha				1.0.0  --XXXXX--> 1.0.0-alpha.1  !!!!!
		my $isversion = 1;
		$isversion = 0 if
			defined $versiontype 
			and not $versiontype eq "major"
			and not $versiontype eq "minor"
			and not $versiontype eq "patch";
				
		if ( defined $versiontype
			and not $isversion
			and not $release
		) {
			$self->logWarning("versiontype must be major, minor or patch if releasename is defined");
			return;
		}

		if ( not $isversion
			and (
					( $releasename eq "alpha" and $release =~ /^(alpha|beta|rc)/ )
				or ( $releasename eq "beta" and $release =~ /^(beta|rc)/ )
				or ( $releasename eq "rc" and $release =~ /^rc/ )
			)
		) {
			$self->logWarning("releasename '$releasename' must be > current release: $release");
			return;
		}		

		if ( not defined $versiontype
			and (
					( $releasename eq "alpha" and $release =~ /^(alpha|beta|rc)/ )
				or ( $releasename eq "beta" and $release =~ /^(beta|rc)/ )
				or ( $releasename eq "rc" and $release =~ /^rc/ )
			)
		) {
			$self->logWarning("releasename '$releasename' must be > current release: $release");
			return;
		}		
	}

	#### INCREMENT VERSION IF VERSION TYPE IS DEFINED
	if ( defined $versiontype ) {
		if ( $versiontype eq "major" ) {
			$major++ ;
			$minor = 0;
			$patch = 0;
			$build = '';
			$release = '';
		}
		elsif ( $versiontype eq "minor" ) {
			$minor++;
			$patch = 0;
			$build = '';
			$release = '';
		}
		elsif ( $versiontype eq "patch" ) {
			$patch++;
			$build = '';
			$release = '';
		}
		elsif ( $versiontype eq "release") {
			if ( not defined $release or not $release ) {
				$self->logWarning("release must be defined if versiontype is release");
				return;
			}
			else {
				$release = $self->incrementMixed($release);
			}
		}
		elsif ( $versiontype eq "build" ) {
			if ( not $build ) {
				$build = "build.1";
			}
			else {
				#$self->logDebug("BEFORE build", $build);
				$build = $self->incrementMixed($build);
				$self->logDebug("AFTER incrementMixed, build", $build);
			}
		}
	}

	#### IF RELEASE NAME AND VERSION TYPE ARE DEFINED, JUST ATTACH THE
	#### RELEASE TO THE INCREMENTED VERSION TYPE
	####
	#### E.G., MAJOR VERSION WITH RELEASE NAME alpha:
	####
	#### 	0.9.2 -> 1.0.0-alpha
	####
	if ( defined $releasename ) {
		$release = $releasename;
		$release = $release . ".1" if $release !~ /\d+$/;
	}

	#### FINAL VERSION
	my $finalversion = "$major.$minor.$patch";
	$finalversion .= "-$release" if $release;
	$finalversion .= "+$build" if defined $versiontype and $versiontype eq "build";
	$self->logDebug("finalversion", $finalversion);

	return $finalversion;
}

method incrementMixed ($version) {
	my ($symbol, $number) = $version =~ /^(.*)(\d+)$/;
	$symbol = '' if not defined $symbol;
	$number = 0 if not defined $number;
	$number++;
	$version = $symbol . $number;

	return $version;
}


method parseSemVer ($version) {
	#$self->logDebug("version", $version);
	$version =~
		/^(\d+)\.(\d+)\.(\d+)(-alpha[\.\d]*|-beta[\.\d]*|-rc[\.\d]*)?(\+build[\.\d]*|\+[\.\d]*)?/;
	my $major 	= $1;
	my $minor 	= $2;
	my $patch 	= $3;
	my $release = $4;
	my $build  	= $5;

#$self->logDebug("major", $major);
#$self->logDebug("minor", $minor);
#$self->logDebug("patch", $patch);
#$self->logDebug("release", $release);
#$self->logDebug("build", $build);
	
	$release =~ s/^-// if defined $release;
	$build =~ s/^\+// if defined $build;
	$build =~ s/\.$// if defined $build;
	$release = '' if not defined $release;
	$build = '' if not defined $build;
	
	
	return ($major, $minor, $patch, $release, $build);
}

method getCommitCount ($repodir) {
	print "repodir is a file\n" and exit if -f $repodir;
	chdir($repodir) or die "Can't chdir to repodir: $repodir\n";
	my $iteration = `git log --pretty=format:'' | wc -l`;
	$iteration =~ s/\s+//g;
	$iteration = "0" x ( 5 - length($iteration) ) . $iteration;
	
	return $iteration;	
}

method getBuildId ($repodir) {
	#### 2. GET THE SHORT SHA KEY AS THE BUILD ID
	my $command = "git rev-parse --short HEAD";
	my $buildid = $self->repoCommand($command);
	$buildid =~ s/\s+//g;
	print "buildid: $buildid\n";
	
	return $buildid;
}

method createVersionDir ($repodir, $package, $version) {
#### CREATE THE PACKAGE DIR AND VERSION SUBDIR
	my $versiondir = "$repodir/$package/$version";
	`mkdir -p $versiondir`;
	print "Can't create versiondir: $versiondir\n"
    and exit if not -d $versiondir;
}




1;