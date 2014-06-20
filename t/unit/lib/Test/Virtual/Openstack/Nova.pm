use MooseX::Declare;

use strict;
use warnings;

class Test::Openstack::Nova extends Openstack::Nova {

use FindBin qw($Bin);
use Test::More;
use JSON;

#####////}}}}}

#### Objects
has 'conf'	=> ( isa => 'Conf::Yaml', is => 'rw', lazy	=>	1, builder	=>	"setConf" );

method testParseVolumeId {
	diag("parseVolumeId");
	my $output	=	qq{	+---------------------+--------------------------------------+
	|       Property      |                Value                 |
	+---------------------+--------------------------------------+
	|     attachments     |                  []                  |
	|  availability_zone  |                 nova                 |
	|       bootable      |                false                 |
	|      created_at     |      2014-04-15T20:56:23.978298      |
	| display_description |                 None                 |
	|     display_name    |                 None                 |
	|          id         | e6f5625d-44c3-4aec-a8cb-890b48d1c01e |
	|       metadata      |                  {}                  |
	|         size        |                 100                  |
	|     snapshot_id     |                 None                 |
	|     source_volid    |                 None                 |
	|        status       |               creating               |
	|     volume_type     |                 SSD                  |
	+---------------------+--------------------------------------+
};

	my $volumeid	=	$self->parseVolumeId($output);
	$self->logDebug("volumeid", $volumeid);
	my $expected	=	"e6f5625d-44c3-4aec-a8cb-890b48d1c01e";
	
	ok($volumeid eq $expected, "volumeid");
}

method testParseLine {
	diag("parseLine");
	my $line	=	"| 69274f9b-3e54-41ab-ac12-e752e85802f5 | align.v2-4                                         | ACTIVE | -          | Running     | tenant_net=10.2.24.141, 132.249.227.120 |";
	my $array	=	$self->parseLine($line);
	my $expected	=	[
		"69274f9b-3e54-41ab-ac12-e752e85802f5",
		"align.v2-4",
		"ACTIVE",
		"-",
		"Running",
		"tenant_net=10.2.24.141, 132.249.227.120"
	];
	
	is_deeply($array, $expected, "line parsed");	
}

method testParseList {
	diag("parseList");
	
	my $listfile	=	"$Bin/inputs/novalist.txt";
	$self->logDebug("listfile", $listfile);
	my $list	=	$self->fileContents($listfile);
	$self->logDebug("list", $list);
	
	my $entries		=	$self->parseList($list);
	my $expected	=	$self->fileJson("$Bin/inputs/entries.json");
	#$self->logDebug("entries", $entries);
	#$self->logDebug("expected", $expected);
	
	is_deeply($entries, $expected, "entries");
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

method testGetExports {
	diag("getExports");
	my $configfile	=	"$Bin/inputs/config.yaml";
	$self->conf()->inputfile($configfile);
	
	my $exports	=	$self->getExports();

	my $exportsfile	=	"$Bin/inputs/exports.txt";
	my $expected	=	$self->fileContents($exportsfile);
	
	is_deeply($exports, $expected, "exports");
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

method identicalFiles ($actualfile, $expectedfile) {
	$self->logDebug("actualfile", $actualfile);
	$self->logDebug("expectedfile", $expectedfile);
	
	my $command = "diff -wB $actualfile $expectedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	
	return 1 if $diff eq '';
	return 0;
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

