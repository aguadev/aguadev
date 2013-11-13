package Agua::Cluster::Loop;
use Moose::Role;
=head2

	PACKAGE		Agua::Cluster::Loop
	
	PURPOSE
	
		1. REPEATEDLY EXECUTE AN APPLICATION, CHANGING THE VALUE OF
		
			THE SPECIFIED PARAMETER EVERY TIME AND FOR A SPECIFIED NUMBER
			
			OF REPLICATES
		
		2. DO THE SAME FOR AN ARRAY OF WORKFLOW APPLICATIONS, CHANGING
		
			THE VALUES FOR DOWNSTREAM APPLICATIONS EACH TIME

	VERSION
	
		0.02	Added '--loop' option with args 'serial', 'parallel' and 'distributed'
	
		O.01	Basic loop with serial or 'concurrent'
	
=cut

use strict;
use warnings;

# STRINGS
has 'arguments'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'executable'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'parameter'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'values'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'replicates'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'concurrent'	=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'loopout'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'label'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );

#### EXTERNAL MODULES
use Data::Dumper;
use File::Path;
use threads qw(yield);

=head2

	SUBROUTINE		runLoop
	
	PURPOSE
	
		RUN THE APPLICATION FOR THE DESIGNATED PERMUTATION OF LOOPS

=cut

