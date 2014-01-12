Exec {
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

notice("install-rabbitmq    Installing erlang")

package { 'erlang':
    ensure  =>  installed
}

notice("install-rabbitmq    Completed installing erlang")

class { 'rabbitmq':
    port              => '5672',
    config_variables   => {
      'hipe_compile'  => true,
      'frame_max'     => 131072,
      'log_levels'    => "[{connection, info}]"
    }
}
