package Agua::Ops::S3;
use Moose::Role;
use Method::Signatures::Simple;

has 'filetype'		=> ( isa => 'Str|Undef', is => 'rw', default => 'ext3' );
has 'head' 			=> ( is =>	'rw', 'isa' => 'Agua::Instance', required	=>	0 );

use Net::Amazon::S3;

#### LIST
method listFiles ($id, $name, $description) {
	$self->logDebug("id", $id);
	
	#### GET EXISTING KEYS IF AVAILABLE
	my $aws = $self->getAws($self->username);	
	$self->logDebug("aws", $aws);

	
}









1;