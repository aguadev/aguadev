# BORROWED FROM: Status.pm
# http://perltraining.com.au/tips/2010-03-08.html
package Agua::CLI::Status;
use Moose::Role;

# PARSE OUTPUT AND EXTRACT STATUS SIGNALS

sub completionStatus {
	my $self		=	shift;
	my $outputs		=	shift;
	
	$outputs = [$outputs] if ref($outputs) ne "ARRAY";

	#### COLLECT JOB COMPLETION SIGNAL (AND SUBLABELS OF INCOMPLETE
	#### JOBS, MISSING FILES OR BOTH - I.E., FAILED JOBS)
	#### STATUS REPORTING HIERARCHY: completed < incomplete < missing < failed
	my $overall_status = "completed";
	my $overall_sublabels = '';
	my ($label, $status, $sublabels);
	foreach my $output (@$outputs)
	{
		if ( $output =~ /---\[status\s+(\S+):\s+(\S+)\s*(\S*)\]/ms )
		{
			$label = $1;
			$status = $2;
			$sublabels = $3;
			print "Job label '$label' completion signal: $status";
			$overall_status = "complete" if $status eq "complete"
				and $overall_status ne "incomplete"
				and $overall_status ne "missing"
				and $overall_status ne "failed";
			$overall_status = "incomplete" if $status eq "incomplete"
				and $overall_status ne "missing"
				and $overall_status ne "failed";
			$overall_status = "missing" if $overall_status ne "failed";
			$overall_status = "failed" if $status eq "failed";
			$overall_sublabels .= $sublabels . "," if $sublabels
				and $status ne "complete";
		}
	}
	
	return ($overall_status, $overall_sublabels);
}

no Moose::Role;

1;