package Agua::Common::History;
use Moose::Role;
use Moose::Util::TypeConstraints;

=head2

	PACKAGE		Agua::Common::History
	
	PURPOSE
	
            WORKFLOW HISTORY METHODS FOR Agua::Common
	
=cut

=head2

	SUBROUTINE		getHistory
	
	PURPOSE

		RETURN THE LIST OF WORKFLOW APPLICATIONS INCLUDING
		
		STARTED, COMPLETED, ETC. INFORMATON

=cut

sub getHistory {
	my $self		=	shift;
	$self->logDebug("Agua::Workflow::getHistory()");

    #### GET DATABASE OBJECT
        my $json         =	$self->json();
	
    #### VALIDATE    
    my $username = $json->{username};
    my $sessionid = $json->{sessionid};
	my $validated = $self->validate();
    $self->logError("User session not validated") and exit unless $validated;

	#### GET PROJECT WORKFLOWS THAT HAVE BEEN UPDATED MOST RECENTLY
	my $query = qq{select DISTINCT project,workflow
FROM stage
WHERE username='$username'
ORDER BY started,project,workflow};
	$self->logDebug("$query");
	my $project_workflows = $self->db()->queryhasharray($query);
	$self->logError("{}") and exit if not defined $project_workflows;
	
	#### GET HISTORY FOR EACH PROJECT WORKFLOW
	my $outputs;
	foreach my $projecthash ( @$project_workflows )
	{
		my $project = $projecthash->{project};
		my $workflow = $projecthash->{workflow};
		my $query = qq{select project, workflow, number, name, status, started, completed FROM stage
WHERE username='$username'
AND project='$project'
AND workflow='$workflow'
ORDER BY number ASC};
		$self->logDebug("$query");
		
		my $stages = $self->db()->queryhasharray($query);
		push @$outputs, $stages if defined $stages;
	}

	#### PRINT HISTORY
	use JSON -support_by_pp; 
	my $jsonParser = JSON->new();
	my $history = $jsonParser->allow_singlequote(1)->allow_nonref->loose(1)->pretty->encode($outputs);
	print $history;
}



=head2

	SUBROUTINE		downloadHistory
	
	PURPOSE

		SEND A FILE DOWNLOAD OF WORKFLOW APPLICATIONS

echo {"username":"syoung","sessionid":"1228791394.7868.158","mode":"downloadHistory"} | perl -U download.cgi

=cut


sub downloadHistory {
	my $self		=	shift;
	$self->logDebug("Workflow::downloadHistory()");

    #### GET DATABASE OBJECT
        my $json         =	$self->json();
	
    #### VALIDATE    
    my $username = $json->{username};
    my $sessionid = $json->{sessionid};
	my $validated = $self->validate();
    $self->logError("User session not validated") and exit unless $validated;

	#### GET PROJECTS AND WORKFLOWS
	my $query = qq{select DISTINCT project,workflow FROM stage WHERE username='$username' order by started};
	$self->logDebug("$query");
	my $project_workflows = $self->db()->queryhasharray($query);
	$self->logError("{}") and exit if not defined $project_workflows;

	#### CONVERT TO PROJECT:WORKFLOWS ARRAY HASH
	my $projects;
	
	my $current_project = $$project_workflows[0]->{project};
	my $workflow_array;
	foreach my $row ( @$project_workflows )
	{
		my $project = $row->{project};
		if ( $project eq $current_project )
		{
			push @$workflow_array, $row->{workflow};
		}
		else
		{
			push @$projects, { $current_project => $workflow_array };
			$current_project = $project;
			$workflow_array = undef;
			push @$workflow_array, $row->{workflow};
		}		
	}
	push @$projects, { $current_project => $workflow_array } if defined $workflow_array;

	my $output;
	foreach my $projecthash ( @$projects)
	{
		my ($project) = keys %$projecthash;
		my $workflows = $projecthash->{$project};
		$self->logDebug("project", $project);
		$self->logDebug("workflows: @$workflows");

		foreach my $workflow ( @$workflows )
		{
			my $query = qq{select * FROM stage WHERE username='$username' AND project='$project' and workflow='$workflow' ORDER BY number DESC};
			$self->logDebug("$query");
			my $applications = $self->db()->queryhasharray($query);

			$output .= qq{Project: $project\tWorkflow: $workflow\n};
			$output .= qq{\nApplication\tNumber\tStatus\tStarted\tCompleted\n};

			#### PRINT APPLICATION NAME, NUMBER, STATUS, STARTED AND COMPLETED
			foreach my $application ( @$applications )
			{
				#username            VARCHAR(30),
				#project             VARCHAR(30),
				#workflow            VARCHAR(60),
				#workflownumber      INT(12),
				#name                VARCHAR(60),
				#number              VARCHAR(10),
				#arguments           TEXT,
				#outputs             TEXT,
				#inputs              TEXT,
				#inputfiles          TEXT,
				#started             DATETIME,
				#completed           DATETIME,
				#workflowpid         INT(12),
				#parentpid           INT(12),
				#childpid            INT(12),
				#status              VARCHAR(20),
				#runnumber           INT(20),
				
				$output .= qq{$application->{name}\t$application->{number}\t$application->{status}\t$application->{started}\t$application->{completed}\n};
			
				my $inputshash = $application->{arguments};
				if ( defined $inputshash )
				{
					my $array = $self->parseHash($inputshash);
					my $lines = "\nInputs\n";
					$lines .= "name\tvalue\n";
					$lines .= join "", @$array;
					$output .= $lines;
				}
				
				my $outputshash = $application->{outputs};
				if ( defined $outputshash )
				{
					my $array = $self->parseHash($outputshash);
					my $lines = "\nOutputs\n";
					$lines .= "name\tvalue\n";
					$lines .= join "", @$array;
					$output .= $lines;
				}
			}
			
			$output .= "\n";
		}
	}

	#### PRINT HISTORY
	my $filesize = length($output);
	my $datetime = $self->datetime();	
	my $filename = "$username-agua-history-$datetime.txt";
	
	print qq{Content-type: application/x-download\n};
	print qq{Content-Disposition: attachment;filename="$filename"\n};
	print qq{Content-Length: $filesize\n\n};
	print $output;
}

1;