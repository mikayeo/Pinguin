DELIMITER //

CREATE PROCEDURE create_transaction(
    IN p_sender_phone VARCHAR(20),
    IN p_recipient_phone VARCHAR(20),
    IN p_amount DECIMAL(10, 2)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction failed';
    END;

    START TRANSACTION;

    -- Insert the transaction record
    INSERT INTO transactions (sender_phone, recipient_phone, amount, type)
    VALUES (p_sender_phone, p_recipient_phone, p_amount, 'transfer');

    -- Update sender's balance (subtract amount)
    UPDATE accounts a
    JOIN users u ON a.user_id = u.id
    SET a.balance = a.balance - p_amount
    WHERE u.phoneNumber = p_sender_phone;

    -- Update recipient's balance (add amount)
    UPDATE accounts a
    JOIN users u ON a.user_id = u.id
    SET a.balance = a.balance + p_amount
    WHERE u.phoneNumber = p_recipient_phone;

    COMMIT;
END //

DELIMITER ;
