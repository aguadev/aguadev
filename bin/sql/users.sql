CREATE TABLE IF NOT EXISTS users
(
    username        VARCHAR(30) NOT NULL,
    password        VARCHAR(30) NOT NULL,
    email           VARCHAR(50),
    firstname       VARCHAR(20),
    lastname        VARCHAR(20),
    description     TEXT,
    datetime        DATETIME NOT NULL,
    
    PRIMARY KEY (username)
);