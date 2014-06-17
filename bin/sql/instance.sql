CREATE TABLE IF NOT EXISTS instance
(
    username        VARCHAR(30) NOT NULL,
    queue         	VARCHAR(30) NOT NULL,
    instanceid      VARCHAR(20),
	status			VARCHAR(20),
	time			DATETIME,
    
    PRIMARY KEY (username, queue, instanceid)
);