use MooseX::Declare;

=head2

	PRINT FILE TO CLIENT FOR DOWNLOAD

=cut

use strict;
use warnings;
use Carp;

class Agua::Download with (Agua::Common::Base,
	Agua::Common::Database,
	Agua::Common::History,
	Agua::Common::Logger,
	Agua::Common::Privileges,
	Agua::Common::Transport,
	Agua::Common::Util)
{
#### EXTERNAL MODULES
use Data::Dumper;
#use FindBin qw($Bin);
#use lib "$Bin/..";
use FindBin::Real;
use lib FindBin::Real::Bin() . "/lib";

#### INTERNAL MODULES	
use Agua::JSON;

# Integers
has 'SHOWLOG'		=>  ( isa => 'Int', is => 'rw', default => 1 );  
has 'PRINTLOG'		=>  ( isa => 'Int', is => 'rw', default => 5 );
has 'validated'		=> ( isa => 'Int', is => 'rw', default => 0 );

# Strings
has 'input'			=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'fileroot'		=> ( isa => 'Str|Undef', is => 'rw', default => '' );
has 'username'  	=>  ( isa => 'Str', is => 'rw' );
has 'sessionId'     => ( isa => 'Str|Undef', is => 'rw' );
has 'workflow'  	=>  ( isa => 'Str', is => 'rw' );
has 'project'   	=>  ( isa => 'Str', is => 'rw' );
has 'outputdir'		=>  ( isa => 'Str', is => 'rw' );

# Objects
has 'jsonparser'	=> ( isa => 'JSON', is => 'rw', required => 0 );
has 'json'			=> ( isa => 'HashRef', is => 'rw', required => 0 );
has 'db'		=> ( isa => 'Agua::DBase::MySQL', is => 'rw', required => 0 );
has 'conf' 	=> (
	is =>	'rw',
	isa => 'Conf::Agua',
	default	=>	sub { Conf::Agua->new(	backup	=>	1, separator => "\t"	);	}
);

####////}}}

method BUILD ($hash) {
	$self->logDebug("");
	$self->initialise();
}

method initialise {
	$self->logDebug("");
	my $input = $self->input();

	my $jsonConverter = Agua::JSON->new();
	my $json = $jsonConverter->cgiToJson($input);
	print "Content-type: text/xml\n\n{ error: 'download.pl    json not defined' }\n" and exit if not defined $json;
	$self->json($json);
	$self->logDebug("json", $json);

	#### IF JSON IS DEFINED, ADD VALUES TO SLOTS
	if ( $json )
	{
		foreach my $key ( keys %{$json} ) {
			$json->{$key} = $self->unTaint($json->{$key});
			$self->$key($json->{$key}) if $self->can($key);
		}
	}
	$self->logDebug("json", $json);
	my $username = $self->username();
	$self->logDebug("username", $username);
	
	#### SET DATABASE HANDLE
	$self->setDbh();
	
	my $outfile = "/tmp/download-initialise.out";
	open(OUT, ">$outfile") or die "Can't open outfile: $outfile\n";
	print OUT "input: $input";
	$self->logDebug("input", $input);
	close(OUT) or die "Can't close outfile: $outfile\n";
   
	#### VALIDATE
    $self->logError("User session not validated for username: $username") and exit unless $self->validate();
}



}

1;

