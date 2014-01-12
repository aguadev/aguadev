package Agua::Install::Apache;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Method::Signatures;

use FindBin qw($Bin);

#### APACHE
method installApache {

    #### CREATE www DIRS
    $self->createWwwDirs();
 
    #### LINK DIRS INSIDE www DIRS
	$self->linkWwwDirs();

    #### COPY FAVICON
	$self->copyFavicon();
    
	##### INSTALL PACKAGES
	#$self->installApachePackages();	
	$self->puppetInstallApache();
    
	#### ENABLE APACHE AUTO RESTART ON BOOT
    $self->setApacheAutoStart();
}

method puppetInstallApache {
	#### NB: librarian-puppet HAS ALREADY INSTALLED apache AND stdlib
	
	#### ON CENTOS, INSTALL SUIDPERL
	#### yum install -y perl-suidperl

	#### LINK *.pp FILE
	my $filename	=	"apache.pp";
	$self->linkManifestFile($filename);

	#### APPLY *.pp FILE
	#### INSTALL APACHE
	$self->applyManifestFile($filename);	
}

method installApachePackages {
	my $arch	=	$self->getArch();
    $self->logDebug("arch", $arch);
	
	$self->apacheCentos() if $arch eq "centos";
	$self->apacheUbuntu() if $arch eq "ubuntu";
    
	$self->restartApache();	
}

method apacheUbuntu {
    #### INSTALL APACHE2
    $self->logDebug("Installing apache");	
	$self->installPackage("apache2=2.2.22");
    $self->logDebug("Completed installing apache");	
    
    #### REPLACE mpm-worker WITH mpm-prefork (Non-threaded) CGI DAEMON
    #### TO AVOID THIS ERROR: 'unable to connect to cgi daemon'
    $self->removePackage("apache2-mpm-prefork");
    $self->installPackage("apache2-prefork-dev");	
	
	# IN ORDER TO INSTALL libapache2-mod-fastcgi
	# EDIT /etc/apt/sources.list
	# ADD LINE
	# deb http://us.archive.ubuntu.com/ubuntu/ saucy multiverse
	$self->replaceSourcesList();
	$self->updateAptGet();

	# INSTALL libapache2-mod-fastcgi
    $self->installPackage("libapache2-mod-fastcgi");
    my $command = "a2enmod cgid actions";
    $self->runCommands([$command]);

	#### REPLACE apache2.conf, sites-available/default AND envvars
	$self->replaceApacheConfs();
}

method apacheCentos {
	#### INSTALL APACHE
    $self->logDebug("installing httpd");	
	$self->installPackage("httpd");

	#### INSTALL FASTCGI DEPENDENCIES
    $self->installPackage("httpd-devel apr apr-devel libtool");	
	
	#### INSTALL FASTCGI
	$self->installPackage("mod_fcgid");
	
	#"wget http://mirror.tcpdiag.net/apache//httpd/mod_fcgid/mod_fcgid-2.3.9.tar.gz";
	
	#### TO MAKE APACHE LOAD THE MODULE, REPLACE FILE
	#### /etc/httpd/conf/httpd.conf
	#### TO CONTAIN LINE
	#### LoadModule cgi_module modules/mod_cgi.so
	my $sourcefile = "$Bin/resources/apache2/centos/httpd.conf";
	my $configfile	=	"/etc/httpd/conf/httpd.conf";
	my $backupfile	=	$self->incrementFile($configfile);
	my $force	=	1;
    $self->backupFile($configfile, $backupfile, $force);
    $self->replaceFile($configfile, $sourcefile, $force);   
}
method setApacheAutoStart {
#### SET COMMANDS TO BE RUN AT STARTUP FROM STARTUP SCRIPT
    my $startupfile	=	shift;

	my $arch		=	$self->getArch();
	my $apache		=	"apache2";
	$apache			=	"httpd" if $arch eq "centos";

# centos:
# chkconfig --levels 235 httpd on
# /etc/init.d/httpd restart

    $startupfile = "/etc/init.d/rc.local" if not defined $startupfile;
	$startupfile = "/etc/rc.local" if $arch eq "centos";
    $self->logDebug("startupfile", $startupfile);
	
    my $command = "/etc/init.d/$apache restart";
    my $contents = $self->fileContents($startupfile);
    $contents .="\n$command\n" if not $contents =~ /$command/ms;

    $self->toFile($startupfile, $contents);	
}

method restartApache {
	my $arch		=	$self->getArch();
	my $apache		=	"apache2";
	$apache			=	"httpd" if $arch eq "centos";

	my $commands		=	[
		"killall -9 /usr/sbin/$apache",
		"service $apache restart"
	];
	$self->logDebug("commands", $commands);
   
    return $self->runCommands($commands);
}

method replaceSourcesList {
	my $arch = $self->getArch();

	#### centos: /etc/yum.conf AND /etc/yum.repos.d/*
	return if not $arch eq "ubuntu";
	
	#### ubuntu VERSION
	my $version = $self->getUbuntuVersion();
	$self->logDebug("version", $version);		
	my $sourcefile = "$Bin/resources/ubuntu/$version/sources.list";
	
    #### REPLACE /etc/apt/sources.list
    $self->backupFile("/etc/apt/sources.list", "/etc/apt/sources.list.ORIGINAL", 0);
    $self->replaceFile("/etc/apt/sources.list", $sourcefile, 1);   
}

method createWwwDirs {
    my $wwwdir = $self->wwwdir();
    $self->createDir("$wwwdir/html");
    $self->createDir("$wwwdir/cgi-bin");
}

