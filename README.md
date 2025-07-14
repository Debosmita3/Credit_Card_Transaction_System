# 💳 Credit Card Transaction System

This project is a relational database system built using **MySQL** to manage and analyze credit card transactions. It is designed to simulate real-world banking operations including customer management, credit card transactions, payments, fraud detection, and vendor performance.

---

## 📁 Project Structure

- **Schema Design**: Includes 5 interconnected tables.
- **Views**: 9 analytical and business-centric views.
- **Stored Procedures**: 3 procedures handling transactions, payments, and card activation.
- **Analysis & Business Queries**: SQL queries for insights, checks, and reports.

---

## 🗃️ Database Schema

### 🔹 `customers`
Stores personal info of customers.  
**Fields**: `customer_id (PK)`, `customer_name`, `customer_email (Unique)`, `customer_phone`, `customer_address`

### 🔹 `credit_cards`
Credit card details linked to customers.  
**Fields**: `card_id (PK)`, `customer_id (FK)`, `card_no (Unique)`, `credit_limit`, `expiry_date`, `status`

### 🔹 `vendors`
Vendors accepting card payments.  
**Fields**: `vendor_id (PK)`, `vendor_name`, `category`, `city`

### 🔹 `transactions`
Tracks card purchases and payments to vendors.  
**Fields**: `transaction_id (PK)`, `card_id (FK)`, `vendor_id (FK)`, `transaction_date`, `amount`, `status`

### 🔹 `payments`
Customer payments towards card balances.  
**Fields**: `payment_id (PK)`, `card_id (FK)`, `payment_date`, `amount`

---

## 👁️ Database Views

| View Name | Description |
|-----------|-------------|
| `customer_transactions` | Combines customers, cards, vendors, and transactions |
| `credit_card_balance` | Current balance per card using payments and spend |
| `monthly_spending_summary` | Monthly spending per customer |
| `vendor_performance` | Vendor revenue and transaction summary |
| `unsuccessful_transactions` | Failed and reversed transactions |
| `high_value_customers` | Customers with > ₹10,000 total spending |
| `category_wise_vendor_earning` | Earnings grouped by vendor category |
| `payment_done_per_card` | Total payment received per card |
| `payment_frequency_per_customer` | Payment trends per customer |

---

## 📊 SQL Query Highlights

### 🔍 Analysis Queries
- **Total spending per customer**
- **Top 5 vendors by revenue**
- **Failed/reversed transactions per customer**
- **Highest single transaction**
- **Most used credit card**

### ⚙️ Business Logic Queries
- **Blocked cards with outstanding balance**
- **Cards with ≥90% usage**

### 🔎 Data Validation
- **Inactive customers (no transaction in last 30 days)**

### 📈 Reporting Queries
- **Top 3 cities by transaction volume and value**

---

## 🔁 Stored Procedures

### 🔸 `record_transaction`
Validates a transaction:
- Checks card validity, status, balance
- Inserts transaction with `success` or `failed` status  
```sql
CALL record_transaction('4539876543210001', 7, 100000.0);
```

### 🔸 `make_payment`
Adds a payment for a valid, active card  
```sql
CALL make_payment('4539876543210001', 50000.0);
```

### 🔸 `activate_blocked_card`
Verifies user and activates card based on balance/payment  
```sql
CALL activate_blocked_card('4539876543210033', 'sourav.das03@example.com');
```

---

## 🚀 Getting Started

### 📦 Requirements
- MySQL 8.0+
- MySQL Workbench (optional)
- Sample data if desired(provided here)

### ▶️ Setup Instructions
1. Clone the repository
2. Open MySQL Workbench or CLI
3. Execute `credit_card_system.sql` in order:
   - Create database and tables
   - Insert sample data (provided here if needed)
   - Create views and stored procedures
4. Run queries as needed

---

## 🧰 Tools Used

- **MySQL**
- **MySQL Workbench**
- Optional: ER diagramming tools (dbdiagram.io, draw.io)

---

## 🧑‍💻 Author

**Debosmita Pal**  
📧 [LinkedIn](https://www.linkedin.com/in/debosmita-pal-82b1a3265/)

---

## 📜 License

This project is open-source and free to use for learning and academic purposes.
