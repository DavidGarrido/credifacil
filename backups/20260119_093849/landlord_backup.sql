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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,'David Alexander Garrido Hernandez','1022978178','alexg.9207@proton.me','3205731318','2026-01-14 17:47:53','Circasia Porvenir CR 9 BLOQ 7 APT 201','pending_verification',NULL,1,'2026-01-14 17:47:27','2026-01-14 17:47:53');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credits`
--

LOCK TABLES `credits` WRITE;
/*!40000 ALTER TABLE `credits` DISABLE KEYS */;
INSERT INTO `credits` VALUES (1,'CRE-6967D8E3B34EF',1,NULL,300000.00,0.00,300000.00,3.50,12,31045.18,0.15,450.00,372992.16,'mensual',1,530000.02,1300000.00,'2026-01-14','2027-01-14','2026-01-14','active',NULL,1,'2026-01-14 17:52:53','2026-01-16 20:42:57');
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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credit_transactions`
--

LOCK TABLES `credit_transactions` WRITE;
/*!40000 ALTER TABLE `credit_transactions` DISABLE KEYS */;
INSERT INTO `credit_transactions` VALUES (1,1,'purchase','approved',300000.00,0.00,0.00,'tenant_695fd35066fb8','Compra de Cafe de Origen para Exportacion','{\"tenant_name\": \"Cafe JC\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"approved_at\": \"2026-01-14 17:56:51\", \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"tenant_domain\": \"cafejc.localhost\", \"tenant_user_id\": 1}','2026-01-14 17:52:53','2026-01-14 17:56:51'),(2,1,'credit_adjustment','approved',1000000.00,0.00,1000000.00,'landlord','Habilitación de cupo adicional por administrador','{\"new_total_limit\": \"1300000.00\", \"old_total_limit\": 300000}','2026-01-14 18:09:21','2026-01-14 18:09:21'),(3,1,'purchase','approved',150000.00,1000000.00,850000.00,'tenant_69208a3194d34','Compra de creditos de participacion en sorteos','{\"tenant_name\": \"Coindraw\", \"auto_approved\": true, \"tenant_domain\": null, \"tenant_user_id\": 2}','2026-01-14 18:10:09','2026-01-14 18:10:09'),(4,1,'purchase','approved',119999.98,850000.00,730000.02,'tenant_695fd35066fb8','Compra de filtros y Melitas para preparacion en v60','{\"tenant_name\": \"Cafe JC\", \"auto_approved\": true, \"tenant_domain\": null, \"tenant_user_id\": 1}','2026-01-14 18:30:09','2026-01-14 18:30:09'),(5,1,'purchase','approved',200000.00,730000.02,530000.02,'tenant_695fd35066fb8','Compra de Maquina de preparacion','{\"tenant_name\": \"Cafe JC\", \"auto_approved\": true, \"tenant_domain\": null, \"tenant_user_id\": 1}','2026-01-16 20:42:57','2026-01-16 20:42:57');
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
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `client_documents`
--

LOCK TABLES `client_documents` WRITE;
/*!40000 ALTER TABLE `client_documents` DISABLE KEYS */;
INSERT INTO `client_documents` VALUES (1,1,'identification_front','client_documents/1/1022978178_identification_front_20260114175243.pdf','cedula.pdf','application/pdf',540420,'pending',NULL,NULL,NULL,'2026-01-14 17:52:43','2026-01-14 17:52:43'),(2,1,'identification_back','client_documents/1/1022978178_identification_back_20260114175249.pdf','cedula.pdf','application/pdf',540420,'pending',NULL,NULL,NULL,'2026-01-14 17:52:49','2026-01-14 17:52:49');
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
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `verification_codes`
--

LOCK TABLES `verification_codes` WRITE;
/*!40000 ALTER TABLE `verification_codes` DISABLE KEYS */;
INSERT INTO `verification_codes` VALUES (1,1,'3205731318','180839','sms','verified','2026-01-14 17:57:39','2026-01-14 17:47:53',0,'2026-01-14 17:47:39','2026-01-14 17:47:53');
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
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `payment_links`
--

