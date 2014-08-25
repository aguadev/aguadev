CREATE TABLE IF NOT EXISTS heartbeat
(
    host    	VARCHAR(40),
	ipaddress	VARCHAR(40),
	cpu			TEXT,
	io			TEXT,
	disk		TEXT,
	memory		TEXT,
    time		DATETIME,
	
    PRIMARY KEY (host, time)
);