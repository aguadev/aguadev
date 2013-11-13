CREATE TABLE groupmember
(
    owner            VARCHAR(20),
    groupname        VARCHAR(20),
    groupdesc        VARCHAR(255),
    name            VARCHAR(20),
    type            VARCHAR(50),
    description        TEXT,
    location        VARCHAR(255),
    
    PRIMARY KEY (owner, groupname, name, type)
);
