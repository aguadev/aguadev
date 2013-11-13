CREATE TABLE project
(
    username      VARCHAR(20) NOT NULL,
    name          VARCHAR(20) NOT NULL,
    number        INT(12),
    status        VARCHAR(30) NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    notes         TEXT NOT NULL DEFAULT '',
    provenance    TEXT NOT NULL DEFAULT '',
    
    PRIMARY KEY (username, name)
);
