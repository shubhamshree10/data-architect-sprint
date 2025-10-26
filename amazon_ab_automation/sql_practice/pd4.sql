
-----

### \#\# 🪂 Parachute Drop \#4: The Nightmare Report

**Your Situation:**
You've just been pulled onto the "Customer Retention" task force. You've been given the main query
 that generates the weekly "At-Risk Customer" report. It's a mess. 
 The Head of Retention just gave you three new, non-negotiable requirements that need to be 
 implemented for a meeting tomorrow morning.

**Your Task:**
Modify the legacy query. Do not rewrite it; modify it.

-----

### \#\# The "Battlefield" (The Schema)

  * **`customers`**: `customer_id` (INT), `join_date` (DATE), `segment` (VARCHAR), `region_id` (INT)
  * **`regions`**: `region_id` (INT), `region_name` (VARCHAR), `country` (VARCHAR)
  * **`orders`**: `order_id` (INT), `customer_id` (INT), `order_date` (DATE), `status` (VARCHAR - 'Completed', 'Shipped', 'Cancelled'), `shipping_cost` (DECIMAL)
  * **`order_items`**: `order_item_id` (INT), `order_id` (INT), `product_id` (INT), `quantity` (INT), `price` (DECIMAL)
  * **`products`**: `product_id` (INT), `category` (VARCHAR)
  * **`promotions`**: `promo_id` (INT), `promo_code` (VARCHAR), `discount_percent` (INT)
  * **`order_promotions`**: `order_id` (INT), `promo_id` (INT)

-----

### \#\# The "Legacy Code" (The Beast)

```sql
WITH cust_base AS (
  SELECT 
    c.customer_id, 
    c.join_date, 
    c.segment, 
    r.region_name, 
    r.country 
  FROM customers c 
  JOIN regions r ON c.region_id = r.region_id
), 
order_base AS (
  SELECT 
    order_id, 
    customer_id, 
    order_date, 
    status 
  FROM orders 
  WHERE EXTRACT(YEAR FROM order_date) >= 2024
), 
agg_items AS (
  SELECT 
    oi.order_id, 
    SUM(oi.quantity * oi.price) AS total_order_value, 
    STRING_AGG(p.category, ', ') AS distinct_categories 
  FROM order_items oi 
  JOIN products p ON oi.product_id = p.product_id 
  GROUP BY 1
), 
customer_kpis AS (
  SELECT 
    b.customer_id, 
    SUM(ai.total_order_value) AS total_spent_2024, 
    MAX(b.order_date) AS last_order_date, 
    COUNT(b.order_id) AS total_orders_2024, 
    SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders 
  FROM order_base b 
  JOIN agg_items ai ON b.order_id = ai.order_id 
  WHERE b.status IN ('Completed', 'Shipped', 'Cancelled') 
  GROUP BY 
    b.customer_id
), 
final_data AS (
  SELECT 
    cb.customer_id, 
    cb.segment, 
    cb.country, 
    cb.join_date, 
    k.total_spent_2024, 
    k.last_order_date, 
    (DATE '2025-01-01' - k.last_order_date) AS days_since_last_order, 
    k.total_orders_2024, 
    k.cancelled_orders 
  FROM cust_base cb 
  LEFT JOIN customer_kpis k ON cb.customer_id = k.customer_id
  WHERE cb.country = 'USA'
) 
SELECT 
  fd.*, 
  CASE 
    WHEN fd.days_since_last_order > 90 THEN 'High_Risk' 
    WHEN fd.cancelled_orders > fd.total_orders_2024 / 2 THEN 'High_Risk' 
    WHEN fd.days_since_last_order > 60 THEN 'Medium_Risk' 
    ELSE 'Low_Risk' 
  END AS at_risk_flag 
FROM final_data fd 
WHERE 
  fd.total_spent_2024 > 0 
ORDER BY 
  fd.total_spent_2024 DESC;
```

-----

