package Agua::Install::Https;
use Moose::Role;
use Moose::Util::TypeConstraints;
use Method::Signatures;

use FindBin qw($Bin);

#### HTTPS
method enableHttps {
	$self->logDebug("Agua::Install::enableHttps()");

	$self->logDebug("Doing generateCACert()");
	$self->generateCACert();
	
	$self->logDebug("Doing enableApacheSsl()");
	$self->enableApacheSsl();

	$self->logDebug("Doing restartApache()");
	$self->restartApache();	
}

method generateCACert {
=head2

	SUBROUTINE 		generateCACert
	
	PURPOSE
	
		GENERATE AUTHENTICATED CERTIFICATE FILE USING GIVEN PRIVATE KEY
		
		AND COPY TO APACHE conf DIR
		
		(NB: MUST RESTART APACHE TO USE NEW PUBLIC CERT)


	NOTES
	
		1. GET DOMAIN NAME
		
		2. CREATE CONFIG FILE
		
		3. GENERATE CERTIFICATE REQUEST
		
			openssl req
		
		4. GENERATE PUBLIC CERTIFICATE

			openssl x509 -req

		5. COPY TO APACHE AND RESTART APACHE

		NB: APACHE ssl.conf FILE SHOULD LOOK LIKE THIS:

			...		
			SSL Virtual Hosts
			<IfDefine SSL>
			
			<VirtualHost _default_:443>
			ServerAdmin webmaster@domain.com
			...
			SSLEngine on
			SSLCertificateFile /etc/httpd/conf/ssl.crt/server.crt
			SSLCertificateKeyFile /etc/httpd/conf/ssl.key/server.key
			SetEnvIf User-Agent ".*MSIE.*" nokeepalive ssl-unclean-shutdown
			CustomLog /var/log/httpd/ssl_request_log \
				"%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"
			</VirtualHost>
			
			</IfDefine>
			...

=cut

	#### SET FILES
	my $configdir			=	"$Bin/../../conf/.https";
	my $pipefile			=	"$configdir/intermediary.pem";
	my $CA_certfile			=	"$configdir/CA-cert.pem";
	my $configfile			=	"$configdir/config.txt";
	my $privatekey			=	"$configdir/id_rsa";

	#### MAKE DIRECTORY
	$self->logDebug("configdir", $configdir);
	`mkdir -p $configdir` if not -d $configdir;
	$self->logDebug("Could not create https configdir", $configdir) and return if not -d $configdir;
	
	#### 1. CREATE A PRIVATE KEY
	my $remove = "rm -fr $privatekey*";
	$self->logDebug("remove", $remove);
	`$remove`;
	my $command = qq{cd $configdir; ssh-keygen -t rsa -f $privatekey -q -N ''};
	$self->logDebug("command", $command);
	print `$command`;	

	#### 2. GET DOMAIN NAME
	my $domainname = $self->getDomainName();
	$self->logDebug("domainname", $domainname);
	my $distinguished_name 	= 	"agua_" . $domainname . "_DN";

	#### 3. GET APACHE INSTALLATION LOCATION
	my $apachedir 	= 	$self->apachedir();

	#### 4. CREATE CONFIG FILE
	open(OUT, ">$configfile") or die "Can't open configfile: $configfile\n"; 	
	print OUT qq{# SSL server cert/key parms
# Cert extensions
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always,issuer:always
basicConstraints        = CA:false
nsCertType              = server
# openssl req
[req]
default_bits            = 1024
prompt                  = no
distinguished_name      = $distinguished_name
# DN fields for SSL Server cert
[$distinguished_name]
C                       = US
ST                      = Maryland
O                       = UMCP/OIT/TSS/EIS
CN                      = $domainname
emailAddress            = trash\@trash.com
};
	close(OUT) or die "Can't close configfile: $configfile\n";

	#### 3. GENERATE CERTIFICATE REQUEST
	chdir($configdir);
	my $request = qq{openssl \\
req \\
-config $configfile \\
-newkey rsa:1024 \\
-key $privatekey \\
-out $pipefile
};
	$self->logDebug("request", $request);
	`$request`;
	$self->logDebug("Can't find pipefile", $pipefile) and return if not -f $pipefile;

	#### 4. GENERATE PUBLIC CERTIFICATE
	chdir($configdir);
	my $certify = qq{openssl \\
x509 -req \\
-extfile $configfile \\
-days 730 \\
-signkey $privatekey \\
-in $pipefile \\
-out $CA_certfile
};
	$self->logDebug("certify", $certify);
	`$certify`;
	$self->logDebug("Can't find CA_certfile", $CA_certfile) if not -f $CA_certfile;

	#### COPY THE PRIVATE KEY AND CERTIFICATE TO APACHE
	my $arch		=	$self->getArch();
	$self->logDebug("arch", $arch);
	
	#### SET KEYDIR
	my $keydir = "$apachedir/ssl.key";
	$keydir = "/etc/pki/tls/private" if $arch eq "centos";
	$keydir = "/private/etc/apache2/ssl" if $arch eq "osx";
	$self->logDebug("keydir", $keydir);

	#### CREATE KEYDIR
	`mkdir -p $keydir` if not -d $keydir;
	$self->logDebug("Can't create keydir", $keydir) if not -d $keydir;

	#### SET CERTDIR
	my $certdir = "$apachedir/ssl.key";
	$certdir = "/etc/pki/tls/certs" if $arch eq "centos";
	$certdir = "/private/etc/apache2/ssl" if $arch eq "osx";
	
	#### CREATE CERTDIR
	`mkdir -p $certdir` if not -d $certdir;
	$self->logDebug("Can't create certdir", $certdir) if not -d $certdir;
	
	#### COPY PRIVATE KEY
	my $copyprivate = "cp -f $privatekey $keydir/server.key";
	$self->logDebug("copyprivate", $copyprivate);
	`$copyprivate`;

	#### COPY CA CERTIFICATE
	my $copypublic = "cp -f $CA_certfile $certdir/server.crt";
	$self->logDebug("copypublic", $copypublic);
	`$copypublic`;
}

