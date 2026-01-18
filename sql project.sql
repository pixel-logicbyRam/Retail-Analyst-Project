CREATE TABLE dim_customer (
    customer_key INT PRIMARY KEY,
    customer_id TEXT,
    customer_name TEXT,
    city TEXT,
    state TEXT
);
CREATE TABLE dim_product (
    product_key INT PRIMARY KEY,
    product_name TEXT,
    category TEXT,
    subcategory TEXT,
    price NUMERIC
);
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    date DATE,
    month TEXT,
    quarter TEXT,
    year INT
);

CREATE TABLE fact_sales (
    transaction_id TEXT,
    date_key INT,
    customer_key INT,
    product_key INT,
    quantity INT,
    sales_amount NUMERIC
);

-----Total Sales-----------

SELECT SUM(sales_amount) AS total_revenue
FROM fact_sales;


---Top 10 Customers by Revenue----

SELECT
    f.transaction_id,
    d.date,
    c.customer_name,
    p.product_name,
    f.quantity,
    f.sales_amount
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
JOIN dim_product p ON f.product_key = p.product_key
JOIN dim_date d ON f.date_key = d.date_key
LIMIT 10;

----Top Products-----

SELECT SUM(sales_amount) AS total_sales
FROM fact_sales;
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;

--Monthly Sales Trend--------

SELECT
    d.year,
    d.month,
    SUM(f.sales_amount) AS total_sales
FROM fact_sales f
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

---RFM Base Table------

CREATE TEMP TABLE rfm_base AS
SELECT
    c.customer_id,
    MAX(d.date) AS last_purchase_date,
    CURRENT_DATE - MAX(d.date) AS recency,
    COUNT(f.transaction_id) AS frequency,
    SUM(f.sales_amount) AS monetary
FROM fact_sales f
JOIN dim_customer c ON f.customer_key = c.customer_key
JOIN dim_date d ON f.date_key = d.date_key
GROUP BY c.customer_id;

----RFM Scoring (1–5)-------

SELECT
    *,
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency) AS f_score,
    NTILE(5) OVER (ORDER BY monetary) AS m_score
FROM rfm_base;

--RFM Segments--------------------
SELECT
    *,
    CASE
        WHEN r_score = 5 AND f_score = 5 AND m_score = 5 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal'
        WHEN r_score <= 2 THEN 'At Risk'
        ELSE 'Regular'
    END AS segment
FROM (
    SELECT
        *,
        NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM rfm_base
) t;

