# MySQL Stored Procedure Patterns

Common design patterns for stored procedures.

## CRUD Patterns

### Read (SELECT)
```sql
CREATE PROCEDURE sp_get_user_by_id(
    IN p_user_id INT
)
SQL SECURITY INVOKER
BEGIN
    SELECT * FROM users WHERE id = p_user_id;
END
```

### Create (INSERT)
```sql
CREATE PROCEDURE sp_create_user(
    IN p_email VARCHAR(255),
    IN p_name VARCHAR(255),
    OUT p_user_id INT,
    OUT p_success BOOLEAN
)
SQL SECURITY INVOKER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = FALSE;
        SET p_user_id = NULL;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    INSERT INTO users (email, name, created_at)
    VALUES (p_email, p_name, NOW());
    
    SET p_user_id = LAST_INSERT_ID();
    SET p_success = TRUE;
    
    COMMIT;
END
```

### Update with Optimistic Locking
```sql
CREATE PROCEDURE sp_update_user(
    IN p_user_id INT,
    IN p_email VARCHAR(255),
    IN p_version INT,
    OUT p_success BOOLEAN
)
SQL SECURITY INVOKER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = FALSE;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    UPDATE users 
    SET email = p_email, version = version + 1
    WHERE id = p_user_id AND version = p_version;
    
    IF ROW_COUNT() = 0 THEN
        SET p_success = FALSE;
        ROLLBACK;
    ELSE
        SET p_success = TRUE;
        COMMIT;
    END IF;
END
```

### Soft Delete
```sql
CREATE PROCEDURE sp_delete_user(
    IN p_user_id INT,
    OUT p_success BOOLEAN
)
SQL SECURITY INVOKER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = FALSE;
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    UPDATE users 
    SET deleted_at = NOW(), is_active = FALSE
    WHERE id = p_user_id AND deleted_at IS NULL;
    
    SET p_success = (ROW_COUNT() > 0);
    
    COMMIT;
END
```

## Input Validation Pattern
```sql
CREATE PROCEDURE sp_create_order(
    IN p_user_id INT,
    IN p_amount DECIMAL(10,2),
    OUT p_order_id INT
)
SQL SECURITY INVOKER
BEGIN
    -- Input validation
    IF p_user_id IS NULL OR p_user_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid user_id';
    END IF;
    
    IF p_amount IS NULL OR p_amount <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Invalid amount';
    END IF;
    
    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'User not found';
    END IF;
    
    -- Proceed with insert
    INSERT INTO orders (user_id, amount, created_at)
    VALUES (p_user_id, p_amount, NOW());
    
    SET p_order_id = LAST_INSERT_ID();
END
```

## Error Logging Pattern
```sql
CREATE PROCEDURE sp_log_error(
    IN p_procedure_name VARCHAR(255),
    IN p_error_message TEXT,
    IN p_error_code INT
)
SQL SECURITY INVOKER
BEGIN
    INSERT INTO error_logs (
        procedure_name,
        error_message,
        error_code,
        created_at
    ) VALUES (
        p_procedure_name,
        p_error_message,
        p_error_code,
        NOW()
    );
END
```

## Pagination Pattern
```sql
CREATE PROCEDURE sp_get_users_paginated(
    IN p_page INT,
    IN p_page_size INT,
    OUT p_total_count INT
)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_offset INT;
    
    -- Validate inputs
    SET p_page = COALESCE(p_page, 1);
    SET p_page_size = COALESCE(p_page_size, 20);
    SET v_offset = (p_page - 1) * p_page_size;
    
    -- Get total count
    SELECT COUNT(*) INTO p_total_count FROM users WHERE is_active = TRUE;
    
    -- Return paginated results
    SELECT * FROM users 
    WHERE is_active = TRUE
    ORDER BY created_at DESC
    LIMIT p_page_size OFFSET v_offset;
END
```

## Transaction Wrapper Pattern
```sql
CREATE PROCEDURE sp_transfer_funds(
    IN p_from_account INT,
    IN p_to_account INT,
    IN p_amount DECIMAL(10,2),
    OUT p_success BOOLEAN
)
SQL SECURITY INVOKER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET p_success = FALSE;
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Deduct from source
    UPDATE accounts 
    SET balance = balance - p_amount
    WHERE id = p_from_account AND balance >= p_amount;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient funds or account not found';
    END IF;
    
    -- Add to destination
    UPDATE accounts 
    SET balance = balance + p_amount
    WHERE id = p_to_account;
    
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Destination account not found';
    END IF;
    
    COMMIT;
    SET p_success = TRUE;
END
```

## Bulk Insert Pattern
```sql
CREATE PROCEDURE sp_bulk_insert_users(
    IN p_json_data JSON
)
SQL SECURITY INVOKER
BEGIN
    DECLARE i INT DEFAULT 0;
    DECLARE v_count INT;
    
    SET v_count = JSON_LENGTH(p_json_data);
    
    START TRANSACTION;
    
    WHILE i < v_count DO
        INSERT INTO users (email, name)
        VALUES (
            JSON_UNQUOTE(JSON_EXTRACT(p_json_data, CONCAT('$[', i, '].email'))),
            JSON_UNQUOTE(JSON_EXTRACT(p_json_data, CONCAT('$[', i, '].name')))
        );
        SET i = i + 1;
    END WHILE;
    
    COMMIT;
END
```
