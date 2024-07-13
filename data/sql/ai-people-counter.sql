-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: db
-- Generation Time: Jul 13, 2024 at 02:35 PM
-- Server version: 11.4.1-MariaDB-1:11.4.1+maria~ubu2204
-- PHP Version: 8.2.20

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `ai-people-counter`
--
CREATE DATABASE IF NOT EXISTS `ai-people-counter` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `ai-people-counter`;

-- --------------------------------------------------------

--
-- Table structure for table `scheduledcounts`
--

CREATE TABLE `scheduledcounts` (
  `id` int(11) NOT NULL,
  `jobname` tinytext NOT NULL,
  `model` text NOT NULL,
  `x` smallint(6) DEFAULT NULL,
  `y` smallint(6) DEFAULT NULL,
  `width` smallint(6) DEFAULT NULL,
  `height` smallint(6) DEFAULT NULL,
  `object` tinytext NOT NULL,
  `frequencymin` mediumint(9) NOT NULL,
  `URL` text NOT NULL,
  `enabled` tinyint(1) NOT NULL,
  `created` datetime NOT NULL DEFAULT current_timestamp(),
  `lastchanged` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `keeppics` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `scheduledcounts`
--
ALTER TABLE `scheduledcounts`
  ADD UNIQUE KEY `id` (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `scheduledcounts`
--
ALTER TABLE `scheduledcounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
COMMIT;
