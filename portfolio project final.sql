create database retail_company;
use retail_company;

create table customers
(customer_id int Primary Key,
first_name varchar(255),
last_name varchar(255),
email varchar(255),
gender varchar(20),
date_of_birth date,
registration_date date,
last_purchase_date date);

create table Products
(product_id int Primary Key,
product_name varchar(255),
category varchar(255),
price float,
stock_quantity int,
date_added date);

create table Sales
(sale_id int Primary Key,
customer_id int,
product_id int,
quantity_sold int,
sale_date date,
discount_applied float,
total_amount float);


create table Inventory_Movements
(movement_id int Primary Key,
product_id int,
movement_type varchar(5),
quantity_moved int,
movement_date date);

alter table inventory_movements
add constraint fk_product_id
foreign key (product_id)
references products(product_id);

alter table sales
add constraint fk_product_id1
foreign key (product_id)
references products(product_id),
add constraint fk_customer_id
foreign key (customer_id)
references customers(customer_id);

select * from customers;
select * from inventory_movements;
select * from products;
select * from sales;

-- Key Objectives and Questions

-- Module 1: Sales Performance Analysis

-- 1. Total Sales per Month:
-- Calculate the total sales amount per month, including the number of units sold and the total revenue generated.

select date_format(s.sale_date, "%m-%Y") sale_month, 
sum(s.quantity_sold) "Total Units Sold",
round(sum(s.total_amount),2) "Total Revenue Generated"
from products p join sales s
on p.product_id=s.product_id
Group by sale_month
order by sale_month;

-- 2. Average Discount per Month:
--  Calculate the average discount applied to sales in each month and assess how discounting strategies impact total sales.

select date_format(s.sale_date,"%m,%Y") as sale_month, 
round(avg(s.discount_applied),2) Average_Discount,
round(sum(s.total_amount),2) "Total Revenue Generated per month",
sum(s.quantity_sold) "Total Quantity Sold"
from sales s join products p
on s.product_id=p.product_id
group by sale_month
order by sale_month;

-- Module 2: Customer Behavior and Insights

-- 3. Identify high-value customers:
--  Which customers have spent the most on their purchases? Show their details

with high_purchase as
(
select c.customer_id,c.first_name,c.last_name,c.gender,s.total_amount
from customers c join sales s
on c.customer_id=s.customer_Id
)
select customer_id,first_name,last_name,gender,round(sum(total_amount),2) Overall_Total_Amount from high_purchase
group by customer_id,first_name,last_name,gender
order by Overall_Total_Amount desc;

-- 4. Identify the oldest Customer:
--  Find the details of customers born in the 1990s, including their total spending andspecific order details.
select * from customers;
select c.customer_id, c.first_name, c.last_name, c.email, c.gender,date_format(c.date_of_birth,"%Y") birth_year,s.product_id,p.product_name,s.quantity_sold,s.sale_date,s.discount_applied,round(sum(s.total_amount),2) Overall_Total_amount
from customers c join sales s
on c.customer_id=s.customer_id
join products p
on p.product_id=s.product_id
where date_format(date_of_birth,"%Y") between 1990 and 1999
group by c.customer_id, c.first_name, c.last_name, c.email, c.gender,date_format(c.date_of_birth,"%Y"),s.product_id,p.product_name,s.quantity_sold,s.sale_date,s.discount_applied
ORDER BY c.date_of_birth ASC;
 
-- 5. Customer Segmentation:
--  Use SQL to create customer segments based on their total spending (e.g., LowSpenders, High Spenders).

with segmentation as
(
select c.customer_id,c.first_name,sum(s.total_amount) Total_Spending,
case
when sum(s.total_amount)<1500 then "Low Spenders"
when sum(s.total_amount)<3000 then "Medium Spenders"
else "High Spenders"
end as Customer_Segmentations
from customers c join sales s
on c.customer_id=s.customer_id
group by c.customer_id,c.first_name 
)
select * from segmentation;

