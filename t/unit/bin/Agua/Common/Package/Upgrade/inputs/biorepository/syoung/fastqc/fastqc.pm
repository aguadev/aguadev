use MooseX::Declare;
class fastqc extends Agua::Ops {

sub install {
	my $self		=	shift;
	my $version		=	shift;
	my $installdir	=	shift;
	
	$version = "0.9.3" if not defined $version;
	$installdir = "/usr/local/src/fastqc" if not defined $installdir;

    $self->changeDir($installdir);
	$self->makeDir($version);
	$self->changeDir($version);
	$self->runCommand("wget http://www.bioinformatics.bbsrc.ac.uk/projects/fastqc/fastqc_v$version.zip");
	$self->runCommand("unzip fastqc_v$version.zip");
	$self->changeDir("FastQC");
	$self->runCommand("chmod a+x fastqc");	
}

}
