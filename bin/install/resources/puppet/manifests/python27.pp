class python27 {

	$pkgs = ['python2.7']
	package {$pkgs:
		ensure => 'installed'
	}
}

include python27