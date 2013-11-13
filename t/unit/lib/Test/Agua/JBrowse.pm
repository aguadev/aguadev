use MooseX::Declare;

=head2

PACKAGE		Test::Agua::JBrowse

PURPOSE

	TEST bin/jbrowse APPLICATIONS
	
	E.G., bin/jbrowse/trackData.pl

        1. REMOVE outputs DIRECTORY
		
		2. COPY inputs DIRECTORY TO outputs DIRECTORY

		3. RUN trackData.pl
		
		4. CONFIRM DIFFERENCES BETWEEN FILES IN inputs AND outputs
		
=cut

use strict;
use warnings;

#### USE LIB FOR INHERITANCE
use FindBin qw($Bin);
use lib "$Bin/../";
use lib "$Bin/../external";
use Data::Dumper;

class Test::Agua::JBrowse extends Agua::JBrowse with Test::Agua::Common {

#### USE LIB
use FindBin qw($Bin);
use lib "$Bin/../../lib";

#### EXTERNAL MODULES
use Test::More;
use Data::Dumper;
use Term::ReadKey;
use File::Copy::Recursive;

#### INTERNAL MODULES
use Agua::DBaseFactory;
use Conf::Simple;

# STRINGS
has 'configfile'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'logfile'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'database'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );

####/////}

method BUILD {
	$self->logDebug("");
}

method testPretty ($originalfile, $inputfile, $application, $prettyfile) {
	diag("Test pretty");

	#### SET UP
	$self->setupFile($originalfile, $inputfile);

	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode pretty};
	$self->logDebug("command", $command);
	`$command`;
	
	$command = "diff -wB $inputfile $prettyfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	is($diff, '', "testPretty: input and pretty files are identical");

	#### CLEAN UP
	$self->setupFile($originalfile, $inputfile);
}

method testUnpretty ($originalfile, $inputfile, $application, $prettyfile, $unprettyfile) {
	diag("Test unpretty");
	
	#### SET UP: COPY PRETTY TO INPUT
	$self->setupFile($prettyfile, $inputfile);

	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode unpretty};
	$self->logDebug("command", $command);
	`$command`;
	
	$command = "diff -wB $inputfile $unprettyfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	is($diff, '', "testUnpretty: input and unpretty files are identical");

	#### CLEAN UP
	$self->setupFile($originalfile, $inputfile);
}

method testInsert ($originalfile, $inputfile, $application, $prettyfile, $insertedfile, $logfile, $key, $value) {
	diag("Test insert");
	
	#### SET UP: COPY PRETTY TO INPUT
	$self->setupFile($prettyfile, $inputfile);
	
	my $command = qq{$application \\
--inputfile "$inputfile" \\
--mode insert \\
--key $key \\
--value "$value"
};	
	$self->logDebug("command", $command);
	`$command`;

	$command = "diff -wB $inputfile $insertedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	is($diff, '', "testInsert: input and inserted files are identical");

	#### CLEAN UP
	$self->setupFile($originalfile, $inputfile);
}

method testMultiInsert ($originalfile, $inputfile, $application, $prettyfile, $multifile, $insertedfile, $logfile, $key, $value) {
	diag("Test multiInsert");
	$self->logDebug("multifile", $multifile);
	
	#### SET UP: COPY DIRECTORY OF INPUT FILES
	$self->setupDirs();
	
	#### RUN
	my $command = qq{$application \\
--inputfile "$multifile" \\
--mode pretty
};	
	`$command`;

	$command = qq{$application \\
--inputfile "$multifile" \\
--mode insert \\
--key $key \\
--value "$value"
};	
	$self->logDebug("command", $command);
	`$command`;

	$command = "diff -wB $inputfile $insertedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	is($diff, '', "testMultiInsert: input and inserted files are identical");
}


method setupDirs {
	#### CLEAN UP
	`rm -fr $Bin/outputs`;
	`cp -r $Bin/inputs $Bin/outputs`;
	`cd $Bin/outputs; find ./ -type d -exec chmod 0755 {} \\;; find ./ -type f -exec chmod 0644 {} \\;;`;
}

method setupFile ($sourcefile, $targetfile) {

	`cp $sourcefile $targetfile`;
	`chmod 644 $targetfile`;	
}




} #### Test::Agua::JBrowse