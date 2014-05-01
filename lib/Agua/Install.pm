use MooseX::Declare;

=head2

=head3 PACKAGE		Agua::Install

=head3 PURPOSE
    
	INSTALL AGUA DEPENDENCIES
	
=head3 LICENCE

This code is released under the MIT license, a copy of which should
be provided with the code.

=end pod

=cut

use strict;
use warnings;
use Carp;

class Agua::Install	with (Agua::Common::Logger, Agua::Install::Apache, Agua::Install::Https, Agua::Install::MySQL, Agua::Install::Exchange) {

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Conf::Yaml;

# Integers
has 'showlog'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'		=>  ( isa => 'Int', is => 'rw', default => 5 );

# Strings
has 'tempdir'		=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );
has 'installdir'	=> 	( isa => 'Str|Undef', is => 'rw', required => 0 );
has 'urlprefix'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'arch'			=> 	( isa => 'Str|Undef', is => 'rw' );
has 'mode'			=> 	( isa => 'Str|Undef', is => 'rw' );
has 'apachedir'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'userdir'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'wwwdir'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'wwwuser'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'domainname'	=> 	( isa => 'Str|Undef', is => 'rw' );
has 'logfile'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'newlog'		=> 	( isa => 'Str|Undef', is => 'rw' );
has 'urlprefix'		=> 	( isa => 'Str|Undef', is => 'rw' );

# Objects
has 'conf' 	=> (
	isa 	=> 'Conf::Yaml',
	is 		=>	'rw'
);

#####////}}}

method BUILD ($args) {
	$self->logDebug("args", $args);	
	if ( $args ) {
		foreach my $key ( keys %{$args} ) {
			$self->$key($args->{$key}) if $self->can($key);
		}
	}
	
	#### BACK UP ANY PREVIOUS LOGFILE
	my $newlog = $self->newlog();
	$self->logDebug("newlog", $newlog) if defined $newlog;

	if ( defined $newlog ) {
		my $logfile	=	$self->logfile();
		my $backupfile = $logfile;
		$backupfile = $self->incrementFile($backupfile);
		$self->logDebug("backupfile", $backupfile);
		my $force = 1;
		$self->backupFile($logfile, $backupfile, $force);
	}

	$self->logDebug("self", $self);
}

#### INSTALL
method install {
    #### SET INSTALLDIR TO SIMPLEST PATH
    $self->setInstalldir();
    
    #### COPY CONFIG FILE
    $self->copyConf();

	#### SET CONF
	$self->setConf();

	#### SET PUPPET DIRS
	$self->setPuppetDirs();
	
    ##### INSTALL APACHE
    #$self->installApache();

    #### GENERATE NEW PUBLIC CERTIFICATE (HTTPS)
    $self->enableHttps();
    
    #### INSTALL NODE, RABBIT AND AMQP EXCHANGE
    $self->installExchange();
    
    ##### FIX /etc/fstab SO MICRO INSTANCE CAN REBOOT
    #$self->enableReboot();
    
    #### INSTALL MYSQL
    $self->installMysql();
    
    ##### INSTALL EC2-API-TOOLS
    #$self->installEc2();

    #### LINK INSTALLATION DIRECTORIES TO WEB DIRECTORIES
    $self->linkDirectories();
    
    ##### SET PERMISSIONS TO ALLOW ACCESS BY www-data USER
    #$self->setPermissions();
    
    ##### SET COMMANDS IN STARTUP SCRIPT
    #$self->setStartupScript();
    
    #### CONFIRM INSTALLATION AND PRINT INFO
    $self->installConfirmation();
}

##### CONFIG
method copyConf {
	#### COPY config.yaml FILE FROM RESOURCES TO conf DIR
	#### SKIP IF TARGET FILE ALREADY EXISTS
    my $confdir 	= 	"$Bin/../../conf";
    my $resourcedir = 	"$Bin/resources/agua/conf";
    my $sourcefile 	= 	"$resourcedir/config.yaml";
    my $targetfile 	= 	"$confdir/config.yaml";
	$self->logDebug("targetfile", $targetfile);
	
    return if -f $targetfile;
	
    #### COPY
    my $command = "cp -f $sourcefile $targetfile";
	$self->logDebug("command", $command);
    `$command`;
}

