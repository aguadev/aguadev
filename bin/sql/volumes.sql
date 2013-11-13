CREATE TABLE IF NOT EXISTS volumes
(
    username        VARCHAR(30) NOT NULL,
    volumeid        VARCHAR(30) NOT NULL,
    volumesize      INT(6),
    instance        VARCHAR(30) NOT NULL,
    availabilityzone    VARCHAR(12) NOT NULL,
    mountpoint      VARCHAR(255) NOT NULL,
    device          VARCHAR(30) NOT NULL,
    snapshot        VARCHAR(30) NOT NULL,
    created         DATE,
    
    PRIMARY KEY (username, volumeid)
);

