package testpackage;
use Moose::Role;
use Method::Signatures::Simple;

method doInstall ($installdir, $version) {
    $self->logDebug("version", $version);
    $self->logDebug("installdir", $installdir);
    $version = $self->version() if not defined $version;
    
        return if not $self->gitInstall();
    return if not $self->zipInstall();
    return if not $self->makeInstall();
    return if not $self->perlInstall();


    return $version;
}
