package Agua::Common::Sample;
use Moose::Role;
use Method::Signatures::Simple;


method loadSamples ($username, $project, $workflow, $workflownumber, $file) {
	my $table	=	"queuesample";
	$username	=	$self->username() if not defined $username;
	$project	=	$self->project() if not defined $project;
	$workflow	=	$self->workflow() if not defined $workflow;
	$workflownumber	=	$self->workflownumber() if not defined $workflownumber;
	
	$self->logError("username not defined") and return if not defined $username;
	$self->logError("project not defined") and return if not defined $project;
	$self->logError("workflow not defined") and return if not defined $workflow;
	$self->logError("workflownumber not defined") and return if not defined $workflownumber;
	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	$self->logDebug("workflownumber", $workflownumber);
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->logError("Can't find file: $file") and return if not -f $file;

	my $lines	=	$self->fileLines($file);
	$self->logDebug("no. lines", scalar(@$lines));

	#### SET DATABASE HANDLE	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();

	my $tsv = [];
	foreach my $line ( @$lines ) {
		my ($sample)	=	$line	=~ 	/^(\S+)/;
		#$self->logDebug("sample", $sample);
		
		my $out	=	"$username\t$project\t$workflow\t$workflownumber\t$sample\tnone";
		push @$tsv, $out;
	}
	
	my $outputfile	=	$file;
	$outputfile		=~	s/\.{2,3}$//;
	$outputfile		.=	"-querysample.tsv";
	my $output	=	join "\n", @$tsv;
	$self->logDebug("output", $output);

	$self->printToFile($outputfile, $output);
	
	my $success	=	$self->loadTsvFile($table, $outputfile);
	$self->logDebug("success", $success);
	
	return $success;	
}

method loadSampleFiles ($username, $project, $workflow, $workflownumber, $file) {
	my $table	=	"samplefile";
	$username	=	$self->username() if not defined $username;
	$project	=	$self->project() if not defined $project;
	$workflow	=	$self->workflow() if not defined $workflow;
	$workflownumber	=	$self->workflownumber() if not defined $workflownumber;
	
	$self->logError("username not defined") and return if not defined $username;
	$self->logError("project not defined") and return if not defined $project;
	$self->logError("workflow not defined") and return if not defined $workflow;
	$self->logError("workflownumber not defined") and return if not defined $workflownumber;
	$self->logDebug("username", $username);
	$self->logDebug("project", $project);
	$self->logDebug("workflow", $workflow);
	$self->logDebug("workflownumber", $workflownumber);
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->logError("Can't find file: $file") and return if not -f $file;

	my $lines	=	$self->fileLines($file);
	$self->logDebug("no. lines", scalar(@$lines));

	#### SET DATABASE HANDLE	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();

	my $tsv = [];
	foreach my $line ( @$lines ) {
		my ($sample)	=	$line	=~ 	/^(\S+)/;
		#$self->logDebug("sample", $sample);
		
		my $out	=	"$username\t$project\t$workflow\t$workflownumber\t$sample\tnone";
		push @$tsv, $out;
	}
	
	my $outputfile	=	$file;
	$outputfile		=~	s/\.{2,3}$//;
	$outputfile		.=	"-querysample.tsv";
	my $output	=	join "\n", @$tsv;
	$self->logDebug("output", $output);


	$self->printToFile($outputfile, $output);
	
	my $success	=	$self->loadTsvFile($table, $outputfile);
	$self->logDebug("success", $success);
	
	return $success;	
}

method fileLines ($file) {
#### GET THE LINES FROM A FILE
	my $contents = $self->fileContents($file); 
	return if not defined $contents;

	my @lines = split "\n", $contents;

	return \@lines;
}

method fileContents ($file) {
    $self->logDebug("Agua::Install::fileContents(file)");
    $self->logDebug("file", $file);
    die("Agua::Install::contents    file not defined\n") if not defined $file;
    die("Agua::Install::contents    Can't find file: $file\n$!") if not -f $file;

    my $temp = $/;
    $/ = undef;
    open(FILE, $file) or die("Can't open file: $file\n$!");
    my $contents = <FILE>;
    close(FILE);
    $/ = $temp;
    
    return $contents;
}

method loadTsvFile ($table, $file) {
	$self->logCaller("");
	return if not $self->can('db');
	
	$self->logDebug("table", $table);
	$self->logDebug("file", $file);
	
	$self->setDbh() if not defined $self->db();
	return if not defined $self->db();
	my $query = qq{LOAD DATA LOCAL INFILE '$file' INTO TABLE $table};
	my $success = $self->db()->do($query);
	$self->logCritical("load data failed") if not $success;
	
	return $success;	
}



1;