-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
--
-- Host: localhost    Database: landlord_creditapi
-- ------------------------------------------------------
-- Server version	8.0.32

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clients` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `identification` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phone_verified_at` timestamp NULL DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `status` enum('active','suspended','blocked','pending_verification') COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `creator_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `clients_identification_unique` (`identification`),
  KEY `clients_creator_id_foreign` (`creator_id`),
  KEY `clients_identification_index` (`identification`),
  KEY `clients_status_index` (`status`),
  CONSTRAINT `clients_creator_id_foreign` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,'alex','1022','alex@alex.com','3212830921',NULL,'jasñlkdfjñl','active',NULL,1,'2025-11-26 15:36:42','2025-11-26 15:36:42'),(2,'David Alexander Garrido Hernandez','1022978178','alexg.9207@proton.me','3205731318',NULL,'Circacia, El Porvenir','active',NULL,1,'2025-11-26 15:47:56','2025-11-26 15:47:56'),(3,'Cliente Prueba','1234567890','test@test.com','1234567890',NULL,'Dirección prueba','active',NULL,1,'2025-11-27 00:19:07','2025-11-27 00:19:07'),(4,'aslkdkjf','12341232','ajsld@aklsjdf.com','234534254',NULL,'añlskdjflñks','active',NULL,1,'2025-11-27 00:20:53','2025-11-27 00:20:53'),(5,'Alexander Garrido','1022978179','alexg.9207@proton.mex','3205731318',NULL,'Circasia','active',NULL,1,'2025-12-01 15:00:38','2025-12-01 15:00:38'),(6,'Ana Hernandez','51792359','anahernandezc@hotmail.com','3103362753','2025-12-02 15:47:10',NULL,'pending_verification',NULL,1,'2025-12-02 15:45:42','2025-12-02 15:47:10'),(7,'Laura Garrido Hernandez','1098311405','laxi91@hotmail.com','3214567890','2025-12-02 20:49:46','Santa Librada Bogotá','pending_verification',NULL,1,'2025-12-02 20:49:23','2025-12-02 20:49:46'),(8,'Oscar Lopez','1070975116','oscarlopez@gmail.com','3219876543','2025-12-08 20:43:27','Villavicencio Meta','pending_verification',NULL,1,'2025-12-08 20:39:04','2025-12-08 20:43:27'),(9,'Cristian Castro','123456789','cc@hotmail.com','3331234567','2025-12-08 20:53:56','Cricasia Quidio','pending_verification',NULL,1,'2025-12-08 20:53:40','2025-12-08 20:53:56'),(10,'Laura Castro','987654321','laurac@gmail.com','1232468024','2025-12-08 20:58:11','Bogota usme','pending_verification',NULL,1,'2025-12-08 20:57:54','2025-12-08 20:58:11');
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `credits`
--

DROP TABLE IF EXISTS `credits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credits` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `client_id` bigint unsigned NOT NULL,
  `credit_plan_id` bigint unsigned DEFAULT NULL,
  `amount` decimal(12,2) DEFAULT NULL,
  `initial_fee` decimal(12,2) NOT NULL DEFAULT '0.00',
  `financed_amount` decimal(12,2) DEFAULT NULL,
  `interest_rate` decimal(8,2) DEFAULT NULL,
  `term` int DEFAULT NULL,
  `installment_amount` decimal(12,2) DEFAULT NULL,
  `insurance_percentage` decimal(5,2) NOT NULL DEFAULT '0.15',
  `insurance_amount` decimal(12,2) DEFAULT NULL,
  `total_payable` decimal(12,2) DEFAULT NULL,
  `frequency` enum('diario','semanal','quincenal','mensual') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'mensual',
  `cutoff_day` tinyint unsigned DEFAULT NULL COMMENT 'Día del mes para el corte del crédito (1-31)',
  `available_amount` decimal(12,2) NOT NULL,
  `total_limit` decimal(12,2) NOT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `activation_date` date DEFAULT NULL,
  `status` enum('pendiente','pending','activo','active','pagado','vencido','cancelado','suspended','blocked','rejected') COLLATE utf8mb4_unicode_ci DEFAULT 'pendiente',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `creator_id` bigint unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `credits_code_unique` (`code`),
  KEY `credits_creator_id_foreign` (`creator_id`),
  KEY `credits_client_id_index` (`client_id`),
  KEY `credits_status_index` (`status`),
  KEY `credits_credit_plan_id_foreign` (`credit_plan_id`),
  CONSTRAINT `credits_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `credits_creator_id_foreign` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `credits_credit_plan_id_foreign` FOREIGN KEY (`credit_plan_id`) REFERENCES `credit_plans` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credits`
--

LOCK TABLES `credits` WRITE;
/*!40000 ALTER TABLE `credits` DISABLE KEYS */;
INSERT INTO `credits` VALUES (1,NULL,1,NULL,NULL,0.00,NULL,NULL,NULL,NULL,0.15,NULL,NULL,'mensual',NULL,0.00,230000.00,NULL,NULL,NULL,'rejected',NULL,1,'2025-11-26 15:36:42','2025-12-08 20:59:03'),(2,NULL,2,NULL,NULL,0.00,NULL,NULL,NULL,NULL,0.15,NULL,NULL,'mensual',NULL,660000.01,4520000.00,NULL,NULL,NULL,'active',NULL,1,'2025-11-26 15:47:56','2026-01-10 00:20:05'),(3,NULL,3,NULL,NULL,0.00,NULL,NULL,NULL,NULL,0.15,NULL,NULL,'mensual',NULL,801000.00,1001000.00,NULL,NULL,NULL,'active',NULL,1,'2025-11-27 00:19:07','2025-11-28 13:58:41'),(4,NULL,4,NULL,NULL,0.00,NULL,NULL,NULL,NULL,0.15,NULL,NULL,'mensual',NULL,5678744.00,5678744.00,NULL,NULL,NULL,'active',NULL,1,'2025-11-27 00:20:53','2025-11-27 00:21:27'),(5,'CRE-692DD402ADECF',5,NULL,300000.00,0.00,300000.00,10.00,24,33389.93,5.00,15000.00,816358.32,'mensual',28,200000.00,500000.00,'2025-12-01','2027-12-01','2025-12-01','active',NULL,1,'2025-12-01 15:00:38','2025-12-08 21:58:48'),(6,'CRE-692F1D1423411',6,NULL,90000.00,0.00,90000.00,3.50,12,9313.56,0.15,135.00,111897.72,'mensual',1,1000000.00,1090000.00,'2025-12-02','2026-12-02','2025-12-02','active',NULL,1,'2025-12-02 16:04:35','2025-12-08 21:55:34'),(7,'CRE-69370477A95D0',7,NULL,3000000.00,0.00,3000000.00,3.50,12,310451.85,0.15,4500.00,3729922.20,'mensual',1,2040000.01,3000000.00,'2025-12-08','2026-12-08','2025-12-08','active',NULL,1,'2025-12-02 20:49:57','2026-01-06 23:25:07'),(8,'CRE-69373977D6D86',8,NULL,4000000.00,0.00,4000000.00,3.50,12,413935.80,0.15,6000.00,4973229.60,'mensual',1,3090000.00,4000000.00,'2025-12-08','2026-12-08','2025-12-08','active',NULL,1,'2025-12-08 20:44:25','2026-01-08 15:41:08'),(9,'CRE-69373B2CA4F6C',9,NULL,2000000.00,0.00,2000000.00,3.50,12,206967.90,0.15,3000.00,2486614.80,'mensual',1,1100000.00,2000000.00,'2025-12-08','2026-12-08','2025-12-08','active',NULL,1,'2025-12-08 20:54:05','2025-12-08 21:25:18'),(10,NULL,10,NULL,NULL,0.00,NULL,NULL,NULL,NULL,0.15,NULL,NULL,'mensual',NULL,0.00,150000.00,NULL,NULL,NULL,'rejected',NULL,1,'2025-12-08 20:58:19','2025-12-08 20:58:32');
/*!40000 ALTER TABLE `credits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `credit_transactions`
--

