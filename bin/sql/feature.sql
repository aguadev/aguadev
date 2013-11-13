CREATE TABLE IF NOT EXISTS feature
(
    username        VARCHAR(30) NOT NULL,
    project         VARCHAR(20) NOT NULL,
    workflow        VARCHAR(20) DEFAULT '',
    feature         VARCHAR(30) NOT NULL,
    type            VARCHAR(20) NOT NULL,
    species         VARCHAR(20),
    build           VARCHAR(20),
    location        TEXT NOT NULL,
    
    PRIMARY KEY (username, project, workflow, feature)
);