### \#\# Your "Urgent" Mission (The New Requirements)

1.  **Region Fix:** The `WHERE cb.country = 'USA'`
 filter is wrong. It's missing a key market. 
 It needs to be for customers in **'USA' OR 'Canada'**.
2.  **New Risk Flag Logic:** The `at_risk_flag` logic is 
too simple. The business has a new definition: 
A customer is **also** considered 'High\_Risk' 
if their `distinct_categories` (from the `agg_items` CTE) 
**ONLY** contains 'Electronics' AND they have placed **zero 
'Completed' orders** in the last 6 months (i.e., since '2024-06-01').
 This new rule must be added to the `CASE` statement.
3.  **New Data Point:** We need to add the `promo_code` 
they used on their **most recent order** (by `order_date`).
 If they used multiple promos on that one order, just pick one. 
 If they used no promo, it should be NULL.

You have to find the right places to modify this beast, join in new tables, and alter the core logic without breaking the rest of the report.

WITH cust_base AS (

  SELECT 

    c.customer_id, 

    c.join_date, 

    c.segment, 

    r.region_name, 

    r.country 

  FROM customers c 

  JOIN regions r ON c.region_id = r.region_id

), 

order_base AS (

  SELECT 

    order_id, 

    customer_id, 

    order_date, 

    status 

  FROM orders 

  WHERE EXTRACT(YEAR FROM order_date) >= 2024

), 

agg_items AS (

  SELECT 

    oi.order_id, 

    SUM(oi.quantity * oi.price) AS total_order_value, 

    STRING_AGG(p.category, ', ') AS distinct_categories 

  FROM order_items oi 

  JOIN products p ON oi.product_id = p.product_id 

  GROUP BY 1

), 

customer_kpis AS (

  SELECT 

    b.customer_id, 
    ai.distinct_categories

    SUM(ai.total_order_value) AS total_spent_2024, 

    MAX(b.order_date) AS last_order_date, 
     (Select MAX(b.order_date) WHERE b.status = 'Completed') AS last_completed_order_date, 

    COUNT(b.order_id) AS total_orders_2024, 

    SUM(CASE WHEN b.status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_orders 

  FROM order_base b 

  JOIN agg_items ai ON b.order_id = ai.order_id 

  WHERE b.status IN ('Completed', 'Shipped', 'Cancelled') 

  GROUP BY 

    b.customer_id, ai.distinct_categories

), 

final_data AS (

  SELECT 

    cb.customer_id, 

    cb.segment, 

    cb.country, 

    cb.join_date, 

    k.total_spent_2024, 

    k.last_order_date, 

    (DATE '2025-01-01' - k.last_order_date) AS days_since_last_order, 
    (DATE '2025-01-01' - k.last_completed_order_date) AS days_since_last_completed_order, 

    k.total_orders_2024, 

    k.cancelled_orders ,
    k.distinct_categories
  FROM cust_base cb 

  LEFT JOIN customer_kpis k ON cb.customer_id = k.customer_id

  WHERE cb.country IN ( 'USA', 'Canada') 

) 

SELECT 

  fd.*, 
  
  CASE 

    WHEN (fd.days_since_last_order > 90 AND fd.days_since_last_completed_order >180 AND distinct_categories='Electronics') THEN 'High_Risk' 

    WHEN fd.cancelled_orders > fd.total_orders_2024 / 2 THEN 'High_Risk' 

    WHEN fd.days_since_last_order > 60 THEN 'Medium_Risk' 

    ELSE 'Low_Risk' 

  END AS at_risk_flag ,
  TOP 1 P.promo_code

FROM final_data fd 
LEFT JOIN orders o 
ON fd.customer_id = o.customer_id
LEFT JOIN order_promotions  op 
ON o.order_id = op.order_id
LEFT JOIN promotions p
ON op.promo_id = p.promo_id 
 

WHERE 

  fd.total_spent_2024 > 0 

ORDER BY 

  fd.total_spent_2024 DESC;