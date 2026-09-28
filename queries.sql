-- Northwind Sales Analysis — Business Questions
-- Line revenue = unitPrice * quantity * (1 - discount), using the price actually charged
-- on each order line (order_details.unitPrice), not the current catalogue price.

-- Q1. Top 10 products by revenue
SELECT p.productName,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS revenue
FROM order_details od
JOIN products p ON p.productID = od.productID
GROUP BY p.productName
ORDER BY revenue DESC
LIMIT 10;

-- Q2. Top 10 products by units sold (Northwind has no cost column, so volume replaces margin)
SELECT p.productName, SUM(od.quantity) AS units_sold
FROM order_details od
JOIN products p ON p.productID = od.productID
GROUP BY p.productName
ORDER BY units_sold DESC
LIMIT 10;

-- Q3. Monthly revenue trend
SELECT strftime('%Y-%m', o.orderDate) AS month,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS revenue
FROM orders o
JOIN order_details od ON od.orderID = o.orderID
GROUP BY month
ORDER BY month;

-- Q4. Month-over-month revenue growth % (window function)
WITH monthly AS (
    SELECT strftime('%Y-%m', o.orderDate) AS month,
           SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS revenue
    FROM orders o
    JOIN order_details od ON od.orderID = o.orderID
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 1) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- Q5. Customers with no order in the 90 days before the last order in the dataset (churn-risk list)
WITH last_order AS (
    SELECT customerID, MAX(orderDate) AS last_order_date
    FROM orders
    GROUP BY customerID
),
dataset_end AS (
    SELECT MAX(orderDate) AS max_date FROM orders
)
SELECT c.companyName, c.country, lo.last_order_date
FROM last_order lo
JOIN customers c ON c.customerID = lo.customerID
CROSS JOIN dataset_end d
WHERE julianday(d.max_date) - julianday(lo.last_order_date) > 90
ORDER BY lo.last_order_date;

-- Q6. Average order value by customer country (top 10)
SELECT c.country,
       COUNT(DISTINCT o.orderID) AS orders,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)) / COUNT(DISTINCT o.orderID), 2) AS avg_order_value
FROM orders o
JOIN customers c ON c.customerID = o.customerID
JOIN order_details od ON od.orderID = o.orderID
GROUP BY c.country
ORDER BY avg_order_value DESC
LIMIT 10;

-- Q7. Sales rep performance ranking
SELECT e.firstName || ' ' || e.lastName AS employee,
       e.title,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS revenue,
       RANK() OVER (ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS revenue_rank
FROM orders o
JOIN employees e ON e.employeeID = o.employeeID
JOIN order_details od ON od.orderID = o.orderID
GROUP BY e.employeeID
ORDER BY revenue_rank;

-- Q8. Revenue and share of total by category
SELECT cat.categoryName,
       COUNT(DISTINCT od.orderID) AS orders,
       ROUND(SUM(od.unitPrice * od.quantity * (1 - od.discount)), 2) AS revenue,
       ROUND(100.0 * SUM(od.unitPrice * od.quantity * (1 - od.discount))
             / SUM(SUM(od.unitPrice * od.quantity * (1 - od.discount))) OVER (), 1) AS pct_of_total
FROM order_details od
JOIN products p ON p.productID = od.productID
JOIN categories cat ON cat.categoryID = p.categoryID
GROUP BY cat.categoryName
ORDER BY revenue DESC;

-- Q9. Top 10 customers by spend, with a high-value flag for the top decile
WITH customer_spend AS (
    SELECT c.customerID, c.companyName, c.country,
           SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS total_spend
    FROM customers c
    JOIN orders o ON o.customerID = c.customerID
    JOIN order_details od ON od.orderID = o.orderID
    GROUP BY c.customerID
),
ranked AS (
    SELECT *, PERCENT_RANK() OVER (ORDER BY total_spend) AS pct_rank
    FROM customer_spend
)
SELECT companyName, country, ROUND(total_spend, 2) AS total_spend,
       CASE WHEN pct_rank >= 0.9 THEN 'High Value' ELSE 'Standard' END AS customer_tier
FROM ranked
ORDER BY total_spend DESC
LIMIT 10;

-- Q10. Discount impact by category: share of order lines discounted, and revenue given up to discounts
SELECT cat.categoryName,
       ROUND(100.0 * SUM(CASE WHEN od.discount > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_lines_discounted,
       ROUND(SUM(od.unitPrice * od.quantity * od.discount), 2) AS revenue_given_up
FROM order_details od
JOIN products p ON p.productID = od.productID
JOIN categories cat ON cat.categoryID = p.categoryID
GROUP BY cat.categoryName
ORDER BY revenue_given_up DESC;

-- Q11. Repeat customer rate: share of customers who ordered more than once
SELECT ROUND(100.0 * SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_customer_pct,
       COUNT(*) AS customers_with_orders
FROM (
    SELECT customerID, COUNT(*) AS order_count
    FROM orders
    GROUP BY customerID
);

-- Q12. Best-selling product in each category (RANK with PARTITION BY)
WITH product_sales AS (
    SELECT cat.categoryName, p.productName,
           SUM(od.unitPrice * od.quantity * (1 - od.discount)) AS revenue,
           RANK() OVER (PARTITION BY cat.categoryName
                        ORDER BY SUM(od.unitPrice * od.quantity * (1 - od.discount)) DESC) AS rnk
    FROM order_details od
    JOIN products p ON p.productID = od.productID
    JOIN categories cat ON cat.categoryID = p.categoryID
    GROUP BY cat.categoryName, p.productName
)
SELECT categoryName, productName, ROUND(revenue, 2) AS revenue
FROM product_sales
WHERE rnk = 1
ORDER BY revenue DESC;

-- Q13. Shipper performance: average days from order to shipment, and % of orders shipped after the required date
-- (Northwind records shipment dates, not delivery dates, so 'late' means shipped after the required date.)
SELECT s.companyName AS shipper,
       COUNT(*) AS shipped_orders,
       ROUND(AVG(julianday(o.shippedDate) - julianday(o.orderDate)), 1) AS avg_days_to_ship,
       ROUND(100.0 * SUM(CASE WHEN o.shippedDate > o.requiredDate THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_late
FROM orders o
JOIN shippers s ON s.shipperID = o.shipVia
WHERE o.shippedDate IS NOT NULL
GROUP BY s.companyName
ORDER BY pct_late DESC;