method setConf {	
	my $configfile = "$Bin/../../conf/config.yaml";
	my $conf = Conf::Yaml->new(	inputfile	=>	$configfile);
	
	$self->conf($conf);
}

#### INSTALLDIR
method setInstalldir {    
    my $installdir = $self->installdir();
    $installdir = $self->reducePath($installdir);
    $self->installdir($installdir);
}

method reducePath ($path) {
	while ( $path =~ s/\/[^\/]+\/\.\.//g ) {
		#### reducing
	}
	
	return $path;
}

#### PACKAGE MANAGER
method isInstalled ($package) {
	return undef if not defined $package;
	
	my $packagemanager = $self->getPackageManager();
	$self->logDebug("packagemanager", $packagemanager);

	return undef if not defined $packagemanager;
	return $self->isAptGetInstalled($package) if $packagemanager eq "apt-get";
	return $self->isYumInstalled($package) if $packagemanager eq "yum";	
}
method getPackageManager {
	my $aptfile	=	"/etc/apt/apt.conf.d";
	return "apt-get" if -d $aptfile;
	
	my $yumdir	=	"/etc/yum.repos.d";
	return "yum" if -f $yumdir;
	
	return undef;
}
#### APT-GET
method isAptGetInstalled ($package) {
	return undef if not defined $package;

	my $command = "apt-cache policy $package";
	my $output = `$command`;

	return 1 if $output !~ /Installed: \(none\)/ms;
	return 0;
}
method isYumInstalled ($package) {
	return undef if not defined $package;

	my $command = "yum list installed | egrep -e '^$package\.'";
	my $output = `$command`;

	return 1 if defined $output and $output ne "";
	return 0;
}
method updateAptGet {
	$self->logDebug("");

    $self->runCommands([
	    "rm -fr /var/lib/apt/lists/lock"
	    , "apt-get update"
	    #, "apt-get upgrade -y"
    ])
}
#### STARTUP SCRIPT
method setStartupScript {
	#### SET COMMANDS TO BE RUN AT STARTUP FROM STARTUP SCRIPT
	my $apachedir  	= $self->apachedir();
	my $installdir  = $self->installdir();
	my $domainname  = $self->domainname();

	#### SET STARTUPFILE
	my $arch	=	$self->getArch();
    my $startupfile = "/etc/init.d/rc.local";
	$startupfile = "/etc/rc.local" if $arch eq "centos";
	$self->logDebug("startupfile", $startupfile) if defined $startupfile;
	
	my $executable = "$installdir/bin/scripts/createCert.pl";
	my $line = qq{$executable \\
--installdir $installdir \\
--domainname $domainname \\
--apachedir	$apachedir
};
	my $contents = $self->fileContents($startupfile);
	$contents .="\n$line\n" if not $contents =~ /$executable/ms;

	$self->toFile($startupfile, $contents);	
}

