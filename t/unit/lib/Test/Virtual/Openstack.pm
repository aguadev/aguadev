use MooseX::Declare;


#### EXTERNAL MODULES


class Test::Virtual::Openstack extends Virtual::Openstack {

####////}}}

method BUILD ($args) {
	$self->initialise($args);
}

method testLaunchNode {
	diag("launchNode");

	use FindBin qw($Bin);
	use Test::More;

	my $tenant	=	{
		OS_USERNAME		=>	$ENV{'osusername'},
		OS_TENANT_ID	=>	$ENV{'ostenantid'},
		OS_TENANT_NAME	=>	$ENV{'ostenantname'},
		OS_AUTH_URL		=>	$ENV{'osauthurl'},
		OS_PASSWORD		=>	$ENV{'ospassword'}
	};
	$self->logDebug("tenant", $tenant);
	
	#### PRINT OPENSTACK AUTH FILE
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $authtemplate	=	"$installdir/bin/install/resources/openstack/openrc.sh";
	my $authfile		=	"$Bin/outputs/openrc.sh";
	$self->logDebug("authfile", $authfile);

	$self->printAuthFile($tenant, $authtemplate, $authfile);

	my $userdatafile	=	"$Bin/inputs/userdata.sh";
	my $maxnodes 		=	1;
	my $name			=	"testnode-5606151865a";
	my $instancetype	=	$ENV{'instancetype'};
	my $amiid			=	$ENV{'amiid'};
	my $keypair			=	$ENV{'keypair'};

	#### LAUNCH NODE
	my $id	=	$self->launchNode($authfile, $amiid, $maxnodes, $instancetype, $userdatafile, $keypair, $name);
	$self->logDebug("id", $id);
	
	my $success	=	0;
	$success	=	1 if defined $id;
	$success	=	1 if $id =~ /^[0-9a-z\-]+$/;
	
	ok($success, "launched node ID is defined");
}

method testDeleteNode {
	diag("deleteNode");
	
	use FindBin qw($Bin);
	use Test::More;

	my $tenant	=	{
		OS_USERNAME		=>	$ENV{'osusername'},
		OS_TENANT_ID	=>	$ENV{'ostenantid'},
		OS_TENANT_NAME	=>	$ENV{'ostenantname'},
		OS_AUTH_URL		=>	$ENV{'osauthurl'},
		OS_PASSWORD		=>	$ENV{'ospassword'}
	};
	$self->logDebug("tenant", $tenant);
	
	#### PRINT OPENSTACK AUTH FILE
	my $installdir		=	$self->conf()->getKey("agua", "INSTALLDIR");
	my $authtemplate	=	"$installdir/bin/install/resources/openstack/openrc.sh";
	my $authfile		=	"$Bin/outputs/openrc.sh";
	$self->logDebug("authfile", $authfile);

	$self->printAuthFile($tenant, $authtemplate, $authfile);

	my $userdatafile	=	"$Bin/inputs/userdata.sh";
	my $maxnodes 		=	1;
	my $name			=	"testinstance";
	my $instancetype	=	$ENV{'instancetype'};
	my $amiid			=	$ENV{'amiid'};
	my $keypair			=	$ENV{'keypair'};
	
	#### LAUNCH NODE
	my $id	=	$self->launchNode($authfile, $amiid, $maxnodes, $instancetype, $userdatafile, $keypair, $name);
	$self->logDebug("id", $id);
	
	sleep($self->sleep());
	
	$self->_deleteNode($authfile, $id);
	
	my $novalist	=	$self->getNovaList($authfile);
	
	my $taskstate	=	$novalist->{$id}->{taskstate};	
	$self->logDebug("taskstate", $taskstate);
	
	my $success = 0;
	$success = 1 if not defined $taskstate;
	$success = 1 if $taskstate eq "deleting";
	
	ok($success, "node is deleting or deleted");
}

method testParseNovaBoot {
	diag("parseNovaBoot");
	
	my $tests		=	[
		{
			output		=>	qq{+--------------------------------------+---------------------------------------------------+
| Property                             | Value                                             |
+--------------------------------------+---------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                            |
| OS-EXT-AZ:availability_zone          | nova                                              |
| OS-EXT-STS:power_state               | 0                                                 |
| OS-EXT-STS:task_state                | scheduling                                        |
| OS-EXT-STS:vm_state                  | building                                          |
| OS-SRV-USG:launched_at               | -                                                 |
| OS-SRV-USG:terminated_at             | -                                                 |
| accessIPv4                           |                                                   |
| accessIPv6                           |                                                   |
| adminPass                            | cACY8bQtfVp9                                      |
| config_drive                         |                                                   |
| created                              | 2014-06-19T00:31:32Z                              |
| flavor                               | bcf.8c.64g (fa1b57f1-a377-40eb-8378-e9a23f317745) |
| hostId                               |                                                   |
| id                                   | e6b02b4a-c036-465a-ad63-b53e23c54d4a              |
| image                                | worker.v9 (0168ae2e-d9e7-47ab-a57d-aec56988021d)  |
| key_name                             | -                                                 |
| metadata                             | {}                                                |
| name                                 | testinstance-e6b02b4a-c036-465a-ad63-b53e23c54d4a |
| os-extended-volumes:volumes_attached | []                                                |
| progress                             | 0                                                 |
| security_groups                      | default                                           |
| status                               | BUILD                                             |
| tenant_id                            | 892dc778a2e14257b75b6e96d2e503ee                  |
| updated                              | 2014-06-19T00:31:32Z                              |
| user_id                              | 790c7697f3694b3087ba9637205bc046                  |
+--------------------------------------+---------------------------------------------------+
},
			expected	=>	"e6b02b4a-c036-465a-ad63-b53e23c54d4a"
		},
		{
			output	=>	qq{+--------------------------------------+---------------------------------------------------+
| Property                             | Value                                             |
+--------------------------------------+---------------------------------------------------+
| OS-DCF:diskConfig                    | MANUAL                                            |
| OS-EXT-AZ:availability_zone          | nova                                              |
| OS-EXT-STS:power_state               | 0                                                 |
| OS-EXT-STS:task_state                | scheduling                                        |
| OS-EXT-STS:vm_state                  | building                                          |
| OS-SRV-USG:launched_at               | -                                                 |
| OS-SRV-USG:terminated_at             | -                                                 |
| accessIPv4                           |                                                   |
| accessIPv6                           |                                                   |
| adminPass                            | b25mVmPZgrr8                                      |
| config_drive                         |                                                   |
| created                              | 2014-06-19T00:54:16Z                              |
| flavor                               | bcf.8c.64g (fa1b57f1-a377-40eb-8378-e9a23f317745) |
| hostId                               |                                                   |
| id                                   | 8dae400c-912d-4622-8d18-5c13ab158f57              |
| image                                | worker.v9 (0168ae2e-d9e7-47ab-a57d-aec56988021d)  |
| key_name                             | -                                                 |
| metadata                             | {}                                                |
| name                                 | testinstance                                      |
| os-extended-volumes:volumes_attached | []                                                |
| progress                             | 0                                                 |
| security_groups                      | default                                           |
| status                               | BUILD                                             |
| tenant_id                            | 892dc778a2e14257b75b6e96d2e503ee                  |
| updated                              | 2014-06-19T00:54:16Z                              |
| user_id                              | 790c7697f3694b3087ba9637205bc046                  |
+--------------------------------------+---------------------------------------------------+},
			expected	=>	"8dae400c-912d-4622-8d18-5c13ab158f57"
		}
	];
	
	foreach my $test ( @$tests ) {
		my $output		=	$test->{output};
		my $expected	=	$test->{expected};
		my $id	=	$self->parseNovaBoot($output);
		ok($id eq $expected, "parsed ID from nova boot output: $id");
	}
}

method testParseNovaList {
	diag("parseNovaList");

	my $tests	=	[
		{
			output	=>	qq{+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+
| ID                                   | Name                                              | Status | Task State | Power State | Networks                                |
+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+
| a2f3c071-c9fe-4406-a46a-fb8112dde3b2 | bwa.v9                                            | ACTIVE | -          | Running     | tenant_net=10.2.24.114                  |
| f4c2954b-2e1e-4790-ac65-b01506467f41 | download.v9                                       | ACTIVE | -          | Running     | tenant_net=10.2.24.112, 132.249.227.105 |
| 3666c5eb-1677-45a2-b348-4c9b0bd40ea8 | download.v9.userdata                              | ACTIVE | -          | Running     | tenant_net=10.2.24.125, 132.249.227.107 |
| 4210e6ba-1141-4f72-b3fa-b2a2eb9933e3 | download.v9.userdataNEW                           | ACTIVE | -          | Running     | tenant_net=10.2.24.131, 132.249.227.108 |
| cf81cf12-5c92-403a-a9ec-7d4fc686323c | freebayes.v9.8c.64g                               | ACTIVE | -          | Running     | tenant_net=10.2.24.119                  |
| 7b6bf94d-f8e7-4989-a123-7c22af1d6333 | master                                            | ACTIVE | -          | Running     | tenant_net=10.2.24.103, 132.249.227.125 |
| 4f724c22-c8c4-4ecc-b537-9554eddde200 | share                                             | ACTIVE | -          | Running     | tenant_net=10.2.24.107, 132.249.227.126 |
| 6f1879f8-90d5-45ae-aaad-ebc548f0a74b | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.139                  |
| 8dae400c-912d-4622-8d18-5c13ab158f57 | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.141                  |
| b6509930-50f5-4fa8-8d39-fd2eef3c57e5 | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.140                  |
| 851440ea-76b5-4fcc-95ee-2ad3a87392c0 | testinstance-851440ea-76b5-4fcc-95ee-2ad3a87392c0 | ACTIVE | -          | Running     | tenant_net=10.2.24.136                  |
| e6b02b4a-c036-465a-ad63-b53e23c54d4a | testinstance-e6b02b4a-c036-465a-ad63-b53e23c54d4a | ACTIVE | deleting   | Running     | tenant_net=10.2.24.135                  |
+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+},
			id			=>	"e6b02b4a-c036-465a-ad63-b53e23c54d4a",
			expected	=>	"deleting"
		}
		,
		{
			output	=>	qq{+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+
| ID                                   | Name                                              | Status | Task State | Power State | Networks                                |
+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+
| a2f3c071-c9fe-4406-a46a-fb8112dde3b2 | bwa.v9                                            | ACTIVE | -          | Running     | tenant_net=10.2.24.114                  |
| f4c2954b-2e1e-4790-ac65-b01506467f41 | download.v9                                       | ACTIVE | -          | Running     | tenant_net=10.2.24.112, 132.249.227.105 |
| 3666c5eb-1677-45a2-b348-4c9b0bd40ea8 | download.v9.userdata                              | ACTIVE | -          | Running     | tenant_net=10.2.24.125, 132.249.227.107 |
| 4210e6ba-1141-4f72-b3fa-b2a2eb9933e3 | download.v9.userdataNEW                           | ACTIVE | -          | Running     | tenant_net=10.2.24.131, 132.249.227.108 |
| cf81cf12-5c92-403a-a9ec-7d4fc686323c | freebayes.v9.8c.64g                               | ACTIVE | -          | Running     | tenant_net=10.2.24.119                  |
| 7b6bf94d-f8e7-4989-a123-7c22af1d6333 | master                                            | ACTIVE | -          | Running     | tenant_net=10.2.24.103, 132.249.227.125 |
| 4f724c22-c8c4-4ecc-b537-9554eddde200 | share                                             | ACTIVE | -          | Running     | tenant_net=10.2.24.107, 132.249.227.126 |
| 6f1879f8-90d5-45ae-aaad-ebc548f0a74b | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.139                  |
| 8dae400c-912d-4622-8d18-5c13ab158f57 | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.141                  |
| b6509930-50f5-4fa8-8d39-fd2eef3c57e5 | testinstance                                      | ACTIVE | -          | Running     | tenant_net=10.2.24.140                  |
| 851440ea-76b5-4fcc-95ee-2ad3a87392c0 | testinstance-851440ea-76b5-4fcc-95ee-2ad3a87392c0 | ACTIVE | -          | Running     | tenant_net=10.2.24.136                  |
+--------------------------------------+---------------------------------------------------+--------+------------+-------------+-----------------------------------------+},
			id			=>	"e6b02b4a-c036-465a-ad63-b53e23c54d4a",
			expected	=>	undef
		}
	];

	foreach my $test ( @$tests ) {
		my $output		=	$test->{output};
		my $expected	=	$test->{expected};
		my $id			=	$test->{id};
		my $hash		=	$self->parseNovaList($output);
		$self->logDebug("hash", $hash);

		my $taskstate		=	$hash->{$id}->{taskstate};
		$self->logDebug("taskstate", $taskstate);

		is_deeply($taskstate, $expected, "parsed nova list output: $id");
	}
}


} #### END


