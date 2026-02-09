-- Amazon Project


-- database schema-->
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS shippings;
DROP TABLE IF EXISTS inventory;


-- category TABLE
CREATE TABLE category
(
category_id	INT PRIMARY KEY,
category_name VARCHAR(20)
);

-- customers TABLE

CREATE TABLE customers
(
customer_id INT PRIMARY KEY,	
first_name	VARCHAR(20),
last_name	VARCHAR(20),
state VARCHAR(20)
);

-- sellers TABLE
CREATE TABLE sellers
(
seller_id INT PRIMARY KEY,
seller_name	VARCHAR(25),
origin VARCHAR(15)
);

-- updating data types
ALTER TABLE sellers
ALTER COLUMN origin TYPE VARCHAR(10)
;

-- products table
CREATE TABLE products
(
product_id INT PRIMARY KEY,	
product_name VARCHAR(50),	
price	FLOAT,
cogs	FLOAT,
category_id INT, -- FK 
CONSTRAINT product_fk_category FOREIGN KEY(category_id) REFERENCES category(category_id)
);

-- orders
CREATE TABLE orders
(
order_id INT PRIMARY KEY, 	
order_date	DATE,
customer_id	INT, -- FK
seller_id INT, -- FK 
order_status VARCHAR(15),
CONSTRAINT orders_fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
CONSTRAINT orders_fk_sellers FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);


-- order_item table

