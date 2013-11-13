package Agua::Cluster::Cleanup;
use Moose::Role;
use Moose::Util::TypeConstraints;

use Data::Dumper;
################################################################################
##########################      CLEANUP METHODS       ##########################
################################################################################
=head2

	SUBROUTINE     deleteMiscfiles
	    
    PURPOSE
  
        REMOVE THE ALIGNMENT SUBDIRS USED TO PERFORM INPUT FILE CHUNK ALIGNMENTS

    INPUT

        1. LOCATION OF OUTPUTDIR 

=cut

sub deleteMiscfiles {
	my $self		=	shift;
	my $directory	=	shift;
	my $references	=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logInfo("directory not defined: $directory") if not defined $directory or not $directory;
	$self->logInfo("directory is '': $directory") if not defined $directory;
	$self->logInfo("Can't find directory: $directory") if not -d $directory;

	##### CHDIR TO OUTPUT DIRECTORY
	#chdir($directory) or die "Could not CHDIR to directory: $directory\n";
	#opendir(DIR, $directory) or die "Can't open directory: $directory\n";
	#my @subdirs = readdir(DIR);
	#close(DIR);
	#
	#foreach my $subdir ( @subdirs )
	#{
	#	next if not $subdir =~ /^\d+$/;
	#	$self->logInfo("subdir: $subdir");
	#	
	#	foreach my $reference ( @$references )
	#	{
	#		my $refdir = "$directory/$subdir/$reference";
	#		opendir(REFDIR, $refdir) or die "Can't open refdir: $refdir\n";
	#		my @reffiles = readdir(REFDIR);
	#		close(REFDIR);
	#		
	#		foreach my $reffile ( @reffiles )
	#		{
	#			next if not $reffile =~ /^\d+$/;
	#			$self->logInfo("rm -fr $refdir/$reffile");
	#			`rm -fr $refdir/$reffile`;
	#		}
	#	}
	#}
	
}



=head2

	SUBROUTINE     archiveMiscfiles
	    
    PURPOSE
  
        REMOVE THE ALIGNMENT SUBDIRS USED TO PERFORM INPUT FILE CHUNK ALIGNMENTS

    INPUT

        1. LOCATION OF OUTPUTDIR 

=cut

sub archiveMiscfiles {
	my $self		=	shift;
	my $directory	=	shift;
	my $references	=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logInfo("directory not defined: $directory") if not defined $directory or not $directory;
	$self->logInfo("directory is '': $directory") if not defined $directory;
	$self->logInfo("Can't find directory: $directory") if not -d $directory;

	##### CHDIR TO OUTPUT DIRECTORY
	#chdir($directory) or die "Could not CHDIR to directory: $directory\n";
	#opendir(DIR, $directory) or die "Can't open directory: $directory\n";
	#my @subdirs = readdir(DIR);
	#close(DIR);
	#
	#foreach my $subdir ( @subdirs )
	#{
	#	next if not $subdir =~ /^\d+$/;
	#	$self->logInfo("subdir: $subdir");
	#	
	#	foreach my $reference ( @$references )
	#	{
	#		my $refdir = "$directory/$subdir/$reference";
	#		opendir(REFDIR, $refdir) or die "Can't open refdir: $refdir\n";
	#		my @reffiles = readdir(REFDIR);
	#		close(REFDIR);
	#		
	#		foreach my $reffile ( @reffiles )
	#		{
	#			next if not $reffile =~ /^\d+$/;
	#			$self->logInfo("rm -fr $refdir/$reffile");
	#			`rm -fr $refdir/$reffile`;
	#		}
	#	}
	#}	
}

=head2

	SUBROUTINE     deleteAlignmentSubdirs
	    
    PURPOSE
  
        REMOVE THE ALIGNMENT SUBDIRS USED TO PERFORM INPUT FILE CHUNK ALIGNMENTS

    INPUT

        1. LOCATION OF OUTPUTDIR 

=cut

sub deleteAlignmentSubdirs {
	my $self		=	shift;
	my $directory	=	shift;
	my $references	=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logInfo("directory not defined: $directory") if not defined $directory or not $directory;
	$self->logInfo("directory is '': $directory") if not defined $directory;
	$self->logInfo("Can't find directory: $directory") if not -d $directory;

	#### CHDIR TO OUTPUT DIRECTORY
	chdir($directory) or die "Could not CHDIR to directory: $directory\n";
	opendir(DIR, $directory) or die "Can't open directory: $directory\n";
	my @subdirs = readdir(DIR);
	close(DIR);
	$self->logInfo("subdirs: @subdirs");

	foreach my $subdir ( @subdirs )
	{
		next if not $subdir =~ /^\d+$/;
		$self->logInfo("subdir: $subdir");
		
		foreach my $reference ( @$references )
		{
			my $refdir = "$directory/$subdir/$reference";
			opendir(REFDIR, $refdir) or die "Can't open refdir: $refdir\n";
			my @reffiles = readdir(REFDIR);
			close(REFDIR);
			
			foreach my $reffile ( @reffiles )
			{
				next if not $reffile =~ /^\d+$/;
				$self->logInfo("rm -fr $refdir/$reffile");
				`rm -fr $refdir/$reffile`;
			}
		}		
	}
}

=head2

	SUBROUTINE     deleteSplitfiles
	    
    PURPOSE
  
        REMOVE THE INPUT FILE CHUNKS (SPLITFILES)

    INPUT

        1. LOCATION OF OUTPUTDIR 

=cut

sub deleteSplitfiles {
	my $self		=	shift;
	my $directory	=	shift;

	#### CHECK FOR OUTPUT DIRECTORY
	$self->logInfo("directory not defined: $directory") and exit if not defined $directory or not $directory;
	$self->logInfo("Can't find directory: $directory") and exit if not -d $directory;

	#### CHDIR TO OUTPUT DIRECTORY
	chdir($directory) or die "Could not CHDIR to directory: $directory\n";
	opendir(DIR, $directory) or die "Can't open directory: $directory\n";
	my @subdirs = readdir(DIR);
	close(DIR);
	foreach my $subdir ( @subdirs )
	{
		next if not $subdir =~ /^\d+$/;
		opendir(SUBDIR,"$directory/$subdir") or die "Can't open subdir: $directory/$subdir\n";
		my @subfiles = readdir(SUBDIR);
		close(SUBDIR);
		foreach my $subfile ( @subfiles )
		{
			next if not $subfile =~ /^\d+$/;
			$self->logInfo("subfile: $directory/$subdir/$subfile");
			`rm -fr $directory/$subdir/$subfile`;
		}
	}
}




1;
