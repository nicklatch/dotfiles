# MySQL Stored Procedure Syntax

Complete syntax reference for stored routines.

## CREATE PROCEDURE

```sql
CREATE PROCEDURE sp_name(
    [IN | OUT | INOUT] param_name data_type,
    ...
)
[SQL SECURITY {DEFINER | INVOKER}]
BEGIN
    -- procedure body
END
```

## CREATE FUNCTION

```sql
CREATE FUNCTION fn_name(
    param_name data_type,
    ...
)
RETURNS return_type
[DETERMINISTIC | NO SQL | READS SQL DATA | MODIFIES SQL DATA]
[SQL SECURITY {DEFINER | INVOKER}]
BEGIN
    -- function body
    RETURN value;
END
```

## Parameter Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| IN | Read-only input (default) | Passing values to procedure |
| OUT | Output only | Returning single values |
| INOUT | Input and output | Modifying passed values |

## Variable Declaration

```sql
DECLARE var_name data_type [DEFAULT value];
DECLARE var_name data_type DEFAULT value;

-- Examples
DECLARE user_count INT DEFAULT 0;
DECLARE user_name VARCHAR(255);
DECLARE done BOOLEAN DEFAULT FALSE;
```

## Control Flow

### IF Statement
```sql
IF condition THEN
    -- statements
ELSEIF condition THEN
    -- statements
ELSE
    -- statements
END IF;
```

### CASE Statement
```sql
CASE expression
    WHEN value1 THEN statements;
    WHEN value2 THEN statements;
    ELSE statements;
END CASE;

-- Or
CASE
    WHEN condition1 THEN statements;
    WHEN condition2 THEN statements;
    ELSE statements;
END CASE;
```

### Loops
```sql
-- Simple LOOP
label: LOOP
    -- statements
    IF condition THEN
        LEAVE label;
    END IF;
END LOOP label;

-- WHILE
WHILE condition DO
    -- statements
END WHILE;

-- REPEAT
REPEAT
    -- statements
UNTIL condition END REPEAT;
```

## Error Handling

### DECLARE HANDLER
```sql
DECLARE handler_type HANDLER FOR condition_value [, ...] statement;

-- Handler types
CONTINUE  -- Continue execution after handler
EXIT      -- Exit current block after handler
UNDO      -- Not supported in MySQL

-- Condition values
SQLEXCEPTION          -- Any SQL exception
SQLWARNING            -- Any SQL warning
NOT FOUND             -- No rows found
error_code            -- Specific error code (e.g., 1062)
SQLSTATE 'value'      -- SQLSTATE value
condition_name        -- Named condition
```

### SIGNAL
```sql
SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Custom error message',
        MYSQL_ERRNO = 10001;
```

## Cursors

```sql
-- Declare
DECLARE cursor_name CURSOR FOR select_statement;

-- Handler for cursor end
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

-- Open, fetch, close
OPEN cursor_name;
FETCH cursor_name INTO var1, var2, ...;
CLOSE cursor_name;
```

## Transactions

```sql
START TRANSACTION;
-- or
BEGIN;

-- operations

COMMIT;
-- or
ROLLBACK;
```

## Dynamic SQL (Prepared Statements)

```sql
SET @sql = 'SELECT * FROM users WHERE id = ?';
PREPARE stmt FROM @sql;
SET @id = 1;
EXECUTE stmt USING @id;
DEALLOCATE PREPARE stmt;
```

## Privileges Required

```sql
-- To create
GRANT CREATE ROUTINE ON database.* TO 'user'@'host';

-- To execute
GRANT EXECUTE ON database.* TO 'user'@'host';

-- To grant execute to others (with DEFINER)
GRANT GRANT OPTION ON database.* TO 'user'@'host';
```
