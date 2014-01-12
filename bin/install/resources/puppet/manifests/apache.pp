Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

class install {

    notice("install-apache    Installing apache")
    class {
        apache:;
    }

    notice("install-apache    Installing mod::ssl")
    class { 'apache::mod::ssl': }
    notice("install-apache    Installing mod::fcgid")
    class { 'apache::mod::fcgid': }

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

    apache::vhost { 'ssl.example.com':
        port     => '443',
        docroot  => '/var/www/html',
        ssl      => true,
        ssl_cert => $certfile,
        ssl_key  => $keyfile,
    }
    notice("install-apache    COMPLETED install apache::vhost")

}

include install
