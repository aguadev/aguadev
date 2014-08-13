use MooseX::Declare;
=head2

	PACKAGE		Virtual::Openstack
	
    VERSION:        0.01

    PURPOSE
  
        1. UTILITY FUNCTIONS TO ACCESS A MYSQL DATABASE

=cut 

use strict;
use warnings;
use Carp;

#### INTERNAL MODULES
use FindBin qw($Bin);
use lib "$Bin/../../";
use Agua::DBase;

class Virtual::Openstack with (Logger, Virtual::Openstack::Nova) {

#### EXTERNAL MODULES
use Conf::Yaml;
use Agua::Ssh;


# Ints
has 'sleep'		=>  ( isa => 'Int', is => 'rw', default => 4 );  
has 'log'		=>  ( isa => 'Int', is => 'rw', default => 2 );  
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
	$self->logNote("");
}

method createConfig ($object, $templatefile, $targetfile, $extra) {
	$self->logNote("object", $object);
	$self->logNote("templatefile", $templatefile);
	$self->logNote("targetfile", $targetfile);

	# EDIT TEMPLATE 
	my $template		=	$self->getFileContents($templatefile);
	foreach my $key ( keys %$object ) {
		my $templatekey	=	uc($key);
		my $value	=	$object->{$key};
		#$self->logDebug("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}
	
	$template	=~ s/<EXTRA>/$extra/msg;
	
	# PRINT TEMPLATE
	$self->printToFile($targetfile, $template);
}

method printAuthFile ($tenant, $templatefile, $targetfile) {
	$self->logDebug("tenant", $tenant);
	$self->logNote("templatefile", $templatefile);
	$self->logNote("targetfile", $targetfile);

	my $template		=	$self->getFileContents($templatefile);
	#$self->logNote("template", $template);

	foreach my $key ( keys %$tenant ) {
		my $templatekey	=	uc($key);
		my $value	=	$tenant->{$key};
		#$self->logNote("substituting key $key value '$value' into template");
		$template	=~ s/<$templatekey>/$value/msg;
	}
	#$self->logNote("template", $template);
	
	$self->printToFile($targetfile, $template);

	return $targetfile;
}

method launchNode ($authfile, $amiid, $maxnodes, $instancetype, $userdatafile, $keypair, $workflow) {
	#$self->logDebug("authfile", $authfile);
	#$self->logDebug("amiid", $amiid);
	
	my $command	=	qq{. $authfile && \\
nova boot \\
--image $amiid \\
--flavor $instancetype \\
--key-name $keypair \\
--user-data $userdatafile \\
$workflow};
	$self->logDebug("command", $command);

	my ($out, $err) 	=	$self->runCommand($command);
	$self->logDebug("out", $out);
	$self->logDebug("err", $err);

	my $id	=	$self->parseNovaBoot($out);
	$self->logDebug("id", $id);
	
	return $id;
}

method parseNovaBoot ($output) {
	#$self->logDebug("output", $output);
	my ($id)	=	$output	=~ /\n\|\s+id\s+\|\s+(\S+)/ms;
	#$self->logDebug("id", $id);
	
	return $id;
}

method getNovaList ($authfile) {
	#$self->logDebug("authfile", $authfile);
	
	my $command		=	qq{. $authfile && nova list};
	my ($out, $err)	=	$self->runCommand($command);
	#$self->logDebug("out", $out);
	#$self->logDebug("err", $err);
	
	return $self->parseNovaList($out);
}

method parseNovaList ($output) {
	#$self->logDebug("output", $output);
	return if not defined $output or $output eq "";

	my @lines	=	split "\n", $output;
	my $hash		=	{};
	
	my $columns	=	$self->parseOutputColumns($output);
	foreach my $column ( @$columns ) {
		$column	=	lc($column);
		$column	=~	s/\s+//g;
	}
	#$self->logDebug("columns", $columns);
	
	foreach my $line ( @lines ) {
		next if $line =~ /^\+/ or $line	=~	/^\\|\s+ID/;
		
		my $entries	=	$self->splitOutputLine($line);	
		#$self->logDebug("entries", $entries);
		my $record	=	{};
		for ( my $i = 0; $i < @$columns; $i++ ) {
			$record->{$$columns[$i]}	=	$$entries[$i];
		}
		#$self->logDebug("record", $record);
		my $id	=	$$entries[0];
		$hash->{$id}	= $record;	
	}
	
	return $hash;
}

method parseOutputColumns ($output) {
	#$self->logDebug("output", $output);
	my ($line)	=	$output	=~ /^.+?(\|\s+ID[^\n]+)/msg;
	$self->logDebug("line", $line);

	return	$self->splitOutputLine($line);
}

method splitOutputLine ($line) {
	#$self->logDebug("line", $line);
	
	my @entries	=	split "\\|", $line;
	shift @entries;
	foreach my $entry ( @entries ) {
		$entry	=~	s/^\s+//;
		$entry	=~	s/\s+$//;
	}
	#$self->logDebug("entries", \@entries);
	
	return \@entries;	
}

method addNode {
	
	my $nodeid;
	
	return $nodeid;
}

method deleteNode ($authfile, $id) {
	$self->_deleteNode($authfile, $id);
	
	my $novalist	=	$self->getNovaList($authfile);
	
	my $taskstate	=	$novalist->{$id}->{taskstate};	
	$self->logDebug("taskstate", $taskstate);
	
	my $success = 0;
	$success = 1 if not defined $taskstate;
	$success = 1 if defined $taskstate and $taskstate eq "deleting";

	return $success;
}

method _deleteNode ($authfile, $id) {
	$self->logNote("authfile", $authfile);
	$self->logNote("id", $id);
	
	my $command		=	qq{. $authfile && nova delete $id};
	my ($out, $err)	=	$self->runCommand($command);
	$self->logNote("out", $out);
	$self->logNote("err", $err);
	
	return $self->parseNovaList($out);
}

method getQuotas ($authfile, $tenantid) {
	$self->logNote("authfile", $authfile);
	$self->logNote("tenantid", $tenantid);
	
	my $command	=	". $authfile && nova quota-show";
	$self->logNote("command", $command);
	
	return `$command`;
}

method printToFile ($file, $text) {
	$self->logNote("file", $file);
	$self->logNote("substr text", substr($text, 0, 100));

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

method runCommand ($command) {
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


