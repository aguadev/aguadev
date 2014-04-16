use MooseX::Declare;

use strict;
use warnings;

class Test::Queue::Manager extends Queue::Manager {

has 'logfile'	=> 	( isa => 'Str|Undef', is => 'rw', required => 1 );

use FindBin qw($Bin);
use Test::More;

#####////}}}}}

method testWorkflowStatus {
	my $configfile	=	"$Bin/inputs/config.yaml";
	$self->conf()->inputfile($configfile);

	$self->workflowStatus();
}

method testDownloadPercent {
	diag("downloadPercent");
	my $status		=	q{Status:  195 GB downloaded (40.401% complete) current rate:        /s
};
	my $expected	=	"40.401";

	my $percent	=	$self->downloadPercent($status);
	is($percent, $expected, "percent");	
}

method testParseUuid {
	diag("parseUuid");
	my $contents	=	qq{root     18375  0.0  0.0   4400   604 ?        S    Apr12   0:00 sh -c time /usr/bin/gtdownload \?--max-children 8 \?-c /home/ubuntu/annai-cghub.key \?-v -d \?eba7900a-2e1d-4a55-a3ba-e900be55642e \?-l syslog:full?
root     18376  0.0  0.0   4168   348 ?        S    Apr12   0:00 time /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18377  0.0  0.0 156940 11796 ?        S    Apr12   0:23 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18378  1.4  0.4 641056 321376 ?       Sl   Apr12  55:57 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18382  1.5  0.4 641060 324292 ?       Sl   Apr12  56:36 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18386  1.3  0.4 641064 324900 ?       Sl   Apr12  51:28 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18390  1.4  0.4 641068 324672 ?       Sl   Apr12  54:10 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18394  1.6  0.4 641072 323988 ?       Sl   Apr12  62:22 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18398  1.3  0.4 641076 323128 ?       Sl   Apr12  50:52 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18402  1.3  0.4 641080 321196 ?       Sl   Apr12  51:05 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
root     18406  1.4  0.4 641084 325152 ?       Sl   Apr12  56:02 /usr/bin/gtdownload --max-children 8 -c /home/ubuntu/annai-cghub.key -v -d eba7900a-2e1d-4a55-a3ba-e900be55642e -l syslog:full
ubuntu   20477  0.0  0.0  11144  1540 pts/1    Ss+  13:50   0:00 bash -c ps aux | grep /usr/bin/gtdownload
ubuntu   20482  0.0  0.0   8112   920 pts/1    S+   13:50   0:00 grep /usr/bin/gtdownload
};
	my @lines		=	split "\n", $contents;
	my $expected	=	"eba7900a-2e1d-4a55-a3ba-e900be55642e";
	$self->logDebug("expected", $expected);
	
	my $uuid	=	$self->parseUuid(\@lines);
	$self->logDebug("uuid", $uuid);
	
	ok($uuid eq $expected, "uuid");	
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

method identicalFiles ($actualfile, $expectedfile) {
	$self->logDebug("actualfile", $actualfile);
	$self->logDebug("expectedfile", $expectedfile);
	
	my $command = "diff -wB $actualfile $expectedfile";
	$self->logDebug("command", $command);
	my $diff = `$command`;
	
	return 1 if $diff eq '';
	return 0;
}


}