sub runLoop {
	my $self		=	shift;

	#### GET ARGUMENT VALUES
	my $executable 	=	$self->loop_value("executable");
	my $parameter 	= 	$self->loop_value("parameter");
	my $values 		= 	$self->loop_value("values");
	my $replicates 	= 	$self->loop_value("replicates");
	my $loop 		= 	$self->loop_value("loop");
	my $loopout 	= 	$self->loop_value("loopout");
	my $label 		=	$self->loop_value("looplabel");
	
	#### EXTRACT CLUSTER-RELATED ARGUMENTS IF loop IS distributed
	my ($cluster, $outdir, $maxjobs, $queue);
	if ( $loop eq "distributed" )
	{
		$cluster=	$self->loop_value("cluster");
		$outdir =	$self->loop_value("outdir");
		$maxjobs=	$self->loop_value("maxjobs");
		$queue	=	$self->loop_value("queue");

		$self->loop_value("walltime");
		$self->loop_value("cpus");
		$self->loop_value("qstat");
		$self->loop_value("qsub");
		$self->loop_value("sleep");
		$self->loop_value("cleanup");
		$self->loop_value("dot");
	}

	my $oldout;
	if ( defined $loopout )
	{
		$self->logDebug("Printing STDOUT to loopout:\n\n$loopout\n");

		open $oldout, ">&STDOUT" or die "Can't open old STDOUT\n";
		#open $olderr, ">&STDERR" or die "Can't open old STDERR\n";
	
		my ($loopout_path) = $loopout =~ /^(.+)\/[^\/]+$/;
		File::Path::mkpath($loopout_path) if not -d $loopout_path;
		open(STDOUT, ">$loopout") or die "Can't open STDOUT file: $loopout\n" if defined $loopout;
	}

	#### GET THE REMAINING ARGUMENTS FOR THE EXECUTABLE
	my $arguments	=	$self->get_arguments();
	$self->logDebug("executable", $executable);
	$self->logDebug("parameter", $parameter) if defined $parameter;
	$self->logDebug("values", $values) if defined $values;
	$self->logDebug("replicates", $replicates) if defined $replicates;
	$self->logDebug("loop", $loop) if defined $loop;
	$self->logDebug("cluster", $cluster) if defined $cluster;
	$self->logDebug("outdir", $outdir) if defined $outdir;
	$self->logDebug("label", $label) if defined $label;

	#### CHECK loop IS DEFINED AND CORRECT VALUE
	$self->logCritical("loop not defined. Exiting") and exit if not defined $loop;
	if ( $loop eq "distributed" )
	{
		$self->logCritical("cluster not defined. Exiting") and exit if not defined $cluster;
		$self->logCritical("label not defined. Exiting") and exit if not defined $label;
		$self->logCritical("outdir not defined. Exiting") and exit if not defined $outdir;
		$self->logCritical("maxjobs not defined. Exiting") and exit if not defined $maxjobs;
		$self->logCritical("queue not defined. Exiting") and exit if not defined $queue;
	}

	$self->logCritical("loop value not supported: $loop") and exit
		if $loop !~ /^(serial|parallel|distributed)$/;
	
	$self->logDebug("Neither parameter nor replicates is defined. Exiting.") if not defined $parameter and not defined $replicates;
	$self->logDebug("values not defined for parameter. Exiting.") if defined $parameter and not defined $values;
	
	#### GET VALUES AND REPLICATES ARRAYS
	my $values_array = [];
	@$values_array = split ",", $values if defined $values;
	
	my $replicates_array = $self->stringToArray($replicates);
	#### GET LOOPED COMMANDS
	my $commands = $self->loop($executable, $arguments, $parameter, $values_array, $replicates_array);
#	$self->logDebug("Number commands: " . scalar(@$commands));
#	$self->logDebug("commands[0]: ");
#	print $$commands[0];

	#### COLLECT OVERALL STATUS AND FAILED OR DUBIOUS JOB LABELS
	my $status = 'unknown';
	my $sublabels = '';

	#### RUN COMMANDS ON CLUSTER
	if ( $loop eq "distributed" )
	{
		$self->logDebug("Running loop in $loop mode");
		
		my $jobs = [];
		for ( my $i = 0; $i < @$commands; $i++ )
		{
			my $replicate_number = $$replicates_array[$i];
			my $command = $$commands[$i];
			my $joblabel = "$label-$replicate_number";
			my $scriptfile = "$outdir/$label-$replicate_number.sh";
			my $usagefile = "$outdir/$label-$replicate_number-usage.txt";
			my $stdoutfile = "$outdir/$label-$replicate_number-stdout.txt";
			my $stderrfile = "$outdir/$label-$replicate_number-stderr.txt";

			my $job = $self->setJob([$command], $joblabel, $outdir, $scriptfile, $usagefile, $stdoutfile, $stderrfile);
			push @$jobs, $job;
		}

		#### USE LIB FOR CLUSTER MONITOR
		$self->logDebug("cluster: **$cluster**");

		if ( $cluster =~ /^PBS$/ )
		{
			$self->logDebug("DOING require Monitor::PBS");
			eval "require Monitor::PBS";
		}
		elsif ( $cluster =~ /^LSF$/ )
		{
			$self->logDebug("DOING require Monitor::LSF");
			eval "require Monitor::LSF";
		}
		elsif ( $cluster =~ /^SGE$/ )
		{
			$self->logDebug("DOING require Monitor::LSF");
			eval "require Monitor::SGE";
		}
		else
		{
			$self->logDebug("cluster $cluster did not match LSF or PBS");
		}

		#### WILL AUTOMATICALLY CHECK OUTPUTS FOR COMPLETION
		#### AND PRINT STATUS SIGNAL TO STDOUT 
		($status, $sublabels) = $self->runJobs($jobs, $label);
		
		#### PRINT JOB STATUS SIGNAL
		$self->logCritical("\n------------------------------------------------------------");
		$self->logCritical("---[status $label: $status $sublabels]---");
		$self->logCritical("\n------------------------------------------------------------");		

		$self->logDebug("Finished doing distributed jobs");
	}
	
	#### RUN COMMANDS IN PARALLEL LOCALLY
	elsif ( $loop eq "parallel" )
	{
		$self->logDebug("DOING CONCURRENT JOBS");
		my $threads = [];
		for my $command ( @$commands )
		{
			$self->logDebug("CONCURRENT", $command);
			my $thread = threads->new(
				sub {
					return `$command`;
				}
			);
			sleep(1);
			push @$threads, $thread;
		}

		my $outputs = [];
		foreach my $thread ( @$threads )
		{
			my $output = $thread->join;
			$self->logDebug("OUTPUT", $output);
			push @$outputs, $output;
		}

		#### CHECK OUTPUTS FOR COMPLETION
		($status, $sublabels) = $self->completionStatus($outputs);

		#### PRINT JOB STATUS SIGNAL
		$self->logCritical("\n------------------------------------------------------------");
		$self->logCritical("---[status $label: $status $sublabels]---");
		$self->logCritical("\n------------------------------------------------------------");		
		
		$self->logDebug("Finished doing parallel jobs");
	}
	
	#### RUN COMMANDS IN SERIES
	elsif ( $loop eq "serial" )
	{
		$self->logDebug("Running loop in 'serial' mode");

		#### RUN THE COMMANDS
		my $outputs = [];
		foreach my $command ( @$commands )
		{
			$self->logDebug("$command");
			my $output = `$command`;
			push @$outputs, $output;
		}
		
		#### CHECK OUTPUTS FOR COMPLETION 
		($status, $sublabels) = $self->completionStatus($outputs);
		
		($label) = $executable =~ /([^\/]+)$/ if not defined $label;
		
		#### PRINT JOB STATUS SIGNAL
		$self->logCritical("\n------------------------------------------------------------");
		$self->logCritical("---[status $label: $status $sublabels]---");
		$self->logCritical("\n------------------------------------------------------------");		

		$self->logDebug("Finished doing distributed jobs");
	}
	else
	{
		$self->logCritical("Exiting. Missing handler for loop mode", $loop);
		exit;
	}


	##### RESTORE OLD STDOUT 
	if ( defined $oldout )
	{
		$self->logDebug("Redirecting STDOUT back to standard output");
		open STDOUT, ">&", $oldout;
	}
	
	#### PRINT JOB STATUS SIGNAL
	$self->logCritical("\n------------------------------------------------------------");
	$self->logCritical("---[status $label: $status $sublabels]---");
	$self->logCritical("\n------------------------------------------------------------");
}

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
			$self->logDebug("Job label '$label' completion signal", $status);
			$overall_status = "complete" if $status eq "complete"
				and $overall_status ne "incomplete"
				and $overall_status ne "missing"
				and $overall_status ne "failed";
			$overall_status = "incomplete" if $status eq "incomplete"
				and $overall_status ne "missing"
				and $overall_status ne "failed";
			$overall_status = "missing" if $overall_status eq "missing"
				and $overall_status ne "failed";
			$overall_status = "failed" if $status eq "failed";
			$overall_sublabels .= $sublabels . "," if $sublabels
				and $status ne "complete";
		}
	}
	
	return ($overall_status, $overall_sublabels);
}

	

