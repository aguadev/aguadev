use MooseX::Declare;

=head3

PACKAGE		Init
	
PURPOSE
	
		CARRY OUT INITIAL Agua SETUP:
	
		1. CREATE, STOP/START/TERMINATE AND OTHERWISE MANAGE
		
			AWS AMIs, MANAGE VOLUMES AND OTHER RESOURCES

		2. STORE AWS CREDENTIALS INFO IN FILES

		3. STORE AWS CREDENTIALS INFO IN aws DATABASE TABLE

LICENCE

This code is released under the MIT license, a copy of which should
be provided with the code.

=cut

class Agua::Init with (Agua::Common::Aws,
	Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::Logger,
	Agua::Common::User,
	Agua::Common::Util) {
use strict;
use warnings;

#### EXTERNAL MODULES
use Data::Dumper;
use File::Copy::Recursive;
use File::Path;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Agua::Ops;

if ( 1 ) {
# Booleans
has 'SHOWLOG'			=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'PRINTLOG'			=>  ( isa => 'Int', is => 'rw', default => 5 );

#### Ints
has 'datavolumesize'	=> ( isa => 'Int', is  => 'rw',  required	=>	1, default => 0	);
has 'uservolumesize'	=> ( isa => 'Int', is  => 'rw',  required	=>	1, default => 0	);

#### Strings
has 'tempdir'			=> ( isa => 'Str', is => 'rw', default	=>	"/tmp"	);
has 'username'			=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'password'			=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'amazonuserid'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'awsaccesskeyid'	=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'awssecretaccesskey'=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'ec2publiccert'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'ec2privatekey'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'datavolume'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'uservolume'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'username'			=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'wwwuser'			=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'instanceid'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'privatefile'		=> ( isa => 'Str', is => 'rw', required	=>	0	);
has 'publicfile'		=> ( isa => 'Str', is => 'rw', required	=>	0	);

#### Objects
has 'db'	=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	'isa' => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);
has 'ops' 	=> (
	is 		=>	'rw',
	isa 	=>	'Agua::Ops',
	default	=>	sub { Agua::Ops->new();	}
);
	
}

#####////}}}}

method BUILD ($hash) {
	#### SET DATABASE HANDLE AND ENVIRONMENT VARIABLES
	$self->setDbh();
	$self->setEnvironment();

	#### CHECK FOR UNDEFINED ITEMS
	my $required_fields = ["username","password", "datavolume", "uservolume", "datavolumesize", "uservolumesize", "amazonuserid", "awsaccesskeyid", "awssecretaccesskey", "ec2publiccert", "ec2privatekey"];	
	my $undefined = $self->db()->notDefined($hash, $required_fields);
	$self->logError("Required variables not defined: @$undefined") and exit if @$undefined;

	#### SET OPS TEMPDIR
	$self->ops->tempdir($self->tempdir());
	$self->ops->SHOWLOG($self->SHOWLOG());
	$self->ops->PRINTLOG($self->PRINTLOG());	
}

method init {
=head2

	SUBROUTINE		init
	
	PURPOSE
	
		1. LOAD USER DATA INTO AGUA DATABASE

=cut

	$self->logDebug("");

	#### CHECK INITIALISED FLAG
	return if not $self->checkInitialised();
	
	#### SET HOSTNAME TO LONG INTERNAL IP
	print "Agua::Init::init    Setting hostname\n";
	$self->setHostname();
	
	#### SET STARTUP SCRIPT
	print "Agua::Init::init    Setting startup file\n";
	$self->setStartupScript();
	
	#### MOUNT /data VOLUME CONTAINING AGUA DATA
	print "Agua::Init::init    Mounting data volume\n";
	$self->mountData();
	
	#### MOUNT /nethome USER DATA 
	print "Agua::Init::init    Mounting user home volume\n";
	$self->mountUserHome();
	
	#### MOUNT MYSQL AND START
	print "Agua::Init::init    Mounting MySQL\n";
	$self->mountMysql();
	
	#### ADD nfs INFO TO /etc/fstab FOR LATER EXPORTS
	print "Agua::Init::init    Adding NFS info to /etc/fstab\n";
	$self->addNfsToFstab();
	
	#### CREATE ADMIN USER LINUX ACCOUNT AND AGUA ACCOUNT
	$self->addAdminUser();
	
	#### LINK JBROWSE USER DATA DIR
	print "Agua::Init::init    Linking JBrowse data directory\n";
	$self->linkJBrowseDir();
	
	#### CREATE KEYPAIR FILE FROM PRIVATE AND PUBLIC KEYS
	print "Agua::Init::init    Generating cluster keypair\n";
	$self->generateClusterKeypair();
	
	#### SET INITIALISED FLAG
	$self->conf()->setKey('agua', 'INITCOMPLETE', 1);
	
	#### REPORT COMPLETION
	print "Agua::Init::init    Completed init\n";
}

#### SET ENVIRONMENT
method setEnvironment {
####  SET EC2 ENVIRONMENT VARIABLES
	my $conf 		= 	$self->conf();
	
	#### GET KEYFILES
	my $username	=	$self->conf()->getKey("agua", 'ADMINUSER');	
    my $publicfile 	= $self->getEc2PublicFile($username);
	my $privatefile = $self->getEc2PrivateFile($username);

	$ENV{'EC2_PRIVATE_KEY'} 	= $privatefile;
	$ENV{'EC2_CERT'} 			= $publicfile;
	$ENV{'EC2_HOME'} 			= $conf->getKey("aws", "EC2HOME");
	$ENV{'EC2_AMITOOL_HOME'} 	= $conf->getKey("aws", "EC2HOME");
	$ENV{'EC2_APITOOL_HOME'} 	= $conf->getKey("aws", "EC2HOME");
	$ENV{'JAVA_HOME'} 			= $conf->getKey("aws", "JAVAHOME");
	my $path 					= $ENV{'PATH'};
	$path 						= $conf->getKey("aws", "EC2HOME") . "/bin:$path";
	$ENV{'PATH'} = $path;
}