method enableApacheSsl {
	$| = 1;
	
	#### COPY SSL CONFIG FILE
	my $configpairs	=	$self->getSslConfigFiles();
	
	foreach my $configpair ( @$configpairs ) {
		my $source	=	$$configpair[0];
		my $target	=	$$configpair[1];

		$self->backupFile($target, "$target.bkp", 0);
		my $commands = [
			"cp $source $target",
			"chmod 755 $target"
		];
		$self->logDebug("commands", $commands);
		$self->runCommands($commands);
	}

	return $configpairs;
}

method getSslConfigFiles {
	my $arch	=	$self->getArch();
	
	return [
		[
			"$Bin/resources/apache2/ubuntu/sites-available/default-ssl",
			"/etc/apache2/sites-available/default-ssl"
		]
	] if $arch eq "ubuntu";

	return [
		[
			"$Bin/resources/apache2/centos/httpd.conf",
			"/etc/httpd/conf/httpd.conf"
		],
		[
			"$Bin/resources/apache2/centos/ports.conf",
			"/etc/httpd/conf/ports.conf"
		],
		[
			"$Bin/resources/apache2/centos/conf.d/15-default.conf",
			"/etc/httpd/conf.d/15-default.conf"
		],
		[
			"$Bin/resources/apache2/centos/conf.d/25-ssl.example.com.conf",
			"/etc/httpd/conf.d/25-ssl.example.com.conf"
		],
		[
			"$Bin/resources/apache2/centos/conf.d/ssl.conf",
			"/etc/httpd/conf.d/ssl.conf"
		]
	] if $arch eq "centos";

	return [
		[
			"$Bin/resources/apache2/osx/extra/httpd-ssl.conf",
			"/private/etc/apache2/extra/httpd-ssl.conf"
		]
	] if $arch eq "osx";
}

method getDomainName {	
	my $domainname = $self->domainname();
	$domainname = `facter domain` if not defined $domainname or not $domainname;
	chomp($domainname);

	return $domainname;
}


1;