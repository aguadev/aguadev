-- MySQL dump 10.11
--
-- Host: ussd-dev-lndb01.illumina.com    Database: devtest
-- ------------------------------------------------------
-- Server version	5.1.49-community-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `casava_bcl_to_gvcf`
--

DROP TABLE IF EXISTS `casava_bcl_to_gvcf`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `casava_bcl_to_gvcf` (
  `report_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `workflow_queue_id` int(11) unsigned NOT NULL,
  `check_md5sum` varchar(200) DEFAULT NULL,
  `status_id` int(10) DEFAULT NULL,
  `update_time` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `create_date` datetime DEFAULT NULL,
  `sample` varchar(250) DEFAULT NULL,
  `manifestgender` varchar(15) DEFAULT NULL,
  `arraygender` varchar(15) DEFAULT NULL,
  `sequencedgender` varchar(15) DEFAULT NULL,
  `genome` varchar(15) DEFAULT NULL,
  `genome_file` varchar(100) DEFAULT NULL,
  `gt_gen_concordance` decimal(5,4) DEFAULT NULL,
  `gt_gen_usage` decimal(5,4) DEFAULT NULL,
  `casava_coverage_autosomal_depth` decimal(8,5) DEFAULT NULL,
  `casava_coverage_autosomal_coverage` decimal(8,5) DEFAULT NULL,
  `casava_duplicates_percent` decimal(10,7) DEFAULT NULL,
  `casava_snp_total_count` int(11) DEFAULT NULL,
  `casava_snp_het_hom_ratio` decimal(10,7) DEFAULT NULL,
  `consensus_gene_coverage` decimal(10,7) DEFAULT NULL,
  `consensus_gene_depth` decimal(10,6) DEFAULT NULL,
  `consensus_exon_coverage` decimal(10,7) DEFAULT NULL,
  `consensus_exon_depth` decimal(10,6) DEFAULT NULL,
  `dbSNP_call_count` int(11) DEFAULT NULL,
  `dbSNP_het_count` int(11) DEFAULT NULL,
  `dbSNP_hom_count` int(11) DEFAULT NULL,
  `dbSNP_novel_call_count` int(11) DEFAULT NULL,
  `dbSNP_per_novel` decimal(5,4) DEFAULT NULL,
  `tv_ratio` decimal(5,4) DEFAULT NULL,
  `depth_per_1X` decimal(12,8) DEFAULT NULL,
  `depth_per_8X` decimal(12,8) DEFAULT NULL,
  `depth_per_10X` decimal(12,8) DEFAULT NULL,
  `gene_depth_per_1X` decimal(12,8) DEFAULT NULL,
  `gene_depth_per_8X` decimal(12,8) DEFAULT NULL,
  `gene_depth_per_10X` decimal(12,8) DEFAULT NULL,
  `exon_depth_per_1X` decimal(12,8) DEFAULT NULL,
  `exon_depth_per_8X` decimal(12,8) DEFAULT NULL,
  `exon_depth_per_10X` decimal(12,8) DEFAULT NULL,
  `pf_total_gb` decimal(12,2) DEFAULT NULL,
  `per_aligned` decimal(12,2) DEFAULT NULL,
  `per_q30` decimal(12,2) DEFAULT NULL,
  `per_q35` decimal(12,2) DEFAULT NULL,
  `gb_q30` decimal(12,2) DEFAULT NULL,
  `gb_q35` decimal(12,2) DEFAULT NULL,
  `insert_median` decimal(12,2) DEFAULT NULL,
  `insert_lowsd` decimal(12,2) DEFAULT NULL,
  `insert_highsd` decimal(12,2) DEFAULT NULL,
  `contam_hom_fraction_bad` decimal(12,8) DEFAULT NULL,
  `casava_bcl_to_gvcfcol` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`report_id`),
  UNIQUE KEY `un_wfq` (`workflow_queue_id`),
  CONSTRAINT `fk_wfq` FOREIGN KEY (`workflow_queue_id`) REFERENCES `workflow_queue` (`workflow_queue_id`) ON DELETE NO ACTION ON UPDATE NO ACTION
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-03-28 13:39:34
