CREATE TABLE IF NOT EXISTS ami
(
    username        VARCHAR(30) NOT NULL,
    amiid           VARCHAR(20),
    aminame         VARCHAR(30) NOT NULL,
    amitype         VARCHAR(20),
    description     TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY (username, amiid)
);
