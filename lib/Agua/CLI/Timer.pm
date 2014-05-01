package Agua::CLI::Timer;
use Moose::Role;
use Method::Signatures::Simple;

# USING CLASS MUST HAVE THESE VARIABLES:
#has 'status'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'locked'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'queued'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'started'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'stopped'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'duration'	    => ( isa => 'Str|Undef', is => 'rw', default => '' );
#has 'epochqueued'	=> ( isa => 'Maybe', is => 'rw', default => 0 );
#has 'epochstarted'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );
#has 'epochstopped'  => ( isa => 'Int|Undef', is => 'rw', default => 0 );
#has 'epochduration'	=> ( isa => 'Int|Undef', is => 'rw', default => 0 );

method timestamp () {
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp = sprintf "%4d-%02d-%02d %02d:%02d:%02d",
        $year+1900,$mon+1,$mday,$hour,$min,$sec;

    #print "Agua::CLI::Timer::setStarted    timestamp: ", $timestamp, "\n";

    return $timestamp;
}

method setStarted {
    $self->epochstarted(time);
    $self->started($self->timestamp());
    #print "Agua::CLI::Timer::setStarted    started: ", $self->started(), "\n";
}

method setStopped {
    $self->epochstopped(time);
    $self->stopped($self->timestamp());
}

method setDuration {
    $self->epochduration($self->epochstopped() - $self->epochstarted());
    my $duration = int($self->epochduration()/3600) . " hrs ";
    $duration .= int( ($self->epochduration() % 3600) / 60 ) . " mins ";
    $duration .= ($self->epochduration() % 60) . " secs";
    $self->duration($duration);
}



no Moose::Role;

1;