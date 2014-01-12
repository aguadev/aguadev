class awscli {

#	$pkgs = ['python2.7', 'python-pip']
	$pkgs = ['python-pip']
	package {$pkgs:
		ensure => 'installed'
	}
	  
	exec { 'pip install awscli':
#		logoutput   =>  on_failure,
		command => 'pip install awscli',
		path    => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
		unless  => 'which aws',
		require => Package[$pkgs],
		user    => 'root',
		timeout => '0',
	}
}

include awscli