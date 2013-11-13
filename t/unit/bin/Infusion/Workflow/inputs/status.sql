-- MySQL dump 10.11
--
-- Host: ussd-dev-lndb01    Database: wgspipe
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
-- Table structure for table `status`
--

DROP TABLE IF EXISTS `status`;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
CREATE TABLE `status` (
  `status_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `status` varchar(45) NOT NULL,
  `description` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `status_UNIQUE` (`status`)
) ENGINE=InnoDB AUTO_INCREMENT=96 DEFAULT CHARSET=latin1;
SET character_set_client = @saved_cs_client;

--
-- Dumping data for table `status`
--

LOCK TABLES `status` WRITE;
/*!40000 ALTER TABLE `status` DISABLE KEYS */;
INSERT INTO `status` VALUES (1,'run_started','flow cell registered for a run started'),(2,'run_finished','flow cell data files are all present'),(3,'in_align_queue','script placed a path in queue for alignment'),(4,'aligning','launched  from queue to align'),(5,'skip_align','flowcell that are aligned already likely manu'),(6,'alignment_complete','got alignment finished'),(7,'alignment_failed','got an error from pl_config'),(8,'run_failed','the whole flowcell should be ignored'),(9,'alignment_unusable','it aligned OK but the data is poor and should'),(10,'alignHW','todo in HW '),(11,'dontAlign','per lane status specially for skipping'),(12,'poorDiv','per lane poor div dont align'),(13,'bad_data','lane or flowcell bad data. stop using.'),(14,'in_build_queue','added to build queue'),(15,'building','building launched'),(16,'build_finished','it finished successfully'),(17,'build_failed','build  fail'),(18,'run_rehybed','flowcell was rehybed'),(19,'hold','wait'),(20,'delivered','sample has been delivered'),(21,'lane_mixup','sample wrongly assigned'),(22,'auto_bad_data','croned status that checks stats'),(23,'auto_lane_fail','gt 50 % bad tiles ; error and other metrics n'),(24,'auto_lane_review','50% > goodtiles >=75%; metrics ok'),(25,'auto_lane_pass','less or equal 50% good tiles; R1<1%; R2<2%'),(26,'send_to_cloud','sample to cloud'),(27,'fail_gt','sample failed gt, do no proceed'),(28,'cancelled','sample was cancelled altogether '),(29,'ignore','sample barcode to ignore'),(30,'build_fail_coverage','build does not meet required coverage'),(31,'build_fail_gt_fail','build final gt concordance bellow acceptable'),(32,'bad_library','library in lane is bad; dont use'),(33,'Unassigned','fail code not described '),(34,'UserError',NULL),(36,'Fluidics',NULL),(37,'Library',NULL),(38,'PhasePrePhase',NULL),(39,'ResynthFailure','BroadSympton'),(40,'ClusterDensity','BroadSympton'),(42,'Other',NULL),(43,'Reagent',NULL),(44,'Software',NULL),(45,'Hardware',NULL),(46,'Optics',NULL),(47,'q30ErrorRate',NULL),(48,'Intensity','broadSymptom'),(49,'Facilities',NULL),(50,'archive_pending','sample file moved to archive pending'),(51,'bcl_deleted','sample was delivered and bcls deleted '),(52,'insufficient_coverage','build missing coverage'),(53,'q30','broadSymptom'),(54,'Freeze','broadSymptom'),(55,'Diversity','broadSymptom'),(56,'HighPhase_PrePhase','broadSymptom'),(57,'bioinfo_threshold','bioinfo threshold'),(58,'complete','project complete'),(59,'in_requeue_queue','requeues acknoledged'),(60,'write_to_disk','samplesheet is database but not in file syste'),(61,'lane_qc_pass','pass qc metrics '),(62,'contamination','lanes discarted for contamination fear'),(63,'active','the sample or project is active '),(65,'qc_pass','the sample is ready to write to disk'),(66,'qc_fail','the sample fails to pass qc '),(68,'Swath_Dropouts','broadSymptom'),(70,'ErrorRate','broadSymptom'),(71,'clustered_on_flowcell','requeue put on a flowcell, expect a lane in a'),(72,'requeue_fulfilled','q requeue request found the next lane for the'),(73,'requeue_acknowledged','lab sets it from in_queue'),(74,'requeue_cancelled','cannot requeue'),(75,'to_rehyb','the flowcell with be attempted to rehyb'),(76,'fullbuild_queue','the sample has been assigned to a fullbuild W'),(77,'build_pass','build metrics look ok'),(78,'build_downloading','from somewhere like aws'),(79,'build_downloaded','done downloading'),(80,'lane_archive_pending','Lane archive in process'),(81,'lane_archive_complete','Lane archive complete - handed off to system'),(82,'lane_deleting','Lane deletion submitted'),(83,'lane_deleted','Lane deletion complete'),(84,'lane_archive_skip','Don\'t archive this lane'),(85,'lane_archive_error','Something went wrong when backing up the lane'),(86,'loading_to_hd','qc passed and now loading to HD'),(87,'loaded_to_hd','finished loading to a HD'),(88,'pm_hold','sample is on hold by PM'),(89,'lane_archive_running','tar for lane archive has started'),(90,'fingerprinting_queue','lane marked for fingerprinting'),(91,'fingerprinting_running','fingerprinting running on lane'),(92,'fingerprinting_finished','fingerprinting finished on lane'),(93,'fingerprinting_failed','fingerprinting failed on lane'),(94,'lane_swap','lane doesnt not belong of the sample'),(95,'alignment_unused','Data is good but not used');
/*!40000 ALTER TABLE `status` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2013-03-07 19:37:31
