class ec2api {
	notice("Installing ec2api")
	exec { 'install ec2api':
		cwd		=>	'/tmp',
		command => 'wget --no-check-certificate https://s3-us-west-1.amazonaws.com/aguadev/ec2-api-tools-1.6.9.0.zip; unzip ec2-api-tools-1.6.9.0.zip; mkdir /usr/local/ec2; cp -r ec2-api-tools-1.6.9.0/* /usr/local/ec2/; echo 0',
		path    => [ '/usr/local/ec2/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
		unless  => 'which ec2din',
		user    => 'root',
		timeout => '0'
	}
}

include ec2api