#### CHECK INITIALISE
method checkInitialised {
	my $initcomplete = $self->conf()->getKey('agua', 'INITCOMPLETE');
	$self->logDebug("initcomplete", $initcomplete);
	
	print "Agua::Init::init     initcomplete flag is set. Quitting\n" and return 0 if defined $initcomplete and $initcomplete;
	return 1;
}

#### SET HOST NAME
method setHostname {
#### GET ALLOCATED ELASTIC IP OR SET ONE IF NOT ALREADY ALLOCATED
	$self->logDebug("");
	my $installdir = $self->conf()->getKey('agua', 'INSTALLDIR');
	$self->logDebug("installdir", $installdir);
	
	my $executable = "$installdir/bin/scripts/updateHostname.pl";
	$self->logDebug("executable", $executable);
	my $output = `$executable`;
	$self->logDebug("output", $output);
}

#### SET STARTUP SCRIPT
method setStartupScript () {
#### SET COMMANDS TO BE RUN AT STARTUP FROM STARTUP SCRIPT
	my $startupfile = "/etc/rc.local";
	$self->logDebug("startupfile", $startupfile);

	my $installdir = $self->conf()->getKey('agua', 'INSTALLDIR');
	my $source = "$installdir/bin/scripts/updateHostname.pl";
	
	my ($lines) = $self->ops()->fileLines($startupfile);
	#print "Agua::Init::setStartupScript    lines: @$lines\n";
	$lines = $self->ops()->removeLines($lines, "exit\\s*.*");
	#print "Agua::Init::setStartupScript    lines: @$lines\n";
	
	$lines = $self->ops()->addNoDups($lines,
		[
			"#### SET HOSTNAME",
			"$installdir/bin/scripts/updateHostname.pl",

			"#### RESTART apache2",
			"/etc/init.d/apache2 restart",
			
			##"#### AUTOMOUNT /data",
			##"mount -t ext3 /dev/sdh /data",
			##
			##"#### AUTOMOUNT /nethome",
			##"mount -t ext3 /dev/sdi /nethome",
	
			"#### EXIT 0 ON SUCCESS",
			"exit 0",
			"####  END ####"
	]);

	my $text = join "\n", @$lines;
	#print "Agua::Init::setStartupScript    text: $text\n";

	return $self->ops()->writeFile($startupfile, $text);	
}

#### IP ADDRESS
method getPublicIp {
	my $publicip = `/usr/bin/curl -s http://169.254.169.254/latest/meta-data/public-ipv4`;
	$self->logDebug("publicip", $publicip);

	return $publicip;
}

method getIp {
#### CALLED BY init.pl: GET ELASTIC IP OR SET ONE IF NOT ALREADY ALLOCATED
	$self->logDebug("");
	my $url = $self->getElasticIp();
	$self->logDebug("url", $url)  if defined $url;

	$url = $self->setElasticIp() if not defined $url or not $url;

	return $url;
}

method setElasticIp {
	$self->logDebug("");
	my $command = "ec2-describe-addresses";
	$self->logDebug("command", $command);
	# 	ADDRESS	54.243.227.131		standard		
	# 	ADDRESS	107.20.137.20		standard		
    #	ADDRESS	107.20.183.34		i-3ba8c35a
	my $string = `$command`;
	$self->logDebug("string", $string);
	my @lines = split "\n", $string;
  
	#### GET INSTANCE ID
	my $instanceid = `/usr/bin/curl -s http://169.254.169.254/latest/meta-data/instance-id`;
	$self->logDebug("instanceid", $instanceid);

	#### ASSOCIATE ELASTIC IP WITH INSTANCE:
	my $address = '';
	foreach my $line ( @lines )
	{
		if ( $line =~ /ADDRESS\s+(\S+)\s+$instanceid/ ) {
			$self->logDebug("MATCHED line", $line);
			$address = $1;
			last;
		}
	}
	$self->logDebug("address", $address);

	#### SET VALUE IN CONF AND RETURN VALUE IF ELASTIC IP IS ALREADY ALLOCATED
	$self->conf()->setKey('agua', '', "ELASTICIP", $address) and return $address if defined $address and $address;
	
	#### OTHERWISE, CREATE A NEW ELASTIC IP:
	$command = "ec2-allocate-address";
	$self->logDebug("command", $command);

    #### ADDRESS	107.20.183.34
	my $output = `$command`;
	$self->logDebug("output", $output);
	($address) = $output =~ /^ADDRESS\s+(\S+)/;
	$self->logDebug("FINAL address", $address);

	#### ASSOCIATE ELASTIC IP WITH INSTANCE:
	$command = "ec2-associate-address -i $instanceid $address";
	$self->logDebug("command", $command);
	print `$command`;
    #### ADDRESS	107.20.183.34	i-3ba8c35a

	#### SET VALUE IN CONF AND RETURN VALUE
	$self->logDebug("address", $address);
	$self->conf()->setKey('agua', '', "ELASTICIP", $address);

	return $address;
}

method getElasticIp {
#### GET ALL ELASTIC IPS
	$self->logDebug("");
	return $self->conf()->getKey('agua', "ELASTICIP");
}

method releaseElasticIp ($address) {
	my $command = "ec2-disassociate-address $address";
	$self->logDebug("command", $command);
	
	$command = "ec2-release-address $address";
	$self->logDebug("command", $command);
	
	print `$command`;
}

