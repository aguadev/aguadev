package Agua::Install::Exchange;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Method::Signatures;

#### EXCHANGE
method installExchange {
#### SUMMARY: FIRST, INSTALL RABBITMQ AND START rabbit@myservername.
#### THEN, INSTALL RABBIT.JS AND START server.js
	$self->setConf() if not defined $self->conf();
	
	my $installdir 	= $self->installdir();
	my $install	=	$self->conf()->getKey("install", undef);
	$self->logDebug("install", $install);		
	
	my $nodeurl			=	$install->{NODEURL};
	my $amqpversion		=	$install->{AMQPVERSION};
	my $rabbitversion	=	$install->{RABBITVERSION};
	my $socketversion	=	$install->{SOCKETVERSION};
	$self->logDebug("installdir", $installdir);		
	$self->logDebug("nodeurl", $nodeurl);
	$self->logDebug("amqpversion", $amqpversion);
	$self->logDebug("rabbitversion", $rabbitversion);
	$self->logDebug("socketversion", $socketversion);
	
	#### INSTALL node AND PLUGINS rabbit.js, forever
	$self->installNode($nodeurl, $installdir);
	
	#### INSTALL rabbitmq
	$self->installRabbitMq();
	
	#### INSTALL rabbitmq
	$self->startRabbitMq();
	
	#$self->puppetInstallRabbitMq();
	#$self->puppetInstallNodeJs();
	
	#### 1. INSTALL node-amqp (A CLIENT FOR RABBITMQ)
	$self->runCommands(["npm install amqp\@$amqpversion -g"]);
	
	#### 2. INSTALL rabbit.js
	$self->runCommands(["npm install rabbit.js\@$rabbitversion -g"]);
	
	#### 3. INSTALL SOCKET.IO
	$self->runCommands(["npm install socket.io\@$socketversion -g"]);
	
	#### 4. INSTALL FOREVER
	$self->runCommands(["npm install forever -g"]);
	

	#### 5. SET EXCHANGE TO RUN AS A DAEMON
	$self->daemoniseExchange();

    #### 6. START EXCHANGE
    $self->startExchange();


	print "Installer::installExchange    END\n";
}
method daemoniseExchange {	
	#### COPY rabbitjs.conf FILE TO /etc/init
	my $installdir 	=	$self->installdir();
	$self->logDebug("installdir", $installdir);
    my $sourcefile 	= 	"$installdir/bin/install/resources/node/init/rabbitjs.conf";
    $self->logDebug("sourcefile", $sourcefile);
    my $contents 	= $self->fileContents($sourcefile);
	$contents 		=	$self->replaceVariables($contents);
    $self->logDebug("contents", $contents);

    my $targetfile 	= 	"/etc/init/rabbitjs.conf";
    if ( not -f $targetfile ) {
		#### COPY
		open(OUT, ">$targetfile") or die "Can't open targetfile: $targetfile\n";
		print OUT $contents;
		close(OUT) or die "Can't close targetfile: $targetfile\n";
	}	
}

method startExchange {
	my $installdir 	=	$self->installdir();
#	my $command  	=	"cd $installdir/apps/node-amqp/node_modules/rabbit.js/example/socketio; /usr/local/bin/forever server.js 2>&1 >> /var/log/rabbitjs-server.log &";
	my $command 	=	"/bin/sh $installdir/conf/run.sh";

	my $pid		=	fork();
	if ( $pid ) {
		$self->logDebug("PARENT. child pid: $pid. RETURNING");
		return;
	}
	elsif ($pid == 0) {
		$self->logDebug("CHILD. RUNNING COMMAND:\n\n$command\n");
		`$command`;
		exit 0;
	}	
}

method puppetInstallRabbitMq {
	#### INSTALL rabbitmq AND ITS erlang DEPENDENCY
	#### NB: librarian-puppet HAS ALREADY INSTALLED apache AND stdlib

	#### LINK *.pp FILE
	my $filename	=	"rabbitmq.pp";
	$self->linkManifestFile($filename);

	#### APPLY *.pp FILE
	#### INSTALL APACHE
	$self->applyManifestFile($filename);		
}

method puppetInstallNodeJs {
	#### INSTALL node AND MODULES express, rabbit.js, forever
	#### NB: librarian-puppet HAS ALREADY INSTALLED apache AND stdlib

	#### LINK *.pp FILE
	my $filename	=	"nodejs.pp";
	$self->linkManifestFile($filename);

	#### APPLY *.pp FILE
	#### INSTALL APACHE
	$self->applyManifestFile($filename);	
}

