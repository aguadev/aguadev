class dependencies {
	notice("dependencies")

	package {"openjdk-6-jdk":
		ensure => installed,
		name => $operatingsystem ? {
			Ubuntu => "openjdk-6-jdk",
			CentOS => "java-1.6.0-openjdk",
		}
	}
	
	->
	
	package {['ruby1.8-full', 'rubygems', 'libxml2-utils', 'libxml2-dev', 'libxslt-dev', 'unzip', 'cpanminus', 'build-essential' ]:
		ensure => 'present'
	}
}

include dependencies