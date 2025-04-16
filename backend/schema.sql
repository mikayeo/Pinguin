CREATE DATABASE IF NOT EXISTS pinguin
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE pinguin;

CREATE TABLE IF NOT EXISTS accounts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(191) UNIQUE NOT NULL,
  password VARCHAR(191) NOT NULL,
  full_name VARCHAR(191) NOT NULL,
  account_number VARCHAR(10) UNIQUE NOT NULL,
  balance DECIMAL(10, 2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS transactions (
  id INT PRIMARY KEY AUTO_INCREMENT,
  sender_account_id INT NOT NULL,
  recipient_account_id INT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  type ENUM('transfer', 'deposit', 'withdrawal') NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sender_account_id) REFERENCES accounts(id),
  FOREIGN KEY (recipient_account_id) REFERENCES accounts(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci; 