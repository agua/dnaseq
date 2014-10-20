CREATE TABLE IF NOT EXISTS srasample
(
    sample             VARCHAR(40) NOT NULL,
    biosample          VARCHAR(40) NOT NULL,
    assay              VARCHAR(40) NOT NULL,
    samplename         VARCHAR(40) NOT NULL,
    srasample          VARCHAR(40) NOT NULL,
    libraryname        VARCHAR(40) NOT NULL,
    mbases             INT(40) NOT NULL,
    mbytes             INT(40) NOT NULL,    
    status             VARCHAR(40) NOT NULL,
 
    PRIMARY KEY  (username, project, sample)
)

