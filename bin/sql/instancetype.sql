CREATE TABLE IF NOT EXISTS instancetype
(
    username        VARCHAR(30) NOT NULL,
    cluster         VARCHAR(30) NOT NULL,
    instancetype    VARCHAR(20),
    cpus        	INT(12),
    memory        	INT(12),
    disk       		INT(12),
    ephemeral      	INT(12),
    
    PRIMARY KEY (username, cluster)
);