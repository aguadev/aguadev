use MooseX::Declare;

use strict;
use warnings;

class Test::Openstack::Nova::Ips extends Openstack::Nova {

use FindBin qw($Bin);
use Test::More;
use JSON;

#####////}}}}}

#### Objects
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy	=>	1, builder	=>	"setConf" );
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw');

method testGetIps {
	diag("getIps");
	my $listfile	=	"$Bin/inputs/novalist.txt";
	my $ipsfile		=	"$Bin/inputs/ips.json";
	my $configfile	=	"$Bin/inputs/config.yaml";
	
	#### SET CONFIG
	$self->conf()->inputfile($configfile);

	*novaList = sub {
		return $self->fileContents($listfile);
	};
	
	my $ips	=	$self->getIps("dummy");
	#$self->logDebug("ips", $ips);

	my $expected	=	$self->fileJson($ipsfile);
	
	is_deeply($ips, $expected, "ips");
}

method fileContents ($file) {
	$self->logNote("file", $file);
	return undef if not -f $file;
	
	my $contents;
	open(FILE, $file) or die "Can't open file: $file\n";
	{
		$/ = undef;
		$contents	=	<FILE>;
	}
	close(FILE) or die "Can't close file: $file\n";
	$self->logNote("contents", $contents);
	
	return $contents;
}

method getJsonParser {
	return $self->jsonparser() if defined $self->jsonparser();
	my $jsonparser = JSON->new();
	$self->jsonparser($jsonparser);

	return $self->jsonparser();
}

method fileJson ($inputfile) {
	my $contents = $self->fileContents($inputfile);

	my $parser = $self->getJsonParser();
	return $parser->decode($contents);
}

method setConf {
	my $conf 	= Conf::Yaml->new({
		backup		=>	1,
		log		=>	$self->log(),
		printlog	=>	$self->printlog()
	});
	
	$self->conf($conf);
}



}