#### UPDATE /etc/fstab
method addNfsToFstab {
=head2

	SUBROUTINE		addNfsToFstab
	
	PURPOSE
	
		ADD nfs MOUNT INFO TO /etc/fstab. THE MOUNTPOINTS WILL 
		
		BE EXPORTED TO THE MASTER AND EXEC NODES OF EACH NEW
		
		STARCLUSTER.

=cut

	my $datadir 	= 	$self->conf()->getKey('agua', "DATADIR");
	my $userdir 	= 	$self->conf()->getKey('agua', "USERDIR");
	my $datadevice 	= 	$self->conf()->getKey("aws", "DATADEVICE");
	my $userdevice 	= 	$self->conf()->getKey('aws', "USERDEVICE");
	my $filetype  	=	"nfs";

	#### SET TO ALTERNATE DEVICE IF ORIGINAL DEVICE NOT PRESENT
	$datadevice = $self->ops()->alternateDevice($datadevice) if not -e $datadevice;
	$userdevice = $self->ops()->alternateDevice($userdevice) if not -e $userdevice;
	
	#### ADD TO FSTAB
	$self->addToFstab($datadevice, $datadir, $filetype, "$datadevice	$datadir	nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0");
	$self->addToFstab($userdevice, $userdir, $filetype, "$userdevice	$userdir	nfs     rw,vers=3,rsize=32768,wsize=32768,hard,proto=tcp 0 0");
}

method addToFstab ($device, $mountpoint, $filetype, $line) {
#### ADD A MOUNTPOINT TO FSTAB SO VOLUME DEVICE IS MOUNTED AUTOMATICALLY AFTER REBOOT
	$self->logDebug("device", $device);
	$self->logDebug("mountpoint", $mountpoint);
	$self->logDebug("filetype", $filetype);
	$self->logDebug("line", $line);
	
	#### CHECK INPUTS
	$self->logError("Agua::Init::addToFstab    device not defined") if not defined $device;
	$self->logError("Agua::Init::addToFstab    mountpoint not defined") if not defined $mountpoint;
	$self->logError("Agua::Init::addToFstab    filetype not defined") if not defined $filetype;

	#### LOAD OLD FSTAB INFO
	my $fstabfile = "/etc/fstab";
	open(FSTABBKP, $fstabfile) or die "Can't open backupfile: $fstabfile";
	my $fstab;
	@$fstab = <FSTABBKP>;
	close(FSTABBKP) or die "Can't close backupfile: $fstabfile\n";
	#### REMOVE EMPTY LINES AND NEW LINE
	for ( my $i = 0; $i < @$fstab; $i++ ) {
		if ( $$fstab[$i] =~ /^\s*$/ )
		{
			splice @$fstab, $i, 1;
			$i--;
		}
		$$fstab[$i] =~ s/\s+$//;
	}
	
	#### BACKUP FSTAB FILE
	my $counter = 1;
	my $backupfile = "$fstabfile.$counter";
	while ( -f $backupfile ) {
		$counter++;
		$backupfile = "$fstabfile.$counter";
	}
	print "Agua::Init::addToFstab    backupfile: $backupfile\n";
	rename $fstabfile, $backupfile;

	#### REMOVE EXISTING FSTAB LINE FOR THIS MOUNT POINT
	for ( my $i = 0; $i < @$fstab; $i++ ) {
		my ($current_device, $current_mountpoint, $current_filetype) = $$fstab[$i] =~ /^\s*(\S+)\s+(\S+)\s+(\S+)/;
		next if not defined $current_device or not defined $current_mountpoint; 
		next if $current_device =~ /^#/;
		
		if ( $current_device eq $device
			and $current_mountpoint eq $mountpoint ) {
			print "Agua::Init::addToFstab    splicing line $i: $$fstab[$i]\n";
			splice @$fstab, $i, 1;
			$i--;
		}
	}
		
	#### ADD NEW LINE
	push @$fstab, $line;
	for ( my $i = 0; $i < @$fstab; $i++ ) {
		$$fstab[$i] .= "\n";
	}

    #### PRINT TO FSTAB FILE
	open(FSTAB, ">$fstabfile") or die "AWS::addToFstab    Can't open fstabfile: $fstabfile\n";
	print FSTAB @$fstab;
	close(FSTAB) or die "AWS::addToFstab    Can't close fstabfile: $fstabfile\n";
}

#### PRINT KEYFILES
method printKeyFiles {
	my $username	=	$self->username();
	my $publiccert	=	$self->ec2publiccert();
	my $privatekey	=	$self->ec2privatekey();
	$self->logDebug("username", $username);
	$self->logNote("privatekey", $privatekey);
	$self->logNote("publiccert", $publiccert);
	
	$self->printEc2KeyFiles($username, $privatekey, $publiccert);
}

#### GENERATE CLUSTER KEYPAIR
method generateClusterKeypair {
#### CREATE KEYPAIR FILE FROM PRIVATE AND PUBLIC KEYS

	#### PASSED VARIABLES
	my $conf 			= 	$self->conf();
	my $username 		=	$self->username();

	#### SET KEYNAME
	my $keyname = "$username-key";

	#### SET FILES
	my $installdir 		= 	$conf->getKey('agua', "INSTALLDIR");
	my $privatekey		=	$self->getEc2PrivateFile($username);
	my $publiccert		=	$self->getEc2PublicFile($username);
	
	#### RUN starcluster.pl TO GENERATE KEYPAIR FILE IN .starcluster DIR
	my $starcluster = "$installdir/bin/cluster/starcluster.pl";
	my $command = qq{$starcluster generateKeypair \\
--privatekey $privatekey \\
--publiccert $publiccert \\
--keyname $keyname \\
--username $username
};
	print "$command\n";
	print `$command`;
}

