CREATE TABLE IF NOT EXISTS fileinfo
(
    username        VARCHAR(30) NOT NULL,
    filepath        VARCHAR(255) NOT NULL,
    type            VARCHAR(20),
    modified        DATETIME,
    fileinfo        TEXT,
    
    PRIMARY KEY  (username, filepath)
);