CREATE TABLE order_items
(
order_item_id INT PRIMARY KEY,
order_id INT,	-- FK 
product_id INT, -- FK
quantity INT,	
price_per_unit FLOAT,
CONSTRAINT order_items_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id),
CONSTRAINT order_items_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- payment TABLE
CREATE TABLE payments
(
payment_id	
INT PRIMARY KEY,
order_id INT, -- FK 	
payment_date DATE,
payment_status VARCHAR(20),
CONSTRAINT payments_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- shipping table
CREATE TABLE shippings
(
shipping_id	INT PRIMARY KEY,
order_id	INT, -- FK
shipping_date DATE,	
return_date	 DATE,
shipping_providers	VARCHAR(15),
delivery_status VARCHAR(15),
CONSTRAINT shippings_fk_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- inventory table
CREATE TABLE inventory
(
inventory_id INT PRIMARY KEY,
product_id INT, -- FK
stock INT,
warehouse_id INT,
last_stock_date DATE,
CONSTRAINT inventory_fk_products FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- End of schemas


select * from category;
select * from customers;
select * from sellers;
select * from products;
select * from orders;
select * from order_items;
select * from payments;
select * from shippings;
select * from inventory;




-- 1. Basic Select: Retrieve the names of all products in the products table.

select 
distinct(product_name) 
from products;


SELECT COUNT(DISTINCT product_name) AS distinct_products FROM products;

-- 2. Simple Join: Write a query to find the full name of customers (first_name + last_name) and the names of the products they ordered. 
--    Use a JOIN between customers, orders, and order_items.

-- join two columns
select 
first_name || ' ' || last_name as full_name 
from customers;

-- joining the tables
SELECT 
*
FROM customers as c
JOIN orders as o ON c.customer_id = o.customer_id
JOIN order_items as oi ON o.order_id = oi.order_id
JOIN products as p ON oi.product_id = p.product_id;

-- filtering the data as asked
SELECT 
  c.first_name || ' ' || c.last_name AS full_name,
  p.product_name
FROM customers as c
JOIN orders as o ON c.customer_id = o.customer_id
JOIN order_items as oi ON o.order_id = oi.order_id
JOIN products as p ON oi.product_id = p.product_id;



-- 3. Conditional Select: List all products with a price greater than 100. Display the product name and price.

select
* 
from products
where price > 100;

-- 4. Inner Join: List all orders along with customer names and product names. 
--    Use INNER JOIN between orders, customers, and order_items.

select 
o.order_id,
c.customer_id,
c.first_name,
p.product_name
FROM orders as o
inner JOIN customers as c ON o.customer_id = c.customer_id
inner JOIN order_items as oi ON o.order_id = oi.order_id
inner JOIN products as p ON oi.product_id = p.product_id;

-- 5. Left Join: Retrieve all customers and their corresponding orders. Include customers who haven't placed any orders.

SELECT 
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  o.order_id,
  o.order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
where o.order_id is null;		-- to check which customer has not placed any order



-- 6. Right Join: Retrieve all orders and their corresponding customers. Include orders without customer information.
SELECT 
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  o.order_id,
  o.order_date
FROM customers c
RIGHT JOIN orders o ON c.customer_id = o.customer_id;



-- 7. Join with Filtering: List all products sold by sellers originating from 'USA.' Include product names and seller names.


select
p.product_name,
s.origin,
s.seller_name
from orders as o 
join sellers as s
on o.seller_id = s.seller_id
join order_items as oi 
on oi.order_id = o.order_id
join products as p
ON p.product_id = oi.product_id
where s.origin = 'USA';


-- 8. Multi-table Join: Write a query to find the total amount paid for each order. Include the orders, order_items, and payments tables.

select 
o.order_id,
SUM(oi.quantity * oi.price_per_unit) AS total_amount
from orders as o
join order_items as oi 
on o.order_id = oi.order_id
join payments as p 
ON p.order_id = o.order_id
where payment_status = 'Payment Successed'
group by o.order_id
order by o.order_id asc;


-- 9. Join with Subquery: List the customers who have ordered products in the 'electronics' category. Use a subquery to find the category ID.

select 
distinct c.first_name || ' ' || c.last_name AS customer_name
from customers as c
join orders as o 
on o.customer_id = c.customer_id
join order_items as oi 
on oi.order_id = o.order_id
join products as p 
on oi.product_id = p.product_id
where p.category_id = (select category_id from category where category_name = 'electronics');

-- 10. Cross Join: Write a query to list all combinations of category and sellers.

select 
* 
from category as c 
cross join sellers as s;

-- 11. Count Function: Count the total number of unique customers in the customers table.

select 
count(distinct customer_id)
from customers;

-- 12. Sum and Group By: Find the total revenue generated by each seller. Display the seller name and total revenue.

select 
s.seller_name,
sum(oi.quantity * oi.price_per_unit) as revenue
from sellers as s
join orders as o 
on o.seller_id = s.seller_id
join order_items as oi
on o.order_id = oi.order_id
group by s.seller_name;


-- 13. Average Function: Calculate the average price of products in the products table.

SELECT 
AVG(price) AS average_price
FROM products;


-- 14. Group By with Having: List all sellers who have sold more than 500 products. Display seller names and total products sold.

select 
s.seller_name,
sum(oi.quantity) 
from sellers as s
join orders as o 
on o.seller_id = s.seller_id
join order_items as oi
on o.order_id = oi.order_id
group by s.seller_name
having sum(quantity) > 500;

-- 15. Group By Multiple Columns: Find the total revenue generated by each seller for each category.Display seller names, category names, and total revenue.

select 
s.seller_name,
c.category_name,
SUM(oi.quantity * oi.price_per_unit) AS total_revenue
FROM sellers as  s
JOIN orders as o 
ON s.seller_id = o.seller_id
JOIN order_items as oi 
ON o.order_id = oi.order_id
JOIN products as p 
ON oi.product_id = p.product_id
JOIN category as c 
ON p.category_id = c.category_id
group by s.seller_name,c.category_name
order by s.seller_name;

-- 16. Count and Distinct: Find the total number of distinct products sold in each category.

select 
c.category_name,
COUNT(DISTINCT p.product_id) AS distinct_products_sold
FROM category as  c
JOIN products as p 
ON c.category_id = p.category_id
JOIN order_items as oi 
ON p.product_id = oi.product_id
GROUP BY c.category_name;

-- 17. Join with Aggregation: Write a query to find the total number of orders and the total revenue generated for each customer.

select 
c.customer_id,
count(o.order_id) as total_orders,
SUM(oi.quantity * oi.price_per_unit) AS total_revenue
FROM customers  as c
JOIN orders as o 
ON c.customer_id = o.customer_id
JOIN order_items as oi 
ON o.order_id = oi.order_id
group by c.customer_id;


-- 18. Aggregate Functions and CASE: Find the number of orders for each order status ('Inprogress,''Delivered,' etc.). Use CASE to categorize the statuses.

select 
order_status,
count(*) as counts
from orders
group by order_status;

select 
payment_status,
count(*) as counts
from payments
group by payment_status;

-- 19. Nested Aggregation: Find the category with the highest total revenue.

select 
c.category_name,
SUM(oi.quantity * oi.price_per_unit) AS total_revenue
FROM category as c
JOIN products as p 
ON c.category_id = p.category_id
JOIN order_items as oi 
ON p.product_id = oi.product_id
GROUP BY c.category_name
ORDER BY total_revenue DESC
limit 1;


-- 20. Conditional Aggregation: Count the number of successful and failed payments for each customer.

select 
c.customer_id,
c.first_name || ' ' || c.last_name AS customer_name,
SUM(CASE WHEN p.payment_status ILIKE 'payment successed%' THEN 1 ELSE 0 END) AS successful_payments,
SUM(CASE WHEN p.payment_status ILIKE 'payment Failed%' THEN 1 ELSE 0 END) AS failed_payments
FROM customers as c
JOIN orders as o 
ON c.customer_id = o.customer_id
JOIN payments  as p 
ON o.order_id = p.order_id 
GROUP BY c.customer_id, c.first_name, c.last_name;


SELECT 
COUNT(CASE WHEN payment_status = 'successful' THEN 1 END) AS successful_payments,
COUNT(CASE WHEN payment_status = 'failed' THEN 1 END) AS failed_payments 
FROM payments WHERE order_id IN
(SELECT order_id FROM orders WHERE customer_id = 184)

-- 21. Simple Subquery: Find the product with the highest price. Use a subquery to get the maximum price.

SELECT 
product_id, 
product_name, 
price
FROM products
WHERE price = (SELECT MAX(price) FROM products);


-- 22. Correlated Subquery: Find all products whose price is above the average price in their category.





-- 23. Subquery in WHERE Clause: Retrieve the names of customers who have ordered at least one product in the 'Pet Supplies' category.
-- 24. Subquery in SELECT Clause: For each product, display its name and the total number of times it has been ordered.
-- 25. Subquery with EXISTS: List all customers who have made at least one order.
-- 26. IN Clause with Subquery: Find the names of sellers who have sold 'Apple' products.
-- 27. NOT IN Clause: List all customers who have not placed any orders.
-- 28. Subquery with JOIN: Find the names of products that are out of stock. Use a subquery to get product IDs with stock = 0 in the inventory table.
-- 29. Subquery with HAVING: Retrieve sellers who have an average selling price of their products greater than 300.
-- 30. Multi-level Subqueries: Find the product that has generated the highest revenue. Use nested subqueries to calculate revenue.
-- 31. RANK() Function: For each category, rank the products based on their total sales amount.
-- 32. DENSE_RANK() Function: List the top 5 customers based on the total amount spent. Use DENSE_RANK().
-- 33. ROW_NUMBER() Function: Assign a row number to each product in the products table, ordered by price descending.
-- 34. NTILE() Function: Divide all customers into 4 quartiles based on the total amount they have spent.
-- 35. OVER Clause: For each order, calculate the running total of sales for the corresponding customer.
-- 36. PARTITION BY Clause: Find the total revenue generated by each seller in each year.
-- 37. LEAD() Function: For each product, find the next higher-priced product in the same category.
-- 38. LAG() Function: For each product, find the previous lower-priced product in the same category.
-- 39. Cumulative Sum: Calculate the cumulative sum of sales for each seller.
-- 40. Window Function with Aggregation: Find the average order amount for each customer and compare it with their individual orders.
-- 41. Date Filtering: List all orders placed in the current month. Include order ID, order date, and customer name.
-- 42. Extract and Group By: Find the number of orders placed in each year. Use the EXTRACT() function to group by year.
-- 43. DATEDIFF Function: Calculate the average delivery time for all delivered orders.
-- 44. DATE_TRUNC Function: Find the total sales amount for each month in the current year.
-- 45. Age Function: Find customers who have not placed any orders in the last 6 months.
-- 46. Date Conversion: Convert the order_date to a different format (e.g., 'YYYY-MM-DD') and display it with the order ID.
-- 47. Date Arithmetic: Calculate the total number of days between the order date and shipping date for each order.
-- 48. Current Date Usage: Find all orders that are overdue for payment. Assume payment is due within 30 days of the order date.
-- 49. Weekend Orders: Retrieve all orders that were placed on weekends.
-- 50. Next Day Delivery: List all orders 

-- ---------------------------
-- Advanced Business Problems
-- ---------------------------

/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/


/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
*/


/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/


/*
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
/*



/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/


/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*
/


/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/



/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/




/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/



/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/



/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/


/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/


/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/



/*
14. Orders Pending Shipment
Find orders that have been paid but are still pending shipment.
Challenge: Include order details, payment date, and customer information.
*/


/*
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/

/*
16. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/


/*
17. Cross-Sell Opportunities
Find customers who purchased product A but not product B (e.g., customers who bought AirPods but not AirPods Max).
Challenge: Suggest cross-sell opportunities by displaying matching product categories.
*/


/*
18. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/



/*
19. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
*/


/*
20. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result

Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/


/*
Final Task
-- Store Procedure
create a function as soon as the product is sold the the same quantity should reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 





