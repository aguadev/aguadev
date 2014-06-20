use MooseX::Declare;

use strict;
use warnings;

#### INTERNAL MODULES
use FindBin qw($Bin);
use lib "$Bin/../../";
use Agua::DBase;

class Mock::Virtual::Openstack extends Virtual::Openstack {

#### EXTERNAL MODULES
use Conf::Yaml;

# Ints
has 'log'	=>  ( isa => 'Int', is => 'rw', default => 2 );  
has 'printlog'	=>  ( isa => 'Int', is => 'rw', default => 2 );

# Strings

# Objects
has 'conf'			=> ( isa => 'Conf::Yaml', is => 'rw', required	=>	0 );
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', lazy	=>	1, builder	=>	"setJsonParser"	);
has 'ssh'			=> ( isa => 'Agua::Ssh', is => 'rw', lazy	=>	1, builder	=>	"setSsh"	);

####////}}}

method BUILD ($args) {
	$self->initialise($args);
}

method initialise ($args) {
	$self->logDebug("");
}

method createConfigFile ($object, $templatefile, $targetfile) {
	$self->logDebug("object", $object);
	$self->logDebug("templatefile", $templatefile);
	$self->logDebug("targetfile", $targetfile);

	# EDIT TEMPLATE 
	my $template		=	$self->getFileContents($templatefile);
	foreach my $key ( keys %$object ) {
		my $templatekey	=	uc($key);
		my $value	=	$object->{$key};
		#$self->logDebug("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}
	
	# PRINT TEMPLATE
	$self->printToFile($targetfile, $template);
}

method printAuthFile ($tenant, $templatefile, $targetfile) {
	$self->logDebug("tenant", $tenant);
	$self->logDebug("templatefile", $templatefile);
	$self->logDebug("targetfile", $targetfile);

	my $template		=	$self->getFileContents($templatefile);
	#$self->logDebug("template", $template);

	foreach my $key ( keys %$tenant ) {
		my $templatekey	=	uc($key);
		my $value	=	$tenant->{$key};
		#$self->logDebug("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}
	#$self->logDebug("template", $template);
	
	$self->printToFile($targetfile, $template);

	return $targetfile;
}

method launchNodes ($authfile, $amiid, $maxnodes, $instancetype, $userdatafile, $workflow) {
	$self->logDebug("authfile", $authfile);
	$self->logDebug("amiid", $amiid);
	
	return 1;
}

method printToFile ($file, $text) {
	$self->logDebug("file", $file);
	$self->logDebug("text", substr($text, 0, 100));

    open(FILE, ">$file") or die "Can't open file: $file\n";
    print FILE $text;    
    close(FILE) or die "Can't close file: $file\n";
}

method getFileContents ($file) {
	$self->logNote("file", $file);
	open(FILE, $file) or $self->logCritical("Can't open file: $file") and exit;
	my $temp = $/;
	$/ = undef;
	my $contents = 	<FILE>;
	close(FILE);
	$/ = $temp;

	return $contents;
}

method ($command) {
	$self->logDebug("command", $command);
	my $stdoutfile = "/tmp/$$.out";
	my $stderrfile = "/tmp/$$.err";
	my $output = '';
	my $error = '';
	
	#### TAKE REDIRECTS IN THE COMMAND INTO CONSIDERATION
	if ( $command =~ />\s+/ ) {
		#### DO NOTHING, ERROR AND OUTPUT ALREADY REDIRECTED
		if ( $command =~ /\s+&>\s+/
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>\s+/)
			or ( $command =~ /\s+1>\s+/ and $command =~ /\s+2>&1\s+/) ) {
			return `$command`;
		}
		#### STDOUT ALREADY REDIRECTED - REDIRECT STDERR ONLY
		elsif ( $command =~ /\s+1>\s+/ or $command =~ /\s+>\s+/ ) {
			$command .= " 2> $stderrfile";
			$output		= `$command`;
			$error 		= `cat $stderrfile`;
		}
		#### STDERR ALREADY REDIRECTED - REDIRECT STDOUT ONLY
		elsif ( $command =~ /\s+2>\s+/ or $command =~ /\s+2>&1\s+/ ) {
			$command .= " 1> $stdoutfile";
			print `$command`;
			$output = `cat $stdoutfile`;
		}
	}
	else {
		$command .= " 1> $stdoutfile 2> $stderrfile";
		print `$command`;
		$output = `cat $stdoutfile`;
		$error = `cat $stderrfile`;
	}
	
	$self->logNote("output", $output) if $output;
	$self->logNote("error", $error) if $error;
	
	##### CHECK FOR PROCESS ERRORS
	$self->logError("Error with command: $command ... $@") and exit if defined $@ and $@ ne "" and $self->can('warn') and not $self->warn();

	#### CLEAN UP
	`rm -fr $stdoutfile`;
	`rm -fr $stderrfile`;
	chomp($output);
	chomp($error);
	
	return $output, $error;
}


} #### END