DROP TABLE IF EXISTS `credit_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credit_transactions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `credit_id` bigint unsigned NOT NULL,
  `type` enum('purchase','payment','refund','credit_adjustment') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `amount` decimal(12,2) NOT NULL,
  `previous_balance` decimal(12,2) NOT NULL,
  `new_balance` decimal(12,2) NOT NULL,
  `tenant_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `credit_transactions_credit_id_created_at_index` (`credit_id`,`created_at`),
  KEY `credit_transactions_tenant_id_index` (`tenant_id`),
  KEY `credit_transactions_type_index` (`type`),
  KEY `credit_transactions_status_index` (`status`),
  CONSTRAINT `credit_transactions_credit_id_foreign` FOREIGN KEY (`credit_id`) REFERENCES `credits` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credit_transactions`
--

LOCK TABLES `credit_transactions` WRITE;
/*!40000 ALTER TABLE `credit_transactions` DISABLE KEYS */;
INSERT INTO `credit_transactions` VALUES (1,1,'purchase','rejected',230000.00,0.00,0.00,'tenant_69208a3194d34','jañsldjfkslñd',NULL,'2025-11-26 15:36:42','2025-12-08 20:59:03'),(2,2,'purchase','approved',520000.00,0.00,0.00,'tenant_69208a3194d34','Casco para Bicicleta','{\"tenant_name\": \"Coindraw\"}','2025-11-26 15:47:56','2025-11-27 00:00:02'),(3,3,'purchase','approved',1000.00,0.00,0.00,'69208a3194d34','Compra de prueba','{\"tenant_name\": \"coindraw\", \"tenant_user_id\": 2}','2025-11-27 00:19:07','2025-11-27 00:32:12'),(4,4,'purchase','approved',5678744.00,0.00,0.00,'tenant_69208a3194d34','ajsdñlfkjasdñl','{\"tenant_name\": \"Coindraw\", \"tenant_user_id\": 2}','2025-11-27 00:20:53','2025-11-27 00:21:27'),(5,2,'credit_adjustment','approved',2000000.00,2520000.00,4520000.00,'landlord','Habilitación de cupo adicional por administrador','{\"new_total_limit\": \"4520000.00\", \"old_total_limit\": 2520000}','2025-11-28 13:48:45','2025-11-28 13:48:45'),(6,2,'purchase','approved',300000.00,4520000.00,4220000.00,'tenant_69208a3194d34','venta de paquete de recarga','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-11-28 13:49:42','2025-11-28 13:49:42'),(7,2,'purchase','approved',300000.00,4220000.00,3920000.00,'tenant_69208a3194d34','venta de paquete de recarga','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-11-28 13:50:22','2025-11-28 13:50:22'),(8,2,'purchase','approved',340000.00,3920000.00,3580000.00,'tenant_69208a3194d34','compra de creditos','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-11-28 13:56:14','2025-11-28 13:56:14'),(9,3,'credit_adjustment','approved',1000000.00,1000.00,1001000.00,'landlord','Habilitación de cupo adicional por administrador','{\"new_total_limit\": \"1001000.00\", \"old_total_limit\": 1000}','2025-11-28 13:58:34','2025-11-28 13:58:34'),(10,3,'purchase','approved',200000.00,1001000.00,801000.00,'tenant_69208a3194d34','prueba','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-11-28 13:58:41','2025-11-28 13:58:41'),(11,2,'purchase','approved',120000.00,3580000.00,3460000.00,'tenant_6920ca18630b5','Suscripcion en platafoma','{\"tenant_name\": \"Libercol\", \"auto_approved\": true, \"tenant_user_id\": 1}','2025-11-28 19:14:49','2025-11-28 19:14:49'),(12,5,'purchase','approved',300000.00,0.00,0.00,'tenant_69208a3194d34','compra de prueba','{\"tenant_name\": \"Coindraw\", \"credit_config\": {\"term\": \"24\", \"frequency\": \"mensual\", \"cutoff_day\": \"28\", \"approved_at\": \"2025-12-01 17:44:34\", \"interest_rate\": \"10.00\", \"insurance_percentage\": \"5.00\"}, \"tenant_user_id\": 2}','2025-12-01 15:00:38','2025-12-01 17:44:34'),(13,2,'purchase','approved',210000.00,3460000.00,3250000.00,'tenant_69208a3194d34','Plan suscripcion a claude','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-12-01 20:54:54','2025-12-01 20:54:54'),(14,2,'purchase','approved',329999.99,3250000.00,2920000.01,'tenant_69208a3194d34','prueba','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-12-01 21:16:06','2025-12-01 21:16:06'),(15,2,'purchase','approved',180000.00,2920000.01,2740000.01,'tenant_6920ca18630b5','compra en libercol','{\"tenant_name\": \"Libercol\", \"auto_approved\": true, \"tenant_user_id\": 1}','2025-12-02 13:36:37','2025-12-02 13:36:37'),(16,2,'purchase','approved',200000.00,2740000.01,2540000.01,'tenant_6920ca18630b5','Servicios de Aseo','{\"tenant_name\": \"Libercol\", \"auto_approved\": true, \"tenant_user_id\": 1}','2025-12-02 14:40:09','2025-12-02 14:40:09'),(17,2,'purchase','approved',540000.00,2540000.01,2000000.01,'tenant_692858bce7b16','Medicamentos','{\"tenant_name\": \"Drogas Circasia\", \"auto_approved\": true, \"tenant_user_id\": 1}','2025-12-02 14:43:11','2025-12-02 14:43:11'),(18,6,'purchase','approved',90000.00,0.00,0.00,'tenant_69208a3194d34','compra de prueba','{\"tenant_name\": \"Coindraw\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"approved_at\": \"2025-12-02 17:08:36\", \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"tenant_user_id\": 2}','2025-12-02 16:04:35','2025-12-02 17:08:36'),(19,7,'purchase','approved',359999.99,0.00,0.00,'tenant_6920ca18630b5','Celular','{\"tenant_name\": \"Libercol\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"approved_at\": \"2025-12-08 17:01:43\", \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"tenant_user_id\": 1}','2025-12-02 20:49:57','2025-12-08 17:01:43'),(20,8,'purchase','approved',450000.00,0.00,0.00,'tenant_6920ca18630b5','Cama Doble con Cabecera','{\"tenant_name\": \"Libercol\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"approved_at\": \"2025-12-08 20:47:51\", \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"tenant_user_id\": 1}','2025-12-08 20:44:25','2025-12-08 20:47:51'),(21,9,'purchase','approved',200000.00,0.00,0.00,'tenant_6920ca18630b5','Moto Electrica','{\"tenant_name\": \"Libercol\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"approved_at\": \"2025-12-08 20:55:08\", \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"tenant_user_id\": 1}','2025-12-08 20:54:05','2025-12-08 20:55:08'),(22,10,'purchase','rejected',150000.00,0.00,0.00,'tenant_6920ca18630b5','compra para negar','{\"tenant_name\": \"Libercol\", \"tenant_user_id\": 1}','2025-12-08 20:58:19','2025-12-08 20:58:32'),(23,9,'purchase','approved',500000.00,1800000.00,1300000.00,'tenant_69208a3194d34','Compra de tiquetes','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-12-08 21:17:18','2025-12-08 21:17:18'),(24,9,'purchase','approved',200000.00,1300000.00,1100000.00,'tenant_69208a3194d34','tiquetes de vuelo','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2025-12-08 21:25:18','2025-12-08 21:25:18'),(25,6,'credit_adjustment','approved',1000000.00,0.00,1000000.00,'landlord','Habilitación de cupo adicional por administrador','{\"new_total_limit\": \"1090000.00\", \"old_total_limit\": 90000}','2025-12-08 21:55:34','2025-12-08 21:55:34'),(26,5,'credit_adjustment','approved',200000.00,0.00,200000.00,'landlord','Habilitación de cupo adicional por administrador','{\"new_total_limit\": \"500000.00\", \"old_total_limit\": 300000}','2025-12-08 21:58:48','2025-12-08 21:58:48'),(27,2,'purchase','approved',300000.00,2000000.01,1700000.01,'tenant_69279ccce227e','compra de prueba','{\"tenant_name\": \"Liceo Anglo Colombiano\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-06 23:21:07','2026-01-06 23:21:07'),(28,7,'purchase','approved',600000.00,2640000.01,2040000.01,'tenant_69279ccce227e','compra de Laura Garcia','{\"tenant_name\": \"Liceo Anglo Colombiano\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-06 23:25:07','2026-01-06 23:25:07'),(29,2,'purchase','approved',180000.00,1700000.01,1520000.01,'tenant_69208a3194d34','compra de dos manzanas bicicleta gw','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_user_id\": 2}','2026-01-07 15:31:49','2026-01-07 15:31:49'),(30,2,'purchase','approved',300000.00,1520000.01,1220000.01,'tenant_692858bce7b16','Compra de prueba','{\"tenant_name\": \"Drogas Circasia\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-08 14:01:01','2026-01-08 14:01:01'),(31,8,'purchase','approved',250000.00,3550000.00,3300000.00,'tenant_6920ca18630b5','Compra de activos para negocio','{\"tenant_name\": \"Libercol\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-08 14:47:20','2026-01-08 14:47:20'),(32,8,'purchase','approved',210000.00,3300000.00,3090000.00,'tenant_6920ca18630b5','prueba','{\"tenant_name\": \"Libercol\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-08 15:41:08','2026-01-08 15:41:08'),(33,2,'purchase','approved',150000.00,1220000.01,1070000.01,'tenant_695fd35066fb8','cafe de origen','{\"tenant_name\": \"Cafe JC\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-08 15:56:57','2026-01-08 15:56:57'),(34,2,'purchase','approved',200000.00,1070000.01,870000.01,'tenant_692858bce7b16','play station gaming','{\"tenant_name\": \"Drogas Circasia\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-08 18:56:10','2026-01-08 18:56:10'),(35,2,'purchase','approved',60000.00,870000.01,810000.01,'tenant_695fd35066fb8','Cuotas de prueba','{\"tenant_name\": \"Cafe JC\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-09 15:31:32','2026-01-09 15:31:32'),(36,2,'purchase','approved',150000.00,810000.01,660000.01,'tenant_695fd35066fb8','Compra de prueba reunión','{\"tenant_name\": \"Cafe JC\", \"auto_approved\": true, \"tenant_user_id\": 1}','2026-01-10 00:20:05','2026-01-10 00:20:05');
/*!40000 ALTER TABLE `credit_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `client_documents`
--

