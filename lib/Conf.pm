package Conf;
use Moose::Role;

#### EXTERNAL MODULES
use Data::Dumper;

# Booleans
has 'memory'  		=>  ( 	isa => 'Bool', 	is => 'rw',	default	=>	0 );

# Strings
has 'inputfile'  	=>  ( 	isa => 'Str|Undef', is => 'rw' );


=head2

	PACKAGE		Conf

    PURPOSE
    
        1. READ AND WRITE CONFIGURATION FILES WITH VARIOUS FORMATS
		
			[section name]
			KEY<SPACER>VALUE

			E.G.:

				[section name1]
				KEY1=VALUE1
				KEY2=VALUE2
	
				[section name2]
				KEY3=name2
				KEY4=VALUE3

			... AND yaml-FORMAT CONFIGURATION FILES:

				#qc quality of cancer samples
				build_qc_cancer_samples:
					gt_gen_concordance:
						- ge
						- 0.991
				
				error_emails:
					- anyusername@illumina.com
	
=cut


#### STUBS
sub hasKey {}
sub getKey {}
sub setKey {}
sub getKeys {}
sub removeKey {}

sub makeBackup {

=head2

	SUBROUTINE 		makeBackup
	
	PURPOSE
	
		COPY FILE TO NEXT NUMERICALLY-INCREMENTED BACKUP FILE

=cut

	my $self	=	shift;
	my $file	=	shift;
	
	$self->logWarning("file not defined") if not defined $file;
	
	#### BACKUP FSTAB FILE
	my $counter = 1;
	my $backupfile = "$file.$counter";
	while ( -f $backupfile )
	{
		$counter++;
		$backupfile = "$file.$counter";
	}
	$self->logNote("backupfile", $backupfile);

	require File::Copy;
	File::Copy::copy($file, $backupfile);
};


1;
