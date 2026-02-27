-- phpMyAdmin SQL Dump
-- version 5.1.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Oct 16, 2025 at 01:59 PM
-- Server version: 5.7.24
-- PHP Version: 8.1.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hr_system`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_check_ip_allowed` (IN `p_ip_address` VARCHAR(45), OUT `p_is_allowed` TINYINT(1), OUT `p_range_name` VARCHAR(100), OUT `p_range_type` VARCHAR(20))   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_range VARCHAR(50);
    DECLARE v_name VARCHAR(100);
    DECLARE v_type VARCHAR(20);
    DECLARE v_network VARCHAR(45);
    DECLARE v_prefix INT;
    DECLARE v_ip_int BIGINT UNSIGNED;
    DECLARE v_network_int BIGINT UNSIGNED;
    DECLARE v_mask_int BIGINT UNSIGNED;
    
    DECLARE cur CURSOR FOR 
        SELECT ip_range, range_name, range_type 
        FROM company_ip_ranges 
        WHERE is_active = 1;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SET p_is_allowed = 0;
    SET p_range_name = NULL;
    SET p_range_type = NULL;

    -- แปลง IP address ที่ต้องการเช็คเป็นตัวเลข
    SET v_ip_int = INET_ATON(p_ip_address);
    
    -- ถ้าแปลง IP ไม่ได้ (เช่น IPv6 หรือ format ผิด) ให้ return ทันที
    IF v_ip_int IS NULL THEN
        SET p_is_allowed = 0;
        -- ไม่ต้องทำอะไรต่อ จบทันที
    ELSE
        OPEN cur;
        read_loop: LOOP
            FETCH cur INTO v_range, v_name, v_type;
            IF done THEN
                LEAVE read_loop;
            END IF;

        -- แยก IP range และ prefix (เช่น 192.168.1.0/24)
        IF v_range LIKE '%/%' THEN
            SET v_network = SUBSTRING_INDEX(v_range, '/', 1);
            SET v_prefix = CAST(SUBSTRING_INDEX(v_range, '/', -1) AS UNSIGNED);
            
            -- คำนวณ subnet mask จาก prefix
            -- เช่น /24 = 255.255.255.0 = 4294967040
            SET v_mask_int = (0xFFFFFFFF << (32 - v_prefix)) & 0xFFFFFFFF;
            
            -- แปลง network address เป็นตัวเลข
            SET v_network_int = INET_ATON(v_network);
            
            -- ตรวจสอบว่า IP อยู่ใน subnet หรือไม่
            -- โดยใช้ bitwise AND กับ subnet mask แล้วเปรียบเทียบกับ network address
            IF v_network_int IS NOT NULL AND (v_ip_int & v_mask_int) = (v_network_int & v_mask_int) THEN
                SET p_is_allowed = 1;
                SET p_range_name = v_name;
                SET p_range_type = v_type;
                LEAVE read_loop;
            END IF;
        ELSE
            -- กรณีไม่มี / (Single IP เช่น 192.168.1.100)
            -- ตรวจสอบว่า IP ตรงกันเลยหรือไม่
            IF v_range = p_ip_address THEN
                SET p_is_allowed = 1;
                SET p_range_name = v_name;
                SET p_range_type = v_type;
                LEAVE read_loop;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
    END IF; -- ปิด IF v_ip_int IS NOT NULL
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `access_logs`
--

CREATE TABLE `access_logs` (
  `log_id` int(11) NOT NULL,
  `em_id` int(11) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `user_agent` text,
  `action` varchar(50) NOT NULL COMMENT 'checkin, checkout, ot_request, etc.',
  `success` tinyint(1) DEFAULT '0' COMMENT '1=สำเร็จ, 0=ไม่สำเร็จ',
  `error_message` text COMMENT 'ข้อความ error (ถ้ามี)',
  `location_verified` tinyint(1) DEFAULT '0' COMMENT 'IP อยู่ในบริษัทหรือไม่',
  `matched_range` varchar(50) DEFAULT NULL COMMENT 'ช่วง IP ที่ตรงกัน',
  `request_data` json DEFAULT NULL COMMENT 'ข้อมูล request เพิ่มเติม',
  `response_time` decimal(8,3) DEFAULT NULL COMMENT 'เวลาตอบสนอง (milliseconds)',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `reason` text,
  `additional_data` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ตาราง Log การเข้าถึงระบบ';

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `admin_id` int(11) NOT NULL,
  `admin_name` varchar(150) NOT NULL,
  `admin_user` varchar(100) NOT NULL,
  `admin_pass` varchar(255) NOT NULL,
  `admin_realpass` varchar(100) NOT NULL,
  `admin_permission` tinyint(1) NOT NULL,
  `admin_sort` int(11) NOT NULL,
  `admin_status` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`admin_id`, `admin_name`, `admin_user`, `admin_pass`, `admin_realpass`, `admin_permission`, `admin_sort`, `admin_status`) VALUES
(1, 'Admin ', 'admin', 'e698f2679be5ba5c9c0b0031cb5b057c', '@admin', 1, 0, 1),
(2, 'admin2', 'admin2', 'e698f2679be5ba5c9c0b0031cb5b057c', '@admin', 2, 2, 1),
(3, 'admin1', 'admin1', 'e00cf25ad42683b3df678c61f42c6bda', 'admin1', 1, 1, 1),
(4, 'admin3', 'admin3', '32cacb2f994f6b42183a1300d9a3e8d6', 'admin3', 3, 3, 1);

-- --------------------------------------------------------

--
-- Table structure for table `attendance_logs`
--

