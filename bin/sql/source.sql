CREATE TABLE source
(
    username        VARCHAR(30) NOT NULL,
    name            VARCHAR(30),
    description        TEXT,
    location        VARCHAR(255),
    
    PRIMARY KEY (username, name)
);
