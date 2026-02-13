---
name: mysql-stored-procs
description: Create MySQL stored procedures with proper syntax, error handling, and security. Use when writing or reviewing stored procedures, functions, or triggers in MySQL.
---

# MySQL Stored Procedures

Guidelines for creating robust, secure, and maintainable MySQL stored routines.

## Quick Decision Tree

```
What do you need to create?
├─ Reusable calculation → FUNCTION (returns single value)
├─ Multi-step operation → PROCEDURE (can return result sets)
├─ Auto-execute on data change → TRIGGER
└─ Scheduled task → EVENT (calls procedure)
```

## Core Principles

1. **Security First**
   - Use SQL SECURITY INVOKER (default)
   - Validate all inputs
   - Never concatenate user input into SQL
   - Grant minimal permissions

2. **Error Handling**
   - Always declare handlers for expected errors
   - Use SIGNAL for custom error conditions
   - Log errors when appropriate

3. **Performance**
   - Avoid cursors when possible
   - Use indexes effectively
   - Keep transactions short
   - Consider query cache implications

## Reading Order

| Task | Read |
|------|------|
| Syntax reference | references/syntax.md |
| Design patterns | references/patterns.md |
| Working examples | references/examples.md |

## Quick Checklist

Before creating a procedure:
- [ ] Input parameters validated
- [ ] Error handlers declared
- [ ] Transaction boundaries defined
- [ ] SQL injection prevented
- [ ] Return values documented

## Common Patterns

### Basic Structure
```sql
DELIMITER $$

CREATE PROCEDURE sp_name(IN param_name TYPE)
SQL SECURITY INVOKER
BEGIN
    -- Variable declarations
    DECLARE var_name TYPE DEFAULT value;
    
    -- Error handler
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Logic here
END$$

DELIMITER ;
```

### Naming Conventions
- Procedures: `sp_<action>_<entity>` (e.g., `sp_get_user`, `sp_create_order`)
- Functions: `fn_<calculation>` (e.g., `fn_calculate_tax`)
- Triggers: `tr_<table>_<action>` (e.g., `tr_users_insert`)

## See Also
- [MySQL Stored Procedure Reference](https://dev.mysql.com/doc/refman/8.0/en/stored-programs-defining.html)
