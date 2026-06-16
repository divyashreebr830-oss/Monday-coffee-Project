-- Q1 Coffee Consumers Count
SELECT
    city_name,
    ROUND((population * 0.25)/1000000,2) AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

-- Q2 Total Revenue from Coffee Sales (Q4 2023)
SELECT
    SUM(total) AS total_revenue
FROM sales
WHERE YEAR(sale_date)=2023
AND QUARTER(sale_date)=4;

-- Q3 Sales Count for Each Product
SELECT
    p.product_name,
    COUNT(s.sale_id) AS total_orders
FROM products p
LEFT JOIN sales s
ON p.product_id=s.product_id
GROUP BY p.product_name
ORDER BY total_orders DESC;

-- Q4 Average Sales Amount per City
SELECT
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    ROUND(
        SUM(s.total)/COUNT(DISTINCT s.customer_id),2
    ) AS avg_sale_per_customer
FROM sales s
JOIN customers c
ON s.customer_id=c.customer_id
JOIN city ci
ON c.city_id=ci.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

-- Q5 City Population and Coffee Consumers
SELECT
    ct.city_name,
    ct.coffee_consumers,
    cu.unique_customers
FROM
(
    SELECT
        city_name,
        ROUND((population*0.25)/1000000,2) AS coffee_consumers
    FROM city
) ct
JOIN
(
    SELECT
        ci.city_name,
        COUNT(DISTINCT c.customer_id) AS unique_customers
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY ci.city_name
) cu
ON ct.city_name = cu.city_name;

-- Q6 Top 3 Selling Products By City
SELECT *
FROM
(
    SELECT
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER(
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS ranking
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY ci.city_name, p.product_name
) x
WHERE ranking <= 3;

-- Q7 Customer Segmentation By City
SELECT
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_customers
FROM city ci
JOIN customers c
ON ci.city_id=c.city_id
JOIN sales s
ON c.customer_id=s.customer_id
GROUP BY ci.city_name;

-- Q8 Average Sale vs Rent
WITH city_sales AS
(
    SELECT
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)/COUNT(DISTINCT s.customer_id),2
        ) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c
    ON s.customer_id=c.customer_id
    JOIN city ci
    ON c.city_id=ci.city_id
    GROUP BY ci.city_name
)
SELECT
    c.city_name,
    c.estimated_rent,
    cs.total_customers,
    cs.avg_sale_per_customer,
    ROUND(
        c.estimated_rent/cs.total_customers,2
    ) AS avg_rent_per_customer
FROM city c
JOIN city_sales cs
ON c.city_name=cs.city_name;

-- Q9 Monthly Sales Growth
SELECT
    city_name,
    month_no,
    year_no,
    current_month_sales,
    previous_month_sales,
    ROUND(
        ((current_month_sales - previous_month_sales) / previous_month_sales) * 100,
        2
    ) AS growth_percentage
FROM
(
    SELECT
        city_name,
        month_no,
        year_no,
        current_month_sales,
        LAG(current_month_sales) OVER (
            PARTITION BY city_name
            ORDER BY year_no, month_no
        ) AS previous_month_sales
    FROM
    (
        SELECT
            ci.city_name,
            MONTH(s.sale_date) AS month_no,
            YEAR(s.sale_date) AS year_no,
            SUM(s.total) AS current_month_sales
        FROM sales s
        JOIN customers c
            ON s.customer_id = c.customer_id
        JOIN city ci
            ON c.city_id = ci.city_id
        GROUP BY
            ci.city_name,
            YEAR(s.sale_date),
            MONTH(s.sale_date)
    ) monthly_sales
) growth_data
WHERE previous_month_sales IS NOT NULL
ORDER BY city_name, year_no, month_no;

-- Q10 Market Potential Analysis
SELECT
    c.city_name,
    cs.total_revenue,
    c.estimated_rent,
    cs.total_customers,
    ROUND((c.population * 0.25)/1000000,2) AS estimated_coffee_consumers,
    cs.avg_sale_per_customer
FROM city c
JOIN
(
    SELECT
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_customers,
        ROUND(
            SUM(s.total)/COUNT(DISTINCT s.customer_id),2
        ) AS avg_sale_per_customer
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON c.city_id = ci.city_id
    GROUP BY ci.city_name
) cs
ON c.city_name = cs.city_name
ORDER BY total_revenue DESC
LIMIT 3;