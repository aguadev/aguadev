CREATE TABLE IF NOT EXISTS tenant
(
    username       	VARCHAR(30) NOT NULL,
    os_username		VARCHAR(40) NOT NULL,
    os_auth_url		VARCHAR(40) NOT NULL,
    os_password		VARCHAR(40) NOT NULL,
    os_tenant_id	VARCHAR(40) NOT NULL,
    os_tenant_name	VARCHAR(40) NOT NULL,
	keypair			VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username)
);