CREATE TABLE `attendance_logs` (
  `log_id` int(11) NOT NULL,
  `em_id` int(11) NOT NULL,
  `work_date` date NOT NULL,
  `checkin_time` datetime DEFAULT NULL,
  `checkout_time` datetime DEFAULT NULL,
  `checkin_location` varchar(255) DEFAULT NULL,
  `ip_address_checkin` varchar(45) DEFAULT NULL,
  `checkout_location` varchar(255) DEFAULT NULL,
  `ip_address_checkout` varchar(45) DEFAULT NULL,
  `work_hours` decimal(5,2) DEFAULT NULL COMMENT 'ชั่วโมงทำงานจริง (ไม่รวมเวลาพัก)',
  `break_hours` decimal(5,2) DEFAULT '1.00' COMMENT 'ชั่วโมงพัก (ค่าเริ่มต้น 1 ชั่วโมง)',
  `total_hours` decimal(5,2) DEFAULT NULL COMMENT 'ชั่วโมงทำงานรวม (รวมเวลาพัก)',
  `status` enum('on-time','is_late','leave','absent') DEFAULT 'on-time',
  `note` text,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `location_verified_checkin` tinyint(1) DEFAULT '0' COMMENT 'ตรวจสอบ IP เข้าบริษัทแล้ว',
  `location_verified_checkout` tinyint(1) DEFAULT '0' COMMENT 'ตรวจสอบ IP ออกบริษัทแล้ว'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `attendance_logs`
--

INSERT INTO `attendance_logs` (`log_id`, `em_id`, `work_date`, `checkin_time`, `checkout_time`, `checkin_location`, `ip_address_checkin`, `checkout_location`, `ip_address_checkout`, `work_hours`, `break_hours`, `total_hours`, `status`, `note`, `created_at`, `updated_at`, `location_verified_checkin`, `location_verified_checkout`) VALUES
(152, 1, '2025-09-24', '2025-09-24 10:59:18', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 149 นาที', '2025-09-24 10:59:18', '2025-09-24 10:59:18', 0, 0),
(153, 2, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(154, 3, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(155, 4, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(156, 5, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(157, 6, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(158, 7, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(159, 8, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(160, 9, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(161, 10, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(162, 11, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(163, 12, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(164, 13, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(165, 14, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(166, 15, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(167, 16, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(168, 17, '2025-09-24', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-24 12:08:03', '2025-09-24 12:08:03', 0, 0),
(169, 1, '2025-09-25', '2025-09-25 11:10:24', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 160 นาที', '2025-09-25 11:10:24', '2025-09-25 11:10:24', 0, 0),
(170, 12, '2025-09-25', '2025-09-25 11:12:05', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 162 นาที', '2025-09-25 11:12:05', '2025-09-25 11:12:05', 0, 0),
(171, 3, '2025-09-25', '2025-09-25 11:17:31', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 168 นาที', '2025-09-25 11:17:31', '2025-09-25 11:17:31', 0, 0),
(172, 2, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(173, 4, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(174, 5, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(175, 6, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(176, 7, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(177, 8, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(178, 9, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(179, 10, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(180, 11, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(181, 13, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(182, 14, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(183, 15, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(184, 16, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(185, 17, '2025-09-25', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-25 13:09:47', '2025-09-25 13:09:47', 0, 0),
(186, 1, '2025-09-26', '2025-09-26 09:14:13', '2025-09-26 09:15:00', 'ระบุตำแหน่งด้วยตนเอง', NULL, 'Auto Checkout System', NULL, NULL, '1.00', NULL, 'on-time', 'มาสาย 44 นาที เช็คเอาท์อัตโนมัติ', '2025-09-26 09:14:13', '2025-09-26 09:15:08', 0, 0),
(187, 3, '2025-09-26', '2025-09-26 11:55:00', '2025-09-26 11:55:06', 'ระบุตำแหน่งด้วยตนเอง', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, '1.00', NULL, 'on-time', 'มาสาย 205 นาที ออกก่อนเวลา มาสาย 205 นาที', '2025-09-26 11:55:00', '2025-09-26 11:55:06', 0, 0),
(188, 2, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(189, 4, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(190, 5, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(191, 6, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(192, 7, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(193, 8, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(194, 9, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(195, 10, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(196, 11, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(197, 12, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(198, 13, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(199, 14, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(200, 15, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(201, 16, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(202, 17, '2025-09-26', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-09-26 16:04:57', '2025-09-26 16:04:57', 0, 0),
(203, 1, '2025-10-02', '2025-10-02 11:23:18', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 173 นาที', '2025-10-02 11:23:18', '2025-10-02 11:23:18', 0, 0),
(204, 2, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(205, 3, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(206, 4, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(207, 5, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(208, 6, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(209, 7, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(210, 8, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(211, 9, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(212, 10, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(213, 11, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(214, 12, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(215, 13, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(216, 14, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(217, 15, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(218, 16, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(219, 17, '2025-10-02', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-02 12:00:49', '2025-10-02 12:00:49', 0, 0),
(220, 1, '2025-10-03', '2025-10-03 10:34:55', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 125 นาที', '2025-10-03 10:34:55', '2025-10-03 10:34:55', 0, 0),
(221, 3, '2025-10-03', '2025-10-03 10:36:32', '2025-10-03 10:37:36', 'ระบุตำแหน่งด้วยตนเอง', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, '0.02', '0.00', '0.02', 'on-time', 'มาสาย 127 นาที ออกก่อนเวลา มาสาย 127 นาที', '2025-10-03 10:36:32', '2025-10-03 10:37:36', 0, 0),
(222, 2, '2025-10-03', '2025-10-03 11:46:21', NULL, 'ระบุตำแหน่งด้วยตนเอง', NULL, NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 196 นาที', '2025-10-03 11:46:21', '2025-10-03 11:46:21', 0, 0),
(223, 4, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(224, 5, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(225, 6, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(226, 7, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(227, 8, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(228, 9, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(229, 10, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(230, 11, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(231, 12, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(232, 13, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(233, 14, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(234, 15, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(235, 16, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(236, 17, '2025-10-03', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-03 12:12:03', '2025-10-03 12:12:03', 0, 0),
(253, 1, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(254, 2, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(255, 3, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(256, 4, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(257, 5, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(258, 6, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(259, 7, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(260, 8, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(261, 9, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(262, 10, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(263, 11, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(264, 12, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(265, 13, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(266, 14, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(267, 15, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:10', '2025-10-06 11:28:10', 0, 0),
(268, 16, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:11', '2025-10-06 11:28:11', 0, 0),
(269, 17, '2025-01-03', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:28:11', '2025-10-06 11:28:11', 0, 0),
(270, 1, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(271, 2, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(272, 4, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(273, 5, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(274, 6, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(275, 7, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(276, 8, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(277, 9, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(278, 10, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:47', '2025-10-06 11:31:47', 0, 0),
(279, 11, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(280, 12, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(281, 13, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(282, 14, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(283, 15, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(284, 16, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(285, 17, '2025-10-05', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', '', '2025-10-06 11:31:48', '2025-10-06 11:31:48', 0, 0),
(286, 1, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(287, 2, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(288, 3, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(289, 4, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(290, 5, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(291, 6, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(292, 7, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(293, 8, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(294, 9, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(295, 10, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(296, 11, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(297, 12, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(298, 13, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(299, 14, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(300, 15, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(301, 16, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(302, 17, '2025-10-06', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-06 12:41:03', '2025-10-06 12:41:03', 0, 0),
(327, 3, '2025-10-07', '2025-10-07 12:44:24', '2025-10-07 12:44:28', 'สำนักงาน', '127.0.0.1', 'สำนักงาน', '127.0.0.1', '0.00', '0.00', '0.00', 'on-time', 'มาสาย 254 นาที ออกก่อนเวลา มาสาย 254 นาที', '2025-10-07 12:44:24', '2025-10-07 12:44:28', 0, 0),
(328, 1, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(329, 2, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(330, 4, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(331, 5, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(332, 6, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(333, 7, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(334, 8, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(335, 9, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(336, 10, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(337, 11, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(338, 12, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(339, 13, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(340, 14, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(341, 15, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(342, 16, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(343, 17, '2025-10-07', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-08 08:49:57', '2025-10-08 08:49:57', 0, 0),
(344, 1, '2025-10-08', '2025-10-08 08:30:00', '2025-10-08 17:30:00', 'สำนักงาน', '127.0.0.1', 'สำนักงาน', '127.0.0.1', '3.20', '1.00', '4.20', 'on-time', 'มาสาย 94 นาที ออกก่อนเวลา มาสาย 94 นาที', '2025-10-08 10:03:44', '2025-10-08 14:19:10', 0, 0),
(345, 2, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(346, 3, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(347, 4, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(348, 5, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(349, 6, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(350, 7, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(351, 8, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(352, 9, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(353, 10, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(354, 11, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(355, 12, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(356, 13, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(357, 14, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(358, 15, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(359, 16, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(360, 17, '2025-10-08', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2025-10-09 09:46:04', '2025-10-09 09:46:04', 0, 0),
(362, 12, '2025-10-14', '2025-10-14 08:18:02', '2025-10-14 12:46:21', 'สำนักงาน', '127.0.0.1', NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 108 นาที', '2025-10-14 10:18:02', '2025-10-14 10:53:51', 0, 0),
(363, 1, '2025-10-14', '2025-10-14 08:23:37', '2025-10-14 00:00:00', 'สำนักงาน', '127.0.0.1', 'Auto Checkout System', NULL, NULL, '1.00', NULL, 'on-time', 'มาสาย 144 นาที เช็คเอาท์อัตโนมัติ', '2025-10-14 10:53:37', '2025-10-14 14:57:29', 0, 0),
(364, 2, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(365, 3, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(366, 4, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(367, 5, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(368, 6, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(369, 7, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(370, 8, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(371, 9, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(372, 10, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(373, 11, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(374, 13, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(375, 14, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(376, 15, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(377, 16, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(378, 17, '2025-10-14', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-14 14:57:29', '2025-10-14 14:57:29', 0, 0),
(379, 2, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(380, 3, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(381, 4, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(382, 5, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(383, 6, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(384, 7, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(385, 8, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(386, 9, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(387, 10, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(388, 11, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(389, 13, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(390, 14, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(391, 15, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(392, 16, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(393, 17, '2025-10-14', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-14 18:02:32', '2025-10-14 18:02:32', 0, 0),
(396, 2, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(397, 3, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(398, 4, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(399, 5, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(400, 6, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(401, 7, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(402, 8, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(403, 9, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(404, 10, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(405, 11, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(406, 13, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(407, 14, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(408, 15, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(409, 16, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(410, 17, '2025-10-15', NULL, NULL, 'Auto Absent System', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาเข้างานภายในเวลาที่กำหนด', '2025-10-15 12:00:08', '2025-10-15 12:00:08', 0, 0),
(420, 1, '2025-10-15', '2025-10-15 08:17:31', '2025-10-15 17:31:00', 'สำนักงาน', '127.0.0.1', 'Auto Checkout System (Manual Test)', NULL, '8.22', '1.00', '9.22', 'on-time', 'มาสาย 348 นาที เช็คเอาท์อัตโนมัติ (ทดสอบ)', '2025-10-15 14:17:31', '2025-10-15 14:20:12', 0, 0),
(421, 12, '2025-10-15', '2025-10-15 14:25:12', NULL, 'สำนักงาน', '127.0.0.1', NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 355 นาที', '2025-10-15 14:25:12', '2025-10-15 14:25:12', 0, 0),
(422, 2, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(423, 3, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(424, 4, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(425, 5, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(426, 6, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(427, 7, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(428, 8, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(429, 9, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(430, 10, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(431, 11, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(432, 13, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(433, 14, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(434, 15, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(435, 16, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(436, 17, '2025-10-15', NULL, NULL, 'End of Day Check', NULL, NULL, NULL, NULL, '1.00', NULL, 'absent', 'ขาดงาน - ไม่ได้ลงเวลาทั้งวัน (สรุปท้ายวัน)', '2025-10-15 17:07:45', '2025-10-15 17:07:45', 0, 0),
(437, 1, '2025-10-16', '2025-10-16 09:35:21', NULL, 'สำนักงาน', '127.0.0.1', NULL, NULL, NULL, '1.00', NULL, 'is_late', 'มาสาย 65 นาที', '2025-10-16 09:35:21', '2025-10-16 09:35:21', 0, 0),
(438, 1, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(439, 2, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(440, 3, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(441, 4, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(442, 5, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(443, 6, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(444, 7, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(445, 8, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(446, 9, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(447, 10, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(448, 11, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(449, 12, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(450, 13, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(451, 14, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(452, 15, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(453, 16, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0),
(454, 17, '2026-01-14', NULL, NULL, NULL, NULL, NULL, NULL, '0.00', '0.00', '0.00', 'absent', 'Auto generated - Absent', '2026-01-15 10:23:44', '2026-01-15 10:23:44', 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `attendance_settings`
--

CREATE TABLE `attendance_settings` (
  `id` int(11) NOT NULL,
  `setting_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ชื่อการตั้งค่า',
  `setting_value` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ค่าการตั้งค่า',
  `setting_type` enum('time','number','text','boolean') COLLATE utf8mb4_unicode_ci DEFAULT 'text' COMMENT 'ประเภทของการตั้งค่า',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT 'คำอธิบาย',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='ตารางตั้งค่าระบบลงเวลา';

--
-- Dumping data for table `attendance_settings`
--

INSERT INTO `attendance_settings` (`id`, `setting_name`, `setting_value`, `setting_type`, `description`, `created_at`, `updated_at`) VALUES
(1, 'standard_work_start', '08:30:00', 'time', 'เวลาเริ่มงานมาตรฐาน', '2025-07-16 13:13:08', '2025-07-29 15:36:00'),
(2, 'standard_work_end', '17:30:00', 'time', 'เวลาเลิกงานมาตรฐาน', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(3, 'break_start', '12:00:00', 'time', 'เวลาเริ่มพักกลางวัน', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(4, 'break_end', '13:00:00', 'time', 'เวลาจบพักกลางวัน', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(5, 'late_threshold', '15', 'number', 'จำนวนนาทีที่ถือว่ามาสาย', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(6, 'overtime_threshold', '8', 'number', 'จำนวนชั่วโมงงานปกติก่อนคิดเป็น OT', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(7, 'working_days_per_week', '5', 'number', 'จำนวนวันทำงานต่อสัปดาห์', '2025-07-16 13:13:08', '2025-07-16 13:13:08'),
(8, 'auto_checkout_enabled', '1', 'boolean', 'เปิดใช้งานการเช็คเอาท์อัตโนมัติ', '2025-07-16 13:13:08', '2025-10-14 11:30:39'),
(9, 'auto_checkout_time', '00:00', 'time', 'เวลาเช็คเอาท์อัตโนมัติ', '2025-07-16 13:13:08', '2025-10-14 11:30:39'),
(10, 'last_auto_checkout_date', '2025-10-15', 'text', 'วันที่ทำ auto checkout ล่าสุด', '2025-09-23 14:11:13', '2025-10-15 12:08:08'),
(11, 'auto_absent_enabled', '1', 'boolean', 'เปิดใช้งานการทำเครื่องหมายขาดงานอัตโนมัติ', '2025-09-24 10:22:02', '2025-09-24 10:22:02'),
(12, 'auto_absent_time', '12:00:00', 'time', 'เวลาทำเครื่องหมายขาดงานอัตโนมัติ', '2025-09-24 10:22:02', '2025-09-24 10:22:02'),
(13, 'last_auto_absent_date', '2025-10-15', 'text', 'วันที่ทำเครื่องหมายขาดงานล่าสุด', '2025-09-24 10:22:02', '2025-10-15 12:00:08');

-- --------------------------------------------------------

--
-- Table structure for table `company_ip_ranges`
--

CREATE TABLE `company_ip_ranges` (
  `range_id` int(11) NOT NULL,
  `range_name` varchar(100) NOT NULL COMMENT 'ชื่อช่วง IP',
  `ip_range` varchar(50) NOT NULL COMMENT 'ช่วง IP เช่น 192.168.1.0/24',
  `range_type` enum('internal','vpn','public','wifi') DEFAULT 'internal' COMMENT 'ประเภทเครือข่าย',
  `location_name` varchar(255) DEFAULT NULL COMMENT 'ชื่อสถานที่',
  `description` text COMMENT 'คำอธิบาย',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ตารางเก็บช่วง IP ที่อนุญาตให้ Check-in';

--
-- Dumping data for table `company_ip_ranges`
--

INSERT INTO `company_ip_ranges` (`range_id`, `range_name`, `ip_range`, `range_type`, `location_name`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(23, 'Office WiFi Network', '192.168.1.110', 'vpn', 'WiFi สำนักงาน', 'เครือข่าย WiFi สำหรับพนักงาน', 0, '2025-10-07 09:58:06', '2025-10-15 11:02:19'),
(24, 'VPN Network', '10.8.0.0/24', 'vpn', 'VPN จากบ้าน', 'เครือข่าย VPN สำหรับ Work from Home', 0, '2025-10-07 09:58:06', '2025-10-15 10:57:41'),
(25, 'Branch Office 1', '192.168.20.0/24', 'internal', 'สาขา 1 - ซอยอโศก', 'เครือข่าย LAN สาขาอโศก', 0, '2025-10-07 09:58:06', '2025-10-15 11:02:22'),
(26, 'Branch Office 2', '192.168.30.0/24', 'internal', 'สาขา 2 - สีลม', 'เครือข่าย LAN สาขาสีลม', 0, '2025-10-07 09:58:06', '2025-10-15 11:02:24'),
(27, 'Public IP Main', '203.154.123.45/32', 'public', 'IP Public หลัก', 'IP Public สำนักงานใหญ่', 0, '2025-10-07 09:58:06', '2025-10-15 11:02:26'),
(28, '1111', '192.168.1.100', 'internal', 'WiFi สำนักงาน', '1111', 0, '2025-10-08 09:12:40', '2025-10-15 11:02:28'),
(30, 'Office WiFi Network', '127.0.0.1/32', 'internal', 'WiFi สำนักงาน', NULL, 1, '2025-10-15 10:25:05', '2025-10-15 11:03:17');

-- --------------------------------------------------------

--
-- Table structure for table `cross_year_leave_deductions`
--

CREATE TABLE `cross_year_leave_deductions` (
  `id` int(11) NOT NULL,
  `leave_request_id` int(11) NOT NULL,
  `employee_id` int(11) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `year` int(4) NOT NULL,
  `days_deducted` decimal(5,2) NOT NULL DEFAULT '0.00',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `cross_year_leave_deductions`
--

INSERT INTO `cross_year_leave_deductions` (`id`, `leave_request_id`, `employee_id`, `leave_type_id`, `year`, `days_deducted`, `start_date`, `end_date`, `created_at`) VALUES
(1, 37, 2, 3, 2025, '1.00', '2025-12-30', '2026-01-06', '2025-10-16 10:20:53'),
(2, 37, 2, 3, 2026, '4.00', '2025-12-30', '2026-01-06', '2025-10-16 10:20:53');

-- --------------------------------------------------------

--
-- Table structure for table `departments`
--

CREATE TABLE `departments` (
  `dept_id` int(11) NOT NULL,
  `dept_name` varchar(255) NOT NULL,
  `dept_sort` int(11) NOT NULL DEFAULT '0',
  `dept_status` tinyint(1) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `departments`
--

INSERT INTO `departments` (`dept_id`, `dept_name`, `dept_sort`, `dept_status`) VALUES
(1, '. แผนกทรัพยากรบุคคล (HR Department)', 5, 1),
(4, '. แผนกบัญชีและการเงิน (Finance & Accounting Department)', 6, 1),
(5, 'แผนกไอที (IT Department)', 7, 1);

-- --------------------------------------------------------

--
-- Table structure for table `employees`
--

CREATE TABLE `employees` (
  `em_id` int(11) NOT NULL,
  `first_name` varchar(100) DEFAULT NULL,
  `age` int(2) NOT NULL,
  `birth_date` date DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `position` varchar(100) DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `status` int(11) NOT NULL,
  `employee_sort` int(11) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `registered_address` text NOT NULL,
  `start_date` varchar(50) NOT NULL,
  `current_address` text NOT NULL,
  `employee_code` varchar(50) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `profile_image` varchar(25) DEFAULT NULL,
  `id_card_image` varchar(25) DEFAULT NULL,
  `certificate_image` varchar(25) DEFAULT NULL,
  `bookbank_image` varchar(25) DEFAULT NULL,
  `prefix` varchar(20) NOT NULL,
  `gender` varchar(20) NOT NULL,
  `id_card_number` varchar(13) NOT NULL,
  `emergency_phone` int(11) NOT NULL,
  `relation` varchar(50) NOT NULL,
  `education_institute` varchar(50) NOT NULL,
  `education_level` varchar(50) NOT NULL,
  `education_year` int(11) NOT NULL,
  `education_major` varchar(50) NOT NULL,
  `gpa` int(11) NOT NULL,
  `skills` text NOT NULL,
  `employment_first_name` varchar(100) NOT NULL,
  `employment_last_name` varchar(100) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `em_realpass` varchar(255) NOT NULL,
  `role` enum('admin','employee','hr') DEFAULT 'employee',
  `is_active` tinyint(1) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `employees`
--

INSERT INTO `employees` (`em_id`, `first_name`, `age`, `birth_date`, `email`, `position`, `department`, `created_at`, `status`, `employee_sort`, `phone`, `registered_address`, `start_date`, `current_address`, `employee_code`, `last_name`, `profile_image`, `id_card_image`, `certificate_image`, `bookbank_image`, `prefix`, `gender`, `id_card_number`, `emergency_phone`, `relation`, `education_institute`, `education_level`, `education_year`, `education_major`, `gpa`, `skills`, `employment_first_name`, `employment_last_name`, `username`, `password`, `em_realpass`, `role`, `is_active`) VALUES
(1, 'John', 35, '2533-01-15', 'john.doe@company.com', 'Manager', '1', '2025-07-14 13:51:12', 1, 1, '0947210689', '123 Main St', '17-07-2568', '456 Elm St', 'EMP-1001', 'Doe', '20250715105112_Lktdj.jpg', '20250715105112_EfGNg.jpg', '20250715105112_REUgZ.jpg', '20250715105112_FSDgo.jpg', 'นาย', 'ชาย', '2147483647123', 1111111111, 'Father', 'Chiang Mai', 'ปริญญาโท', 2021, 'Computer Science', 4, 'C++, Java', 'John', 'Doe', 'EMP-1001', '$2y$10$smYA.t.zyK7xIbpk.4Ly5eAjAw3OMWQtMcR3vjvq4OMVgYXDBD0Wq', '1234567', 'hr', 1),
(2, 'สมชาย', 28, '2540-03-10', 'somchai.jaidi@company.com', 'นักพัฒนาระบบ', '1', '2025-09-22 20:00:00', 1, 2, '0812345678', '123 ถนนรัชดาภิเษก กรุงเทพฯ 10400', '15-01-2568', '123 ถนนรัชดาภิเษก กรุงเทพฯ 10400', 'EMP-1002', 'ใจดี', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นาย', 'ชาย', '1234567890123', 898765432, 'พ่อ', 'มหาวิทยาลัยเกษตรศาสตร์', 'ปริญญาตรี', 2020, 'วิทยาการคอมพิวเตอร์', 3, 'Python, JavaScript, PHP', 'สมชาย', 'ใจดี', 'EMP-1002', '$2y$10$f6ijfMHORNDgA/pdd6e1xuq8zanbz/rpp6i22roJk1BgJpmZTJ5VW', '', 'employee', 1),
(3, 'วันดี', 26, '3085-05-22', 'wandee.rakdee@company.com', 'นักบัญชี', '1', '2025-09-22 20:05:00', 1, 3, '0823456789', '456 ถนนสุขุมวิท กรุงเทพฯ 10110', '01-02-3111', '456 ถนนสุขุมวิท กรุงเทพฯ 10110', 'EMP-1003', 'รักดี', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นางสาว', 'หญิง', '1234567890124', 887654321, 'แม่', 'จุฬาลงกรณ์มหาวิทยาลัย', 'ปริญญาตรี', 2019, 'บัญชีบัณฑิต', 4, 'Excel, SAP, QuickBooks', 'วันดี', 'รักดี', 'EMP-1003', '$2y$10$T9CwhOk0qAtGsoov.Y1AyuRpXRLqqAHqlIlTFxi/f8a4P7wFAATi2', '123456', 'employee', 1),
(4, 'มานพ', 32, '2536-08-14', 'manop.sukai@company.com', 'ผู้จัดการฝ่ายขาย', '3', '2025-09-22 20:10:00', 1, 4, '0834567890', '789 ถนนพหลโยธิน กรุงเทพฯ 10220', '20-01-2568', '789 ถนนพหลโยธิน กรุงเทพฯ 10220', 'EMP-1004', 'สุขใส', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นาย', 'ชาย', '1234567890125', 876543210, 'พี่ชาย', 'มหาวิทยาลัยธรรมศาสตร์', 'ปริญญาโท', 2018, 'บริหารธุรกิจ', 4, 'การขาย, การตลาด, การเจรจา', 'มานพ', 'สุขใส', 'EMP-1004', '$2y$10$F1dpBI3CyyNRg/U/92jlU.mHZckbXjBr7SQ/F0GGc90swkNGdo1ym', '', 'employee', 1),
(5, 'สุมาลี', 24, '2544-11-08', 'sumalee.mankong@company.com', 'เลขานุการ', '4', '2025-09-22 20:15:00', 1, 5, '0845678901', '321 ถนนเพชรบุรี กรุงเทพฯ 10400', '01-03-2568', '321 ถนนเพชรบุรี กรุงเทพฯ 10400', 'EMP-1005', 'มั่นคง', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นางสาว', 'หญิง', '1234567890126', 865432109, 'น้องสาว', 'มหาวิทยาลัยรามคำแหง', 'ปริญญาตรี', 2021, 'นิเทศศาสตร์', 3, 'MS Office, การประชาสัมพันธ์', 'สุมาลี', 'มั่นคง', 'EMP-1005', '$2y$10$ym1/eiuMGpBBH4QGQagcbeK1GHqkUPv90L2dkluOhMUgT6QajnveS', '', 'employee', 1),
(6, 'ประยุทธ', 40, '1985-02-28', 'prayuth.kaonana@company.com', 'หัวหน้าแผนก IT', '1', '2025-09-22 20:20:00', 1, 6, '0856789012', '654 ถนนวิภาวดีรังสิต กรุงเทพฯ 10900', '2024-12-01', '654 ถนนวิภาวดีรังสิต กรุงเทพฯ 10900', 'EMP-1006', 'ก้าวหน้า', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นาย', 'ชาย', '1234567890127', 854321098, 'พ่อ', 'สถาบันเทคโนโลยีพระจอมเกล้า', 'ปริญญาโท', 2017, 'วิศวกรรมคอมพิวเตอร์', 4, 'Network Admin, Database, Security', 'ประยุทธ', 'ก้าวหน้า', 'EMP-1006', '$2y$10$defaultpasswordhash', '', 'hr', 1),
(7, 'อนุสรา', 29, '1996-07-12', 'anusara.charoemsuk@company.com', 'นักทรัพยากรบุคคล', '5', '2025-09-22 20:25:00', 1, 7, '0867890123', '987 ถนนงามวงศ์วาน กรุงเทพฯ 10510', '2025-01-10', '987 ถนนงามวงศ์วาน กรุงเทพฯ 10510', 'EMP-1007', 'เจริญสุข', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นางสาว', 'หญิง', '1234567890128', 843210987, 'แม่', 'มหาวิทยาลัยศรีนครินทรวิโรฒ', 'ปริญญาตรี', 2020, 'จิตวิทยาอุตสาหกรรม', 3, 'HR Management, Recruitment', 'อนุสรา', 'เจริญสุข', 'EMP-1007', '$2y$10$defaultpasswordhash', '', 'hr', 1),
(8, 'กิตติ', 27, '1998-04-06', 'kitti.rueangyot@company.com', 'นักการตลาด', '3', '2025-09-22 20:30:00', 1, 8, '0878901234', '159 ถนนลาดพร้าว กรุงเทพฯ 10230', '2025-02-15', '159 ถนนลาดพร้าว กรุงเทพฯ 10230', 'EMP-1008', 'เรืองยศ', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นาย', 'ชาย', '1234567890129', 832109876, 'ลุง', 'มหาวิทยาลัยเชียงใหม่', 'ปริญญาตรี', 2019, 'การตลาด', 3, 'Digital Marketing, SEO, Content', 'กิตติ', 'เรืองยศ', 'EMP-1008', '$2y$10$defaultpasswordhash', '', 'employee', 1),
(9, 'ปิยะดา', 23, '2002-01-18', 'piyada.sangsarn@company.com', 'นักออกแบบ', '4', '2025-09-22 20:35:00', 1, 9, '0889012345', '753 ถนนบางนา กรุงเทพฯ 10260', '2025-03-10', '753 ถนนบางนา กรุงเทพฯ 10260', 'EMP-1009', 'สร้างสรรค์', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นางสาว', 'หญิง', '1234567890130', 821098765, 'พี่สาว', 'มหาวิทยาลัยศิลปกรรมศาสตร์', 'ปริญญาตรี', 2021, 'การออกแบบกราฟิก', 4, 'Photoshop, Illustrator, InDesign', 'ปิยะดา', 'สร้างสรรค์', 'EMP-1009', '$2y$10$defaultpasswordhash', '', 'employee', 1),
(10, 'วีระ', 25, '2000-09-03', 'veera.pattana@company.com', 'ช่างเทคนิค', '1', '2025-09-22 20:40:00', 1, 10, '0890123456', '852 ถนนสาทร กรุงเทพฯ 10120', '2025-01-25', '852 ถนนสาทร กรุงเทพฯ 10120', 'EMP-1010', 'พัฒนา', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นาย', 'ชาย', '1234567890131', 810987654, 'น้องชาย', 'วิทยาลัยเทคนิคกรุงเทพ', 'ปวส.', 2022, 'เทคนิคคอมพิวเตอร์', 3, 'Hardware Repair, Network Setup', 'วีระ', 'พัฒนา', 'EMP-1010', '$2y$10$defaultpasswordhash', '', 'employee', 1),
(11, 'นิตยา', 30, '1995-12-25', 'nitaya.somboon@company.com', 'นักบริหารทั่วไป', '2', '2025-09-22 20:45:00', 1, 11, '0801234567', '741 ถนนอโศก กรุงเทพฯ 10110', '2025-02-20', '741 ถนนอโศก กรุงเทพฯ 10110', 'EMP-1011', 'สมบูรณ์', 'default_profile.jpg', 'default_id.jpg', 'default_cert.jpg', 'default_bank.jpg', 'นางสาว', 'หญิง', '1234567890132', 809876543, 'ป้า', 'มหาวิทยาลัยกรุงเทพ', 'ปริญญาตรี', 2020, 'การจัดการทั่วไป', 3, 'การบริหาร, การประสานงาน', 'นิตยา', 'สมบูรณ์', 'EMP-1011', '$2y$10$defaultpasswordhash', '', 'employee', 1),
(12, 'numnim', 25, '2000-09-23', 'numnim.akornchatsarn@company.com', 'เจ้าหน้าที่ธุรการ', '4', '2025-07-14 20:51:12', 1, 12, '0947210689', '123 ถนนเทพารักษ์ กรุงเทพฯ 10260', '2025-07-17', '123 ถนนเทพารักษ์ กรุงเทพฯ 10260', 'EMP-1012', 'อัครคชสาร', '20250923102821_hznxk.jpg', '20250919095244_YpIPw.jpg', '20250715105112_REUgZ.jpg', '20250715105112_FSDgo.jpg', 'นางสาว', 'หญิง', '2147483647123', 1111111111, 'แม่', 'เชียงใหม่', 'ปวช.', 2021, 'คอมพิวเตอร์', 4, 'การใช้คอมพิวเตอร์ขั้นพื้นฐาน', 'numnim', 'อัครคชสาร', 'EMP-1012', '$2y$10$JOBa5i284mK5RO7a3hwgbe9KcmQwvBzKSRx3KaaSoiLxPjARvam0q', '', 'employee', 1),
(13, 'ปรียาภรณ์', 22, '2003-09-30', 'priyaporn.akornchatsarn@company.com', 'พนักงานต้อนรับ', '5', '2025-07-14 20:53:56', 1, 13, '0947210689', '456 ถนนพระราม 4 กรุงเทพฯ 10110', '2025-07-17', '456 ถนนพระราม 4 กรุงเทพฯ 10110', 'EMP-1013', 'อัครคชสาร', '20250919095512_wNAsh.jpg', '20250919095512_ZfhGE.jpg', '20250715105356_4k6id.jpg', '20250715105356_mDmxL.jpg', 'นางสาว', 'หญิง', '2147483647123', 123455666, 'น้องสาว', 'เชียงใหม่', 'ปวส.', 2021, 'คอมพิวเตอร์', 4, 'การบริการลูกค้า', 'ปรียาภรณ์', 'อัครคชสาร', 'EMP-1013', '$2y$10$HSbvL16lRZ79lOSWVYjpd.O33YiF2lnBWo138zBxloMH8D/.57JUC', '', 'employee', 1),
(14, 'สมปอง', 35, '1990-09-19', 'sompong.jaidee@company.com', 'พนักงานบริการ', '5', '2025-07-14 21:06:48', 1, 14, '0910791870', '789 ถนนลาดพร้าว กรุงเทพฯ 10230', '2025-07-11', '789 ถนนลาดพร้าว กรุงเทพฯ 10230', 'EMP-1014', 'ใจดี', '20250923102805_wfimj.jpg', '20250919093125_x8A4c.jpg', '20250715110649_hYEwp.jpg', '20250715110649_j0hxQ.png', 'นาย', 'ชาย', '2147483647123', 947210689, 'พ่อ', 'เชียงใหม่', 'ปวส.', 2021, 'คอมพิวเตอร์', 2, 'การบริการลูกค้า', 'สมปอง', 'ใจดี', 'EMP-1014', '$2y$10$umExZTNDFy/WVm907qotW.8Sn4egr9r/Ypd/P12tHxfPwfZDKklwW', '', 'employee', 1),
(15, 'มาร์ค', 24, '2001-09-10', 'mark.wanjan@company.com', 'นักพัฒนาเว็บไซต์', '1', '2025-07-15 00:10:42', 1, 15, '0947210689', '852 ถนนพระราม 2 กรุงเทพฯ 10150', '2025-07-11', '852 ถนนพระราม 2 กรุงเทพฯ 10150', 'EMP-1015', 'วันจัน', '20250715141041_rdBH.png', '20250715141041_P8Vn6.jpg', '20250715141042_19adq.jpg', '20250715141042_gei7m.jpg', 'นาง', 'หญิง', '2147483647123', 910791870, 'แม่', 'เชียงใหม่', 'ปริญญาตรี', 2021, 'คอมพิวเตอร์', 2, 'HTML, CSS, JavaScript', 'มาร์ค', 'วันจัน', 'EMP-1015', '$2y$10$Cq32hr0Qga8IHGupBzZA9OStA3/LtpxgcFAKuVKAkXevv0j1Rb/xm', '', 'employee', 1),
(16, 'นุ่มนิ่ม', 26, '1999-07-11', 'numnimm.wanjan@company.com', 'เจ้าหน้าที่บุคคล', '5', '2025-07-15 00:15:30', 1, 16, '0947210689', '963 ถนนงามวงศ์วาน กรุงเทพฯ 10510', '2025-07-11', '963 ถนนงามวงศ์วาน กรุงเทพฯ 10510', 'EMP-1016', 'วันจัน', '20250715141530_ayORR.jpg', '20250715141530_Noall.png', '20250715141530_BJJj9.jpg', '20250715141530_BsRkQ.jpg', 'นาง', 'หญิง', '1509966278757', 2147483647, 'แม่', 'เชียงใหม่', 'ปวช.', 2021, 'คอมพิวเตอร์', 2, 'การบริหารงานบุคคล', 'นุ่มนิ่ม', 'วันจัน', 'EMP-1016', '$2y$10$CavnLAr0FTfled37LqxvruJtHCLcwNofKvd/2kbI452.60DbWepPO', '', 'employee', 1),
(17, 'เอ๋ว', 27, '1998-09-18', 'eww.www@company.com', 'นักวิเคราะห์ข้อมูล', '1', '2025-09-17 21:30:45', 1, 17, '0456734567', '741 ถนนสุขุมวิท กรุงเทพฯ 10110', '2025-09-18', '741 ถนนสุขุมวิท กรุงเทพฯ 10110', 'EMP-1017', 'ว็บ', '20250918113045_O8hPg.jpg', '20250918113045_LMNVB.webp', NULL, NULL, 'นาย', 'ชาย', '2147483647123', 2147483647, 'พ่อ', 'เชียงใหม่', 'ปวช.', 2021, 'วิทยาการคอมพิวเตอร์', 3, 'Data Analysis, SQL', 'เอ๋ว', 'ว็บ', 'EMP-1017', '$2y$10$R6rfbhoc1Fn7i6pg6HaZbeWysQfppN7BvEa8QjgjuAjy7E3vWAGtC', '', 'employee', 1);

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays` (
  `id` int(11) NOT NULL,
  `holiday_name` varchar(255) NOT NULL,
  `holiday_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `holiday_type` enum('national','religious','company','special') NOT NULL DEFAULT 'company',
  `description` text,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `holidays`
--

INSERT INTO `holidays` (`id`, `holiday_name`, `holiday_date`, `end_date`, `holiday_type`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(143, 'วันมาฆบูชา', '2025-02-24', NULL, 'religious', 'วันหยุดราชการ - วันมาฆบูชา', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(144, 'วันจักรี', '2025-04-06', NULL, 'national', 'วันหยุดราชการ - วันจักรี', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(145, 'วันสงกรานต์', '2025-04-13', '2025-04-15', 'national', 'วันหยุดประจำปี - วันสงกรานต์ (3 วัน)', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(146, 'วันแรงงานแห่งชาติ', '2025-05-01', NULL, 'national', 'วันหยุดราชการ - วันแรงงานแห่งชาติ', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(147, 'วันฉัตรมงคล', '2025-05-04', NULL, 'national', 'วันหยุดราชการ - วันฉัตรมงคล', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(148, 'วันวิสาขบูชา', '2025-05-22', NULL, 'religious', 'วันหยุดราชการ - วันวิสาขบูชา', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(149, 'วันเฉลิมพระชนมพรรษา รัชกาลที่ 10', '2025-07-28', NULL, 'national', 'วันหยุดราชการ - วันเฉลิมพระชนมพรรษา', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(150, 'วันหยุดปิดเทอมกลางปี', '2025-07-01', '2025-07-07', 'company', 'วันหยุดบริษัทช่วงปิดเทอม (7 วัน)', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(151, 'วันแม่แห่งชาติ', '2025-08-12', NULL, 'national', 'วันหยุดราชการ - วันแม่แห่งชาติ', 1, '2025-08-18 11:57:11', '2025-08-18 12:04:01'),
(152, 'วันคล้ายวันสวรรคต รัชกาลที่ 9', '2025-10-13', NULL, 'national', 'วันหยุดราชการ - วันคล้ายวันสวรรคต', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(153, 'วันปิยมหาราช', '2025-10-23', NULL, 'national', 'วันหยุดราชการ - วันปิยมหาราช', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(154, 'วันพ่อแห่งชาติ', '2025-12-05', NULL, 'national', 'วันหยุดราชการ - วันพ่อแห่งชาติ', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(155, 'วันรัฐธรรมนูญ', '2025-12-10', NULL, 'national', 'วันหยุดราชการ - วันรัฐธรรมนูญ', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(156, 'วันส่งท้ายปีเก่า', '2025-12-31', NULL, 'national', 'วันหยุดประจำปี - วันส่งท้ายปีเก่า', 1, '2025-08-18 11:57:11', '2025-08-18 11:57:11'),
(157, 'วันเกิด', '2025-08-18', '2025-08-20', 'religious', '', 1, '2025-08-18 12:04:13', '2025-08-18 13:30:52'),
(158, 'วันขึ้นปีใหม่', '2025-01-01', NULL, 'national', 'วันหยุดประจำปี - วันขึ้นปีใหม่', 1, '2025-10-14 16:16:46', '2025-10-14 16:16:46'),
(159, 'วันขึ้นปีใหม่', '2026-01-01', NULL, 'national', 'วันหยุดประจำปี - วันขึ้นปีใหม่', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(160, 'วันมาฆบูชา', '2026-02-24', NULL, 'religious', 'วันหยุดราชการ - วันมาฆบูชา', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(161, 'วันจักรี', '2026-04-06', NULL, 'national', 'วันหยุดราชการ - วันจักรี', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(162, 'วันสงกรานต์', '2026-04-13', '2026-04-15', 'national', 'วันหยุดประจำปี - วันสงกรานต์ (3 วัน)', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(163, 'วันแรงงานแห่งชาติ', '2026-05-01', NULL, 'national', 'วันหยุดราชการ - วันแรงงานแห่งชาติ', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(164, 'วันฉัตรมงคล', '2026-05-04', NULL, 'national', 'วันหยุดราชการ - วันฉัตรมงคล', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(165, 'วันวิสาขบูชา', '2026-05-22', NULL, 'religious', 'วันหยุดราชการ - วันวิสาขบูชา', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(166, 'วันเฉลิมพระชนมพรรษา รัชกาลที่ 10', '2026-07-28', NULL, 'national', 'วันหยุดราชการ - วันเฉลิมพระชนมพรรษา', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(167, 'วันหยุดปิดเทอมกลางปี', '2026-07-01', '2026-07-07', 'company', 'วันหยุดบริษัทช่วงปิดเทอม (7 วัน)', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(168, 'วันแม่แห่งชาติ', '2026-08-12', NULL, 'national', 'วันหยุดราชการ - วันแม่แห่งชาติ', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(169, 'วันคล้ายวันสวรรคต รัชกาลที่ 9', '2026-10-13', NULL, 'national', 'วันหยุดราชการ - วันคล้ายวันสวรรคต', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(170, 'วันปิยมหาราช', '2026-10-23', NULL, 'national', 'วันหยุดราชการ - วันปิยมหาราช', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(171, 'วันพ่อแห่งชาติ', '2026-12-05', NULL, 'national', 'วันหยุดราชการ - วันพ่อแห่งชาติ', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(172, 'วันรัฐธรรมนูญ', '2026-12-10', NULL, 'national', 'วันหยุดราชการ - วันรัฐธรรมนูญ', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05'),
(173, 'วันส่งท้ายปีเก่า', '2026-12-31', NULL, 'national', 'วันหยุดประจำปี - วันส่งท้ายปีเก่า', 1, '2025-10-14 16:23:05', '2025-10-14 16:23:05');

-- --------------------------------------------------------

--
-- Stand-in structure for view `leave_balance_view`
-- (See below for the actual view)
--
CREATE TABLE `leave_balance_view` (
`em_id` int(11)
,`first_name` varchar(100)
,`last_name` varchar(100)
,`leave_type_id` int(11)
,`type_name` varchar(100)
,`max_days` int(11)
,`used_days` decimal(32,0)
,`remaining_days` decimal(33,0)
);

-- --------------------------------------------------------

--
-- Table structure for table `leave_requests`
--

CREATE TABLE `leave_requests` (
  `id` int(11) NOT NULL,
  `em_id` int(11) NOT NULL,
  `leave_type_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `days` int(11) NOT NULL,
  `reason` text NOT NULL,
  `attachment` varchar(255) DEFAULT NULL,
  `status` enum('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  `approved_by` int(11) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `approval_notes` text,
  `rejected_by` int(11) DEFAULT NULL,
  `rejection_reason` text,
  `rejected_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `leave_requests`
--

INSERT INTO `leave_requests` (`id`, `em_id`, `leave_type_id`, `start_date`, `end_date`, `days`, `reason`, `attachment`, `status`, `approved_by`, `approved_at`, `approval_notes`, `rejected_by`, `rejection_reason`, `rejected_at`, `created_at`, `updated_at`) VALUES
(27, 3, 1, '2025-09-25', '2025-09-26', 2, 'แแ', NULL, 'approved', 1, '2025-09-25 11:23:04', NULL, NULL, NULL, NULL, '2025-09-25 11:22:58', '2025-09-25 11:23:04'),
(29, 2, 1, '2025-10-11', '2025-10-14', 4, 'mhv', 'c1a9d4ecc088e1eaa09f3740a756b08a.png', 'approved', 1, '2025-10-03 11:47:17', NULL, NULL, NULL, NULL, '2025-10-03 11:46:49', '2025-10-03 11:47:17'),
(30, 2, 1, '2025-10-13', '2025-10-17', 4, 'ลา', '0ae535647545b4dec37bc685982e6db8.png', 'approved', 1, '2025-10-03 12:10:47', NULL, NULL, NULL, NULL, '2025-10-03 12:10:12', '2025-10-03 12:10:47'),
(31, 3, 3, '2025-10-09', '2025-10-09', 1, 'gg', '1535d1fa90f494113cd17f9b27ca9ae3.jpg', 'rejected', NULL, NULL, NULL, 1, 'no', '2025-10-16 13:28:34', '2025-10-08 10:26:57', '2025-10-16 13:28:34'),
(32, 1, 1, '2025-10-10', '2025-10-14', 3, 'test', NULL, 'approved', 1, '2025-10-08 11:49:14', NULL, NULL, NULL, NULL, '2025-10-08 11:49:06', '2025-10-08 11:49:14'),
(33, 1, 1, '2025-10-15', '2025-10-15', 1, 'ีั', '713c67c765b5e2368ba65d69cefaaefb.jpg', 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-08 13:29:09', NULL),
(35, 1, 1, '2025-10-17', '2025-10-18', 2, 'ddd', NULL, 'pending', NULL, NULL, NULL, NULL, NULL, NULL, '2025-10-16 09:39:35', NULL),
(39, 2, 1, '2026-01-16', '2026-01-17', 2, 'test cross year', NULL, 'approved', 1, '2025-10-16 13:28:25', NULL, NULL, NULL, NULL, '2025-10-16 13:28:12', '2025-10-16 13:28:25');

-- --------------------------------------------------------

--
-- Table structure for table `leave_settings`
--

CREATE TABLE `leave_settings` (
  `id` int(11) NOT NULL,
  `setting_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_value` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `setting_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'text',
  `description` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `leave_settings`
--

INSERT INTO `leave_settings` (`id`, `setting_name`, `setting_value`, `setting_type`, `description`, `created_at`, `updated_at`) VALUES
(1, 'work_on_saturday', '1', 'boolean', 'บริษัททำงานวันเสาร์ (0=ไม่ทำงาน, 1=ทำงาน)', '2025-10-03 11:14:06', '2025-10-16 09:46:43');

-- --------------------------------------------------------

--
-- Table structure for table `leave_types`
--

CREATE TABLE `leave_types` (
  `id` int(11) NOT NULL,
  `type_name` varchar(100) NOT NULL,
  `description` text,
  `max_days` int(11) NOT NULL DEFAULT '0',
  `color` varchar(20) DEFAULT '#3788d8',
  `status` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `leave_types`
--

INSERT INTO `leave_types` (`id`, `type_name`, `description`, `max_days`, `color`, `status`, `created_at`) VALUES
(1, 'ลาป่วย', 'ลาเนื่องจากการเจ็บป่วย', 20, '#000000', 1, '2025-07-21 15:12:32'),
(2, 'ลาพักร้อน', 'ลาพักผ่อนประจำปี', 10, '#4caf50', 1, '2025-07-21 15:12:32'),
(3, 'ลากิจ', 'ลาเพื่อกิจธุระส่วนตัว', 10, '#ff9800', 1, '2025-07-21 15:12:32'),
(4, 'ลาคลอด', 'ลาเพื่อคลอดบุตร', 90, '#e91e63', 1, '2025-07-21 15:12:32'),
(5, 'ลาบวช', 'ลาอุปสมบท', 15, '#9c27b0', 1, '2025-07-21 15:12:32'),
(6, 'ลาฝึกอบรม', 'ลาเพื่อการฝึกอบรม สัมมนา', 5, '#3f51b5', 1, '2025-07-21 15:12:32');

-- --------------------------------------------------------

--
-- Table structure for table `ot_rate_settings`
--

CREATE TABLE `ot_rate_settings` (
  `id` int(11) NOT NULL,
  `day_type` enum('weekday','saturday','sunday','holiday') NOT NULL COMMENT 'Type of day',
  `rate_multiplier` decimal(3,2) NOT NULL COMMENT 'OT rate multiplier',
  `description` varchar(255) DEFAULT NULL COMMENT 'Description of this rate',
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `hourly_rate` decimal(10,2) DEFAULT '50.00' COMMENT 'Base hourly rate'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OT rate multipliers for different day types';

--
-- Dumping data for table `ot_rate_settings`
--

INSERT INTO `ot_rate_settings` (`id`, `day_type`, `rate_multiplier`, `description`, `is_active`, `created_at`, `updated_at`, `hourly_rate`) VALUES
(1, 'weekday', '1.50', NULL, 1, '2025-08-13 03:18:01', '2025-10-08 07:26:16', '50.00'),
(2, 'saturday', '1.70', NULL, 1, '2025-08-13 03:18:01', '2025-10-08 07:26:16', '50.00'),
(3, 'sunday', '2.00', NULL, 1, '2025-08-13 03:18:01', '2025-10-08 07:26:16', '50.00'),
(4, 'holiday', '2.50', NULL, 1, '2025-08-13 03:18:01', '2025-10-08 07:26:16', '50.00');

-- --------------------------------------------------------

--
-- Table structure for table `overtime_requests`
--

CREATE TABLE `overtime_requests` (
  `id` int(11) NOT NULL,
  `em_id` int(11) NOT NULL COMMENT 'Employee ID from employees table',
  `ot_date` date NOT NULL COMMENT 'Date of overtime work',
  `start_time` time NOT NULL COMMENT 'Start time of overtime',
  `end_time` time NOT NULL COMMENT 'End time of overtime',
  `ot_hours` decimal(5,2) NOT NULL COMMENT 'Total overtime hours',
  `ot_amount` decimal(10,2) DEFAULT '0.00' COMMENT 'Calculated overtime pay amount',
  `reason` text NOT NULL COMMENT 'Reason for overtime work',
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending' COMMENT 'Current status of request',
  `approved_by` int(11) DEFAULT NULL COMMENT 'Admin/HR ID who approved',
  `approved_at` datetime DEFAULT NULL COMMENT 'Approval timestamp',
  `rejected_by` int(11) DEFAULT NULL COMMENT 'Admin/HR ID who rejected',
  `rejection_reason` text COMMENT 'Reason for rejection',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Request creation timestamp',
  `updated_at` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last update timestamp'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Employee overtime requests';

--
-- Dumping data for table `overtime_requests`
--

INSERT INTO `overtime_requests` (`id`, `em_id`, `ot_date`, `start_time`, `end_time`, `ot_hours`, `ot_amount`, `reason`, `status`, `approved_by`, `approved_at`, `rejected_by`, `rejection_reason`, `created_at`, `updated_at`) VALUES
(54, 3, '2025-10-13', '21:00:00', '22:00:00', '1.00', '150.00', 'test', 'approved', 1, '2025-10-08 13:19:21', NULL, NULL, '2025-10-06 15:18:32', '2025-10-08 13:19:21'),
(55, 1, '2025-10-09', '18:00:00', '21:00:00', '3.00', '225.00', '้', 'rejected', NULL, '2025-10-08 13:24:54', 1, '่่', '2025-10-08 13:24:27', '2025-10-08 13:24:54'),
(56, 1, '2025-10-10', '18:00:00', '19:00:00', '1.00', '75.00', 'gggg', 'approved', 1, '2025-10-08 14:29:31', NULL, NULL, '2025-10-08 14:28:45', '2025-10-08 14:29:31'),
(57, 1, '2025-10-16', '18:00:00', '22:00:00', '4.00', '300.00', 'd', 'pending', NULL, NULL, NULL, NULL, '2025-10-08 16:00:49', NULL),
(58, 1, '2025-10-15', '18:00:00', '22:00:00', '4.00', '300.00', 'das', 'pending', NULL, NULL, NULL, NULL, '2025-10-14 15:23:16', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `overtime_settings`
--

CREATE TABLE `overtime_settings` (
  `setting_name` varchar(50) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Overtime system settings';

--
-- Dumping data for table `overtime_settings`
--

INSERT INTO `overtime_settings` (`setting_name`, `setting_value`, `description`, `updated_at`) VALUES
('advance_notice_hours', '24', 'Hours of advance notice required for planned OT', '2025-07-23 10:41:34'),
('approval_required', 'true', 'Whether manager approval is required', '2025-07-23 10:41:34'),
('default_rate', '1.5', 'Default overtime rate multiplier', '2025-07-23 10:41:34'),
('holiday_rate', '3.0', 'National holiday overtime rate multiplier', '2025-09-29 16:13:40'),
('max_daily_ot', '4', 'Maximum overtime hours per day', '2025-07-23 10:41:34'),
('max_weekly_ot', '16', 'Maximum overtime hours per week', '2025-07-23 10:41:34'),
('min_ot_hours', '1', 'Minimum overtime hours required', '2025-07-23 10:41:34'),
('weekday_rate', '1.5', 'Weekday overtime rate multiplier', '2025-09-29 16:13:40'),
('weekend_rate', '1.7', 'Weekend overtime rate multiplier (Saturday & Sunday)', '2025-09-29 16:13:40');

-- --------------------------------------------------------

--
-- Table structure for table `security_settings`
--

CREATE TABLE `security_settings` (
  `setting_id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text NOT NULL,
  `setting_type` enum('boolean','number','string','json') DEFAULT 'string',
  `description` text,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='ตารางการตั้งค่าความปลอดภัย';

--
-- Dumping data for table `security_settings`
--

INSERT INTO `security_settings` (`setting_id`, `setting_key`, `setting_value`, `setting_type`, `description`, `is_active`, `created_at`, `updated_at`) VALUES
(18, 'ip_check_enabled', '1', 'string', 'เปิดใช้งานการตรวจสอบ IP Address', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(19, 'strict_checkout_ip', '0', 'string', 'บังคับใช้ IP เดียวกันสำหรับเช็คอิน/เช็คเอาท์', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(20, 'session_timeout', '28800', 'string', 'ระยะเวลา session timeout (วินาที)', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(21, 'max_login_attempts', '5', 'string', 'จำนวนครั้งที่พยายาม login ได้สูงสุด', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(22, 'login_lockout_time', '1800', 'string', 'ระยะเวลาล็อคการ login (วินาที)', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(23, 'require_strong_password', '1', 'string', 'บังคับใช้รหัสผ่านที่แข็งแกร่ง', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(24, 'log_failed_attempts', '1', 'string', 'บันทึกการพยายาม login ที่ล้มเหลว', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13'),
(25, 'allow_concurrent_sessions', '0', 'string', 'อนุญาตให้ login พร้อมกันได้หลาย session', 1, '2025-10-07 12:40:13', '2025-10-07 12:40:13');

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `id` int(11) NOT NULL,
  `setting_group` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'กลุ่มการตั้งค่า',
  `setting_key` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'คีย์การตั้งค่า',
  `setting_value` text COLLATE utf8mb4_unicode_ci COMMENT 'ค่าการตั้งค่า',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT 'คำอธิบายการตั้งค่า',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`id`, `setting_group`, `setting_key`, `setting_value`, `description`, `created_at`, `updated_at`) VALUES
(1, 'auto_checkout', 'work_hours', '8', 'ชั่วโมงทำงานมาตรฐานต่อวัน', '2025-09-17 11:35:52', '2025-09-17 11:35:52'),
(2, 'auto_checkout', 'warning_minutes', '30', 'เวลาเตือนก่อนหมดเวลา (นาที)', '2025-09-17 11:35:52', '2025-09-18 09:44:51'),
(3, 'auto_checkout', 'max_work_minutes', '540', 'เวลาทำงานสูงสุด (นาที)', '2025-09-17 11:35:52', '2025-09-17 11:35:52'),
(4, 'auto_checkout', 'auto_checkout_enabled', '1', 'เปิดใช้งาน auto checkout', '2025-09-17 11:35:52', '2025-10-15 13:42:43'),
(5, 'auto_checkout', 'force_logout_enabled', 'true', 'บังคับ logout หลัง auto checkout', '2025-09-17 11:35:52', '2025-09-18 09:44:51'),
(6, 'auto_checkout', 'notification_enabled', 'true', 'ส่งการแจ้งเตือนอีเมล', '2025-09-17 11:35:52', '2025-09-18 09:44:51'),
(7, 'auto_checkout', 'logout_time', '17:31', NULL, '2025-09-17 15:44:50', '2025-10-15 13:42:43'),
(8, 'auto_checkout', 'grace_period_minutes', '15', NULL, '2025-09-17 15:44:50', '2025-09-18 09:44:51');

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_ip_usage_report`
-- (See below for the actual view)
--
CREATE TABLE `v_ip_usage_report` (
`em_id` int(11)
,`employee_name` varchar(201)
,`employee_code` varchar(50)
,`work_date` date
,`ip_address_checkin` varchar(45)
,`ip_address_checkout` varchar(45)
,`location_verified_checkin` tinyint(1)
,`location_verified_checkout` tinyint(1)
,`checkin_network` varchar(100)
,`checkout_network` varchar(100)
,`checkin_time` datetime
,`checkout_time` datetime
,`status` enum('on-time','is_late','leave','absent')
);

-- --------------------------------------------------------

--
-- Table structure for table `weekend_settings`
--

CREATE TABLE `weekend_settings` (
  `id` int(11) NOT NULL,
  `day_of_week` int(11) NOT NULL COMMENT '1=Monday, 7=Sunday',
  `is_weekend` tinyint(1) NOT NULL DEFAULT '0',
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `weekend_settings`
--

INSERT INTO `weekend_settings` (`id`, `day_of_week`, `is_weekend`, `updated_at`) VALUES
(1, 1, 0, '2025-07-24 10:43:22'),
(2, 2, 0, '2025-07-24 10:43:22'),
(3, 3, 0, '2025-07-24 10:43:22'),
(4, 4, 0, '2025-07-24 10:43:22'),
(5, 5, 0, '2025-07-24 10:43:22'),
(6, 6, 1, '2025-07-24 10:43:22'),
(7, 7, 1, '2025-07-24 10:43:22');

-- --------------------------------------------------------

--
-- Structure for view `leave_balance_view`
--
DROP TABLE IF EXISTS `leave_balance_view`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `leave_balance_view`  AS SELECT `e`.`em_id` AS `em_id`, `e`.`first_name` AS `first_name`, `e`.`last_name` AS `last_name`, `lt`.`id` AS `leave_type_id`, `lt`.`type_name` AS `type_name`, `lt`.`max_days` AS `max_days`, coalesce(sum(`lr`.`days`),0) AS `used_days`, (`lt`.`max_days` - coalesce(sum(`lr`.`days`),0)) AS `remaining_days` FROM ((`employees` `e` join `leave_types` `lt`) left join `leave_requests` `lr` on(((`e`.`em_id` = `lr`.`em_id`) and (`lt`.`id` = `lr`.`leave_type_id`) and (`lr`.`status` = 'approved') and (year(`lr`.`start_date`) = year(curdate()))))) GROUP BY `e`.`em_id`, `lt`.`id``id`  ;

-- --------------------------------------------------------

--
-- Structure for view `v_ip_usage_report`
--
DROP TABLE IF EXISTS `v_ip_usage_report`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_ip_usage_report`  AS SELECT `e`.`em_id` AS `em_id`, concat(`e`.`first_name`,' ',`e`.`last_name`) AS `employee_name`, `e`.`employee_code` AS `employee_code`, `al`.`work_date` AS `work_date`, `al`.`ip_address_checkin` AS `ip_address_checkin`, `al`.`ip_address_checkout` AS `ip_address_checkout`, `al`.`location_verified_checkin` AS `location_verified_checkin`, `al`.`location_verified_checkout` AS `location_verified_checkout`, `cir1`.`range_name` AS `checkin_network`, `cir2`.`range_name` AS `checkout_network`, `al`.`checkin_time` AS `checkin_time`, `al`.`checkout_time` AS `checkout_time`, `al`.`status` AS `status` FROM (((`attendance_logs` `al` left join `employees` `e` on((`al`.`em_id` = `e`.`em_id`))) left join `company_ip_ranges` `cir1` on((`al`.`ip_address_checkin` regexp replace(`cir1`.`ip_range`,'/[0-9]+','')))) left join `company_ip_ranges` `cir2` on((`al`.`ip_address_checkout` regexp replace(`cir2`.`ip_range`,'/[0-9]+','')))) WHERE (`al`.`work_date` >= (curdate() - interval 30 day)) ORDER BY `al`.`work_date` DESC, `al`.`checkin_time` AS `DESCdesc` ASC  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `access_logs`
--
ALTER TABLE `access_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `em_id` (`em_id`),
  ADD KEY `ip_address` (`ip_address`),
  ADD KEY `action` (`action`),
  ADD KEY `success` (`success`),
  ADD KEY `created_at` (`created_at`),
  ADD KEY `location_verified` (`location_verified`);

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`admin_id`);

--
-- Indexes for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `em_id` (`em_id`),
  ADD KEY `idx_ip_checkin` (`ip_address_checkin`),
  ADD KEY `idx_ip_checkout` (`ip_address_checkout`),
  ADD KEY `idx_location_verified` (`location_verified_checkin`,`location_verified_checkout`),
  ADD KEY `idx_work_date_em_id` (`work_date`,`em_id`);

--
-- Indexes for table `attendance_settings`
--
ALTER TABLE `attendance_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_setting_name` (`setting_name`);

--
-- Indexes for table `company_ip_ranges`
--
ALTER TABLE `company_ip_ranges`
  ADD PRIMARY KEY (`range_id`),
  ADD KEY `ip_range` (`ip_range`),
  ADD KEY `is_active` (`is_active`);

--
-- Indexes for table `cross_year_leave_deductions`
--
ALTER TABLE `cross_year_leave_deductions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_employee_year_type` (`employee_id`,`year`,`leave_type_id`),
  ADD KEY `idx_leave_request` (`leave_request_id`);

--
-- Indexes for table `departments`
--
ALTER TABLE `departments`
  ADD PRIMARY KEY (`dept_id`);

--
-- Indexes for table `employees`
--
ALTER TABLE `employees`
  ADD PRIMARY KEY (`em_id`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `holidays`
--
ALTER TABLE `holidays`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_holiday_date` (`holiday_date`),
  ADD KEY `idx_date_range` (`holiday_date`,`end_date`);

--
-- Indexes for table `leave_requests`
--
ALTER TABLE `leave_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `em_id` (`em_id`),
  ADD KEY `leave_type_id` (`leave_type_id`),
  ADD KEY `status` (`status`);

--
-- Indexes for table `leave_settings`
--
ALTER TABLE `leave_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_name` (`setting_name`);

--
-- Indexes for table `leave_types`
--
ALTER TABLE `leave_types`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `ot_rate_settings`
--
ALTER TABLE `ot_rate_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_day_type` (`day_type`);

--
-- Indexes for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `em_id` (`em_id`),
  ADD KEY `status` (`status`),
  ADD KEY `ot_date` (`ot_date`),
  ADD KEY `idx_employee_status` (`em_id`,`status`);

--
-- Indexes for table `overtime_settings`
--
ALTER TABLE `overtime_settings`
  ADD PRIMARY KEY (`setting_name`);

--
-- Indexes for table `security_settings`
--
ALTER TABLE `security_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_setting` (`setting_group`,`setting_key`);

--
-- Indexes for table `weekend_settings`
--
ALTER TABLE `weekend_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `day_of_week` (`day_of_week`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `access_logs`
--
ALTER TABLE `access_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `admin`
--
ALTER TABLE `admin`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=455;

--
-- AUTO_INCREMENT for table `attendance_settings`
--
ALTER TABLE `attendance_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `company_ip_ranges`
--
ALTER TABLE `company_ip_ranges`
  MODIFY `range_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `cross_year_leave_deductions`
--
ALTER TABLE `cross_year_leave_deductions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `departments`
--
ALTER TABLE `departments`
  MODIFY `dept_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `employees`
--
ALTER TABLE `employees`
  MODIFY `em_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `holidays`
--
ALTER TABLE `holidays`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=174;

--
-- AUTO_INCREMENT for table `leave_requests`
--
ALTER TABLE `leave_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `leave_settings`
--
ALTER TABLE `leave_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `leave_types`
--
ALTER TABLE `leave_types`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `ot_rate_settings`
--
ALTER TABLE `ot_rate_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `overtime_requests`
--
ALTER TABLE `overtime_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=59;

--
-- AUTO_INCREMENT for table `security_settings`
--
ALTER TABLE `security_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `weekend_settings`
--
ALTER TABLE `weekend_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `access_logs`
--
ALTER TABLE `access_logs`
  ADD CONSTRAINT `access_logs_ibfk_1` FOREIGN KEY (`em_id`) REFERENCES `employees` (`em_id`) ON DELETE CASCADE;

--
-- Constraints for table `attendance_logs`
--
ALTER TABLE `attendance_logs`
  ADD CONSTRAINT `attendance_logs_ibfk_1` FOREIGN KEY (`em_id`) REFERENCES `employees` (`em_id`);

DELIMITER $$
--
-- Events
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_cleanup_old_logs` ON SCHEDULE EVERY 1 DAY STARTS '2025-10-07 09:58:32' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    DECLARE retention_days INT DEFAULT 90;
    
    -- ดึงค่าการตั้งค่าจากตาราง security_settings
    SELECT CAST(setting_value AS UNSIGNED) INTO retention_days
    FROM security_settings 
    WHERE setting_key = 'log_retention_days' AND is_active = 1
    LIMIT 1;
    
    -- ลบ access_logs ที่เก่าเกินกำหนด
    DELETE FROM access_logs 
    WHERE created_at < DATE_SUB(NOW(), INTERVAL retention_days DAY);
    
    -- ลบ attendance_logs ที่เก่าเกิน 1 ปี (เก็บไว้นานกว่า access_logs)
    DELETE FROM attendance_logs 
    WHERE work_date < DATE_SUB(CURRENT_DATE, INTERVAL 365 DAY);
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