#### rabbit
method installRabbitMq {

	my $arch 	=	$self->getArch();
	
	if ( $arch eq "ubuntu" ) {
		#### SET source.list
		my $listfile 	=	"/etc/apt/sources.list";
		
		#### BACK UP sources.list
		$self->incrementedFileBackup($listfile);
	
		#### SET RabbitMQ LAUNCHPAD
		$self->setRabbitMqLaunchpad($listfile);	
		
		#### SET RabbitMQ SIGNING KEY
		$self->setRabbitMqKey($listfile);
		
		#### UPDATE APT-GET
		$self->updateAptGet();
		
		#### INSTALL RABBITMQ
		$self->runCommands([
			"sudo apt-get install -y rabbitmq-server"
		]);
	}
	elsif ( $arch eq "centos" ) {
		#### INSTALL RABBITMQ
		$self->runCommands([
			"sudo yum install -y rabbitmq-server"
		]);
	}
	

	#### SET RABBITMQ MAX OPEN FILE HANDLES
	$self->setRabbitMqFileHandles();
}
method setRabbitMqLaunchpad ($listfile) {
	### EDIT ADD RabbitMQ LAUNCHPAD TO REPOS
	$self->runCommands([
		"echo '\n\ndeb http://www.rabbitmq.com/debian/ testing main\n\n' >> $listfile",
	]);
}
method incrementedFileBackup ($filename) {
	my $backupfile 	=	$self->incrementFile($filename);
	print "Installer::incrementedFileBackup    backupfile: $backupfile\n";
	my $force = 1;
	
	return $self->backupFile($filename, $backupfile, $force);
}
method setRabbitMqKey ($listfile) {
	##### SET RabbitMQ SIGNING KEY
	my $tempdir = $self->tempdir() || "/tmp";
	$self->runCommands([
		"cd $tempdir; wget http://www.rabbitmq.com/rabbitmq-signing-key-public.asc",
		"cd $tempdir; sudo apt-key add rabbitmq-signing-key-public.asc",
	]);
}
method setRabbitMqFileHandles {
	#### SET MAX OPEN FILE HANDLES TO 1024 IN CONFIG FILE

	#### SET RABBITMQ SERVER CONFIG FILE
	#### This file is sourced by /etc/init.d/rabbitmq-server
	my $configfile	=	"/etc/default/rabbitmq-server";
	
	#### BACKUP CONFIGE FILE
	$self->incrementedFileBackup($configfile);
	
	#### Set the maximum number of file open handles for the RabbitMQ
	#### service process to 1024 (the default):
	$self->runCommands([
		"echo '\n\nulimit -n 1024\n\n' >> $configfile",
	]);
}
method startRabbitMq {
	#### START THE RABBITMQ SERVER
	my $command		=	"service rabbitmq-server start";
	$self->logDebug("command", $command);

	return `$command`;
}
method rabbitMqIsRunning {
	#### RETURN 1 IF RABBITMQ IS RUNNING, 0 OTHERWISE
	#my $command	=	"rabbitmqctl status";
	#my $output	=	`$command`;
	my $output 	=	`rabbitmqctl status 2>&1`;
	my $pattern 	=	"Error: unable to connect to node";

	return 1 if $output !~ /$pattern/ms;
	return 0;	
}
method stopRabbitMq {
	#### STOP THE RABBITMQ SERVER
	my $command	=	"service rabbitmq-server stop";
	
	return `$command`;
}
#### node.js
method installNode ($nodeurl, $installdir) {
	print "Installer::installNode    nodeurl: $nodeurl\n";	

	# INSTALL BUILD TOOLS
	my $arch	=	$self->getArch();
	if ( $arch eq "ubuntu" ) {
		$self->runCommand("apt-get install libssl-dev");
		$self->installPackage("build-essential g++");
	}
	elsif ( $arch eq "centos" ) {
		$self->runCommand("yum install gcc gcc-c++ kernel-devel");
		$self->runCommand("yum groupinstall \"Development Tools\" -y");
		$self->runCommand("yum install kernel-devel -y");
	}
	
	#### CREATE BASEDIR
	my $basedir	=	"$installdir/apps/node";
	`mkdir -p $basedir` if not -d $basedir;
	print "Installer::installNode     Can't create basedir: $basedir\n" if not -d $basedir;

	$self->runCommands([	
		"cd $basedir; wget $nodeurl"
		,"cd $basedir; tar xvfz node-*"
		, "cd $basedir/node-*; ./configure --prefix=/usr"
		, "cd $basedir/node-*; make"
		, "cd $basedir/node-*; make install"
	]);

	$self->runCommands([
		"cd /usr; wget http://www.npmjs.org/install.sh --no-check-certificate",
		"cd /usr; chmod 755 install.sh",
		"cd /usr; ./install.sh"
	]);
}


1;