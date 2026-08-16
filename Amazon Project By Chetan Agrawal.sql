
##Q1. Find the total number of orders fulfilled by each seller state. 
SELECT 
    s.seller_state,
    COUNT(DISTINCT o.order_id) AS Total_Fullfilled_Orders,
    o.order_status
FROM
    sellers s
        JOIN
    order_items oi USING (seller_id)
        JOIN
    orders o USING (order_id)
GROUP BY s.seller_state , o.order_status
HAVING o.order_status = 'delivered'
ORDER BY COUNT(DISTINCT o.order_id);

##Q2. For each product category, calculate the cumulative revenue generated as orders come in over time. 
SELECT
    p.product_category_name,
    DATE(o.order_purchase_timestamp) AS order_date,
    SUM(oi.price) AS daily_revenue,
    SUM(SUM(oi.price)) OVER(
        PARTITION BY p.product_category_name
        ORDER BY DATE(o.order_purchase_timestamp)
    ) AS cumulative_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name,
         DATE(o.order_purchase_timestamp);
         
##Q3. Which payment method do customers use the most, and what is the average order value for each payment type? 
SELECT 
    payment_type,
    COUNT(payment_type) AS Total_Number_Payment,
    ROUND(AVG(Payment_Value), 2) AS Order_Value
FROM
    order_payments
GROUP BY t
ORDER BY Total_Number_Payment DESC;

##Q4. Find the customer who has spent the most money across all their orders. 
SELECT 
    c.customer_unique_id,
    SUM(op.payment_value) AS Total_Money_Spent
FROM
    customers c
        JOIN
    orders o USING (customer_id)
        JOIN
    order_payments op USING (order_id)
GROUP BY c.customer_unique_id
ORDER BY SUM(op.payment_value) DESC
LIMIT 1;

##Q5. Find the average review score for each product category. 
SELECT 
    pct.product_category_name_english,
    ROUND(AVG(orw.review_score), 2) AS Avg_Review_Score
FROM
    products p
        JOIN
    order_items oi USING (product_id)
        JOIN
    order_reviews orw USING (order_id)
        JOIN
    product_category_name_translation pct ON p.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY AVG(orw.review_score) DESC;

##Q6. Find the total number of orders placed by each customer, broken down by the state they live in. 
SELECT 
    c.customer_unique_id,
    c.customer_state,
    COUNT(o.order_id) AS Total_Order
FROM
    customers c
        JOIN
    orders o USING (customer_id)
GROUP BY customer_unique_id , customer_state
ORDER BY COUNT(o.order_id) DESC;

## Q7. Identify sellers who registered on the platform but have never fulfilled a single order. 
SELECT 
    s.seller_id, s.seller_city, s.seller_state
FROM
    sellers s
        LEFT JOIN
    order_items oi USING (seller_id)
WHERE
    oi.seller_id IS NULL; 
    
##Q8. Find the top 5 product categories by total revenue. 
SELECT 
    pc.product_category_name_english AS Product_Category,
    ROUND(SUM(op.payment_value), 2) AS Total_Revenue
FROM
    product_category_name_translation pc
        JOIN
    products p USING (product_category_name)
        JOIN
    order_items oi USING (product_id)
        JOIN
    order_payments op USING (order_id)
GROUP BY pc.product_category_name_english
ORDER BY SUM(op.payment_value) DESC
LIMIT 5;

##Q9. Find the median delivery time (in days) between order placement and actual delivery. 
WITH delivery_time AS
(
    SELECT
        DATEDIFF(
            order_delivered_customer_date,
            order_purchase_timestamp
        ) AS delivery_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
),
ranked_data AS
(
    SELECT
        delivery_days,
        ROW_NUMBER() OVER(ORDER BY delivery_days) AS rn,
        COUNT(*) OVER() AS total_rows
    FROM delivery_time
)
SELECT AVG(delivery_days) AS median_delivery_days
FROM ranked_data
WHERE rn IN (
    FLOOR((total_rows + 1)/2),
    FLOOR((total_rows + 2)/2)
    );

##Q10. Find all products that have never been ordered. 
SELECT 
    p.product_id, p.product_category_name
FROM
    products p
        LEFT JOIN
    order_items oi USING (product_id)
WHERE
    product_id IS NULL;

##Q11. Find sellers who have fulfilled more orders than the average seller on the platform. 
with ord_cte as 
(
SELECT 
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS Total_Fullfill_Order
FROM
    sellers s
        JOIN
    order_items oi USING (seller_id)
GROUP BY s.seller_id
ORDER BY COUNT(DISTINCT oi.order_id) DESC)
SELECT 
    *
FROM
    ord_cte
WHERE
    Total_Fullfill_Order > (SELECT 
            AVG(Total_Fullfill_Order)
        FROM
            ord_cte);


## 2nd Method.
SELECT 
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS Total_Fullfill_Order
FROM
    sellers s
        JOIN
    order_items oi USING (seller_id)
GROUP BY s.seller_id
HAVING COUNT(DISTINCT oi.order_id) > (SELECT 
        AVG(Total_Order)
    FROM
        (SELECT 
            s.seller_id, COUNT(DISTINCT oi.order_id) AS Total_Order
        FROM
            sellers s
        JOIN order_items oi USING (seller_id)
        GROUP BY s.seller_id) AS Avg_Order)
ORDER BY COUNT(DISTINCT oi.order_id) DESC;


##Q12. Find which Brazilian states have the highest average customer review score for orders delivered there. 
SELECT 
    c.customer_state,
    ROUND(AVG(orv.review_score), 2) AS Average_Review_Score
FROM
    customers c
        JOIN
    orders o USING (customer_id)
        JOIN
    order_reviews orv USING (order_id)
GROUP BY c.customer_state
ORDER BY ROUND(AVG(orv.review_score), 2) DESC;
 
##Q13. Identify customers who have placed orders but never left a review. 
SELECT 
    c.customer_unique_id, orv.review_score
FROM
    customers c
        JOIN
    orders o USING (customer_id)
        LEFT JOIN
    order_reviews orv USING (order_id)
WHERE
    orv.review_score IS NULL;

##Q14. Find the month with the highest number of orders placed across the entire platform. 
SELECT 
    YEAR(order_purchase_timestamp) AS Order_Year,
    MONTHNAME(order_purchase_timestamp) AS Order_Month,
    COUNT(order_id) AS Total_Orders
FROM
    orders
GROUP BY YEAR(order_purchase_timestamp) , MONTHNAME(order_purchase_timestamp)
ORDER BY COUNT(order_id) DESC
LIMIT 1;