method linkWwwDirs {
	#### LINK DIRS INSIDE www DIRS
    my $linksfile	=	"$Bin/resources/agua/links.txt";
    $self->logDebug("linksfile", $linksfile);
    my $contents = $self->fileContents($linksfile);
    $self->logDebug("linksfile is empty", $linksfile) if not defined $contents or not $contents;

	$contents 		=	$self->replaceVariables($contents);
    my @lines 		= split "\n", $contents;
    foreach my $line ( @lines ) {
		next if $line =~ /^#/ or $line =~ /^\s*$/;
		my ($source, $target) = $line =~ /^(\S+)\s+(\S+)/;
	    $self->removeLink($target) if -l $target;
		
	    $self->addLink($source, $target);
    }
}

method replaceApacheConfs {
#### REPLACE apache2.conf, sites-available/default AND envvars

	my $apacheversion	=	$self->getApacheVersion();
	$self->logDebug("apacheversion", $apacheversion);
	
	#### SELECT apache2.conf FILE BASED ON VERSION
	my ($majorminor) = $apacheversion =~ /^(\d+\.\d+)/;
	$self->logDebug("majorminor", $majorminor);

	my $apacheconf = "$Bin/resources/apache2/ubuntu/2.2.2/apache2.conf";
	if ( $majorminor >= 2.4 ) {
		$self->logDebug("USING VERSION 2.4.6 apache2.conf");
		$apacheconf = "$Bin/resources/apache2/ubuntu/2.4.6/apache2.conf";
	}
	$self->logDebug("apacheconf", $apacheconf);

    #### REPLACE /etc/apache2/apache2.conf
    $self->backupFile("/etc/apache2/apache2.conf", "/etc/apache2/apache2.conf.ORIGINAL", 0);
    $self->replaceFile("/etc/apache2/apache2.conf", $apacheconf, 1);
    
    #### REPLACE /etc/apache2/sites-available/default TO:
    #### 1. SET HTML ROOT
    #### 2. ENABLE CGI-BIN
    #### 3. ALLOW FOLLOW SYMLINKS IN CGI-BIN (AVOID ERROR: 'method PUT not allowed')
    $self->backupFile("/etc/apache2/sites-available/default", "/etc/apache2/sites-available/default.ORIGINAL", 0);
    $self->replaceFile("/etc/apache2/sites-available/default", "$Bin/resources/apache2/ubuntu/sites-available/default", 1);
    
    #### REPLACE /etc/apache2/sites-available/default TO:
    #### 1. SET HTML ROOT
    #### 2. ENABLE CGI-BIN
    #### 3. ALLOW FOLLOW SYMLINKS IN CGI-BIN (AVOID ERROR: 'method PUT not allowed')
    $self->backupFile("/etc/apache2/sites-available/000-default.conf", "/etc/apache2/sites-available/000-default.conf.ORIGINAL", 0);
    $self->replaceFile("/etc/apache2/sites-available/000-default.conf", "$Bin/resources/apache2/ubuntu/sites-available/default", 1);

    #### REPLACE /etc/apache2/envvars TO:
    #### 1. SET UMASK (DEFAULT 775/664 FOR NEW FILES/DIRS)
    #### 2. SET SGE ENVIRONMENT VARIABLES
    $self->backupFile("/etc/apache2/envvars", "/etc/apache2/envvars.ORIGINAL", 0);
    $self->replaceFile("/etc/apache2/envvars", "$Bin/resources/apache2/ubuntu/envvars", 1);

	#### REPLACE agua WITH urlprefix IN apache2.conf
	my $urlprefix	=	$self->urlprefix();
	$self->logDebug("urlprefix", $urlprefix);
	
	my $remove = "/var/www/cgi-bin/agua/agua.cgi";
	my $insert = "/var/www/cgi-bin/$urlprefix/agua.cgi";

	$self->replaceInFile("/etc/apache2/apache2.conf", $remove, $insert);	
}

method replaceInFile ($file, $remove, $insert) {
#### REPLACE TEXT IN FILE WITH insert
	$self->logDebug("remove", $remove);
	$self->logDebug("insert", $insert);
	
	#### REMOVE EXISTING ENTRY FOR THESE VOLUMES
	my $oldend = $/;
	$/ = undef;
	open(FILE, $file) or die "Can't open file: $file\n";
	my $contents = <FILE>;
	close(FILE) or die "Can't close file: $file\n";
	#print "replaceInFile    contents: $contents\n";
		
	#### RESTORE FILE END
	$/ = $oldend;

	#### DO REPLACE
	$contents =~ s/$remove/$insert/g;
	
	return $self->toFile($file, $contents);
}

method toFile ($file, $text) {
#### SIMPLE ECHO REDIRECT TO FILE
	print "toFile    file: $file\n";	
	#print "text    text: $text\n";	

	my ($dir) = $file =~ /^(.+?)\/[^\/]+$/;
	my $found = -d $dir;
	`mkdir -p $dir` if not -d $dir;
	open(OUT, ">$file")or die "Can't open file: $file\n";
	print OUT $text;
	close(OUT) or die "Can't close file: $file\n";
}

method copyFavicon {
    my $wwwdir 		= 	$self->wwwdir();
    my $installdir 	= 	$self->installdir();

	my $favicon = "$installdir/html/favicon.ico";
    $self->runCommands(["cp $favicon $wwwdir"]);
}

method getApacheVersion {
	##Server version: Apache/2.4.6 (Ubuntu)
	##Server built:   Dec  5 2013 18:33:15
	my $command = qq{apachectl -v | grep "Server version"};
	$self->logDebug("command", $command);

	my $output = `$command`;

	my ($version)	= $output =~ /Server version:\s*Apache\/(\S+)/;
	$self->logDebug("version", $version);
		
	return $version;
}

1;