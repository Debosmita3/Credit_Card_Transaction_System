-- ===================================================================================================
--  CREDIT CARD TRANSACTION SYSTEM
-- ===================================================================================================


-- ===================================================================================================
--  ANALYSIS QUERIES
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  Query 1
--  Total spending per customer
-- -----------------------------------------------------------------------------------------------------
SELECT
	customer_name,
    SUM(amount) total_amount
FROM customer_transactions
WHERE status='success'
GROUP BY customer_name;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 2
--  Top 5 vendors by revenue
-- -----------------------------------------------------------------------------------------------------
SELECT
	v.vendor_id,
    v.vendor_name,
    v.category,
    SUM(t.amount) revenue
FROM vendors v
JOIN transactions t
ON t.vendor_id=v.vendor_id
WHERE t.status='success'
GROUP BY v.vendor_id
ORDER BY revenue DESC
LIMIT 5;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 3
--  Category-wise vendors earning
-- -----------------------------------------------------------------------------------------------------
SELECT
	v.category,
    SUM(t.amount) amount_earned
FROM vendors v
JOIN transactions t
ON v.vendor_id=t.vendor_id
WHERE t.status='success'
GROUP BY v.category;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 4
--  Number of failed/reversed transactions per customer
-- -----------------------------------------------------------------------------------------------------
SELECT
	cu.customer_id,
    cu.customer_name,
    SUM(
		CASE
			WHEN t.status='success' THEN 0
            ELSE 1
		END
	) failed_reversed_transactions
FROM customers cu
LEFT JOIN credit_cards cc ON cu.customer_id=cc.customer_id
LEFT JOIN transactions t ON t.card_id=cc.card_id
GROUP BY cu.customer_id;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 5
--  Highest single transaction ever made
-- -----------------------------------------------------------------------------------------------------
WITH cte_ranked_transactions AS
(
	SELECT 
		t.transaction_id,
		t.transaction_date,
		t.amount,
        cu.customer_name,
        v.vendor_name,
        v.category,
        (RANK() OVER(ORDER BY amount DESC)) ranking
	FROM transactions t
    JOIN credit_cards cc ON t.card_id=cc.card_id
    JOIN customers cu ON cc.customer_id=cu.customer_id
    JOIN vendors v ON t.vendor_id=v.vendor_id
    WHERE t.status='success'
)
SELECT
transaction_id,
amount,
customer_name,
transaction_date,
vendor_name,
category
FROM cte_ranked_transactions
WHERE ranking=1;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 6
--  Most used credit card details
-- -----------------------------------------------------------------------------------------------------
WITH cte_card_usage AS
(
	SELECT
		t.card_id,
        cc.card_no,
        cc.credit_limit,
        cc.expiry_date,
        cc.status,
        COUNT(t.card_id) count
	FROM transactions t
    JOIN credit_cards cc
    ON t.card_id=cc.card_id
    GROUP BY t.card_id
    ORDER BY count DESC
)
SELECT
	card_id,
    card_no,
    credit_limit,
    expiry_date,
    status,
    count
FROM cte_card_usage
WHERE count=(SELECT MAX(count) FROM cte_card_usage);
-- -----------------------------------------------------------------------------------------------------


-- ===================================================================================================
--  BUSINESS LOGIC QUERIES
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  Query 1
--  Total payments made per card
-- -----------------------------------------------------------------------------------------------------
SELECT
	cc.card_id,
	cc.card_no,
    cc.status,
    SUM(COALESCE(p.amount,0)) total_payment
FROM credit_cards cc
LEFT JOIN payments p
ON cc.card_id=p.card_id
GROUP BY cc.card_id;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 2
--  List of blocked cards with remaining balance
-- -----------------------------------------------------------------------------------------------------
SELECT
	card_id,
    card_no,
    status,
    balance_amount
FROM credit_card_balance
WHERE status='blocked';
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 3
--  Cards that are maxed out or nearly full i.e 90% used
-- -----------------------------------------------------------------------------------------------------
WITH cte_total_spending AS
(
	SELECT
		card_id,
        SUM(amount) total_spent
	FROM transactions
    WHERE status='success'
    GROUP BY card_id
)
SELECT
	cc.card_id,
    cc.card_no,
    t.total_spent,
    cc.credit_limit,
    cc.expiry_date,
    cc.status,
    (t.total_spent/cc.credit_limit) usage_ratio
FROM credit_cards cc
JOIN cte_total_spending t
ON cc.card_id=t.card_id
WHERE (t.total_spent/cc.credit_limit)>=0.9;
-- -----------------------------------------------------------------------------------------------------


-- ===================================================================================================
--  DATA CHECK QUERIES
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  Query 1
--  Customers who haven't made any transaction in the last 30 days
-- -----------------------------------------------------------------------------------------------------
SELECT
	cu.customer_id,
	cu.customer_name,
    cu.customer_phone,
    cu.customer_email,
    MAX(t.transaction_date) last_transaction
FROM customers cu
LEFT JOIN credit_cards cc ON cu.customer_id=cc.customer_id
LEFT JOIN transactions t ON cc.card_id=t.card_id
GROUP BY cu.customer_id, cu.customer_name
HAVING MAX(t.transaction_date) IS NULL OR MAX(t.transaction_date) < NOW()-INTERVAL 30 DAY;
-- -----------------------------------------------------------------------------------------------------


-- ===================================================================================================
--  REPORTING QUERIES
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  Query 1
--  Payment frequency per customer
-- -----------------------------------------------------------------------------------------------------
WITH cte_customer_payment AS
(
	SELECT
		cu.customer_id,
        cu.customer_name,
        cu.customer_phone,
        p.payment_date
	FROM customers cu
    LEFT JOIN credit_cards cc ON cu.customer_id=cc.customer_id
    LEFT JOIN payments p ON cc.card_id=p.card_id
)
SELECT
	customer_id,
    customer_name,
    COUNT(payment_date) total_payments,
    MIN(payment_date) first_payment,
    MAX(payment_date) last_payment,
    DATEDIFF(MAX(payment_date),MIN(payment_date)) time_span_in_days,
    CASE
		WHEN DATEDIFF(MAX(payment_date),MIN(payment_date))>0 THEN
			ROUND(COUNT(payment_date)/(DATEDIFF(MAX(payment_date),MIN(payment_date))/30.44),2)
		ELSE 0.0
	END payment_per_month
FROM cte_customer_payment
GROUP BY customer_id;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Query 2
--  3 most popular cities for credit card transactions
-- -----------------------------------------------------------------------------------------------------
SELECT
	v.city,
	COUNT(t.transaction_id) no_of_transactions,
	SUM(t.amount) total_amount
FROM vendors v
JOIN transactions t
ON v.vendor_id=t.vendor_id
WHERE t.status='success'
GROUP BY v.city
ORDER BY no_of_transactions DESC,total_amount DESC
LIMIT 3;
-- -----------------------------------------------------------------------------------------------------