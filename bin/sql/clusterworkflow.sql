CREATE TABLE IF NOT EXISTS clusterworkflow
(
    username        VARCHAR(30) NOT NULL,
    cluster         VARCHAR(30) NOT NULL,
    project         VARCHAR(20) NOT NULL,
    workflow        VARCHAR(20) NOT NULL,
    status          VARCHAR(20) NOT NULL,
    
    PRIMARY KEY (username, project, workflow)
);
