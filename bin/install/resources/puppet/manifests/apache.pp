Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

class install {

    notice("install-apache    Installing apache")
    class {
        apache:;
    }

    notice("install-apache    Installing mod::ssl")
#    class { 'apache::mod::ssl': }
    include apache::mod::ssl

    if $operatingsystem == "centos" {
        notice("install-apache    Installing mod::fcgid")
        class { 'apache::mod::fcgid': }
    }
    else {
        notice("install-apache    Installing mod::fastcgi")
        class { 'apache::mod::fastcgi': }
    }

    if $ssl and $ensure == 'present' {
        include apache::mod::ssl
        # Required for the AddType lines.
        include apache::mod::mime
    }

    notice("install-apache    Installing apache::vhost")
    case $operatingsystem {
        centos : {
            $keyfile    =   "/etc/pki/tls/private/server.key"
        }
        ubuntu : {
            $keyfile    =   "/etc/apache2/ssl.key/server.key"
        }
    }

    case $operatingsystem {
        centos : {
            $certfile   =   "/etc/pki/tls/certs/server.crt"
        }
        ubuntu : {
            $certfile   =   "/etc/apache2/ssl.key/server.crt"
        }
    }

    notice("install-apache    certfile: $certfile")
    notice("install-apache    keyfile: $keyfile")

    apache::vhost { 'ssl':
        port     => '443',
        docroot  => '/var/www/html',
        ssl      => true,
        ssl_cert => $certfile,
        ssl_key  => $keyfile,
    }
    notice("install-apache    COMPLETED install apache::vhost")

#    file { '/etc/apache2/sites-available/default-ssl':
#        ensure  => present,
#        source  => 'puppet:///modules/appliance_components/redirect-ssl.conf',
#        require => [
#            Package['apache'],
#        ],
#        notify  => Service['apache'],
#    }

}

include install
