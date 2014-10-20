CREATE TABLE IF NOT EXISTS tcgasample
(
    username           	VARCHAR(30) NOT NULL,
    project            	VARCHAR(40) NOT NULL,
    sample              VARCHAR(40) NOT NULL,
    sampletype          int(6) NOT NULL,
    participantid       VARCHAR(40) NOT NULL,
    librarystrategy     VARCHAR(40) NOT NULL,
    filename            VARCHAR(255) NOT NULL,
    filesize            INT(40) NOT NULL,
    status              VARCHAR(40) NOT NULL,

    PRIMARY KEY  (username, project, sample, filename)
)
