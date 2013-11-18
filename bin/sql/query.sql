CREATE TABLE IF NOT EXISTS query
(
    username        VARCHAR(30) NOT NULL,
    query           VARCHAR(40) NOT NULL,
    ordinal         INT(2),
    action          VARCHAR(40) NOT NULL,
    field           VARCHAR(40) NOT NULL,
    operator        VARCHAR(40) NOT NULL,
    value           VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username, query, ordinal)
);
