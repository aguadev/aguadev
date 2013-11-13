CREATE TABLE IF NOT EXISTS viewfeature
(
    username        VARCHAR(30) NOT NULL,
    project         VARCHAR(20) NOT NULL,
    view            VARCHAR(20) NOT NULL,
    feature         VARCHAR(30) NOT NULL,
    species         VARCHAR(20),
    build           VARCHAR(20),
    location        VARCHAR(255) NOT NULL,
    
    PRIMARY KEY (username, project, view, feature)
);
