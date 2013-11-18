CREATE TABLE IF NOT EXISTS download
(
    username        VARCHAR(30) NOT NULL,
    filename        VARCHAR(255) NOT NULL,
    filesize        VARCHAR(16) NOT NULL,
    source          VARCHAR(40) NOT NULL,
    download        VARCHAR(40) NOT NULL,
    progress        VARCHAR(40) NOT NULL,
    status          VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username, filename, source)
);
