-- ===================================================================================================
--   CREDIT CARD TRANSACTION SYSTEM
-- ===================================================================================================


-- ===================================================================================================
--  STORED PROCEDURES
-- ===================================================================================================

-- -----------------------------------------------------------------------------------------------------
--  Procedure 1 : record_transaction
-- -----------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE record_transaction(
	IN input_card_no CHAR(16),
    IN input_vendor_id INT,
    IN transaction_amount DECIMAL(10,2)
)
BEGIN
	DECLARE get_card_id INT;
    DECLARE card_status ENUM('active','blocked');
    DECLARE balance DECIMAL(10,2);
    DECLARE transaction_status ENUM('success','failed');
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET get_card_id = NULL;

    
    proc: BEGIN
		-- 1. check if the card exists and is active
		SELECT
			card_id,status INTO get_card_id,card_status
		FROM credit_cards
		WHERE card_no=input_card_no;
		
		IF get_card_id IS NULL THEN
			SELECT 'Incorrect card number' AS message;
			LEAVE proc;
		END IF;
		
		IF card_status='blocked' THEN
			SELECT 'Card is blocked' AS message;
			LEAVE proc;
		END IF;
		
		-- 2. get the balance of the card
		SELECT
			balance_amount INTO balance
		FROM credit_card_balance
		WHERE card_id=get_card_id;
		
		-- 3. check if balance is sufficient
		IF balance<transaction_amount THEN
			SET transaction_status='failed';
		ELSE
			SET transaction_status='success';
		END IF;
		
		-- 4. insert entry into transaction table
		INSERT INTO transactions (card_id,vendor_id,transaction_date,amount,status)
		VALUES (get_card_id,input_vendor_id,NOW(),transaction_amount,transaction_status);
		
		-- 5. message
		IF transaction_status='success' THEN
			SELECT 'Transaction processed succesfully' AS message;
		ELSE
			SELECT 'Transaction failed due to insufficient balance' AS message;
		END IF;
	END proc;
END $$
DELIMITER ;

CALL record_transaction(4539876543210001,7,100000.0);
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Procedure 2 : make_payment
-- -----------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE make_payment(
	IN input_card_no CHAR(16),
    IN amount_paid DECIMAL(10,2)
)
BEGIN
	DECLARE get_card_id INT;
    DECLARE card_status ENUM('active','blocked');
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET get_card_id = NULL;
    
	proc: BEGIN
		-- 1. check if the card exists and is not blocked
        SELECT
			card_id,status INTO get_card_id,card_status
		FROM credit_cards
        WHERE card_no=input_card_no;
        
        IF get_card_id IS NULL THEN
			SELECT 'Incorrect card details' AS message;
            LEAVE proc;
		END IF;
        
        IF card_status='blocked' THEN
			SELECT 'Card is blocked. Activate card!' AS message;
			LEAVE proc;
		END IF;
        
        -- 2. insert entry into payments table
        INSERT INTO payments (card_id,payment_date,amount)
        VALUES (get_card_id,NOW(),amount_paid);
        
        SELECT 'Payment succesful.' AS message;
        
    END proc;
END $$
DELIMITER ;

CALL make_payment(4539876543210001,50000.0);
-- -----------------------------------------------------------------------------------------------------


-- -----------------------------------------------------------------------------------------------------
--  Procedure 3 : activate_blocked_card
-- -----------------------------------------------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE activate_blocked_card(
	IN input_card_no CHAR(16),
    IN input_email VARCHAR(320)
)
BEGIN
	DECLARE get_customer_id INT;
    DECLARE get_card_id INT;
    DECLARE card_status ENUM('active','blocked');
    DECLARE balance DECIMAL(10,2);
    DECLARE get_email VARCHAR(320);
    DECLARE found_flag BOOLEAN DEFAULT TRUE;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND
	SET found_flag = FALSE;
    
    proc: BEGIN
		-- 1. check if card exists
        SELECT
			card_id,customer_id,status INTO get_card_id,get_customer_id,card_status
		FROM credit_cards
        WHERE card_no=input_card_no;
        
        IF NOT found_flag THEN
			SELECT 'Invalid card details.' AS message;
            LEAVE proc;
		END IF;
        
        SET found_flag=TRUE;
        
        -- 2. verify user using email
        IF get_customer_id IS NULL THEN
			SELECT 'Customer not found.' AS message;
            LEAVE proc;
		END IF;
        
        SELECT
			customer_email INTO get_email
		FROM customers
        WHERE customer_id=get_customer_id;
        
        IF get_email!=input_email THEN
			SELECT 'Verification failed.' AS message;
            LEAVE proc;
		END IF;
        
        -- 3. check if card is already active
        IF card_status='active' THEN
			SELECT 'Card is already active. You can make payments' AS message;
            LEAVE proc;
		END IF;
        
        -- 4. get balance
        SELECT
			balance_amount INTO balance
		FROM credit_card_balance
        WHERE card_id=get_card_id;
        
        -- activate card by making payment of balance amount if negative balance
        IF balance>=0 THEN
			UPDATE credit_cards SET status='active'
            WHERE card_id=get_card_id;
            
            SELECT 'Card had non-negative balance. Card activated.' AS message;
		ELSE
			INSERT INTO payments (card_id,payment_date,amount)
			VALUES (get_card_id,NOW(),ABS(balance));
            
            UPDATE credit_cards SET status='active'
            WHERE card_id=get_card_id;
            
            SELECT 'Made payment. Card activated' AS message;
		END IF;
    END proc;
END $$
DELIMITER ;

CALL activate_blocked_card(4539876543210033,'sourav.das03@example.com');
CALL activate_blocked_card(1234567890123460,'yash.agrawal20@example.com');
-- -----------------------------------------------------------------------------------------------------