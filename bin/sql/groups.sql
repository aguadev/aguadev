CREATE TABLE groups
(
    username    VARCHAR(20),
    groupname   VARCHAR(20),
    description VARCHAR(255),
    notes       TEXT,
    
    PRIMARY KEY (username, groupname)
);