-- Module 3: Inventory and Product Management

-- 6. Stock Management:
--  Write a query to find products that are running low in stock (below a threshold like 10 units) 
-- and recommend restocking amounts based on past sales performance.

WITH Last_Three_Months_Sales AS 
(
SELECT p.product_id, p.product_name, p.stock_quantity,
COALESCE(SUM(s.quantity_sold), 0) AS total_quantity_sold_3_months,
ROUND(COALESCE(SUM(s.quantity_sold), 0) / COUNT(DISTINCT s.sale_date), 0) AS avg_daily_sales_3_months
FROM products p LEFT JOIN sales s 
ON p.product_id = s.product_id 
WHERE s.sale_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH)
GROUP BY p.product_id, p.product_name, p.stock_quantity
HAVING p.stock_quantity < 10
),
Restock_Recommendations AS 
(
SELECT product_id, product_name, stock_quantity, total_quantity_sold_3_months, avg_daily_sales_3_months, 
CASE 
WHEN avg_daily_sales_3_months > 0 THEN ROUND((avg_daily_sales_3_months * 30) - stock_quantity, 0)
ELSE 50
END AS recommended_restock
FROM Last_Three_Months_Sales
)
SELECT product_id, product_name, stock_quantity, total_quantity_sold_3_months, avg_daily_sales_3_months, recommended_restock
FROM Restock_Recommendations;


-- 7. Inventory Movements Overview:
--  Create a report showing the daily inventory movements (restock vs. sales) for each product over a given period.

with inventory_restock as
(
select im.product_id,p.product_name,sum(im.quantity_moved) Total_restock,im.movement_date
from inventory_movements im join products p
on im.product_id=p.product_id
where im.movement_type in ("IN")
group by product_id,movement_date, p.product_name
),
inventory_sale as
(
select s.product_id,p.product_name,sum(s.quantity_sold) total_Sold, s.sale_date
from sales s join products p
on p.product_id=s.product_id
group by product_id,sale_date,p.product_name
)
SELECT r.product_id,r.product_name,r.total_restock AS quantity,r.movement_date AS date,'Restock' AS movement_type
FROM 
    inventory_restock r
UNION
SELECT s.product_id,s.product_name,s.total_sold AS quantity,s.sale_date AS date,'Sale' AS movement_type
FROM 
    inventory_sale s
ORDER BY 
    date DESC, product_id;

-- 8. Rank Products::
--  Rank products in each category by their prices.

select *,
rank() over (partition by category order by price) Rank_product
from products;


-- Module 4: Advanced Analytics

-- 9. Average order size:
--  What is the average order size in terms of quantity sold for each product?

select p.product_id, p.product_name,p.category,p.price,sum(s.quantity_sold), round(avg(s.quantity_sold),2) average_order_size
from sales s join products p
on p.product_id=s.product_id
group by p.product_id, p.product_name,p.category,p.price
order by average_order_size desc;

-- 10. Recent Restock Product:
--  Which products have seen the most recent restocks

select * from inventory_movements;
select * from products;

SELECT p.product_id, p.product_name,MAX(im.movement_date) AS most_recent_restock
FROM inventory_movements im JOIN products p 
ON im.product_id = p.product_id
WHERE im.movement_type = "IN"
GROUP BY p.product_id, p.product_name
ORDER BY most_recent_restock DESC;

-- Advanced Features to Challenge Students
-- ● Dynamic Pricing Simulation: Challenge students to analyze how price changes for products 
-- impact sales volume, revenue, and customer behavior.

