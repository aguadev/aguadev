CREATE TABLE IF NOT EXISTS hub
(
    username        VARCHAR(30) NOT NULL,
    login           VARCHAR(30) NOT NULL,
    hubtype         VARCHAR(30) NOT NULL,
    token           VARCHAR(40) NOT NULL,
    tokenid         INT(12) NOT NULL,
    keyfile         VARCHAR(255) NOT NULL,
    publiccert      TEXT,
    
    PRIMARY KEY (username)
);