=head2

	SUBROUTINE		loop
	
	PURPOSE
	  
        1. REPEATEDLY EXECUTE AN APPLICATION, CHANGING THE VALUE OF
		
			THE SPECIFIED PARAMETER EVERY TIME
		
		2. REPEAT FOR A SPECIFIED NUMBER OF REPLICATES

    INPUT

        1. EXECUTABLE AND ITS ARGUMENTS (WITH STRING '%VALUE%' 
		
			IN THE PLACE OF THE ACTUAL PARAMETER VALUE)
		
		2. PARAMETER TO BE CHANGED
		
		3. COMMA-SEPARATED LIST OF VALUES FOR THE PARAMETER
		
		4. COMMA-SEPARATED LIST OF REPLICATES
        
    OUTPUT
    
        1. OUTPUTS OF EACH RUN OF THE EXECUTABLE USING A
		
			DIFFERENT VALUE FOR THE PARAMETER EACH TIME

=cut

sub loop {

	my $self		=	shift;
	my $executable	=	shift;
	my $arguments	=	shift;
	my $parameter	=	shift;
	my $values		=	shift;
	my $replicates	=	shift;
	$self->logDebug("Agua::Logic::Loop::loop(executable, arguments, parameter, values, replicates)");
	$self->logDebug("executable", $executable);
	$self->logDebug("arguments:  @$arguments");
	$self->logDebug("parameter", $parameter) if defined $parameter;
	$self->logDebug("values:     @$values") if defined $values;
	$self->logDebug("replicates: @$replicates") if defined $replicates;

	my $commands;

	#### RUN replicates TIMES WITH values VALUES
	for ( my $counter = 0; $counter < @$replicates; $counter++ )
	{
		my $replicate = $$replicates[$counter];
		if ( defined $parameter )
		{
			for ( my $i = 0; $i < @$values; $i++ )
			{
				my $instance_args;
				@$instance_args = @$arguments;
				
				my $value = $$values[$i];
		
				#### SUBSTITUTE replicate FOR ONE OR MORE '%REPLICATE%' STRINGS IN ALL ARGUMENTS
				$instance_args = $self->fill_in($instance_args, "%REPLICATE%", $replicate);
		
				#### SUBSTITUTE value FOR ONE OR MORE '%VALUE%' STRINGS IN ALL ARGUMENTS
				$instance_args = $self->fill_in($instance_args, "%VALUE%", $value);
		
				#### SUBSTITUTE parameter FOR ONE OR MORE '%PARAMETER%' STRINGS IN ALL ARGUMENTS
				$instance_args = $self->fill_in($instance_args, "%PARAMETER%", $parameter);
		
				#### ADD parameter ARGUMENT TO FRONT OF ARGS
				unshift @$instance_args, "$parameter $value";
	
				my $command = "$executable @$instance_args";
				push @$commands, $command;
			}
		}
		else
		{
			my $instance_args;
			@$instance_args = @$arguments;
	
			#### SUBSTITUTE replicate FOR ONE OR MORE '%REPLICATE%' STRINGS IN ALL ARGUMENTS
			$instance_args = $self->fill_in($instance_args, "%REPLICATE%", $replicate);
	
			foreach my $arg ( @$instance_args )
			{
				$arg = qq{"$arg"};
			}
			
			my $command = "$executable @$instance_args";

			$self->logDebug("command", $command);
			push @$commands, $command;
		}
	}
	
	return $commands;
}

