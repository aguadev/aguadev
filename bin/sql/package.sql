CREATE TABLE IF NOT EXISTS package 
(
    owner           VARCHAR(30) NOT NULL,
    username        VARCHAR(30) NOT NULL,
    package         VARCHAR(40) NOT NULL,
    repository      VARCHAR(40) NOT NULL,
    privacy         VARCHAR(40) NOT NULL,
    status          VARCHAR(40) NOT NULL,
    version         VARCHAR(40) NOT NULL,
    opsdir          VARCHAR(255),
    installdir      VARCHAR(255) NOT NULL,
 
    description     TEXT,
    notes           TEXT,
    url             TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY  (username, package)
);
