use MooseX::Declare;

class Test::Agua::Util with (Agua::Common::Logger, Agua::Common::Util) {

use Data::Dumper;
use Test::More;

#####///}}}}

method BUILD ($hash) {
}

method testFileTail ($sourcedir) {
	diag("Test fileTail");
	
	my $presentsource = "$sourcedir/inputs/present.txt";
	my $presenttarget = "$sourcedir/outputs/present";
    $self->logDebug("presentsource", $presentsource);
	$self->logDebug("presenttarget", $presenttarget);
    my $reset = 10;
	my $pause = 1;
	my $maxwait = 5;
	$self->stepPrint($presentsource, $presenttarget, 1, 1);
	ok($self->fileTail($presenttarget, "The cluster has been started and configured.", $pause, $maxwait, $reset), "Agua::Util::fileTail    found text in file");

	my $missingsource = "$sourcedir/inputs/missing.txt";
	my $missingtarget = "$sourcedir/outputs/missing";
	$self->stepPrint($missingsource, $missingtarget, 5, 1);
	sleep(2);
	ok(! $self->fileTail($missingtarget, "The cluster has been started and configured.", $pause, $maxwait, $reset), "Agua::Util::fileTail    text not in file");
}

method stepPrint ($sourcefile, $targetfile, $printlines, $pause) {
	$self->logDebug("sourcefile", $sourcefile);
	$self->logDebug("targetfile", $targetfile);
	$self->logDebug("printlines", $printlines);
	$self->logDebug("pause", $pause);

    #### READ SOURCE FILE
    open(FILE, $sourcefile) or die "Can't open sourcefile: $sourcefile\n";
    my @lines = <FILE>;
    close(FILE);
	$self->logDebug("no. lines: ", $#lines + 1, "");
    
	my $pid = fork();
	if ( $pid == 0 )
	{
        #### PRINT TO TARGET FILE IN printlines CHUNKS OF LINES
        open(OUT, ">$targetfile") or die "Can't open targetfile: $targetfile\n";
        my $counter = 0;
        while ( $counter < $#lines + 1 )
        {
            #print "******* counter: $counter ********\n";
            my $step = 0;
            while ( $step < $printlines and $counter < $#lines + 1 )
            {
                print OUT $lines[$counter];
                $step++;
                $counter++;
            }
            sleep($pause);
        }
        close(OUT) or die "Can't close targetfile: $targetfile\n";
        $self->logDebug("FINISHED PRINTING FILE");
		exit;
	}
    
    return;
}





}   #### Test::Agua::Util