method enableReboot {
=head2

SUBROUTINE		enableReboot

PURPOSE

	REMOVE A LINE ADDED TO /etc/fstab BY cloud-init WHICH
	
	STOPS t1.micro INSTANCES FROM REBOOTING

=cut 
	$self->logDebug("Enabling t1.micro instances to reboot");
	my $file = "/etc/fstab";
	open(FILE, $file) or die "Agua::Install::enableReboot    Can't open file: $file\n";
	my @lines = <FILE>;
	close(FILE) or die "Can't close file: $file\n";
	for ( my $i = 0; $i < $#lines + 1; $i++ )
	{
		my $line = $lines[$i];
		next if $line =~ /^#/;
		if ( $line =~ /comment=cloudconfig/ ) {
			splice @lines, $i, 1;
			$i--;
		}
	}
	open(OUT, ">$file") or die "Agua::Install::enableReboot    Can't open file: $file\n";
	foreach my $line ( @lines ) {   print OUT $line;    }
	close(OUT) or die "Can't close file: $file\n";	
}

#### APPS
method installEc2 {
#### INSTALL ec2-api-tools
	return $self->installPackage("ec2-api-tools");
}

method installR {
#### INSTALL R STATISTICAL SOFTWARE PACKAGE
    $self->installPackage("r-base");
}

#### INSTALL UTILS
method replaceFile ($originalfile, $replacementfile, $force) {
    $self->backupFile($originalfile, "$originalfile.bkp", $force);

    $self->logDebug("originalfile", $originalfile);
    $self->logDebug("replacementfile", $replacementfile);
    $self->logDebug("force", $force) if defined $force;
    
    $self->logDebug("originalfile not defined") if not defined $originalfile;
    $self->logDebug("replacementfile not defined") if not defined $replacementfile;
    $self->logDebug("Can't find replacementfile", $replacementfile) if not -f $replacementfile;
    $self->logDebug("Skipping as originalfile already exists: ", $originalfile) and return if -f $originalfile and not defined $force;
    
    return if not defined $originalfile or not $originalfile;
    return if not defined $replacementfile or not $replacementfile;
    return if not -f $replacementfile;
    
    my ($originaldir) = $originalfile =~ /^(.+?)\/[^\/]+$/;
    $self->logDebug("Creating originaldir", $originaldir);
    if ( not -d $originaldir ) {
    	my $command = "mkdir -p $originaldir";
    	$self->logDebug("command", $command);
    	print `$command`;
    	$self->logDebug("Can't create originaldir", $originaldir) if not -d $originaldir;
    }
    
    my $command = "cp $replacementfile $originalfile";
    $self->logDebug("command", $command);
    `$command`;
}

method backupFile ($originalfile, $backupfile, $force) {
    $self->logDebug("originalfile", $originalfile);
    $self->logDebug("backupfile", $backupfile);
    $self->logDebug("force", $force) if defined $force;
    $self->logDebug("Skipping backup as originalfile not present", $originalfile) and return if not -f $originalfile;

    $self->logDebug("originalfile not defined") if not defined $originalfile;
    $self->logDebug("backupfile not defined") if not defined $backupfile;
    $self->logDebug("Skipping backup as backupfile already exists: ", $backupfile) and return if -f $backupfile and not defined $force;

    my ($backupdir) = $backupfile =~ /^(.+?)\/[^\/]+$/;
    $self->logDebug("Creating backupdir", $backupdir);
    if ( not -d $backupdir )
    {
    	my $command = "mkdir -p $backupdir";
    	$self->logDebug("command", $command);
    	print `$command`;
    	$self->logDebug("Can't create backupdir", $backupdir) if not -d $backupdir;
    }
    my $command = "cp $originalfile $backupfile";
    $self->logDebug("command", $command);
    print `$command`;
}


method installPackage ($package) {
    $self->logDebug("package", $package);
    return 0 if not defined $package or not $package;
    $self->logDebug("package", $package);
    
    if ( -f "/usr/bin/apt-get" ) {
    	$self->runCommands([
			"rm -fr /var/lib/dpkg/lock",
			"dpkg --configure -a",
			"rm -fr /var/cache/apt/archives/lock"
    	]);

    	$ENV{'DEBIAN_FRONTEND'} = "noninteractive";
    	my $command = "/usr/bin/apt-get -q -y install $package";
    	$self->logDebug("command", $command);
    	system($command);
    }
    elsif ( -f "/usr/bin/yum" ) {
		my $commands = [
			"rm -fr /var/run/yum.pid", 
			"/usr/bin/yum -y install $package"
		];
    	$self->runCommands($commands);
		$self->logDebug("commands", $commands);
    }    
}

method removePackage ($package) {
    $self->logDebug("package", $package);
    return 0 if not defined $package or not $package;
    
    if ( -f "/usr/bin/apt-get" )
    {
    	$self->runCommands([
    	"rm -fr /var/lib/dpkg/lock",
    	"dpkg --configure -a",
    	"rm -fr /var/cache/apt/archives/lock"
    	]);

    	$ENV{'DEBIAN_FRONTEND'} = "noninteractive";
    	my $command = "/usr/bin/apt-get -q -y --purge remove $package";
    	$self->logDebug("command", $command);
    	system($command);
    	#die("Problem with command: $command\n$!\n") if $!;
    }
    elsif ( -f "/usr/bin/yum" )
    {
    	my $command = "/usr/bin/yum -y remove $package";
    	$self->logDebug("command", $command);
    	system($command);
    }    
}

method cpanInstall ($module, $logfile) {
	$self->logDebug("module", $module);
	$self->logDebug("logfile", $logfile) if defined $logfile;
	return 0 if not defined $module or not $module;

	my $command = "PERL_MM_USE_DEFAULT=1 /usr/bin/perl -MCPAN -e 'install $module'";
	$command .= " &>> $logfile"  if defined $logfile;
	$self->logDebug("command", $command);
	print `$command`;
}

method cpanminusInstall ($module) {
	return 0 if not defined $module or not $module;
	
	my $cpanm = "/usr/local/bin/cpanm";
	$cpanm = "/usr/bin/cpanm" if not -f $cpanm;
	my $command = "$cpanm $module";
	
	print `$command`;
}



#### LINK DIRECTORIES
method linkDirectories {

    my $installdir  =   $self->installdir();
    my $wwwdir      =   $self->wwwdir();
    my $urlprefix	=	$self->urlprefix();

    $self->logDebug("installdir not defined or empty") if not defined $installdir or not $installdir;
    $self->logDebug("wwwdir not defined or empty") if not defined $wwwdir or not $wwwdir;
    $self->logDebug("urlprefix not defined or empty") if not defined $urlprefix or not $urlprefix;

    #### REMOVE EXISTING LINKS
    my $linksfile=	"$Bin/resources/agua/links.txt";
    $self->logDebug("Agua::Install::linkDirectories(linksfile)");
    $self->logDebug("linksfile", $linksfile);
    my $contents = $self->fileContents($linksfile);
    $self->logDebug("linksfile is empty", $linksfile) if not defined $contents or not $contents;

    my @commands 	= split "\n", $contents;
    foreach my $command ( @commands ) {
    	next if $command =~ /^#/ or $command =~ /^\s*$/;
    	$command =~ s/INSTALLDIR/$installdir/g;
    	$command =~ s/WWWDIR/$wwwdir/g;
    	$command =~ s/URLPREFIX/$urlprefix/g;
    	$self->logDebug("command", $command);

		my ($source, $target)	=	 $command =~ /^\s*(\S+)\s+(\S+)/;

	    $self->removeLink($target);
		$self->addLink($source, $target);
    }

    $self->logDebug("Completed")
}

#### SET PERMISSIONS
method setPermissions {
    my $permissionsfile=	"$Bin/resources/agua/permissions.txt";
    $self->logDebug("Agua::Install::setPermissions(permissionsfile)");
    $self->logDebug("permissionsfile", $permissionsfile);
    my $contents = $self->fileContents($permissionsfile);
    $self->logDebug("permissionsfile is empty", $permissionsfile) if not defined $contents or not $contents;
    
    my $installdir 	= $self->installdir();
	my $wwwuser 	= $self->wwwuser();
	my $userdir 	= $self->userdir();
    my @commands 	= split "\n", $contents;
    foreach my $command ( @commands ) {
    	next if $command =~ /^#/ or $command =~ /^\s*$/;
    	$command =~ s/INSTALLDIR/$installdir/g;
    	$command =~ s/WWWUSER/$wwwuser/g;
    	$command =~ s/USERDIR/$userdir/g;
		$self->logDebug($command);

    	print `$command`;
    }
}

method installConfirmation {

    my $installdir  =   $self->installdir();
    my $urlprefix  	=   $self->urlprefix();
    my $domainname	=	$self->getDomainName();

	print qq{
    *******************************************************    
    *******************************************************

Agua has been installed here:

    $installdir

There are two more steps to enable your installation:

1. Run the configuration script to set up the mysql database:

    $installdir/bin/scripts/config.pl

2. Browse to your new Agua instance here to provide your EC2 credentials: 

    http://$domainname/$urlprefix/agua.html

    *******************************************************    

For added security, you can do this over an HTTPS connection:
        
    https://$domainname/$urlprefix/agua.html

In order to do this, you must enable HTTPS access:
    
    a) If you have the ec2-api tools installed, do this:
    
        ec2-authorize default -p 443 -P tcp
        
    or, b) Use the AWS console:

        1. Log in to AWS: http://aws.amazon.com
        2. Click 'EC2' tab
        3. In the left Navigation Bar, click 'Security Groups'
        4. Click on 'default' (or your own, custom security group)
        The security group's details will appear in the bottom pane.
        In the bottom pane, select the 'Inbound' tab and create a
        new 'Custom TCP Rule':

            Port range: 443
            Source:     0.0.0.0/0

    *******************************************************    
    *******************************************************
};    
}