=head2

	SUBROUTINE		set_parameter
	
	PURPOSE
	
		SET THE VALUE OF A PARAMETER IN arguments

=cut
sub set_parameter {
	my $self		=	shift;
	my $arguments		=	shift;
	my $parameter			=	shift;
	my $value			=	shift;
	$self->logDebug("Agua::Logic::Loop::set_parameter(arguments, parameter, value)");
	$self->logDebug("parameter", $parameter);
	$self->logDebug("value", $value);
	
	for ( my $i = 0; $i < @$arguments; $i++ )
	{
		if ( "--$parameter" eq $$arguments[$i] )
		{
			$$arguments[$i + 1] = $value;
			return $arguments;
		}	
	}
	
	return $arguments;
}



=head2

	SUBROUTINE		fill_in
	
	PURPOSE
	
		SUBSTITUTE counter FOR ONE OR MORE '%REPLICATE%' STRINGS IN ALL ARGUMENTS

=cut
sub fill_in {
	my $self		=	shift;
	my $arguments		=	shift;
	my $pattern			=	shift;
	my $value			=	shift;

	foreach my $argument ( @$arguments )
	{
		$argument =~ s/$pattern/$value/ig;
	}

	return $arguments;
}


=head2

	SUBROUTINE		loop_value
	
	PURPOSE
	
		1. EXTRACT THE VALUE FOR THE NAMED ARGUMENT FROM THE arguments
		
			ARRAY AND RETURN IT
			
		2. REPLACE THE EXITING arguments ARRAY WITH THE NEWLY TRUNCATED ONE

=cut

sub loop_value {
	my $self			=	shift;
	my $name			=	shift;
	my $arguments		=	$self->get_arguments();

	my $value;
	for ( my $i = 0; $i < @$arguments; $i++ )
	{
		if ( "--$name" eq $$arguments[$i] )
		{
			$value = $$arguments[$i + 1];
			splice @$arguments, $i, 2;
			$self->{"_$name"} = $value;
		}
	}
	$self->set_arguments($arguments);
	#$self->{_arguments} = $arguments;
	
	return $value;
}







=head2

	SUBROUTINE		oldLoop
	
	PURPOSE
	  
        1. REPEATEDLY EXECUTE AN APPLICATION, CHANGING THE VALUE OF
		
			A PARTICULAR PARAMETER EVERY TIME
		
		2. REPEAT FOR A SPECIFIED NUMBER OF REPLICATES

    INPUT

        1. EXECUTABLE AND ITS ARGUMENTS (WITH STRING '%VALUE%' 
		
			IN THE PLACE OF THE ACTUAL PARAMETER VALUE)
		
		2. PARAMETER TO BE CHANGED
		
		3. COMMA-SEPARATED LIST OF VALUES FOR THE PARAMETER
		
		4. COMMA-SEPARATED LIST OF REPLICATES
        
    OUTPUT
    
        1. OUTPUTS OF EACH RUN OF THE EXECUTABLE USING A
		
			DIFFERENT VALUE FOR THE PARAMETER EACH TIME

=cut

sub oldLoop {
	my $self		=	shift;
	my $executable	=	shift;
	my $arguments	=	shift;
	my $parameter	=	shift;
	my $values		=	shift;
	my $replicates	=	shift;
	
	#### RUN replicates TIMES WITH values VALUES
	for ( my $counter = 0; $counter < @$replicates; $counter++ )
	{
		my $replicate = $$replicates[$counter];
		for ( my $i = 0; $i < @$values; $i++ )
		{
			my $instance_args;
			@$instance_args = @$arguments;
			
			my $value = $$values[$i];
	
			#### SUBSTITUTE replicate FOR ONE OR MORE '%REPLICATE%' STRINGS IN ALL ARGUMENTS
			$instance_args = fill_in($instance_args, "%REPLICATE%", $replicate);
	
			#### SUBSTITUTE value FOR ONE OR MORE '%VALUE%' STRINGS IN ALL ARGUMENTS
			$instance_args = fill_in($instance_args, "%VALUE%", $value);
	
			#### SUBSTITUTE parameter FOR ONE OR MORE '%PARAMETER%' STRINGS IN ALL ARGUMENTS
			$instance_args = fill_in($instance_args, "%PARAMETER%", $parameter);
	
			my $command = "$executable @$instance_args";
			$self->logDebug("command", $command);
			
			`$command`;		
		}
	}
}



1;

