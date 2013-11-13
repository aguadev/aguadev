package Agua::Common;
use Moose::Role;

=head2

	PACKAGE		Agua::Common
	
	PURPOSE 	

		O-O MODULE CONTAINING COMMONLY-USED Agua METHODS
		
=cut

#### STRINGS/INTS	
has 'validated'	=> ( isa => 'Int', is => 'rw', default => 0 );
has 'cgi'		=> ( isa => 'Str|Undef', is => 'rw', default => undef );

use strict;
use warnings;
use Carp;

#### EXTERNAL MODULES
use FindBin qw($Bin);
use Data::Dumper;
use File::Path;
use File::Copy;
use File::Remove;
use File::stat;
use JSON;

with 'Agua::Common::Access';
with 'Agua::Common::Admin';
with 'Agua::Common::Ami';
with 'Agua::Common::App';
with 'Agua::Common::Aws';
with 'Agua::Common::Balancer';
with 'Agua::Common::Base';
with 'Agua::Common::Cluster';
with 'Agua::Common::Database';
with 'Agua::Common::File';
with 'Agua::Common::Group';
with 'Agua::Common::History';
with 'Agua::Common::Hub';
with 'Agua::Common::Logger';
with 'Agua::Common::Login';
with 'Agua::Common::Package';
with 'Agua::Common::Parameter';
with 'Agua::Common::Privileges';
with 'Agua::Common::Project';
with 'Agua::Common::Report';
with 'Agua::Common::SGE';
with 'Agua::Common::Shared';
with 'Agua::Common::Sharing';
with 'Agua::Common::Source';
with 'Agua::Common::Stage';
with 'Agua::Common::Ssh';
with 'Agua::Common::Transport';
with 'Agua::Common::User';
with 'Agua::Common::Util';
with 'Agua::Common::View';
with 'Agua::Common::Workflow';


1;