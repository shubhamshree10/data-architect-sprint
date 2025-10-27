# SQL Notes

## Common Table Expressions (CTEs) - The `WITH` Clause

**Purpose:** Break down complex queries into logical, named steps for readability and organization. Acts like a temporary table for a single query.

**Basic Syntax:**
```sql
WITH Step1_TableName AS (
    SELECT ...
    FROM ...
    WHERE ...
), -- Comma separates CTEs
Step2_TableName AS (
    SELECT ...
    FROM Step1_TableName -- Can refer to previous CTEs
    JOIN ...
)
-- Final query using the CTEs
SELECT *
FROM Step2_TableName
WHERE ...;