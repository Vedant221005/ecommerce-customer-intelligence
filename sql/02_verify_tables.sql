
-- E-Commerce Customer Intelligence
-- Step 02: Database Verification

-- 1. Verify that all expected tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


-- 2. Verify row counts for all nine tables
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL
SELECT 'geolocation', COUNT(*) FROM geolocation

UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items

UNION ALL
SELECT 'order_payments', COUNT(*) FROM order_payments

UNION ALL
SELECT 'order_reviews', COUNT(*) FROM order_reviews

UNION ALL
SELECT 'orders', COUNT(*) FROM orders

UNION ALL
SELECT 'product_category_translations', COUNT(*)
FROM product_category_translations

UNION ALL
SELECT 'products', COUNT(*) FROM products

UNION ALL
SELECT 'sellers', COUNT(*) FROM sellers

ORDER BY table_name;


-- 3. Check for duplicate primary keys in important tables
SELECT 'customers' AS table_name,
       COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_keys
FROM customers

UNION ALL
SELECT 'orders',
       COUNT(*) - COUNT(DISTINCT order_id)
FROM orders

UNION ALL
SELECT 'products',
       COUNT(*) - COUNT(DISTINCT product_id)
FROM products

UNION ALL
SELECT 'sellers',
       COUNT(*) - COUNT(DISTINCT seller_id)
FROM sellers;
