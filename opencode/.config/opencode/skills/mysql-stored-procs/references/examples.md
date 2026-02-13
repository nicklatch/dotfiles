# MySQL Stored Procedure Examples

Practical, complete examples for common scenarios.

## Example 1: User Registration with Validation

```sql
DELIMITER $$

CREATE PROCEDURE sp_register_user(
    IN p_email VARCHAR(255),
    IN p_password_hash VARCHAR(255),
    IN p_name VARCHAR(255),
    OUT p_user_id INT,
    OUT p_success BOOLEAN,
    OUT p_message VARCHAR(255)
)
SQL SECURITY INVOKER
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE, 
            @errno = MYSQL_ERRNO, 
            @text = MESSAGE_TEXT;
        
        SET p_success = FALSE;
        SET p_user_id = NULL;
        SET p_message = @text;
        ROLLBACK;
    END;
    
    -- Validate email format
    IF p_email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SET p_success = FALSE;
        SET p_message = 'Invalid email format';
        SET p_user_id = NULL;
    ELSEIF LENGTH(p_password_hash) < 60 THEN
        SET p_success = FALSE;
        SET p_message = 'Invalid password hash';
        SET p_user_id = NULL;
    ELSEIF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SET p_success = FALSE;
        SET p_message = 'Email already registered';
        SET p_user_id = NULL;
    ELSE
        START TRANSACTION;
        
        INSERT INTO users (email, password_hash, name, created_at, is_active)
        VALUES (p_email, p_password_hash, p_name, NOW(), TRUE);
        
        SET p_user_id = LAST_INSERT_ID();
        SET p_success = TRUE;
        SET p_message = 'User registered successfully';
        
        COMMIT;
    END IF;
END$$

DELIMITER ;
```

## Example 2: Search with Dynamic Filters

```sql
DELIMITER $$

CREATE PROCEDURE sp_search_products(
    IN p_category_id INT,
    IN p_min_price DECIMAL(10,2),
    IN p_max_price DECIMAL(10,2),
    IN p_search_term VARCHAR(255),
    IN p_sort_by VARCHAR(50),
    IN p_page INT,
    IN p_page_size INT
)
SQL SECURITY INVOKER
BEGIN
    SET @sql = 'SELECT p.*, c.name as category_name 
                FROM products p
                JOIN categories c ON p.category_id = c.id
                WHERE 1=1';
    
    IF p_category_id IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.category_id = ', p_category_id);
    END IF;
    
    IF p_min_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.price >= ', p_min_price);
    END IF;
    
    IF p_max_price IS NOT NULL THEN
        SET @sql = CONCAT(@sql, ' AND p.price <= ', p_max_price);
    END IF;
    
    IF p_search_term IS NOT NULL AND p_search_term != '' THEN
        SET @sql = CONCAT(@sql, ' AND (p.name LIKE ''%', p_search_term, '%'' 
                     OR p.description LIKE ''%', p_search_term, '%'')');
    END IF;
    
    -- Sorting
    SET @sql = CONCAT(@sql, ' ORDER BY ', 
        CASE p_sort_by
            WHEN 'price_asc' THEN 'p.price ASC'
            WHEN 'price_desc' THEN 'p.price DESC'
            WHEN 'name' THEN 'p.name ASC'
            ELSE 'p.created_at DESC'
        END);
    
    -- Pagination
    SET @offset = (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
    SET @sql = CONCAT(@sql, ' LIMIT ', COALESCE(p_page_size, 20), 
                      ' OFFSET ', @offset);
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$$

DELIMITER ;
```

## Example 3: Audit Logging Trigger

```sql
DELIMITER $$

CREATE TRIGGER tr_users_audit_update
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    IF OLD.email != NEW.email OR OLD.name != NEW.name THEN
        INSERT INTO audit_log (
            table_name,
            record_id,
            action,
            old_values,
            new_values,
            changed_at
        ) VALUES (
            'users',
            NEW.id,
            'UPDATE',
            JSON_OBJECT('email', OLD.email, 'name', OLD.name),
            JSON_OBJECT('email', NEW.email, 'name', NEW.name),
            NOW()
        );
    END IF;
END$$

DELIMITER ;
```