DROP TABLE IF EXISTS `client_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `client_documents` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `client_id` bigint unsigned NOT NULL,
  `document_type` enum('identification_front','identification_back','selfie','proof_of_address','proof_of_income','other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mime_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `file_size` bigint unsigned NOT NULL,
  `status` enum('pending','approved','rejected') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `rejection_reason` text COLLATE utf8mb4_unicode_ci,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `reviewed_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `client_documents_reviewed_by_foreign` (`reviewed_by`),
  KEY `client_documents_client_id_document_type_index` (`client_id`,`document_type`),
  KEY `client_documents_client_id_status_index` (`client_id`,`status`),
  CONSTRAINT `client_documents_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `client_documents_reviewed_by_foreign` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client_documents`
--

LOCK TABLES `client_documents` WRITE;
/*!40000 ALTER TABLE `client_documents` DISABLE KEYS */;
INSERT INTO `client_documents` VALUES (1,6,'identification_front','client_documents/6/51792359_identification_front_20251202154717.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-02 15:47:17','2025-12-02 15:47:17'),(2,6,'identification_back','client_documents/6/51792359_identification_back_20251202154722.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-02 15:47:22','2025-12-02 15:47:22'),(3,7,'identification_front','client_documents/7/1098311405_identification_front_20251202204950.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-02 20:49:50','2025-12-02 20:49:50'),(4,7,'identification_back','client_documents/7/1098311405_identification_back_20251202204953.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-02 20:49:53','2025-12-02 20:49:53'),(5,8,'identification_front','client_documents/8/1070975116_identification_front_20251208204406.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:44:07','2025-12-08 20:44:07'),(6,8,'identification_back','client_documents/8/1070975116_identification_back_20251208204416.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:44:16','2025-12-08 20:44:16'),(7,9,'identification_front','client_documents/9/123456789_identification_front_20251208205359.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:53:59','2025-12-08 20:53:59'),(8,9,'identification_back','client_documents/9/123456789_identification_back_20251208205403.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:54:03','2025-12-08 20:54:03'),(9,10,'identification_front','client_documents/10/987654321_identification_front_20251208205814.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:58:14','2025-12-08 20:58:14'),(10,10,'identification_back','client_documents/10/987654321_identification_back_20251208205817.pdf','Profile.pdf','application/pdf',45824,'pending',NULL,NULL,NULL,'2025-12-08 20:58:17','2025-12-08 20:58:17');
/*!40000 ALTER TABLE `client_documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `verification_codes`
--

DROP TABLE IF EXISTS `verification_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `verification_codes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `client_id` bigint unsigned NOT NULL,
  `phone_number` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `code` varchar(6) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` enum('sms','whatsapp') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'sms',
  `status` enum('pending','verified','expired') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pending',
  `expires_at` timestamp NOT NULL,
  `verified_at` timestamp NULL DEFAULT NULL,
  `attempts` int NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `verification_codes_client_id_status_index` (`client_id`,`status`),
  KEY `verification_codes_phone_number_code_index` (`phone_number`,`code`),
  CONSTRAINT `verification_codes_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `verification_codes`
--

LOCK TABLES `verification_codes` WRITE;
/*!40000 ALTER TABLE `verification_codes` DISABLE KEYS */;
INSERT INTO `verification_codes` VALUES (1,6,'3103362753','534573','sms','verified','2025-12-02 15:56:59','2025-12-02 15:47:10',0,'2025-12-02 15:46:59','2025-12-02 15:47:10'),(2,7,'3214567890','565105','sms','verified','2025-12-02 20:59:31','2025-12-02 20:49:46',0,'2025-12-02 20:49:31','2025-12-02 20:49:46'),(3,8,'3219876543','176148','sms','verified','2025-12-08 20:49:13','2025-12-08 20:43:27',0,'2025-12-08 20:39:13','2025-12-08 20:43:27'),(4,9,'3331234567','951439','sms','verified','2025-12-08 21:03:47','2025-12-08 20:53:56',0,'2025-12-08 20:53:47','2025-12-08 20:53:56'),(5,10,'1232468024','932941','sms','verified','2025-12-08 21:08:03','2025-12-08 20:58:11',0,'2025-12-08 20:58:03','2025-12-08 20:58:11');
/*!40000 ALTER TABLE `verification_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `payment_links`
--

DROP TABLE IF EXISTS `payment_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `payment_links` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `credit_id` bigint unsigned NOT NULL,
  `client_id` bigint unsigned NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `installments_data` json NOT NULL,
  `total_amount` decimal(12,2) NOT NULL,
  `status` enum('active','paid','expired','cancelled') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `expires_at` timestamp NOT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payment_links_token_unique` (`token`),
  KEY `payment_links_client_id_foreign` (`client_id`),
  KEY `payment_links_token_status_index` (`token`,`status`),
  KEY `payment_links_credit_id_index` (`credit_id`),
  CONSTRAINT `payment_links_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `payment_links_credit_id_foreign` FOREIGN KEY (`credit_id`) REFERENCES `credits` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_links`
--

LOCK TABLES `payment_links` WRITE;
/*!40000 ALTER TABLE `payment_links` DISABLE KEYS */;
INSERT INTO `payment_links` VALUES (1,2,2,'c859d7cc-3991-4df5-955b-198ed564634a','[{\"id\": 43, \"status\": \"parcial\", \"due_date\": \"2026-01-10T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 59976, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-08T01:14:50.000000Z\", \"paid_amount\": \"60066.00\", \"payment_date\": null, \"total_amount\": \"64338.00\", \"final_balance\": \"62076.00\", \"initial_balance\": \"122052.00\", \"interest_amount\": \"4272.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"59976.00\", \"remaining_amount\": \"4272.00\", \"installment_number\": 2, \"landlord_credit_id\": 2}, {\"id\": 44, \"status\": \"parcial\", \"due_date\": \"2026-01-16T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 62076, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-07T16:26:25.000000Z\", \"paid_amount\": \"62166.00\", \"payment_date\": null, \"total_amount\": \"64339.00\", \"final_balance\": \"0.00\", \"initial_balance\": \"62076.00\", \"interest_amount\": \"2173.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"62076.00\", \"remaining_amount\": \"2173.00\", \"installment_number\": 3, \"landlord_credit_id\": 2}]',6445.00,'active','2026-01-21 17:23:59',NULL,NULL,'2026-01-14 17:23:59','2026-01-14 17:23:59'),(2,2,2,'d177cae4-56b6-4eb9-863f-906a2118a061','[{\"id\": 43, \"status\": \"parcial\", \"due_date\": \"2026-01-10T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 59976, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-08T01:14:50.000000Z\", \"paid_amount\": \"60066.00\", \"payment_date\": null, \"total_amount\": \"64338.00\", \"final_balance\": \"62076.00\", \"initial_balance\": \"122052.00\", \"interest_amount\": \"4272.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"59976.00\", \"remaining_amount\": \"4272.00\", \"installment_number\": 2, \"landlord_credit_id\": 2}, {\"id\": 44, \"status\": \"parcial\", \"due_date\": \"2026-01-16T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 62076, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-07T16:26:25.000000Z\", \"paid_amount\": \"62166.00\", \"payment_date\": null, \"total_amount\": \"64339.00\", \"final_balance\": \"0.00\", \"initial_balance\": \"62076.00\", \"interest_amount\": \"2173.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"62076.00\", \"remaining_amount\": \"2173.00\", \"installment_number\": 3, \"landlord_credit_id\": 2}, {\"id\": 13, \"status\": \"pendiente\", \"due_date\": \"2025-12-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 14:40:11\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 16}, \"client_id\": 2, \"created_at\": \"2025-12-02T14:40:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:40:11.000000Z\", \"paid_amount\": \"0.00\", \"payment_date\": null, \"total_amount\": \"20722.00\", \"final_balance\": \"186303.00\", \"initial_balance\": \"200000.00\", \"interest_amount\": \"7000.00\", \"insurance_amount\": \"25.00\", \"principal_amount\": \"13697.00\", \"remaining_amount\": \"20722.00\", \"installment_number\": 1, \"landlord_credit_id\": 2}, {\"id\": 10, \"status\": \"parcial\", \"due_date\": \"2026-01-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 13:36:48\", \"last_payment\": {\"date\": \"2025-12-02 14:10:11\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_6920ca18630b5\", \"is_liquidation\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 59976, \"payment_history\": [{\"date\": \"2025-12-02 14:10:11\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_6920ca18630b5\", \"is_liquidation\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 15}, \"client_id\": 2, \"created_at\": \"2025-12-02T13:36:48.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:10:11.000000Z\", \"paid_amount\": \"60066.00\", \"payment_date\": null, \"total_amount\": \"64338.00\", \"final_balance\": \"62076.00\", \"initial_balance\": \"122052.00\", \"interest_amount\": \"4272.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"59976.00\", \"remaining_amount\": \"4272.00\", \"installment_number\": 2, \"landlord_credit_id\": 2}, {\"id\": 14, \"status\": \"pendiente\", \"due_date\": \"2026-01-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 14:40:11\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 16}, \"client_id\": 2, \"created_at\": \"2025-12-02T14:40:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:40:11.000000Z\", \"paid_amount\": \"0.00\", \"payment_date\": null, \"total_amount\": \"20722.00\", \"final_balance\": \"172127.00\", \"initial_balance\": \"186303.00\", \"interest_amount\": \"6521.00\", \"insurance_amount\": \"25.00\", \"principal_amount\": \"14176.00\", \"remaining_amount\": \"20722.00\", \"installment_number\": 2, \"landlord_credit_id\": 2}, {\"id\": 22, \"status\": \"pendiente\", \"due_date\": \"2026-01-08T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-08 18:56:12\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 34}, \"client_id\": 2, \"created_at\": \"2026-01-08T18:56:12.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-08T18:56:12.000000Z\", \"paid_amount\": \"0.00\", \"payment_date\": null, \"total_amount\": \"24078.00\", \"final_balance\": \"182952.00\", \"initial_balance\": \"200000.00\", \"interest_amount\": \"7000.00\", \"insurance_amount\": \"30.00\", \"principal_amount\": \"17048.00\", \"remaining_amount\": \"24078.00\", \"installment_number\": 1, \"landlord_credit_id\": 2}, {\"id\": 15, \"status\": \"pendiente\", \"due_date\": \"2026-01-10T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-10 00:20:07\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 36}, \"client_id\": 2, \"created_at\": \"2026-01-10T00:20:07.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-10T00:20:07.000000Z\", \"paid_amount\": \"0.00\", \"payment_date\": null, \"total_amount\": \"28188.00\", \"final_balance\": \"78868.00\", \"initial_balance\": \"103399.00\", \"interest_amount\": \"3619.00\", \"insurance_amount\": \"38.00\", \"principal_amount\": \"24531.00\", \"remaining_amount\": \"28188.00\", \"installment_number\": 3, \"landlord_credit_id\": 2}, {\"id\": 16, \"status\": \"pendiente\", \"due_date\": \"2026-01-16T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-10 00:20:07\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 36}, \"client_id\": 2, \"created_at\": \"2026-01-10T00:20:07.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-10T00:20:07.000000Z\", \"paid_amount\": \"0.00\", \"payment_date\": null, \"total_amount\": \"28188.00\", \"final_balance\": \"53478.00\", \"initial_balance\": \"78868.00\", \"interest_amount\": \"2760.00\", \"insurance_amount\": \"38.00\", \"principal_amount\": \"25390.00\", \"remaining_amount\": \"28188.00\", \"installment_number\": 4, \"landlord_credit_id\": 2}]',132615.00,'active','2026-01-21 17:37:01',NULL,NULL,'2026-01-14 17:37:01','2026-01-14 17:37:01'),(3,2,2,'7a11a544-232c-43ef-9c23-a5d5adafe9c7','[{\"id\": 43, \"status\": \"parcial\", \"due_date\": \"2026-01-10T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 59976, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, {\"date\": \"2026-01-08 01:14:50\", \"amount\": 0, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_early_payment\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-08T01:14:50.000000Z\", \"paid_amount\": \"60066.00\", \"tenant_name\": \"Test Tenant\", \"payment_date\": null, \"total_amount\": \"64338.00\", \"final_balance\": \"62076.00\", \"tenant_domain\": \"coindraw.localhost\", \"initial_balance\": \"122052.00\", \"interest_amount\": \"4272.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"59976.00\", \"remaining_amount\": \"4272.00\", \"installment_number\": 2, \"landlord_credit_id\": 2, \"transaction_amount\": \"180000.00\", \"transaction_description\": \"compra de dos manzanas bicicleta gw\"}, {\"id\": 44, \"status\": \"parcial\", \"due_date\": \"2026-01-16T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-07 15:31:51\", \"last_payment\": {\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 62076, \"payment_history\": [{\"date\": \"2026-01-07 16:26:25\", \"amount\": 62166, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"is_liquidation\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 29}, \"client_id\": 2, \"created_at\": \"2026-01-07T15:31:51.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-07T16:26:25.000000Z\", \"paid_amount\": \"62166.00\", \"tenant_name\": \"Test Tenant\", \"payment_date\": null, \"total_amount\": \"64339.00\", \"final_balance\": \"0.00\", \"tenant_domain\": \"coindraw.localhost\", \"initial_balance\": \"62076.00\", \"interest_amount\": \"2173.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"62076.00\", \"remaining_amount\": \"2173.00\", \"installment_number\": 3, \"landlord_credit_id\": 2, \"transaction_amount\": \"180000.00\", \"transaction_description\": \"compra de dos manzanas bicicleta gw\"}, {\"id\": 13, \"status\": \"pendiente\", \"due_date\": \"2025-12-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 14:40:11\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 16}, \"client_id\": 2, \"created_at\": \"2025-12-02T14:40:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:40:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Libercol\", \"payment_date\": null, \"total_amount\": \"20722.00\", \"final_balance\": \"186303.00\", \"tenant_domain\": \"libercol.localhost\", \"initial_balance\": \"200000.00\", \"interest_amount\": \"7000.00\", \"insurance_amount\": \"25.00\", \"principal_amount\": \"13697.00\", \"remaining_amount\": \"20722.00\", \"installment_number\": 1, \"landlord_credit_id\": 2, \"transaction_amount\": \"200000.00\", \"transaction_description\": \"Servicios de Aseo\"}, {\"id\": 10, \"status\": \"parcial\", \"due_date\": \"2026-01-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 13:36:48\", \"last_payment\": {\"date\": \"2025-12-02 14:10:11\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_6920ca18630b5\", \"is_liquidation\": true}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 59976, \"payment_history\": [{\"date\": \"2025-12-02 14:10:11\", \"amount\": 60066, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_6920ca18630b5\", \"is_liquidation\": true}}], \"purchase_amount\": 180000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 15}, \"client_id\": 2, \"created_at\": \"2025-12-02T13:36:48.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:10:11.000000Z\", \"paid_amount\": \"60066.00\", \"tenant_name\": \"Libercol\", \"payment_date\": null, \"total_amount\": \"64338.00\", \"final_balance\": \"62076.00\", \"tenant_domain\": \"libercol.localhost\", \"initial_balance\": \"122052.00\", \"interest_amount\": \"4272.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"59976.00\", \"remaining_amount\": \"4272.00\", \"installment_number\": 2, \"landlord_credit_id\": 2, \"transaction_amount\": \"180000.00\", \"transaction_description\": \"compra en libercol\"}, {\"id\": 14, \"status\": \"pendiente\", \"due_date\": \"2026-01-02T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2025-12-02 14:40:11\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 16}, \"client_id\": 2, \"created_at\": \"2025-12-02T14:40:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2025-12-02T14:40:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Libercol\", \"payment_date\": null, \"total_amount\": \"20722.00\", \"final_balance\": \"172127.00\", \"tenant_domain\": \"libercol.localhost\", \"initial_balance\": \"186303.00\", \"interest_amount\": \"6521.00\", \"insurance_amount\": \"25.00\", \"principal_amount\": \"14176.00\", \"remaining_amount\": \"20722.00\", \"installment_number\": 2, \"landlord_credit_id\": 2, \"transaction_amount\": \"200000.00\", \"transaction_description\": \"Servicios de Aseo\"}, {\"id\": 22, \"status\": \"pendiente\", \"due_date\": \"2026-01-08T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-08 18:56:12\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 34}, \"client_id\": 2, \"created_at\": \"2026-01-08T18:56:12.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-08T18:56:12.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Drogas Circasia\", \"payment_date\": null, \"total_amount\": \"24078.00\", \"final_balance\": \"182952.00\", \"tenant_domain\": \"drogascircasia.localhost\", \"initial_balance\": \"200000.00\", \"interest_amount\": \"7000.00\", \"insurance_amount\": \"30.00\", \"principal_amount\": \"17048.00\", \"remaining_amount\": \"24078.00\", \"installment_number\": 1, \"landlord_credit_id\": 2, \"transaction_amount\": \"200000.00\", \"transaction_description\": \"play station gaming\"}, {\"id\": 15, \"status\": \"pendiente\", \"due_date\": \"2026-01-10T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-10 00:20:07\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 36}, \"client_id\": 2, \"created_at\": \"2026-01-10T00:20:07.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-10T00:20:07.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"28188.00\", \"final_balance\": \"78868.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"103399.00\", \"interest_amount\": \"3619.00\", \"insurance_amount\": \"38.00\", \"principal_amount\": \"24531.00\", \"remaining_amount\": \"28188.00\", \"installment_number\": 3, \"landlord_credit_id\": 2, \"transaction_amount\": \"150000.00\", \"transaction_description\": \"Compra de prueba reunión\"}, {\"id\": 16, \"status\": \"pendiente\", \"due_date\": \"2026-01-16T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-10 00:20:07\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 36}, \"client_id\": 2, \"created_at\": \"2026-01-10T00:20:07.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-10T00:20:07.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"28188.00\", \"final_balance\": \"53478.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"78868.00\", \"interest_amount\": \"2760.00\", \"insurance_amount\": \"38.00\", \"principal_amount\": \"25390.00\", \"remaining_amount\": \"28188.00\", \"installment_number\": 4, \"landlord_credit_id\": 2, \"transaction_amount\": \"150000.00\", \"transaction_description\": \"Compra de prueba reunión\"}]',132615.00,'active','2026-01-21 17:40:00',NULL,NULL,'2026-01-14 17:40:00','2026-01-14 17:40:00');
/*!40000 ALTER TABLE `payment_links` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-14 17:43:37
