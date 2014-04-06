use MooseX::Declare;

use strict;
use warnings;

class GT::Fuse with Agua::Common::Logger {

#####////}}}}}

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 2 );
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'uuid'			=> 	( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'gtrepo'		=> 	( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'keyfile'		=> 	( isa => 'Str|Undef', is => 'rw', default 	=> 	"cghub_public.pem" );
has 'keyurl'		=> 	( isa => 'Str|Undef', is => 'rw', default 	=> 	"https://cghub.ucsc.edu/software/downloads/cghub_public.pem" );
has 'cachedir'		=> 	( isa => 'Str|Undef', is => 'rw', default	=> 	"/tmp/fusecache");
has 'mountdir'		=> 	( isa => 'Str|Undef', is => 'rw', default	=>	"/tmp/fusemnt");
has 'gtrepo'		=>	( isa => 'Str|Undef', is => 'rw', default	=>	"https://cghub.ucsc.edu/cghub/data/analysis/download");
has 'homedir'		=> 	( isa => 'Str|Undef', is => 'rw', lazy	=>	1, 	builder => 	"getHomeDir");

method mountSample ($uuid, $gtrepo) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("gtrepo", $gtrepo);
	
	print "uuid not defined.\n" and return if not defined $uuid;
	if ( not defined $gtrepo ) {
		$gtrepo	=	$self->gtrepo();	
		print "gtrepo not defined. Using default: $gtrepo\n";
	}

	my $cachedir	=	$self->cachedir();
	my $mountdir	=	$self->mountdir();
	$self->logDebug("cachedir", $cachedir);
	$self->logDebug("mountdir", $mountdir);	
	
	#### UNMOUNT
	$self->unmount($uuid, $mountdir);
	
	#### REMOVE OLD DIRECTORIES AND LOCK FILES
	$self->cleanUp($uuid, $cachedir, $mountdir);
	
	#### CREATE DIRECTORIES IF MISSING
	$self->createDirs($uuid, $cachedir, $mountdir);
	
	#### CREATE CONFIG
	my $configfile	=	$self->createConfigFile();
	
	#### MOUNT
	$self->mount($uuid, $gtrepo, $mountdir, $configfile);
}

method mount ($uuid, $gtrepo, $mountdir, $configfile) {
	$self->logDebug("uuid", $uuid);

	#### KILL LINGERING gtfuse PROCESSES
	$self->killZombies();

	my $command		= 	"cd $mountdir; gtfuse --config-file $configfile $gtrepo/$uuid $mountdir/$uuid";
	$self->logDebug("command", $command);

	$self->runCommand($command);
}

method killZombies {
	my $zombies	=	$self->getZombies();
	foreach my $zombie ( @$zombies ) {
		`kill -9 $zombie`;
	}
}

method getZombies {
	my $ps	=	$self->getPs();
	$self->logDebug("ps", $ps);
	
	my $zombies = [];
	foreach my $line ( @$ps ) {
		my @entries	=	split " ", $line;
		my $status	=	$entries[7];
		next if $status ne "T";
	
		push @$zombies, $entries[1];
	}
	
	return $zombies;	
}

method getPs {
	my $list	=	`ps aux | grep "gtfuse" | egrep "\\s+\\T\\s+"`;
	$self->logDebug("");
	
	my $ps;
	@$ps	=	split "\n", $list;
	$self->logDebug("ps", $ps);
	
	return $ps;
}

method cleanUp ($uuid, $cachedir, $mountdir) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("cachedir", $cachedir);
	$self->logDebug("mountdir", $mountdir);
	
	#### UNMOUNT AND REMOVE MOUNTDIR
	$self->unFuse($uuid, $mountdir);
	
	#### CLEAN UP FILES/DIRS
	$self->logDebug("cachedir", $cachedir);
	
	my $lockfile		=	"$cachedir/$uuid.lock";
	my $reservationfile	=	"$cachedir/$uuid.reservation";
	my $gtofile			=	"$cachedir/$uuid.gto";

	print $self->runCommand("rm -fr $lockfile") if -f $lockfile;
	print $self->runCommand("rm -fr $reservationfile") if -f $reservationfile;
	print $self->runCommand("rm -fr $gtofile") if -f $gtofile;

	#### REMOVE CACHECIR	
	my $uuiddir	=	"$cachedir/$uuid";
	print $self->runCommand("rm -fr $uuiddir") if -f $uuiddir;
}

method unFuse ($uuid, $mountdir) {
	$self->logDebug("mountdir", $mountdir);
	$self->logDebug("uuid", $uuid);
	my $uuidmount	=	"$mountdir/$uuid";
	$self->logDebug("uuidmount", $uuidmount);

	#### SKIP IF NOT MOUNTED
	my $containerdir	=	"$uuidmount/$uuid";
	$self->logDebug("containerdir", $containerdir);
	return if not -d $containerdir;

	my $command	=	"fusermount -u $uuidmount";
	$self->logDebug("command", $command);
	
	$self->runCommand($command);
}
method runCommand ($command) {
	$self->logDebug("command", $command);
	
	return `$command`;
}

method createDirs ($uuid, $cachedir, $mountdir) {
	$self->logDebug("uuid", $uuid);
	$self->logDebug("cachedir", $cachedir);
	
	$self->runCommand("mkdir -p $cachedir") if not -d $cachedir;
	
	my $uuidmount 	=	"$mountdir/$uuid";
	$self->runCommand("mkdir -p $uuidmount") if not -d $uuidmount;
}

method getHomeDir {
	return $ENV{"HOME"};
}

method getConfigFile ($homedir) {
	return "$homedir/.gtfuse.cfg"
}
method downloadKeyFile {
	my $keyfile	=	$self->keyfile();
	$self->logDebug("keyfile", $keyfile);
	
	my $homedir		=	$self->homedir();
	my $filepath	=	"$homedir/$keyfile";
	$self->runCommand("rm -fr $filepath");

	my $keyurl	=	$self->keyurl();
	$self->runCommand("cd $homedir; wget --no-check-certificate $keyurl");
}

method createConfigFile {
	my $homedir = $self->homedir();
	#$self->logDebug("homedir: $homedir\n");

	my $configfile	=	$self->getConfigFile($homedir);
	$self->logDebug("configfile", $configfile);
	my $cachedir	=	$self->cachedir();
	
	my $config = qq{credential-file=$homedir/cghub_public.pem
cache-dir=$cachedir/
gto-refresh-period=60
inactivity-timeout=2
log=syslog:standard
};
	
	open(OUT, ">", $configfile) or die "Can't open configfile: $configfile";
	print OUT $config;
	close(OUT) or die "Can't close configfile: $configfile";
	
	return $configfile;
}
method unmount ($uuid, $mountdir) {
	#### UNMOUNT
	$self->unFuse($uuid, $mountdir);

	#### REMOVE MOUNTDIR
	$self->runCommand("rm -fr $mountdir/$uuid");
}

method unmountSample ($uuid) {
	my $mountdir	=	$self->mountdir();
	$self->logDebug("uuid", $uuid);
	$self->logDebug("mountdir", $mountdir);
	
	$self->unFuse($uuid, $mountdir);
}



}