WITH price_simulation AS
(
SELECT c.customer_id, c.first_name,p.product_id,p.price AS old_price, ROUND(s.total_amount, 2) AS old_total_amount,
ROUND(p.price + (p.price * 0.10), 2) AS new_price,  -- Price after 10% increase
s.quantity_sold AS old_quantity_sold, ROUND(s.quantity_sold * 0.95, 2) AS adjusted_quantity_sold,  -- Adjusted quantity sold after 5% reduction
ROUND(((p.price + (p.price * 0.10)) * (s.quantity_sold * 0.95))-((p.price + (p.price * 0.10)) * (s.quantity_sold * 0.95) * (s.discount_applied / 100)),2) AS new_total_amount
FROM products p JOIN sales s 
ON p.product_id = s.product_id
JOIN customers c 
ON c.customer_id = s.customer_id
)
SELECT customer_id, first_name, SUM(old_quantity_sold) AS old_total_quantity_sold,ROUND(SUM(old_total_amount), 2) AS old_total_amount,
SUM(adjusted_quantity_sold) AS new_total_quantity_sold,ROUND(SUM(new_total_amount), 2) AS new_total_amount,
CASE
WHEN SUM(old_total_amount) < 1500 THEN "Low Spender (Old)"
WHEN SUM(old_total_amount) BETWEEN 1500 AND 3000 THEN "Medium Spender (Old)"
ELSE "High Spender (Old)"
END AS old_customer_behaviour,
CASE
WHEN SUM(new_total_amount) < 1500 THEN "Low Spender (New)"
WHEN SUM(new_total_amount) BETWEEN 1500 AND 3000 THEN "Medium Spender (New)"
ELSE "High Spender (New)"
END AS new_customer_behaviour
FROM 
price_simulation
GROUP BY 
customer_id, first_name;

-- ● Customer Purchase Patterns: Analyze purchase patterns using time-series data and window functions to find high-frequency buying behavior.

WITH Customer_Purchase_Patterns AS
(
SELECT c.customer_id, c.first_name, c.last_purchase_date, p.product_id, p.category, s.total_amount, s.sale_date, s.quantity_sold
FROM customers c JOIN sales s 
ON c.customer_id = s.customer_id
JOIN products p ON p.product_id = s.product_id
)
SELECT customer_id, first_name,category, sale_date, TIMESTAMPDIFF(DAY, sale_date, LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) AS days_to_next_purchase,
CASE
WHEN TIMESTAMPDIFF(DAY, sale_date, LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) IS NULL THEN "Last Purchase"
WHEN TIMESTAMPDIFF(DAY, sale_date, LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) < 8 THEN "High Frequency"
WHEN TIMESTAMPDIFF(DAY, sale_date, LEAD(sale_date) OVER (PARTITION BY customer_id ORDER BY sale_date)) BETWEEN 8 AND 30 THEN "Medium Frequency"
ELSE "Low Frequency"
END AS "Customer Buying Behavior"
FROM Customer_Purchase_Patterns;

-- ● Predictive Analytics: Use past data to predict which customers are most likely to churn and recommend strategies to retain them.

WITH Predictive_Analytics AS 
(
SELECT c.customer_id, c.first_name, MAX(s.sale_date) AS last_purchase_date, COUNT(s.sale_id) AS purchase_frequency, round(SUM(s.total_amount),2) AS total_spent,
TIMESTAMPDIFF(DAY, MAX(s.sale_date), CURDATE()) AS days_since_last_purchase
FROM customers c JOIN sales s 
ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.first_name
),
Customer_Churn_Risk AS
(
SELECT customer_id, first_name, last_purchase_date, purchase_frequency, total_spent, days_since_last_purchase,
CASE
WHEN days_since_last_purchase > 90 THEN 'High Risk'
WHEN days_since_last_purchase BETWEEN 60 AND 90 THEN 'Medium Risk'
ELSE 'Low Risk'
END AS churn_risk
FROM Predictive_Analytics
)
SELECT customer_id, first_name, last_purchase_date, purchase_frequency, total_spent, days_since_last_purchase, churn_risk
FROM Customer_Churn_Risk
ORDER BY churn_risk DESC, total_spent DESC;
