CREATE TABLE IF NOT EXISTS workflow
(
    username      VARCHAR(30) NOT NULL,
    project       VARCHAR(20) NOT NULL,
    name          VARCHAR(20) NOT NULL,
    number        INT(12) NOT NULL,
    status        VARCHAR(30) NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    notes         TEXT NOT NULL DEFAULT '',
    provenance    TEXT NOT NULL DEFAULT '',

    PRIMARY KEY  (username, project, name, number)
);