LOCK TABLES `payment_links` WRITE;
/*!40000 ALTER TABLE `payment_links` DISABLE KEYS */;
INSERT INTO `payment_links` VALUES (1,1,1,'f2aa73cf-64b6-414e-ad04-0e3db7f6c91f','[{\"id\": 2, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:02:48\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:02:48.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-14T18:02:48.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"56375.00\", \"final_balance\": \"254200.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"300000.00\", \"interest_amount\": \"10500.00\", \"insurance_amount\": \"75.00\", \"principal_amount\": \"45800.00\", \"remaining_amount\": \"56375.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"300000.00\", \"transaction_description\": \"Compra de Cafe de Origen para Exportacion\"}]',56375.00,'active','2026-01-21 18:03:22',NULL,NULL,'2026-01-14 18:03:22','2026-01-14 18:03:22'),(2,1,1,'a2ebb60a-e1c3-4eb3-9979-ff4bbfb5c22c','[{\"id\": 2, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:10:11\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:10:11.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-14T18:10:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Test Tenant\", \"payment_date\": null, \"total_amount\": \"53615.00\", \"final_balance\": \"101710.00\", \"tenant_domain\": \"coindraw.localhost\", \"initial_balance\": \"150000.00\", \"interest_amount\": \"5250.00\", \"insurance_amount\": \"75.00\", \"principal_amount\": \"48290.00\", \"remaining_amount\": \"53615.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"150000.00\", \"transaction_description\": \"Compra de creditos de participacion en sorteos\"}]',53615.00,'active','2026-01-21 18:12:20',NULL,NULL,'2026-01-14 18:12:20','2026-01-14 18:12:20'),(3,1,1,'5c673c1c-a227-44b6-8b93-bd421002a2de','[{\"id\": 9, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:30:11\", \"purchase_amount\": 119999.98, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 4}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:30:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-14T18:30:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"63258.00\", \"final_balance\": \"61032.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"119999.98\", \"interest_amount\": \"4200.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"58968.00\", \"remaining_amount\": \"63258.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"119999.98\", \"transaction_description\": \"Compra de filtros y Melitas para preparacion en v60\"}, {\"id\": 2, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:10:11\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:10:11.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-14T18:10:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Test Tenant\", \"payment_date\": null, \"total_amount\": \"53615.00\", \"final_balance\": \"101710.00\", \"tenant_domain\": \"coindraw.localhost\", \"initial_balance\": \"150000.00\", \"interest_amount\": \"5250.00\", \"insurance_amount\": \"75.00\", \"principal_amount\": \"48290.00\", \"remaining_amount\": \"53615.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"150000.00\", \"transaction_description\": \"Compra de creditos de participacion en sorteos\"}]',116873.00,'active','2026-01-21 18:30:45',NULL,NULL,'2026-01-14 18:30:45','2026-01-14 18:30:45'),(4,1,1,'fbb9a530-95d5-4b73-8c3b-753ad04e5feb','[{\"id\": 9, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:30:11\", \"purchase_amount\": 119999.98, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 4}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:30:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-14T18:30:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"63258.00\", \"final_balance\": \"61032.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"119999.98\", \"interest_amount\": \"4200.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"58968.00\", \"remaining_amount\": \"63258.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"119999.98\", \"transaction_description\": \"Compra de filtros y Melitas para preparacion en v60\"}, {\"id\": 2, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:10:11\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:10:11.000000Z\", \"creator_id\": 2, \"updated_at\": \"2026-01-14T18:10:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Test Tenant\", \"payment_date\": null, \"total_amount\": \"53615.00\", \"final_balance\": \"101710.00\", \"tenant_domain\": \"coindraw.localhost\", \"initial_balance\": \"150000.00\", \"interest_amount\": \"5250.00\", \"insurance_amount\": \"75.00\", \"principal_amount\": \"48290.00\", \"remaining_amount\": \"53615.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"150000.00\", \"transaction_description\": \"Compra de creditos de participacion en sorteos\"}]',116873.00,'active','2026-01-22 01:15:44',NULL,NULL,'2026-01-15 01:15:44','2026-01-15 01:15:44'),(5,1,1,'59320681-04b7-4ffc-9525-01bce07f145f','[{\"id\": 9, \"status\": \"pendiente\", \"due_date\": \"2026-01-14T00:00:00.000000Z\", \"metadata\": {\"generated_at\": \"2026-01-14 18:30:11\", \"purchase_amount\": 119999.98, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 4}, \"client_id\": 1, \"created_at\": \"2026-01-14T18:30:11.000000Z\", \"creator_id\": 1, \"updated_at\": \"2026-01-14T18:30:11.000000Z\", \"paid_amount\": \"0.00\", \"tenant_name\": \"Cafe JC\", \"payment_date\": null, \"total_amount\": \"63258.00\", \"final_balance\": \"61032.00\", \"tenant_domain\": \"cafejc.localhost\", \"initial_balance\": \"119999.98\", \"interest_amount\": \"4200.00\", \"insurance_amount\": \"90.00\", \"principal_amount\": \"58968.00\", \"remaining_amount\": \"63258.00\", \"installment_number\": 1, \"landlord_credit_id\": 1, \"transaction_amount\": \"119999.98\", \"transfer_to_landlord\": \"0.00\", \"transaction_description\": \"Compra de filtros y Melitas para preparacion en v60\"}]',63258.00,'active','2026-01-23 00:12:13',NULL,NULL,'2026-01-16 00:12:13','2026-01-16 00:12:13');
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

-- Dump completed on 2026-01-19 14:38:49