#### MOUNT DATA VOLUME
method mountData {
=head2

	SUBROUTINE		mountData
	
	PURPOSE
	
		MOUNT /data VOLUME

	INPUTS
	
		USES AWS INFORMATION IN AGUA CONF FILE, E.G.:
		
		#### AWS
		DATASNAPSHOT       snap-55fe4a3f
		DATADIR     /data
		DATAVOLUMESIZE           40
		DATADEVICE         /dev/sdh

=cut

	my $mountpoint	= 	$self->conf()->getKey("agua", 'DATADIR');
	my $filetype	=	$self->conf()->getKey("aws", 'DATAFILETYPE');
	my $device 		= 	$self->conf()->getKey("aws", 'DATADEVICE');
	
	#### SANITY CHECK
	my $appsdir = "$mountpoint/apps";
	print "Agua::Init:mountData    Skipping mountData. appsdir present: $appsdir\n" and return if -d $appsdir;
	
	#### CONFIRM OR RESET DEVICE TO NEXT AVAILABLE
	$device = $self->nextAvailableDevice($device);
	$self->logDebug("Next available device", $device);

	#### SET VOLUME ID
	my $volumeid;
	my $datavolume	=	$self->datavolume();
	$self->logDebug("datavolume", $datavolume);
	if ( $datavolume =~ /^vol-/ ) {
		#### USE EXISTING VOLUME IF PROVIDED
		print "Agua::Init:mountData    Using provided volume: $datavolume\n";
		$volumeid = $datavolume;
	}
	else {
		#### OTHERWISE, CREATE VOLUME FROM SNAPSHOT
		print "Agua::Init:mountData    Creating data volume\n";
		$volumeid = $self->createDataVolume();
	}
	
	#### MAKE MOUNT POINT
	print "Agua::Init::mountData    Creating mountpoint.\n";
	$self->ops()->createMountPoint($mountpoint) if not -d $mountpoint;

	#### GET INSTANCE ID
	my $instanceid = $self->getInstanceId();
	print "Agua::Init::mountData    instanceid: $instanceid\n";

	#### ATTACH THE NEW VOLUME TO THE DEVICE
	print "Agua::Init::mountData    Attaching volume: $volumeid\n";
	my $attached = $self->ops()->attachVolume($instanceid, $volumeid, $device, $mountpoint);
	print "Agua::Init::mountData    attached: $attached\n";
	if ( $attached ne "attached" ) {
		print "Agua::Init::mountData    Can't attach volume: $volumeid to device: $device\n";
		print "Agua::Init::mountData    Possible problem with AWS instance. Use AWS console to STOP and then START this instance (i.e., not reboot)\n";
		exit;
	}

	#### CHECK THAT DEVICE IS PRESENT, CHANGE IF NECESSARY
	print "Agua::Init::mountData    Checking device is present: $device\n";
	$device = $self->ops()->checkDevice($device);
	
	#### MOUNT DEVICE TO MOUNTPOINT
	#### PAUSE TO ENSURE ATTACH IS SECURE
	while ( not -e $device ) {
		print "Agua::Init::mountData    Waiting for device to be ready: $device\n";
	    sleep(3); 
	}

	#### MOUNT DEVICE TO MOUNTPOINT
	print "Agua::Init::mountUserHome    Mounting volume.\n";
	my ($mountsuccess) = $self->ops()->mountVolume($device, $mountpoint, $filetype);
	print "Agua::Init::mountUserHome    Mount success: $mountsuccess\n";
	$self->logDebug("mountsuccess", $mountsuccess);

	#### ADD LINE TO FSTAB
	my $line = "$device	$mountpoint	$filetype	defaults,nobootwait	0	0\n";
	$self->addToFstab($device, $mountpoint, $filetype, $line);
	
	return $mountsuccess;
}

method nextAvailableDevice ($device) {
#### FORMAT: sdh, sdi, sdj, ...
	$self->logDebug("device", $device);
	$self->logError("Device format not supported: $device") and exit if not $device =~ /^\/dev\/[a-z]{3}$/;

	#### GET ALTERNATE DEVICE
	my $alternate = $self->ops()->alternateDevice($device);
	$self->logDebug("alternate", $alternate);
	
	#### RETURN IF NEITHER DEVICE NOR ALTERNATE IS PRESENT
	return $device if not -e $device and not -e $alternate;

	#### OTHERWISE, RETURN THE NEXT AVAILABLE DEVICE THAT IS NOT PRESENT	
	my $alphabet = "abcdefghijklmnopqrstuvwxyz";
	while ( -e $device or -e $alternate ) {
		$device =~ /([a-z])$/;
		my $letter	=	$1;
		$self->logDebug("letter", $letter);
		
		#### GET THE POSITION OF THE LETTER IN THE ALPHABET
		$alphabet =~ m/$letter/;
		my $position = $-[0];
		$position = ($position + 1) % 26;
		$self->logDebug("position", $position);
		
		my $replacement = substr($alphabet, $position, 1);
		$self->logDebug("replacement", $replacement);
		
		$device =~ s/.$/$replacement/;
		$self->logDebug("device", $device);
		
		#### DETACH IF ALTERNATE DEVICE PRESENT
		$alternate = $self->ops()->alternateDevice($device);
		$self->logDebug("alternate", $alternate);
	}
	
	return $device;
}

