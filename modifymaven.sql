create database if not exists maven;

use maven;

describe orders;

alter table order_details 
add column salesAmount int;

alter table orders
modify column orderDate date;

alter table orders
modify column requiredDate date;

alter table orders
modify column shippedDate date;

-- check table--
select * from maven.orders;
select * from maven.order_details;
select * from maven.shippers;
select * from maven.employees;
select * from maven.categories;
select * from maven.products;
select * from maven.customers;  

--- check distinct values--
select distinct * from maven.products;
select distinct * from maven.categories;
select distinct * from maven.employees;
select distinct * from maven.order_details;
select distinct * from maven.shippers;
select distinct * from maven.customers;
select distinct * from maven.orders;
     

--- check duplicate values--
select productID, count(*) 
from maven.products  -- change the tablename for checking
group by productID
having count(*) >1; 

-- data cleaning--
-- calculate sales amount--
update maven.orders
set orderDate = date_format(str_to_date(orderDate, '%m/%d/%Y'), '%Y-%m-%d');-- convert string to date

update maven.orders
set requiredDate = date_format(str_to_date(requiredDate, '%m/%d/%Y'), '%Y-%m-%d');

update maven.orders
set shippedDate = date_format(str_to_date(shippedDate, '%m/%d/%Y'), '%Y-%m-%d');


update order_details
set salesAmount = unitPrice * quantity;

-- Analysis--

-- Which products are the top selling product--
select orderID, productName, salesAmount
from order_details
join products ON orderID = orderID
order by salesAmount desc;

-- since 15,810 is highest selling amount, which companies(customers) have the highest selling product?
select  orderID, companyName, salesAmount
from order_details
join customers ON customerID = customerID
where salesAmount = 15810
order by salesAmount desc;

-- what is the contact title of company
select distinct contactTitle, salesAmount
from order_details
join customers ON customerID = customerID
where salesAmount = 15810
order by salesAmount desc;

-- Which countries do they come from ?
select distinct orderID, country, salesAmount
from order_details
join customers ON customerID = customerID
where salesAmount = 15810;

-- Which year and month has the highest sales
select 
       customers.companyName as customers,
       shippers.companyName as shippingCompany,
	   extract(YEAR from orderDate) as Year,
       extract(MONTH from orderDate) as Month,
       salesAmount
from orders
join order_details ON orders.orderID = order_details.orderID
join customers ON customers.customerID = orders.customerID
join shippers ON orders.shipperID = shippers.shipperID
order by salesAmount desc;

-- Breakdown of sales by company name
select orders.orderID,
       shippers.companyName as shippingCompany , 
       order_details.salesAmount 
from orders
join order_details ON orders.orderID = order_details.orderID
join shippers ON orders.shipperID = shippers.shipperID
order by 3 desc;
-- Breakdown of Monthly sales growth
select 
extract(YEAR from orderDate) as Year,
extract(MONTH from orderDate) as Month, 
salesAmount, 
salesAmount - lag(salesAmount) over(partition by extract(YEAR from orderDate) order by extract(MONTH from orderDate) desc) as monthly_sales_growth
from orders
join order_details ON order_details.orderID = orders.orderID;

-- Which customer has the highest profit
select * from orders;
select * from order_details;
select  companyName as customers, 
        country, 
        extract(YEAR from orderDate) as Year,
		extract(MONTH from orderDate) as Month, 
        (order_details.salesAmount - orders.freight) as profit              
from orders
join 
order_details ON order_details.orderID = orders.orderID
join customers ON customers.customerID = orders.customerID
order by profit desc;

-- Breakdown of shipping cost per customer
select customers.companyName as customers, 
       shippers.companyName as shippingCompany, 
       round(sum(orders.freight)) as shipCost,
       dense_rank() over (partition by shippers.companyName order by  round(sum(orders.freight)) desc) as shipRank
from orders
join customers ON orders.customerID = customers.customerID
join shippers ON orders.shipperID = shippers.shipperID
group by customers.companyName, shippers.companyName;

select customers.companyName as customers, 
       shippers.companyName as shippingCompany, 
       round(sum(orders.freight)) as shipCost
from orders
join customers ON orders.customerID = customers.customerID
join shippers ON orders.shipperID = shippers.shipperID
group by customers.companyName, shippers.companyName
order by 3 desc;

-- Which country and city has the highest shipping cost
select customers.country,
       customers.city,
       shippers.companyName as shippingCompany, 
       round(sum(orders.freight)) as shipCost,
	  dense_rank() over (partition by shippers.companyName order by  round(sum(orders.freight)) desc) as shipRank
from orders
join customers ON orders.customerID = customers.customerID
join shippers ON orders.shipperID = shippers.shipperID
group by customers.companyName, shippers.companyName;

select customers.country,
       customers.city,
       shippers.companyName as shippingCompany, 
       round(sum(orders.freight)) as shipCost	  
from orders
join customers ON orders.customerID = customers.customerID
join shippers ON orders.shipperID = shippers.shipperID
group by customers.companyName, shippers.companyName
order by 4 desc;


