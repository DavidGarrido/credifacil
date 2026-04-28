-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
--
-- Host: localhost    Database: tenant_69279ccce227e
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
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `credit_installments`
--

LOCK TABLES `credit_installments` WRITE;
/*!40000 ALTER TABLE `credit_installments` DISABLE KEYS */;
INSERT INTO `credit_installments` VALUES (1,2,0,NULL,300000.00,0.00,0.00,300000.00,0.00,300000.00,'pendiente',300000.00,300000.00,NULL,2,1,'{\"client_name\": \"David Alexander Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": 3.5, \"insurance_percentage\": 0.15}, \"available_amount\": 1700000.01, \"total_credit_limit\": 4520000, \"transaction_amount\": 300000, \"created_at_purchase\": \"2026-01-06 23:21:09\", \"client_identification\": \"1022978178\", \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(2,2,1,'2026-01-06',45800.00,10500.00,75.00,56375.00,56375.00,0.00,'pagada',300000.00,254200.00,'2026-01-06',2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"last_payment\": {\"date\": \"2026-01-06 23:25:31\", \"amount\": 56375, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69279ccce227e\"}}, \"interest_paid\": 10500, \"insurance_paid\": 75, \"principal_paid\": 45800, \"payment_history\": [{\"date\": \"2026-01-06 23:25:31\", \"amount\": 56375, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69279ccce227e\"}}], \"purchase_amount\": 300000, \"is_early_payment\": false, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:25:31'),(3,2,2,'2026-02-06',47403.00,8897.00,75.00,56375.00,0.00,56375.00,'pendiente',254200.00,206797.00,NULL,2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(4,2,3,'2026-03-06',49062.00,7238.00,75.00,56375.00,0.00,56375.00,'pendiente',206797.00,157735.00,NULL,2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(5,2,4,'2026-04-06',50779.00,5521.00,75.00,56375.00,0.00,56375.00,'pendiente',157735.00,106956.00,NULL,2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(6,2,5,'2026-05-06',52557.00,3743.00,75.00,56375.00,0.00,56375.00,'pendiente',106956.00,54399.00,NULL,2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(7,2,6,'2026-06-06',54399.00,1904.00,75.00,56378.00,0.00,56378.00,'pendiente',54399.00,0.00,NULL,2,1,'{\"generated_at\": \"2026-01-06 23:21:09\", \"purchase_amount\": 300000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 27}','2026-01-06 23:21:09','2026-01-06 23:21:09'),(8,7,0,NULL,600000.00,0.00,0.00,600000.00,0.00,600000.00,'pendiente',600000.00,600000.00,NULL,7,1,'{\"client_name\": \"Laura Garrido Hernandez\", \"credit_config\": {\"term\": 12, \"frequency\": \"mensual\", \"cutoff_day\": 1, \"interest_rate\": 3.5, \"insurance_percentage\": 0.15}, \"available_amount\": 2040000.01, \"total_credit_limit\": 3000000, \"transaction_amount\": 600000, \"created_at_purchase\": \"2026-01-06 23:25:09\", \"client_identification\": \"1098311405\", \"landlord_transaction_id\": 28}','2026-01-06 23:25:09','2026-01-06 23:25:09'),(9,7,1,'2026-01-06',193161.00,21000.00,300.00,214461.00,214461.00,0.00,'pagada',600000.00,406839.00,'2026-01-06',7,1,'{\"generated_at\": \"2026-01-06 23:25:09\", \"last_payment\": {\"date\": \"2026-01-06 23:26:04\", \"amount\": 214461, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69279ccce227e\", \"is_early_payment\": false}}, \"interest_paid\": 21000, \"insurance_paid\": 300, \"principal_paid\": 193161, \"payment_history\": [{\"date\": \"2026-01-06 23:26:04\", \"amount\": 214461, \"method\": \"efectivo\", \"user_id\": 1, \"metadata\": {\"reference\": null, \"tenant_id\": \"tenant_69279ccce227e\", \"is_early_payment\": false}}], \"purchase_amount\": 600000, \"is_early_payment\": false, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 28}','2026-01-06 23:25:09','2026-01-06 23:26:04'),(10,7,2,'2026-02-06',199922.00,14239.00,300.00,214461.00,0.00,214461.00,'pendiente',406839.00,206917.00,NULL,7,1,'{\"generated_at\": \"2026-01-06 23:25:09\", \"purchase_amount\": 600000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 28}','2026-01-06 23:25:09','2026-01-06 23:25:09'),(11,7,3,'2026-03-06',206917.00,7242.00,300.00,214459.00,0.00,214459.00,'pendiente',206917.00,0.00,NULL,7,1,'{\"generated_at\": \"2026-01-06 23:25:09\", \"purchase_amount\": 600000, \"installment_config\": {\"frequency\": \"mensual\", \"interest_rate\": 3.5, \"effective_rate\": 3.5000000000000004, \"insurance_percentage\": 0.15}, \"landlord_transaction_id\": 28}','2026-01-06 23:25:09','2026-01-06 23:25:09');
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

-- Dump completed on 2026-01-14 17:43:37