method createDataVolume {
	my $datavolume	=	$self->datavolume();
	my $size 		= 	$self->datavolumesize();
	my $username	= 	$self->username();
	print "Agua::Init::createDataVolume    datavolume: $datavolume\n";
	print "Agua::Init::createDataVolume    size: $size\n";

	my $availzone 	= 	$self->getAvailabilityZone();
    my $publicfile 	= 	$self->getEc2PublicFile($username);
	my $privatefile = 	$self->getEc2PrivateFile($username);
	$self->logDebug("availzone", $availzone);

	return $self->ops()->_createVolume($privatefile, $publicfile, $datavolume, $availzone, $size);
}

method detachAttached ($instanceid, $device) {
=head2

	SUBROUTINE		detachAttached
	
	PURPOSE
	
		DETACH AN EXISTING VOLUME ATTACHED TO A DEVICE (/dev/*** ) ON THE INSTANCE 
		
		OUTPUT FORMAT:
		
			VOLUME vol-7318ed1b    10      snap-f1453d9b   us-east-1a      in-use  2010-11-19T02:14:37+0000
			ATTACHMENT      vol-7318ed1b    i-10acc57d      /dev/sda1       attached        2010-11-19T04:02:54+0000
			VOLUME  vol-751eeb1d    40      snap-55fe4a3f   us-east-1a      available       2010-11-19T02:05:52+0000
			...
			VOLUME  vol-ed05f085    40      snap-55fe4a3f   us-east-1a      in-use  2010-11-19T02:27:52+0000
			
			ATTACHMENT      vol-ed05f085    i-10acc57d      /dev/sdh        attached        2010-11-19T04:02:54+0000

=cut

	my $attachedvolumeid;
	my @volumes = `ec2-describe-volumes`;
	my $alternatedevice = $self->ops()->alternateDevice($device);
	$self->logDebug("volumes: @volumes");
	$self->logDebug("checking volumes for $instanceid and $device");
	foreach my $volume ( @volumes ) {
		next if not ($volume =~ /$instanceid/ and $volume =~ /$device/)
			and not ($volume =~ /$instanceid/ and $volume =~ /$alternatedevice/);
		($attachedvolumeid) = $volume =~ /ATTACHMENT\s+(\S+)/;
		last;
	}
	
	if ( defined $attachedvolumeid and $attachedvolumeid ) {
		print "Agua::Init::detachAttached    Doing self->ops()->detachVolume($instanceid, $device, $attachedvolumeid)\n";
		$self->ops()->detachVolume($instanceid, $device, $attachedvolumeid);
	}
}

method getInstanceId {
=head2

	SUBROUTINE		getInstanceId

	PURPOSE
	
		RETURN _instanceid IF DEFINED, OTHERWISE DISCOVER
		
		AWS INSTANCE ID FROM EXTERNAL SITE
		
=cut
	return $self->instanceid() if defined $self->instanceid();	
	my $instanceid =`curl -s http://169.254.169.254/latest/meta-data/instance-id`;
	$self->instanceid($instanceid) if defined $instanceid;
	
	return $instanceid;
}

method getDomainName {
=head2

	SUBROUTINE		getDomainName

	PURPOSE
	
		RETURN _domainname IF DEFINED, OTHERWISE DISCOVER
		
		DOMAIN NAME FROM EXTERNAL SITE
		
=cut
	return $self->domainname() if defined $self->domainname();
	
	my $instanceid = $self->getInstanceId();
	my $domainname = `ec2-describe-instances | grep $instanceid | cut -f 4`;
 	print "Agua::Init::getDomainName    domainname: $domainname\n";
	$self->domainname($domainname) if defined $domainname;
	
	return $domainname;
}

#### MOUNT USER HOME VOLUME
method mountUserHome {
#### MOUNT nethome CONTAINING USER HOME DIRECTORIES
	my $mountpoint 	= 	$self->conf()->getKey("agua", 'USERDIR');
	my $device 		= 	$self->conf()->getKey("aws", 'USERDEVICE');
	my $filetype	=	$self->conf()->getKey("aws", 'USERFILETYPE');
	print "Agua::Init::mountUserHome    mountpoint: $mountpoint\n";
	print "Agua::Init::mountUserHome    device: $device\n";
	print "Agua::Init::mountUserHome    filetype: $filetype\n";

	#### MOVE ADMIN HOME DIR
	$self->moveAdminHome($mountpoint);
	
	#### CREATE MOUNTPOINT
	print "Agua::Init::mountUserHome    Creating mountpoint.\n";
	$self->ops()->createMountPoint($mountpoint) if not -d $mountpoint;
	
	#### UNMOUNT JUST IN CASE
	my $alternate = $self->ops()->alternateDevice($device);
	$self->ops()->unmountVolume($device);
	$self->ops()->unmountVolume($alternate);
	
	
	#### SANITY CHECK
	return if $self->nethomeExists($mountpoint);
	
	#### CONFIRM OR RESET DEVICE TO NEXT AVAILABLE
	$device = $self->nextAvailableDevice($device);
	$self->logDebug("Next available device", $device);
	
	### GET INSTANCE ID
	my $instanceid = $self->getInstanceId();
	print "Agua::Init::mountUserHome    instanceid: $instanceid\n";
	
	#### CREATE NETHOME VOLUME
	print "Agua::Init::mountUserHome    Creating nethome volume.\n";
	
	#### SKIP CREATE IF VOLUME ALREADY PROVIDED
	my $volumesize	=	$self->uservolumesize();
	my $uservolume	=	$self->uservolume();	
	my $volumeid = $uservolume;
	
	#### DETERMINE IF VOLUME ALREADY EXISTS
	my $isvolume = 1;
	$isvolume = 0 if not defined $uservolume or not $uservolume or not $uservolume =~ /^vol-/;
	$self->logDebug("isvolume", $isvolume);
	
	#### DETERMINE IF VOLUME PROVIDED IS A SNAPSHOT
	my $issnapshot = 1;
	$issnapshot = 0 if not defined $uservolume or not $uservolume or not $uservolume =~ /^snap-/;
	$self->logDebug("issnapshot", $issnapshot);
	
	#### CREATE VOLUME IF NOT EXISTS
	$volumeid = $self->createUserHomeVolume($volumeid, $volumesize) if not $isvolume;
	
	#### ATTACH VOLUME TO THE DEVICE
	print "Agua::Init::mountUserHome    Attaching volume.\n";
	my $attached = $self->ops()->attachVolume($instanceid, $volumeid, $device, $mountpoint);
	print "Agua::Init::mountUserHome    attached: $attached\n";
	if ( $attached ne "attached" ) {
		print "Agua::Init::mountUserHome    Can't attach volume: $volumeid to device: $device\n";
		print "Agua::Init::mountUserHome    Possible problem with AWS instance. Use AWS console to STOP and then START this instance (i.e., not reboot)\n";
		exit;
	}
	
	#### CHECK DEVICE NAME BECAUSE SOME KERNELS RENAME THE DEVICE
	#### E.G., /dev/sdh --> /dev/xvdh
	$device = $self->ops()->checkDevice($device);
	
	#### FORMAT VOLUME IF NEWLY CREATED
	#### (NOTE: MAY USE /dev/xvdi IF ORIGINAL DEVICE IS /dev/sdi)
	if ( not $isvolume and not $issnapshot ) {	
		print "Agua::Init::mountUserHome    Formatting device $device (filetype $filetype)\n";
		$self->ops()->formatVolume($device, $filetype) 
	}
	
	#### MOUNT DEVICE TO MOUNTPOINT
	print "Agua::Init::mountUserHome    Mounting volume.\n";
	my ($mountsuccess) = $self->ops()->mountVolume($device, $mountpoint, $filetype);
	$self->logDebug("mountsuccess", $mountsuccess);
	
	### RESTORE ADMIN HOME DIR
	$self->restoreAdminHome($mountpoint);
	
	##### ADD TO FSTAB SO VOLUME DEVICE IS MOUNTED AUTOMATICALLY AFTER REBOOT	
	#print "Agua::Init::mountUserHome    Adding to /etc/fstab.\n";
	#$self->addToFstab($device, $mountpoint, $filetype, "$device   $mountpoint	$filetype    defaults,nobootwait	0	0\n");
	#
	#return $mountsuccess;
}

method nethomeExists ($mountpoint) {
	my $mysqldir = "$mountpoint/mysql";
	$self->logDebug("mysqldir", $mysqldir);
	
	return 1 if -d $mysqldir;
	return 0;
}

method createUserHomeVolume ($snapshot, $size) {
	my $username	=	$self->username();	
	my $availzone 	= 	$self->getAvailabilityZone();
    my $publicfile 	= 	$self->getEc2PublicFile($username);
	my $privatefile = 	$self->getEc2PrivateFile($username);

	#### CREATE VOLUME
    my $volumeid = $self->ops()->_createVolume($privatefile, $publicfile, $snapshot, $availzone, $size);
	print "Agua::Init::mountUserHome    volumeid: $volumeid\n";
	$self->logError("volumeid not defined") and exit if not defined $volumeid or not $volumeid;

	return $volumeid;
}

method moveAdminHome ($mountpoint) {
	my $adminhome = $self->getAdminHome($mountpoint);
	return if not -d $adminhome;
	
	#### CREATE TEMPDIR
	my $tempdir = $self->getAdminTempDir();
	`mkdir -p $tempdir` if not -d $tempdir;
	
	#### MOVE ADMIN HOME TO TEMPDIR
	my $command = "mv -f $adminhome $tempdir";
	my ($result) = $self->ops()->runCommand($command);
	$self->logDebug("result", $result);
	
	$self->logError("Can't move adminhome: $adminhome to tempdir: $tempdir") and exit if -d $adminhome;
}

method detachUserHome ($instanceid, $device, $mountpoint) {
	$self->logDebug("device", $device);
	$self->logDebug("mountpoint", $mountpoint);
	print "Agua::Init::detachUserHome    Detaching volume from device: $device.\n";
	
	return $self->detachDevice($instanceid, $device) if -b $device;
	
	#### DETACH IF ALTERNATE DEVICE PRESENT
	my $alternate = $self->ops()->alternateDevice($device);
	$self->logDebug("alternate", $alternate);
	
	return if $alternate eq $device;	
	return if not -b $alternate;	

	#### KILL ALL PROCESSES DED
	$self->ops()->killMountProcesses($mountpoint);
	$self->logDebug("AFTER killMountProcesses");
	
	#### UNMOUNT VOLUME FROM DEVICE (options: lazy, force, readonly)
	my $options = "lfr";
	print "Agua::Init::detachUserHome    DOING self->ops->unmountVolume($device, $options)\n";
	$self->ops()->unmountVolume($device, $options);
	
	#### DETACH DEVICE WITH REPEATED CALLS IF NECESSARY
	print "Agua::Init::detachUserHome    DOING detachDevice($device)\n";
	return $self->detachDevice($instanceid, $device);
}

method detachDevice ($instanceid, $device) {
	print "Agua::Init::detachDevice    Detaching existing volume from device: $device.\n";
	my $success = $self->detachAttached($instanceid, $device);
	$self->logDebug("success", $success);
	
	if ( -b $device ) {
		print "Agua::Init::detachDevice    Could not detach volume from existing volume from device: $device.\n";
		print "Agua::Init::detachDevice    Possible problem with instance\n";
		print "Agua::Init::detachDevice    Use the AWS Console to STOP then START the instance (i.e., not reboot)\n";
		exit;
	}
}

method restoreAdminHome ($mountpoint) {
	my $adminhome = $self->getAdminHome($mountpoint);
	my $adminuser = $self->username();
	my $tempdir = $self->getAdminTempDir();
	my $tempadminhome = "$tempdir/$adminuser";
	return if not -d $tempadminhome;
	
	$self->logDebug("mountpoint", $mountpoint);
	$self->logDebug("-d mountpoint", -d $mountpoint);

	my $command = "mv -f $tempadminhome $mountpoint";
	$command = "rsync -av --safe-links $tempadminhome/* $mountpoint" if -d $mountpoint;
	my ($result) = $self->ops()->runCommand($command);
	$self->logDebug("result", $result);
	
	`rm -fr $tempdir` if -d $tempdir;
}

method getAdminHome ($mountpoint) {
	my $adminuser = $self->conf()->getKey("agua", "ADMINUSER");
	$self->logDebug("adminuser", $adminuser);
	my $adminhome = "$mountpoint/$adminuser";
	$self->logDebug("adminhome", $adminhome);
	
	return $adminhome;	
}

method getAdminTempDir {
	return "/tempdir";	
}

#### MOUNT MYSQL
method mountMysql {
=head2

	SUBROUTINE		mountMysql
	
	PURPOSE
	
		1. IF MYSQL IS PRESENT AT /nethome/mysql, RESTART MYSQL
	
			AND RETURN
	
		2. IF MYSQL NOT PRESENT AT /nethome/mysql, COPY MYSQL
		
			FROM STANDARD DIRS TO /nethome/mysql
			
		3. LINK BACK TO THE STANDARD DIRS, OVERRIDING THE STANDARD
			
			INSTALLATION
		
		3. RESTART MYSQL RUNNING FROM /nethome/mysql

	INPUTS
	
		USES AWS INFORMATION IN AGUA CONF FILE, E.G.:
		
		USERDIR     			/data
		DATADIR     			/nethome

=cut

	#### IF FOLDER ALREADY PRESENT, RESTART MYSQL AND RETURN
	return $self->restartMysql() if $self->mysqlExists();
	
	#### 1. STOP MYSQL AND COPY MYSQL FOLDER FROM /data
	print "Agua::Init::mountMysql    Stopping MySQL\n";
	$self->stopMysql();
	
	#### 2. COPY MYSQL
	print "Agua::Init::mountMysql    Copying MySQL folders to nethome\n";
	$self->unmountMysqlDirs();
	$self->copyMysql();

    #### 3. ADD TO /etc/fstab BINDINGS TO LINK TO MYSQL ON EBS VOLUME	
	print "Agua::Init::mountMysql    Adding MySQL folders to /etc/fstab\n";
	$self->addMysqlToFstab();
	
    #### 4. MOUNT MYSQL DIRS FROM mysql USERDIR
	print "Agua::Init::mountMysql    Mounting MySQL directories\n";
	$self->mountMysqlDirs();

	#### 5. SET mysql OWNERSHIP OF MYSQL DIRS
	print "Agua::Init::mountMysql    Setting MySQL permissions\n";
	$self->setMysqlPermissions();
    
    #### 6. RESTART MYSQL
	my $wait = 20;
	print "Agua::Init::mountMysql    Waiting for $wait seconds\n";
	sleep($wait);
	print "Agua::Init::mountMysql    Restarting MySQL\n";
	$self->restartMysql();
}

method mysqlExists {
	my $userdir 	= 	$self->conf()->getKey("agua", 'USERDIR');
	my $mysqldir 	= 	"$userdir/mysql";
	$self->logDebug("mysqldir", $mysqldir);	
	return 1 if -d $mysqldir;
	return 0;
}

method stopMysql {
	my $mysql = $self->getMysql();
    my $command = "$mysql stop";
	print "Agua::Init::mountMysql    command: $command\n";
	print `$command`;
}

method unmountMysqlDirs () {
	my $dirs = $self->getMysqlDirs();
	$self->logDebug("dirs", $dirs);
	foreach my $dir ( @$dirs ) {
		$self->ops()->killMountProcesses($dir);
		my $command = "umount $dir";
		$self->logDebug("command", $command);
		print `$command`;
	}
}

method getMysql {
	my $mysql = "/etc/init.d/mysqld";
	$mysql = "/etc/init.d/mysql" if not -f $mysql;
	
	return $mysql;
}

method getMysqlDirs {
	return ["/etc/mysql", "/var/log/mysql", "/var/lib/mysql"];
}

method copyMysql {
	my $userdir 			= $self->conf()->getKey("agua", 'USERDIR');
	my $dirs = $self->getMysqlDirs();
	$self->logDebug("dirs", $dirs);
	my $success = 1;
	foreach my $dir ( @$dirs ) {
		my $target = "$userdir/mysql$dir";

		#### CREATE PARENT DIR
		my ($parentdir) = $target =~ /^(.+?)\/[^\/]+$/;
		my $command = "mkdir -p $parentdir";
		$self->logDebug("command", $command);
		`$command`;
		
		#### COPY INTO PARENT DIR
		#my $result = File::Copy::Recursive::rcopy($dir, "$target$dir");
		$command = "cp -r $dir $target";
		$self->logDebug("command", $command);
		`$command`;
		my $result = -d $target;
		$self->logDebug("result", $result);
		$success = 0 if not defined $result or not $result;
	}
	$self->logDebug("success", $success);
	
	return $success;
}

method addMysqlToFstab() {
#### ADD TO /etc/fstab BINDINGS TO LINK TO MYSQL ON EBS VOLUME	
#### (Points MySQL to the correct database files on the EBS volume.)	
	my $userdir 			= $self->conf()->getKey("agua", 'USERDIR');
	my $dirs = $self->getMysqlDirs();
	$self->logDebug("dirs", $dirs);
	foreach my $dir ( @$dirs ) {
		my $target = "$userdir/mysql$dir";
	    $self->addToFstab($target, $dir, "", "$target $dir     none bind");
	}
}

method mountMysqlDirs () {
	my $dirs = $self->getMysqlDirs();
	$self->logDebug("dirs", $dirs);
	foreach my $dir ( @$dirs ) {
		my $command = "";
		$command .= "mkdir $dir;\n" if not -d $dir;
		$command .= "mount $dir";
		$self->logDebug("command", $command);
		print `$command`;
	}
}

method setMysqlPermissions {
#### SET PERMISSIONS SO mysql USER HAS ACCESS TO FOLDERS
	my $userdir 	= 	$self->conf()->getKey("agua", 'USERDIR');
	my $dirs 		= 	$self->getMysqlDirs();
	$self->logDebug("dirs", $dirs);
	foreach my $dir ( @$dirs ) {
		my $command = "chown -R mysql:mysql $userdir/mysql$dir";
		$self->logDebug("command", $command);
		`$command`;
	}
}

method restartMysql {
	my $mysql	=	$self->getMysql();
	my $command = "$mysql restart";
	#my $command = "service mysql restart";
	print "Agua::Init::mountMysql    command: $command\n";
	my $success = `$command`;
	$self->logDebug("success", $success);

	return $success;
}

#### ADMIN USER
method addAdminUser {
#### CREATE THE ADMIN USER LINUX ACCOUNT AND AGUA ACCOUNT
	my $object = {
		username	=>	$self->username(),
		password	=>	$self->password(),
		email		=>	"",
		firstname	=>	"",
		lastname	=>	""
	};
    $self->logDebug("object", $object);

	#### SET DATABASE
	$self->setDbh();
	
	### REMOVE OLD ADMIN USER ENTRY
	$self->_removeUser($object);

	#### ADD ADMIN USER TO AGUA DATABASE
	$self->_addUser($object);
	
	#### ADD LINUX ACCOUNT FOR ADMIN USER AND CREATE HOME DIRECTORY
	$self->_addLinuxUser($object);
}

#### LINK JBROWSE USER DATA DIR
method linkJBrowseDir {
	my $userdir 	= 	$self->conf()->getKey("agua", "USERDIR");
	my $htmldir		=	$self->conf()->getKey("agua", "HTMLDIR");
	my $urlprefix	=	$self->conf()->getKey("agua", 'URLPREFIX');

	#### CHECK USERDIR
	$self->logDebug("userdir", $userdir);
    print "Agua::Installer::createJBrowseDirs    userdir not defined\n" if not defined $userdir;
    print "Agua::Installer::createJBrowseDirs    userdir is a file: $userdir\n" if -f $userdir;
    print "Agua::Installer::createJBrowseDirs    userdir: $userdir\n";
    return if not -d $userdir;
 
	#### CREATE JBROWSE users DIRECTORY 
    my $directory	=	"$userdir/jbrowse/users";
    print `mkdir -p $directory`;
    print "Agua::Installer::createJBrowseDirs    Can't create directory: $directory\n" if not -d $directory;

    #### LINK TO PLUGINS JBROWSE users DIRECTORY
    $self->ops()->removeLink("$htmldir/$urlprefix/plugins/view/jbrowse/users");
    $self->ops()->addLink("$userdir/jbrowse/users", "$htmldir/$urlprefix/plugins/view/jbrowse/users");
}

### UTILS
method generatePrivateKey ($keyname) {
### GENERATE PRIVATE KEY FILE AND REGISTER WITH AWS
	my $conf 			= 	$self->conf();
	my $username 		=	$self->username();
	my $userdir 		= 	$conf->getKey('agua', "USERDIR");
	my $filedir			=	"$userdir/$username/.starcluster";
	my $privatekey		=	"$filedir/privatekey.pem";
	my $publiccert		=	"$filedir/publiccert.pem";
	print "StarCluster::generatePrivateKey    filedir: $filedir\n";
	print "StarCluster::generatePrivateKey    privatekey: $privatekey\n";

	### SET DEFAULT keyname
	$keyname = "$username-key" if not defined $keyname;
	
	### 1. GENERATE PRIVATE KEY
	chdir($filedir);
	my $command = qq{openssl genrsa -out $privatekey-pass 1024};
	print "$command\n";
	print `$command`;
	
	### 2. REMOVE PASS-PHRASE FROM KEY:
	my $remove = "openssl rsa -in $privatekey-pass -out $privatekey";
	print "$remove\n";
	print `$remove`;
    ### writing RSA key
	
	### 3. SET PERMISSIONS TO 600
	my $chmod = "chmod 600 $privatekey";
	print "$chmod\n";
	print `$chmod`;

	### 4. CREATE A PUBLIC CERTIFICATE FOR THE PRIVATE KEY
	my $public = qq{openssl rsa -in $privatekey \\
-pubout \\
-out $publiccert
};
	print "$public\n";
	print `$public`;

	### 4. IMPORT PUBLIC KEY TO AMAZON
	my $import = qq{ec2-import-keypair \\
--debug \\
$keyname \\
--public-key-file $publiccert \\
-U https://ec2.amazonaws.com 
};
	print "$import\n";
	print `$import`;
}



} #### Agua::Init