-- MySQL dump 10.13  Distrib 5.1.41, for debian-linux-gnu (i486)
--
-- Host: localhost    Database: mydb
-- ------------------------------------------------------
-- Server version	5.1.41-3ubuntu12.6

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
-- Table structure for table `auth_table`
--

DROP TABLE IF EXISTS `auth_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auth_table` (
  `esme_id` int(11) NOT NULL AUTO_INCREMENT,
  `system_id` varchar(45) DEFAULT NULL,
  `password` varchar(45) DEFAULT NULL,
  `bandwidth` int(11) DEFAULT NULL,
  `allowed_ip` varchar(256) DEFAULT NULL,
  `allowed_src` varchar(256) DEFAULT NULL,
  `max_connections` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`esme_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Table  for authorization of ESME''s';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_table`
--

LOCK TABLES `auth_table` WRITE;
/*!40000 ALTER TABLE `auth_table` DISABLE KEYS */;
INSERT INTO `auth_table` VALUES (1,'SMSGW','secret',NULL,NULL,NULL,NULL,1);
/*!40000 ALTER TABLE `auth_table` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `messages`
--

DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `msg_type` varchar(3) DEFAULT NULL,
  `esme_id` int(11) DEFAULT NULL,
  `received` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `processed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `src_addr` varchar(32) DEFAULT NULL,
  `dst_addr` varchar(32) DEFAULT NULL,
  `body` varchar(512) DEFAULT NULL,
  `coding` int(11) DEFAULT '0',
  `udh` varchar(512) DEFAULT NULL,
  `mwi` int(11) DEFAULT NULL,
  `mclass` int(11) DEFAULT NULL,
  `message_id` varchar(64) DEFAULT NULL,
  `validity` int(11) DEFAULT '1440',
  `deferred` int(11) DEFAULT '0',
  `registered_delivery` int(11) DEFAULT '0',
  `service_type` varchar(64) DEFAULT NULL,
  `extra` varchar(512) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=17089 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `messages`
--

LOCK TABLES `messages` WRITE;
/*!40000 ALTER TABLE `messages` DISABLE KEYS */;
/*!40000 ALTER TABLE `messages` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2010-09-01 13:26:24
