CREATE TABLE IF NOT EXISTS diffs
(
    name                VARCHAR(20),
    chromosome          VARCHAR(20),
    ccdsstart           INT(12),
    ccdsstop            INT(12),
    referencenucleotide VARCHAR(255),
    variantnucleotide   VARCHAR(255),
    depth               INT(6),
    variantfrequency    INT(6),
    chromosomestart     INT(12),
    chromosomestop      INT(12),
    sense               VARCHAR(1),
    referencecodon      VARCHAR(255),
    variantcodon        VARCHAR(255),
    referenceaa         VARCHAR(255),
    variantaa           VARCHAR(255),
    strand              VARCHAR(1),
    snp                 VARCHAR(20),
    score               INT(6),
    dbsnpstrand         VARCHAR(1),
    
    PRIMARY KEY (name, chromosome, ccdsstart, ccdsstop, referencenucleotide, variantnucleotide)
)
    