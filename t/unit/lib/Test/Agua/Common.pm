package Test::Agua::Common;
use Moose::Role;

=head2

	PACKAGE		Agua::Common
	
	PURPOSE 	

		O-O ROLE MODULE CONTAINING COMMONLY-USED Agua METHODS
		
=cut

#### Strings
has 'outputdir'	=> ( isa => 'Str|Undef', is => 'rw', required => 0 );

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

with 'Test::Agua::Common::Database';
with 'Test::Agua::Common::Util';

1;