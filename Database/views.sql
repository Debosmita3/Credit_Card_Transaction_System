-- ===================================================================================================
--  CREDIT CARD TRANSACTION SYSTEM
-- ===================================================================================================


-- ===================================================================================================
--  VIEWS
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  View 1 : CUSTOMER_TRANSACTIONS
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW customer_transactions AS
(
	SELECT
		cu.customer_id,
        cu.customer_name,
        t.transaction_id,
        t.amount,
        t.transaction_date,
        cc.card_no card_used,
        v.vendor_name,
        v.category,
        t.status
	FROM customers cu
    JOIN credit_cards cc ON cu.customer_id=cc.customer_id
    JOIN transactions t ON cc.card_id=t.card_id
    LEFT JOIN vendors v ON t.vendor_id=v.vendor_id
);
SELECT * FROM customer_transactions;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 2 : CREDIT_CARD_BALANCE
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW credit_card_balance AS
(
	WITH cte_total_spending AS
    (
		SELECT
			card_id,
            SUM(amount) total_spent
		FROM transactions
        WHERE status='success'
        GROUP BY card_id
	),
    cte_total_payment AS
    (
		SELECT
			card_id,
            SUM(amount) total_paid
		FROM payments
        GROUP BY card_id
    )
    SELECT
		cc.card_id,
        cc.card_no,
        cc.credit_limit,
        COALESCE(s.total_spent,0) total_spent,
        COALESCE(p.total_paid,0) total_paidback,
        (cc.credit_limit-COALESCE(s.total_spent,0)+COALESCE(p.total_paid,0)) balance_amount,
        cc.status
	FROM credit_cards cc
    LEFT JOIN cte_total_spending s ON cc.card_id=s.card_id
    LEFT JOIN cte_total_payment p ON cc.card_id=p.card_id
);
SELECT * FROM credit_card_balance;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 3 : MONTHLY_SPENDING_SUMMARY
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW monthly_spending_summary AS
(
	SELECT
		customer_id,
        customer_name,
        DATE_FORMAT(transaction_date, '%m-%Y') month_year,
        SUM(amount) monthly_spent
	FROM customer_transactions
    WHERE status='success'
    GROUP BY customer_id, month_year
);
SELECT * FROM monthly_spending_summary;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 4 : VENDOR_PERFORMANCE
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW vendor_performance AS
(
	SELECT
		v.vendor_id,
        v.vendor_name,
        v.category,
        COUNT(t.transaction_id) total_transactions,
        SUM(COALESCE(t.amount,0)) total_earned,
        v.city
	FROM vendors v
    LEFT JOIN transactions t
    ON v.vendor_id=t.vendor_id AND t.status='success'
    GROUP BY v.vendor_id
);
SELECT * FROM vendor_performance;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 5 : UNSUCCESSFUL_TRANSACTIONS
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW unsuccessful_transactions AS
(
	SELECT
		*
	FROM customer_transactions
    WHERE status IN ('failed','reversed')
);
SELECT * FROM unsuccessful_transactions;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 6 : HIGH_VALUE_CUSTOMERS
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW high_value_customers AS
(
	WITH cte_total_spending AS
    (
		SELECT
			card_id,
            SUM(amount) total_amount
		FROM transactions
        WHERE status='success'
		GROUP BY card_id
	)
    SELECT
		cu.*,
        SUM(t.total_amount) amount_spent
	FROM customers cu
    JOIN credit_cards cc ON cu.customer_id=cc.customer_id
    JOIN cte_total_spending t ON cc.card_id=t.card_id
    GROUP BY customer_id
    HAVING amount_spent>10000
);
SELECT * FROM high_value_customers;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 7 : CATEGORY_WISE_VENDOR_EARNING
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW category_wise_vendor_earning AS(
	SELECT
		v.category,
		SUM(t.amount) amount_earned
	FROM vendors v
	JOIN transactions t
	ON v.vendor_id=t.vendor_id
	WHERE t.status='success'
	GROUP BY v.category
);
SELECT * FROM category_wise_vendor_earning;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 8 : PAYMENT_DONE_PER_CARD
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW payment_done_per_card AS(
	SELECT
		cc.card_id,
		cc.card_no,
		cc.status,
		SUM(COALESCE(p.amount,0)) total_payment
	FROM credit_cards cc
	LEFT JOIN payments p
	ON cc.card_id=p.card_id
	GROUP BY cc.card_id
);
SELECT * FROM payment_done_per_card;
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  View 9 : PAYMENT_FREQUENCY_PER_CUSTOMER
-- -----------------------------------------------------------------------------------------------------
CREATE VIEW payment_frequency_per_customer AS(
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
	GROUP BY customer_id
);
SELECT * FROM payment_frequency_per_customer;
-- -----------------------------------------------------------------------------------------------------