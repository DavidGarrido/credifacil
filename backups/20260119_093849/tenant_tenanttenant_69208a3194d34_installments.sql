-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
--
-- Host: localhost    Database: tenanttenant_69208a3194d34
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
-- Table structure for table `credit_installments`
--

DROP TABLE IF EXISTS `credit_installments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `credit_installments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `landlord_credit_id` bigint unsigned NOT NULL,
  `installment_number` int NOT NULL DEFAULT '1',
  `due_date` date DEFAULT NULL,
  `principal_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `interest_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `insurance_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `total_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `paid_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `remaining_amount` decimal(12,2) NOT NULL DEFAULT '0.00',
  `transfer_to_landlord` decimal(12,2) NOT NULL DEFAULT '0.00',
  `status` enum('pendiente','pagada','vencida','parcial') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `initial_balance` decimal(12,2) NOT NULL DEFAULT '0.00',
  `final_balance` decimal(12,2) NOT NULL DEFAULT '0.00',
  `payment_date` date DEFAULT NULL,
  `client_id` bigint unsigned NOT NULL,
  `creator_id` bigint unsigned NOT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `credit_installments_creator_id_foreign` (`creator_id`),
  KEY `credit_installments_landlord_credit_id_index` (`landlord_credit_id`),
  KEY `credit_installments_client_id_index` (`client_id`),
  KEY `credit_installments_landlord_credit_id_installment_number_index` (`landlord_credit_id`,`installment_number`),
  KEY `credit_installments_due_date_index` (`due_date`),
  KEY `credit_installments_status_index` (`status`),
  CONSTRAINT `credit_installments_creator_id_foreign` FOREIGN KEY (`creator_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credit_installments`
--

LOCK TABLES `credit_installments` WRITE;
/*!40000 ALTER TABLE `credit_installments` DISABLE KEYS */;
INSERT INTO `credit_installments` VALUES (1,1,0,NULL,150000.00,0.00,0.00,150000.00,0.00,150000.00,0.00,'pendiente',150000.00,150000.00,NULL,1,2,'{\"client_name\": \"David Alexander Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": 3.5, \"insurance_percentage\": 0.15}, \"available_amount\": 850000, \"total_credit_limit\": 1300000, \"transaction_amount\": 150000, \"created_at_purchase\": \"2026-01-14 18:10:11\", \"client_identification\": \"1022978178\", \"landlord_transaction_id\": 3}','2026-01-14 18:10:11','2026-01-14 18:10:11'),(2,1,1,'2026-01-14',48290.00,5250.00,75.00,53615.00,53615.00,0.00,0.00,'pagada',150000.00,101710.00,'2026-01-15',1,2,'{\"generated_at\": \"2026-01-14 18:10:11\", \"last_payment\": {\"date\": \"2026-01-15 23:48:03\", \"amount\": 53615, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 5250, \"insurance_paid\": 75, \"principal_paid\": 48290, \"payment_history\": [{\"date\": \"2026-01-15 23:48:03\", \"amount\": 53615, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 150000, \"is_early_payment\": false, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}','2026-01-14 18:10:11','2026-01-15 23:48:03'),(3,1,2,'2026-02-14',49980.00,3560.00,75.00,53615.00,10000.00,40055.00,0.00,'parcial',101710.00,51730.00,NULL,1,2,'{\"generated_at\": \"2026-01-14 18:10:11\", \"last_payment\": {\"date\": \"2026-01-16 00:11:51\", \"amount\": 10000, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 0, \"insurance_paid\": 75, \"principal_paid\": 9925, \"payment_history\": [{\"date\": \"2026-01-16 00:11:51\", \"amount\": 10000, \"method\": \"efectivo\", \"user_id\": 2, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69208a3194d34\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 150000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}','2026-01-14 18:10:11','2026-01-16 00:11:51'),(4,1,3,'2026-03-14',51730.00,1811.00,75.00,53616.00,0.00,53616.00,0.00,'pendiente',51730.00,0.00,NULL,1,2,'{\"generated_at\": \"2026-01-14 18:10:11\", \"purchase_amount\": 150000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 3}','2026-01-14 18:10:11','2026-01-14 18:10:11');
/*!40000 ALTER TABLE `credit_installments` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-01-19 14:38:51
