package Agua::Install::MySQL;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Method::Signatures;

use FindBin qw($Bin);

#### MYSQL
method installMysql {
    print "Agua::Install::installMysql\n";

	#### INSTALL PACAKGES
	$self->installMysqlPackages();

	#### REPLACED BY CALL TO mysql.pp
	######## EDIT CONFIG
	####$self->editMysqlConfig();

	#### MAKE MYSQL START AT BOOT
	$self->mysqlBootStart();
}

method installMysqlPackages {	
	#### MAKE MYSQL START AT BOOT
	#### EDIT CONFIG: ADD load-infile TO mysql AND mysqld SECTIONS
	#### NB: puppetlabs-mysql ALREADY INSTALLED BY librarian-puppet

	$self->logDebug("");

	#### LINK *.pp
	my $filename	=	"mysql.pp";
	$self->linkManifestFile($filename);

	#### APPLY *.pp FILE
	#### INSTALL MYSQL SERVER AND ENSURE IT STARTS AUTOMATICALLY AT BOOT
	$self->applyManifestFile($filename);
}

method mysqlBootStart {
	#### GET ARCHITECTURE
	my $arch = $self->getArch();
	$self->logDebug("arch", $arch);

	#### REPLACE /etc/init.d/mysqld
	my $installdir	=	$self->installdir();
	$self->replaceFile("/etc/init.d/mysqld", "/etc/init.d/mysqld.bkp", 0);
	$self->replaceFile("/etc/init.d/mysqld", "$installdir/bin/install/resources/mysql/init.d/mysqld", 1);
	
#    ##### START MYSQL AUTOMATICALLY AT BOOT
#    my $command = "sudo /sbin/chkconfig --level 2345 mysqld on";
#	#$command = "update-rc.d -f mysql defaults" if $arch eq "ubuntu";
#	$self->runCommands([$command]);

}
method editMysqlConfig {
	#### GET ARCHITECTURE
	my $arch = $self->getArch();
	$self->logDebug("arch", $arch);

    my $configfile = "/etc/mysql/my.cnf";
	$configfile = "/etc/my.cnf" if $arch eq "centos";

	#### BACKUP FILE
	my $backupfile 	=	$self->incrementFile($configfile);
	$self->logDebug("backupfile", $backupfile);
	my $force = 1;
	$self->backupFile($configfile, $backupfile, $force);
	
	require Conf::Ini;
	my $config = Conf::Ini->new({
		inputfile	=>	$configfile,
		separator	=>	"=",
		#showlog		=>	5
	});
	$self->logDebug("config", $config);
	
	$config->setKey("mysqld", "local-infile", 1);
	$config->setKey("mysql", "local-infile", 1);
	
    #### RESTART MYSQL
	my $restart = "service mysqld restart";
	$restart = "service mysql restart" if $arch eq "ubuntu";
    $self->runCommands([$restart]);
}

method createDir ($directory) {
    $self->logDebug("directory not defined") if not defined $directory;
    $self->logDebug("directory is a file", $directory) if -f $directory;
    return if -d $directory;
    
    print `mkdir -p $directory`;
    $self->logDebug("Can't create directory", $directory) if not -d $directory;
}


1;