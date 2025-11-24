SELECT *
FROM customers;

SELECT *
FROM categories; --category_id, category_name, description, and picture--

SELECT *
FROM customer_customer_demo; --empty--

SELECT *
FROM customer_demographics; --empty-- 

SELECT *
FROM customers; -- customer_id, company_name, contact_name, contact_title, address, city, region, postal_code, country, phone, and fax,

SELECT *
FROM employee_territories; --employee_id, territory_id--

SELECT *
FROM employees; 
--employee_id, last_name, first_name, title, title_od_courtesy, birth,--
--date, hire_date, address, city, region, postal_code, country, home_phone, extension, photo, notes, reports_to, and photo_path--

SELECT *
FROM order_details; -- order_id, product_id, unit_price, quantity, and discount--
    

SELECT *
FROM orders; 
--order_id, customer_id, employee_id, order_date, require_date, shipped_date, ship_via, freight, ship_name, ship_address,ship_city, ship_region, ship_postal_code, ship_country--

SELECT *
FROM products --product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, units_in_stock, units_on_order, reorder_level, and discontinued--
WHERE product_id = 1

SELECT *
FROM region;--region_id, and region_description--

SELECT *
FROM shippers;--shiiper_id, company_name, and phone--

SELECT *
FROM suppliers;--supplier_id, company_name, contact_name, contact_title, address, city, region, post_code, country, phone, fax, and homepage--

SELECT *
FROM territories; --territory_id, territory_description, and region_id--

SELECT *
FROM us_states; --state_id, state_name, state_abbrevation, and state_region --


--1: What are the monthly total sales (revenue) for each year?--
CREATE VIEW V_Monthly_Revenue AS
SELECT 
    DATE_PART('year', o.order_date) AS ORDER_YEAR,
    DATE_PART('month', o.order_date) AS ORDER_MONTH,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_REVENUE 
FROM orders AS o
INNER JOIN order_details AS od
    ON od.order_id = o.order_id
GROUP BY 
    ORDER_YEAR, ORDER_MONTH
ORDER BY
     ORDER_YEAR, ORDER_MONTH;

--2: Who are the 10 customers with the highest total spending?--
CREATE VIEW V_Top_Customers_by_Spending AS
SELECT 
    c.customer_id,
    c.company_name,
    COUNT(DISTINCT o.order_id) AS ORDER_COUNT,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_SPENDING
FROM customers AS c
INNER JOIN orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_spending DESC
LIMIT 10;

--3: Which product categories are bringing in the most revenue?--
CREATE VIEW V_Top_Categories_by_Revenue AS
SELECT
    c.category_name,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_REVENUE
FROM products AS p
INNER JOIN categories AS c
    ON p.category_id = c.category_id
INNER JOIN order_details AS od
    ON p.product_id = od.product_id
GROUP BY c.category_name
ORDER BY TOTAL_REVENUE DESC;

--4: Which product has overall the highest number of units sold?--
CREATE VIEW V_Top_Products_by_Units_Sold AS
SELECT 
    p.product_name,
    p.product_id,
    SUM(od.quantity) AS TOTAL_UNITS_SOLD 
FROM products AS p
INNER JOIN order_details AS od
        ON od.product_id = p.product_id
GROUP BY p.product_name, p.product_id
ORDER BY TOTAL_UNITS_SOLD DESC;

--5: Who are the employees with the most sales?--
CREATE VIEW V_Top_Employees_by_Sales AS
SELECT
    e.employee_id,
    e.first_name || ' ' || e.last_name AS EMPLOYEE_NAME,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOP_SALES_BY_EMPLOYEE
FROM employees AS e
INNER JOIN orders AS o  
    ON e.employee_id = o.employee_id
INNER JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY 
    e.employee_id,
    EMPLOYEE_NAME
ORDER BY TOP_SALES_BY_EMPLOYEE DESC;

--6: What is the annual average order value (AOV) for each year?--
CREATE VIEW V_Annual_Average_Order_Value AS
SELECT
    DATE_PART('year', o.order_date) AS YEAR,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) / COUNT(od.order_id) AS AVG_ORDER_VALUE
FROM order_details AS od
INNER JOIN orders AS o 
    ON od.order_id = o.order_id
GROUP BY YEAR
ORDER BY YEAR;

--7: Which supplier's products account for the highest share of total revenue?--
CREATE VIEW V_Supplier_Revenue_Summary AS
SELECT 
    s.company_name AS SUPPLIER_COMPANY_NAME,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS REVENUE
FROM products AS p 
INNER JOIN suppliers AS s
    ON s.supplier_id = p.supplier_id
INNER JOIN order_details AS od
    ON od.product_id = p.product_id
GROUP BY SUPPLIER_COMPANY_NAME
ORDER BY REVENUE DESC;

--8: What is the average shipping time, per carrier?--
CREATE VIEW V_Average_Shipping_Time_by_Shipper AS
SELECT 
    sh.company_name AS SHIPPER_NAME,
    AVG(o.shipped_date - o.order_date) AS AVG_SHIPPING_DAYS
FROM orders AS o
INNER JOIN shippers AS sh
    ON o.ship_via = sh.shipper_id
WHERE o.shipped_date IS NOT NULL    
GROUP BY sh.company_name
ORDER BY AVG_SHIPPING_DAYS;

--9: Which items are low on stock yet are in high demand?--
CREATE VIEW V_High_Demand_Low_Stock_Products AS
SELECT 
    p.product_name,
    p.units_in_stock,
    SUM(od.quantity) AS DEMAND
FROM products AS p
INNER JOIN order_details AS od
    ON p.product_id = od.product_id
GROUP BY 
    p.product_name,
    p.units_in_stock
