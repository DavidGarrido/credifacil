-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
--
-- Host: localhost    Database: tenanttenant_695fd35066fb8
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
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credit_installments`
--

LOCK TABLES `credit_installments` WRITE;
/*!40000 ALTER TABLE `credit_installments` DISABLE KEYS */;
INSERT INTO `credit_installments` VALUES (1,1,0,NULL,300000.00,0.00,0.00,300000.00,0.00,300000.00,0.00,'pendiente',300000.00,300000.00,NULL,1,1,'{\"client_name\": \"David Alexander Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": \"3.50\", \"insurance_percentage\": \"0.15\"}, \"available_amount\": \"0.00\", \"created_at_webhook\": \"2026-01-14 18:02:12\", \"total_credit_limit\": \"300000.00\", \"transaction_amount\": \"300000.00\", \"client_identification\": \"1022978178\", \"landlord_transaction_id\": 1}','2026-01-14 18:02:12','2026-01-14 18:02:12'),(2,1,1,'2026-01-14',45800.00,10500.00,75.00,56375.00,56375.00,0.00,0.00,'pagada',300000.00,254200.00,'2026-01-14',1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"last_payment\": {\"date\": \"2026-01-14 18:05:19\", \"amount\": 56375, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 10500, \"insurance_paid\": 75, \"principal_paid\": 45800, \"payment_history\": [{\"date\": \"2026-01-14 18:05:19\", \"amount\": 56375, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 300000, \"is_early_payment\": false, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-14 18:05:19'),(3,1,2,'2026-02-14',47403.00,8897.00,75.00,56375.00,47478.00,0.00,0.00,'pagada',254200.00,206797.00,'2026-01-16',1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"last_payment\": {\"date\": \"2026-01-16 14:36:04\", \"amount\": 47478, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 0, \"insurance_paid\": 75, \"principal_paid\": 47403, \"payment_history\": [{\"date\": \"2026-01-16 14:36:04\", \"amount\": 47478, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 300000, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-16 14:36:04'),(4,1,3,'2026-03-14',49062.00,7238.00,75.00,56375.00,0.00,56375.00,0.00,'pendiente',206797.00,157735.00,NULL,1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-14 18:02:48'),(5,1,4,'2026-04-14',50779.00,5521.00,75.00,56375.00,0.00,56375.00,0.00,'pendiente',157735.00,106956.00,NULL,1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-14 18:02:48'),(6,1,5,'2026-05-14',52557.00,3743.00,75.00,56375.00,0.00,56375.00,0.00,'pendiente',106956.00,54399.00,NULL,1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-14 18:02:48'),(7,1,6,'2026-06-14',54399.00,1904.00,75.00,56378.00,0.00,56378.00,0.00,'pendiente',54399.00,0.00,NULL,1,1,'{\"generated_at\": \"2026-01-14 18:02:48\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": \"3.50\", \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": \"0.15\"}, \"landlord_transaction_id\": 1}','2026-01-14 18:02:48','2026-01-14 18:02:48'),(8,1,0,NULL,119999.98,0.00,0.00,119999.98,0.00,119999.98,0.00,'pendiente',119999.98,119999.98,NULL,1,1,'{\"client_name\": \"David Alexander Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": 3.5, \"insurance_percentage\": 0.15}, \"available_amount\": 730000.02, \"total_credit_limit\": 1300000, \"transaction_amount\": 119999.98, \"created_at_purchase\": \"2026-01-14 18:30:11\", \"client_identification\": \"1022978178\", \"landlord_transaction_id\": 4}','2026-01-14 18:30:11','2026-01-14 18:30:11'),(9,1,1,'2026-01-14',58968.00,4200.00,90.00,63258.00,63258.00,0.00,0.00,'pagada',119999.98,61032.00,'2026-01-16',1,1,'{\"generated_at\": \"2026-01-14 18:30:11\", \"last_payment\": {\"date\": \"2026-01-16 00:12:52\", \"amount\": 63258, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 4200, \"insurance_paid\": 90, \"principal_paid\": 58968, \"payment_history\": [{\"date\": \"2026-01-16 00:12:52\", \"amount\": 63258, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 119999.98, \"is_early_payment\": false, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 4}','2026-01-14 18:30:11','2026-01-16 00:12:52'),(10,1,2,'2026-02-14',61032.00,2136.00,90.00,63258.00,2522.00,58600.00,0.00,'parcial',61032.00,0.00,NULL,1,1,'{\"generated_at\": \"2026-01-14 18:30:11\", \"last_payment\": {\"date\": \"2026-01-16 14:36:04\", \"amount\": 2522, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}, \"interest_paid\": 0, \"insurance_paid\": 90, \"principal_paid\": 2432, \"payment_history\": [{\"date\": \"2026-01-16 14:36:04\", \"amount\": 2522, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_695fd35066fb8\", \"payment_type\": \"installment\", \"is_early_payment\": false}}], \"purchase_amount\": 119999.98, \"is_early_payment\": true, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 4}','2026-01-14 18:30:11','2026-01-16 14:36:04'),(11,1,0,NULL,200000.00,0.00,0.00,200000.00,0.00,200000.00,0.00,'pendiente',200000.00,200000.00,NULL,1,1,'{\"client_name\": \"David Alexander Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": 3.5, \"insurance_percentage\": 0.15}, \"available_amount\": 530000.02, \"total_credit_limit\": 1300000, \"transaction_amount\": 200000, \"created_at_purchase\": \"2026-01-16 20:42:59\", \"client_identification\": \"1022978178\", \"landlord_transaction_id\": 5}','2026-01-16 20:42:59','2026-01-16 20:42:59'),(12,1,1,'2026-01-16',47450.00,7000.00,75.00,54525.00,0.00,54525.00,0.00,'pendiente',200000.00,152550.00,NULL,1,1,'{\"generated_at\": \"2026-01-16 20:42:59\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 5}','2026-01-16 20:42:59','2026-01-16 20:42:59'),(13,1,2,'2026-02-16',49111.00,5339.00,75.00,54525.00,0.00,54525.00,0.00,'pendiente',152550.00,103439.00,NULL,1,1,'{\"generated_at\": \"2026-01-16 20:42:59\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 5}','2026-01-16 20:42:59','2026-01-16 20:42:59'),(14,1,3,'2026-03-16',50830.00,3620.00,75.00,54525.00,0.00,54525.00,0.00,'pendiente',103439.00,52609.00,NULL,1,1,'{\"generated_at\": \"2026-01-16 20:42:59\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 5}','2026-01-16 20:42:59','2026-01-16 20:42:59'),(15,1,4,'2026-04-16',52609.00,1841.00,75.00,54525.00,0.00,54525.00,0.00,'pendiente',52609.00,0.00,NULL,1,1,'{\"generated_at\": \"2026-01-16 20:42:59\", \"purchase_amount\": 200000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 5}','2026-01-16 20:42:59','2026-01-16 20:42:59');
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

-- Dump completed on 2026-01-19 14:38:55
