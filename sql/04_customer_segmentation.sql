
-- ============================================================
-- E-Commerce Customer Intelligence
-- File: 04_customer_segmentation.sql
-- Database: ecommerce_analytics
-- Dataset: Olist Brazilian E-Commerce
-- ============================================================


-- 1. Order Status Analysis
-- Understand the distribution of order statuses.

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS order_percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- 2. Overall Business Performance
-- Calculate delivered orders, customers, revenue and AOV.

SELECT
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales,
    ROUND(
        SUM(oi.price + oi.freight_value)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';


-- 3. Monthly Sales and Delivery Trend
-- Track delivered orders and revenue by month.

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp)::DATE
        AS sales_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
ORDER BY sales_month;


-- 4. Delivery Performance and Review Analysis
-- Compare delivery timeliness with customer review scores.

SELECT
    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Delivery Date Missing'
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
            THEN 'On Time or Early'
        ELSE 'Late'
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.order_delivered_customer_date
                    - o.order_purchase_timestamp
                )
            ) / 86400.0
        )::NUMERIC,
        2
    ) AS avg_delivery_days,
    ROUND(AVG(r.review_score)::NUMERIC, 2)
        AS avg_review_score
FROM orders o
LEFT JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    CASE
        WHEN o.order_delivered_customer_date IS NULL
            THEN 'Delivery Date Missing'
        WHEN o.order_delivered_customer_date
             <= o.order_estimated_delivery_date
            THEN 'On Time or Early'
        ELSE 'Late'
    END
ORDER BY total_orders DESC;


-- 5. Repeat Customer Analysis
-- Identify one-time and repeat customers using customer_unique_id.

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE order_count = 1)
        AS one_time_customers,
    COUNT(*) FILTER (WHERE order_count > 1)
        AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_count > 1)
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage
FROM customer_orders;


-- 6. Customer Review Score Distribution
-- Understand how customers rate delivered orders.

SELECT
    r.review_score,
    COUNT(*) AS total_reviews,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY r.review_score DESC;


-- 7. Customer RFM Analysis
-- Calculate Recency, Frequency and Monetary value.
-- Recency is measured against the latest purchase timestamp
-- available in the dataset, not today's date.

WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS max_date
    FROM orders
    WHERE order_status = 'delivered'
),
customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE AS last_order_date,
        (SELECT max_date FROM reference_date)
          - MAX(o.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    customer_unique_id,
    last_order_date,
    recency_days,
    frequency,
    monetary,
    NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
FROM customer_rfm
ORDER BY monetary DESC;


-- 8. Customer Segmentation Using RFM Scores
-- Assign customers to actionable segments and summarize them.

WITH reference_date AS (
    SELECT MAX(order_purchase_timestamp)::DATE AS max_date
    FROM orders
    WHERE order_status = 'delivered'
),
customer_rfm AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)::DATE AS last_order_date,
        (SELECT max_date FROM reference_date)
          - MAX(o.order_purchase_timestamp)::DATE AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price + oi.freight_value), 2) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS monetary_score
    FROM customer_rfm
),
segments AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'High-Value Loyal Customers'
            WHEN recency_score >= 4
                 AND monetary_score >= 4
                THEN 'Recent High-Value'
            WHEN recency_score <= 2
                 AND frequency_score >= 4
                THEN 'At-Risk Loyal Customers'
            WHEN recency_score <= 2
                 AND frequency_score <= 2
                THEN 'Hibernating Customers'
            WHEN recency_score >= 4
                 AND frequency_score <= 2
                THEN 'Recent Customers'
            WHEN frequency_score >= 4
                THEN 'Loyal Customers'
            ELSE 'Regular Customers'
        END AS customer_segment
    FROM rfm_scores
)
SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(AVG(monetary), 2) AS avg_customer_spend
FROM segments
GROUP BY customer_segment
ORDER BY customer_count DESC;
