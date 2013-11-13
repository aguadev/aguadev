CREATE TABLE access
(
    owner            VARCHAR(20),
    groupname        VARCHAR(20),
    groupwrite        INT(1),
    groupcopy        INT(1),
    groupview        INT(1),
    worldwrite        INT(1),
    worldcopy        INT(1),
    worldview        INT(1),
    
    PRIMARY KEY (owner, groupname)
);