## Example 4: Batch Processing with Cursor

```sql
DELIMITER $$

CREATE PROCEDURE sp_process_pending_orders()
SQL SECURITY INVOKER
BEGIN
    DECLARE v_order_id INT;
    DECLARE v_user_id INT;
    DECLARE v_amount DECIMAL(10,2);
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE processed_count INT DEFAULT 0;
    DECLARE error_count INT DEFAULT 0;
    
    DECLARE order_cursor CURSOR FOR
        SELECT id, user_id, amount 
        FROM orders 
        WHERE status = 'pending' 
        AND created_at < DATE_SUB(NOW(), INTERVAL 1 HOUR)
        LIMIT 100;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        SET error_count = error_count + 1;
        -- Log error but continue processing
        INSERT INTO processing_errors (order_id, error_time, error_message)
        VALUES (v_order_id, NOW(), 'Processing failed');
    END;
    
    OPEN order_cursor;
    
    read_loop: LOOP
        FETCH order_cursor INTO v_order_id, v_user_id, v_amount;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Process each order
        UPDATE orders 
        SET status = 'processing', processed_at = NOW()
        WHERE id = v_order_id;
        
        -- Call another procedure or perform business logic
        -- CALL sp_process_single_order(v_order_id);
        
        SET processed_count = processed_count + 1;
    END LOOP;
    
    CLOSE order_cursor;
    
    -- Return summary
    SELECT processed_count, error_count;
END$$

DELIMITER ;
```

## Example 5: Function for Calculations

```sql
DELIMITER $$

CREATE FUNCTION fn_calculate_order_total(
    p_order_id INT
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
SQL SECURITY INVOKER
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(quantity * unit_price), 0)
    INTO v_total
    FROM order_items
    WHERE order_id = p_order_id;
    
    RETURN v_total;
END$$

DELIMITER ;
```

## Example 6: Complex Transaction with Rollback Points

```sql
DELIMITER $$

CREATE PROCEDURE sp_create_order_with_items(
    IN p_user_id INT,
    IN p_items JSON,
    OUT p_order_id INT,
    OUT p_success BOOLEAN
)
SQL SECURITY INVOKER
BEGIN
    DECLARE v_item_count INT;
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    DECLARE i INT DEFAULT 0;
    DECLARE v_product_id INT;
    DECLARE v_quantity INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_stock INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = FALSE;
        SET p_order_id = NULL;
        RESIGNAL;
    END;
    
    SET v_item_count = JSON_LENGTH(p_items);
    
    IF v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order must contain at least one item';
    END IF;
    
    START TRANSACTION;
    
    -- Create order header
    INSERT INTO orders (user_id, status, total, created_at)
    VALUES (p_user_id, 'pending', 0, NOW());
    
    SET p_order_id = LAST_INSERT_ID();
    
    -- Process each item
    WHILE i < v_item_count DO
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', i, '].product_id')));
        SET v_quantity = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', i, '].quantity')));
        
        -- Check stock
        SELECT price, stock_quantity 
        INTO v_price, v_stock
        FROM products 
        WHERE id = v_product_id FOR UPDATE;
        
        IF v_stock < v_quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = CONCAT('Insufficient stock for product ', v_product_id);
        END IF;
        
        -- Add order item
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (p_order_id, v_product_id, v_quantity, v_price);
        
        -- Update stock
        UPDATE products 
        SET stock_quantity = stock_quantity - v_quantity
        WHERE id = v_product_id;
        
        SET v_total = v_total + (v_quantity * v_price);
        SET i = i + 1;
    END WHILE;
    
    -- Update order total
    UPDATE orders SET total = v_total WHERE id = p_order_id;
    
    COMMIT;
    SET p_success = TRUE;
END$$

DELIMITER ;
```

## Usage Examples

```sql
-- Register a user
CALL sp_register_user(
    'john@example.com', 
    '$2y$10$...', 
    'John Doe',
    @user_id, 
    @success, 
    @message
);
SELECT @user_id, @success, @message;

-- Search products
CALL sp_search_products(1, 10.00, 100.00, 'laptop', 'price_asc', 1, 20);

-- Calculate order total
SELECT fn_calculate_order_total(123) as total;
```
