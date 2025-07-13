-- ===================================================================================================
--   CREDIT CARD TRANSACTION SYSTEM
-- ===================================================================================================


-- ===================================================================================================
--  DATABASE CREATION 
-- ===================================================================================================
CREATE DATABASE credit_card_system;

USE credit_card_system;

-- =================================================================================================== 
--  TABLES CREATION 
-- ===================================================================================================

-- Table: Customers{customer_id(PK), customer_name, customer_email, customer_phone, customer_address}
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(50) NOT NULL,
    customer_email VARCHAR(320) NOT NULL UNIQUE,
    customer_phone VARCHAR(15) NOT NULL,
    customer_address TEXT
);

-- Table: CreditCards{card_id(PK), customer_id(FK), card_no, credit_limit, expiry_date, status}
CREATE TABLE credit_cards
(
	card_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    card_no CHAR(16) NOT NULL UNIQUE,
    credit_limit DECIMAL(10,2) NOT NULL,
    expiry_date DATE NOT NULL,
    status ENUM('active','blocked') NOT NULL DEFAULT 'active',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE SET NULL,
    CHECK(credit_limit > 0)
);

-- Table: Vendors{vendor_id(PK), vendor_name, category, city}
CREATE TABLE vendors
(
	vendor_id INT PRIMARY KEY AUTO_INCREMENT,
    vendor_name VARCHAR(50) NOT NULL,
    category VARCHAR(50),
    city VARCHAR(50)
);

-- Table: Transactions{transaction_id(PK), card_id(FK), vendor_id(FK), transaction_date, amount, status}
CREATE TABLE transactions
(
	transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT,
    vendor_id INT,
    transaction_date DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('success','failed','reversed') NOT NULL,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id) ON DELETE CASCADE,
    FOREIGN KEY (vendor_id) REFERENCES vendors(vendor_id) ON DELETE SET NULL,
    CHECK(amount > 0)
);

-- Table: Payments{payment_id(PK), card_id(FK), payment_date, amount}
CREATE TABLE payments
(
	payment_id INT PRIMARY KEY AUTO_INCREMENT,
    card_id INT NOT NULL,
    payment_date DATETIME NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (card_id) REFERENCES credit_cards(card_id) ON DELETE CASCADE,
    CHECK(amount > 0)
);