method input ($message) {
    return if ( not defined $message );
    print "$message\n";	

    $/ = "\n";
    my $input = <STDIN>;
    while ( $input =~ /^\s*$/ )
    {
    	print "$message\n";
    	$input = <STDIN>;
    }	

    chop($input);
    return $input;
}

method removeLink ($target) {
    $self->logDebug("target", $target);

    return if not -l $target;    
    $self->logDebug("unlink($target)");    
    unlink($target);
    $self->logDebug("Could not unlink", $target) if -l $target;
}

method addLink ($source, $target) {
    $self->logDebug("source", $source);
    $self->logDebug("target", $target);    
    my $command = "ln -s $source $target";
    $self->logDebug("command", $command); 
	`$command`;
    $self->logDebug("Could not create link", $target) if not -l $target;
}

method removeDir ($target) {
    $self->logDebug("target", $target);

    return if -l $target || -f $target;    
    print `$target`;
    $self->logDebug("Could not remove target", $target) if -l $target;
}


method yes ($message) {
    return if ( not defined $message );
    my $max_times = 10;
    
    $/ = "\n";
    my $input = <STDIN>;
    my $counter = 0;
    while ( $input !~ /^Y$/i and $input !~ /^N$/i )
    {
    	if ( $counter > $max_times )	{	print "Exceeded 10 tries. Exiting...\n";	}
    	
    	print "$message\n";
    	$input = <STDIN>;
    	$counter++;
    }	

    if ( $input =~ /^N$/i )	{	return 0;	}
    else {	return 1;	}
}

