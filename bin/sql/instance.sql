CREATE TABLE IF NOT EXISTS instance
(
    username        VARCHAR(30) NOT NULL,
    queue         	VARCHAR(30) NOT NULL,
    host      		VARCHAR(40),
	id      		VARCHAR(40),
	status			VARCHAR(20),
	time			DATETIME,
    
    PRIMARY KEY (username, queue, host)
);