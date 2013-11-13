CREATE TABLE IF NOT EXISTS aws
(
    username        VARCHAR(30) NOT NULL,
    amazonuserid    VARCHAR(30) NOT NULL,
    ec2publiccert   TEXT,
    ec2privatekey   TEXT,
    awsaccesskeyid  VARCHAR(100),
    awssecretaccesskey VARCHAR(100),
    
    PRIMARY KEY (username)
);