method fileContents ($file) {
    $self->logDebug("Agua::Install::fileContents(file)");
    $self->logDebug("file", $file);
    die("Agua::Install::contents    file not defined\n") if not defined $file;
    die("Agua::Install::contents    Can't find file: $file\n$!") if not -f $file;

    my $temp = $/;
    $/ = undef;
    open(FILE, $file) or die("Can't open file: $file\n$!");
    my $contents = <FILE>;
    close(FILE);
    $/ = $temp;
    
    return $contents;
}

method backupCpanConfig ($configfile) {
    $self->logDebug("configfile", $configfile);
    return if not defined $configfile or not $configfile;
    my $backupfile = "$configfile.original"; 
    $self->logDebug("backupfile", $backupfile);
    if ( not -f $backupfile and -f $configfile )
    {
    	my $command = "cp $configfile $backupfile";
    	$self->logDebug("command", $command);
    	`$command`;
    }
}

method restoreCpanConfig ($configfile) {
    $self->logDebug("configfile", $configfile);
    return if not defined $configfile or not $configfile;
    if ( -f $configfile )
    {
    	$self->logDebug("configfile", $configfile);
    	my $command = "cp $configfile.original $configfile";
    	$self->logDebug("command", $command);
    	`$command`;
    }
}

method replaceCpanConfig ($configfile, $replacement) {
    $self->logDebug("configfile", $configfile);
    $self->logDebug("replacement", $replacement);
    return if not defined $configfile or not $configfile;
    return if not defined $replacement or not $replacement;
    return if not -f $replacement;

    my ($configdir) = $configfile =~ /^(.+?)\/[^\/]+$/;
    $self->logDebug("Creating configdir", $configdir);
    if ( not -d $configdir )
    {
    	my $command = "mkdir -p $configdir";
    	$self->logDebug("command", $command);
    	print `$command`;
    	$self->logDebug("Can't create configdir", $configdir) if not -d $configdir;
    } 

    my $command = "cp $replacement $configfile";
    $self->logDebug("command", $command);
    `$command`;
}