HAVING 
    p.units_in_stock < 20       
    AND SUM(od.quantity) > 30   
ORDER BY 
    DEMAND DESC;

--10: What is the proportion of total revenue by country?--
CREATE VIEW V_Country_Revenue_Share AS
WITH COUNTRY_REVENUE AS (
    SELECT
        c.country AS COUNTRY,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_REVENUE
    FROM customers  AS c
    INNER JOIN orders AS o
        ON o.customer_id = c.customer_id
    INNER JOIN order_details AS od
        ON o.order_id = od.order_id
    GROUP BY COUNTRY
)
SELECT
    COUNTRY,
    TOTAL_REVENUE,
    ROUND(
        CAST(TOTAL_REVENUE * 100 / SUM(TOTAL_REVENUE) OVER() AS numeric), 2) AS REVENUE_PERCENTAGE
FROM COUNTRY_REVENUE
ORDER BY REVENUE_PERCENTAGE DESC;


--11: What are the top 5 most profitable orders (after discounts have been applied)?--
CREATE VIEW V_Top_Orders_by_Profit AS
SELECT
    o.order_id,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_PROFIT
FROM orders AS o
INNER JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY o.order_id
ORDER BY TOTAL_PROFIT DESC;

--12: Which customers have the biggest increase or decrease in spending from year to year?--
CREATE VIEW V_Customer_YOY_Spending AS
WITH CUSTOMER_YEARLY_SPENDING AS (
    SELECT 
        c.customer_id,
        DATE_PART('year', o.order_date) AS YEAR,
        c.company_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_SPENDING
        FROM customers AS c
        INNER JOIN orders AS o
            ON c.customer_id = o.customer_id
        INNER JOIN order_details AS od
            ON o.order_id = od.order_id
        GROUP BY 
            c.customer_id,
            c.company_name,
            YEAR
),
CUSTOMER_YEAR_OVER_YEAR AS (
    SELECT
        customer_id,
        company_name,
        YEAR,
        TOTAL_SPENDING,
        LAG(TOTAL_SPENDING) OVER (PARTITION BY customer_id ORDER BY YEAR) AS PREVIOUS_YEAR_SPENDING
    FROM CUSTOMER_YEARLY_SPENDING
)
SELECT
    customer_id,
    company_name,
    year,
    TOTAL_SPENDING,
    PREVIOUS_YEAR_SPENDING,
    TOTAL_SPENDING - COALESCE(PREVIOUS_YEAR_SPENDING, 0) AS YOY_CHANGE
FROM CUSTOMER_YEAR_OVER_YEAR
WHERE PREVIOUS_YEAR_SPENDING IS NOT NULL     
ORDER BY ABS(TOTAL_SPENDING - PREVIOUS_YEAR_SPENDING) DESC;


--13: Which regions are the ones with the highest revenue?--
CREATE VIEW V_Territory_Revenue_Summary AS
SELECT 
    t.territory_id,
    t.territory_description,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS TOTAL_REVENUE
FROM territories AS t
INNER JOIN employee_territories AS et
    ON t.territory_id = et.territory_id
INNER JOIN employees AS e
    ON et.employee_id = e.employee_id
INNER JOIN orders AS o
    ON e.employee_id = o.employee_id
INNER JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY 
    t.territory_id,
    t.territory_description
ORDER BY TOTAL_REVENUE DESC;

--14: What are the products which are often ordered together? (This is Market basket analysis.)--
CREATE VIEW V_Frequently_Ordered_Products AS
SELECT
    p1.product_name AS product_1,
    p2.product_name AS product_2,
    COUNT(*) AS TIMES_ORDERED_TOGETHER
FROM order_details od1
INNER JOIN order_details od2
    ON od1.order_id = od2.order_id
    AND od1.product_id < od2.product_id   
INNER JOIN products p1
    ON od1.product_id = p1.product_id
INNER JOIN products p2
    ON od2.product_id = p2.product_id
GROUP BY 
    product_1,
    product_2
ORDER BY TIMES_ORDERED_TOGETHER DESC;

--15: For each category, which product is the one with the highest revenue?--
CREATE VIEW V_Top_Product_by_Category AS
WITH PRODUCT_REVENUE AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_revenue
    FROM products p
    INNER JOIN categories AS c
        ON p.category_id = c.category_id
    INNER JOIN order_details AS od
        ON p.product_id = od.product_id
    GROUP BY p.product_id, p.product_name, c.category_name),
RANKED_PRODUCTS AS (
    SELECT
        product_id,
        product_name,
        category_name,
        total_revenue,
        RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS REVENUE_RANK
    FROM PRODUCT_REVENUE)
SELECT
    product_name,
    category_name,
    total_revenue
FROM RANKED_PRODUCTS
WHERE REVENUE_RANK = 1
ORDER BY category_name;

--Total Profit by Country--
CREATE VIEW V_Country_Profit AS
SELECT
    c.country AS country,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) - SUM(o.freight) AS TOTAL_PROFIT_COUNTRY
FROM customers AS c
INNER JOIN orders AS o
    ON c.customer_id = o.customer_id
INNER JOIN order_details AS od
    ON o.order_id = od.order_id
GROUP BY c.country
ORDER BY TOTAL_PROFIT_COUNTRY DESC;

--Total Profit by product--
CREATE VIEW V_Product_Profit AS
SELECT
    p.product_name AS product_name,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) - SUM(o.freight) AS TOTAL_PROFIT_PRODUCT
FROM products AS p
INNER JOIN order_details AS od
    ON p.product_id = od.product_id
INNER JOIN orders AS o
    ON od.order_id = o.order_id
GROUP BY p.product_name
ORDER BY TOTAL_PROFIT_PRODUCT DESC;



