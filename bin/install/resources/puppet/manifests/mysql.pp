Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

class install {    
    class { mysql::server:
        package_ensure => present,
        service_enabled   => true,
        override_options => {
            'mysqld' => {
                'local-infile'             => 1,
            },
            'mysql' => {
                'local-infile'             => 1,
            }
        }
    }

}

include install