method getfiles ($directory, $suffix) {
    opendir(DIR, $directory) or die "Can't open directory: $directory. $!";
    my @files = readdir(DIR);
    closedir(DIR) or die "Can't close directory: $directory. $!";
    
    return \@files if not defined $suffix;
    for ( my $i = 0; $i < $#files + 1; $i++ )
    {
        use re 'eval';
        if ( $files[$i] !~ /$suffix$/ or not -f "$directory/$files[$i]" )
        {
            splice(@files, $i, 1);
            $i--;
        }
        no re 'eval';
    }

    return \@files;
}

method copyDirectories ($installdir, $directories) {
    #### COPY ALL FILES TO BASE DIR
    print "\nCopying folders to base directory: @$directories\n";
    foreach my $directory ( @$directories )
    {
        my $sourcedir = "$Bin/../../$directory";
        print "Copying $sourcedir TO $installdir/$directory\n";
        my $targetdir = "$installdir/$directory";
        
        #### PRINT '.' AS PROGRESS COUNTER
        print ".";
    
        if ( -d $sourcedir )
        {
			require File::Copy::Recursive;
            my $success = File::Copy::Recursive::rcopy("$sourcedir", "$targetdir");
            if ( not $success )
            {
                die "Could not copy directory '$sourcedir' to '$targetdir': $!\n";
            }
        }
        else
        {
            die "Directory is missing from agua distribution: $sourcedir\n";
        }
    }
}


method runCommands ($commands) {
    $self->logDebug("Agua::Install::runCommands(commands)");
    foreach my $command ( @$commands )
    {
    	$self->logDebug("command", $command);		
    	print `$command` or die("Error with command: $command\n$! , stopped");
    }
}

method incrementFile ($file) {
    $file .= ".1";	
    while ( -f $file ) {
    	my ($stub, $index) = $file =~ /^(.+?)\.(\d+)$/;
    	$index++;
    	$file = $stub . "." . $index;
    }

    return $file;    
}

#### MISC
method linkManifestFile ($filename) {
	my $installdir	=	$self->installdir();
	my $sourcefile	=	"$installdir/bin/install/resources/puppet/manifests/$filename";
	my $targetfile	=	"/etc/puppet/manifests/$filename";
	
	my $source		=	"$installdir/bin/install/resources/puppet/manifests/$filename";
	my $target		=	"/etc/puppet/manifests/$filename";
	$self->logDebug("linking $source to $target");
	$self->addLink($source, $target) if not -f $target and not -l $target;	

}

method applyManifestFile ($filename) {
	my $command	=	"puppet apply /etc/puppet/manifests/$filename";
    $self->logDebug("$command");
	print $self->runCommands([$command]);	
}

method setPuppetDirs {
#### NB: WILL NOT OVERWRITE EXISTING FILES OR DIRS
	my $installdir	=	$self->installdir();
	
	#### LINK hiera.yaml FILE
	my $source		=	"$installdir/bin/install/resources/puppet/hiera.yaml";
	my $target		=	"/etc/puppet/hiera.yaml";
	$self->logDebug("linking $source to $target");
	$self->addLink($source, $target) if not -f $target and not -l $target;

	#### LINK hiera DIR
	$source		=	"$installdir/bin/install/resources/puppet/hiera";
	$target		=	"/etc/puppet/hiera";
	$self->logDebug("linking $source to $target");
	$self->addLink($source, $target) if not -l $target and not -d $target;
	
	#### CREATE manifests DIR IF NOT EXISTS
	my $manifestdir = "/etc/puppet/manifests";
	`mkdir -p $manifestdir` if not -d $manifestdir;
}

method replaceVariables ($text) {
	my $installdir 	= 	$self->installdir();
    my $wwwdir 		= 	$self->wwwdir();
    my $urlprefix 	= 	$self->urlprefix();
    my @lines 	= split "\n", $text;
    foreach my $line ( @lines ) {
		next if $line =~ /^#/ or $line =~ /^\s*$/;
    	$line =~ s/INSTALLDIR/$installdir/g;
    	$line =~ s/WWWDIR/$wwwdir/g;
    	$line =~ s/URLPREFIX/$urlprefix/g;
    }
	
	return join "\n", @lines;
}

method getArch {    
	my $arch = $self->arch();
    $self->logDebug("STORED arch", $arch) if defined $arch;

	return $arch if defined $arch;
	
	$arch 	= 	"linux";
	my $command = "uname -a";
    my $output = `$command`;
	#$self->logDebug("output", $output);
	
    #### Linux ip-10-126-30-178 2.6.32-305-ec2 #9-Ubuntu SMP Thu Apr 15 08:05:38 UTC 2010 x86_64 GNU/Linux
    $arch	=	 "ubuntu" if $output =~ /ubuntu/i;
    #### Linux ip-10-127-158-202 2.6.21.7-2.fc8xen #1 SMP Fri Feb 15 12:34:28 EST 2008 x86_64 x86_64 x86_64 GNU/Linux
    $arch	=	 "centos" if $output =~ /fc\d+/;
    $arch	=	 "centos" if $output =~ /\.el\d+\./;
	$arch	=	 "debian" if $output =~ /debian/i;
	$arch	=	 "freebsd" if $output =~ /freebsd/i;
	$arch	=	 "osx" if $output =~ /darwin/i;

	$self->arch($arch);
    $self->logDebug("FINAL arch", $arch);
	
	return $arch;
}


method fixGetcwd {
    if ( not -d "/usr/bin/getcwd" )
    {
    	$self->runCommands([
    		"ln -s /bin/pwd /usr/bin/getcwd",
    		"ln -s /bin/pwd /bin/getcwd"
    	]);
    }
}

method getUbuntuVersion {
	my $command = "cat /etc/lsb-release | grep DISTRIB_RELEASE | sed 's/DISTRIB_RELEASE=//'";
	my $version = `$command`;
	chomp($version);
	
	return $version;
}
method getLocalTags {
	chdir($Bin);
	my $output = `git tag`;
	my @tags = split "\n", $output;
	return \@tags;
}

method currentIteration  {
	chdir($Bin);
	my $iteration = `git log --oneline | wc -l`;
	$iteration =~ s/\s+//g;	
	$iteration = "0" x ( 5 - length($iteration) ) . $iteration;	
	return $iteration;
}

method currentBuild  {
	chdir($Bin);
	my $build = `git rev-parse --short HEAD`;
	$build =~ s/\s+//g;
	return $build;
}

method currentVersion  {
	my $version = `git tag -ln`;
	($version) = $version =~ /\n(\S+)[^\n]+$/;	
}
method copyBashProfile {
    $self->replaceFile("~/.bash_profile", "$Bin/resources/starcluster/.bash_profile");
}


###
}

##### Bio::DB:Sam
#method installBioDbSam {
#    my $conffile = "$Bin/../../conf/config.yaml";
#	require Conf::Yaml;
#	my $conf = Conf::Yaml->new({
#		inputfile	=>	$conffile
#	});
#
#	my $datadir = $conf->getKey("agua", "DATADIR");
#	my $samtools = "$datadir/apps/samtools/0.1.16";
#	my $command = "export SAMTOOLS=$samtools; cpanm install Bio::DB::Sam";
#	$self->logDebug("command", $command);
#
#	print `$command`;
#}
#
 