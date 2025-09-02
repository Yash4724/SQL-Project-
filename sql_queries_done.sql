CREATE DATABASE IF NOT EXISTS sql_project;
USE sql_project;

-- question 1 Find the percentage of orders delivered late vs. on time.

SELECT 
round(sum(order_delivered_customer_date > order_estimated_delivery_date)/count(*)*100,2) as late,
round(SUM(order_delivered_customer_date < order_estimated_delivery_date)/COUNT(*) * 100,2) as on_time
FROM
    orders
WHERE
    order_status = 'delivered';
    
-- question 2  Find the average customer rating for each product categor

with cte1 as (select review_score,order_id from review),
cte2 as (select order_id,product_id from order_items),
c3 as (SELECT product_id,product_category_name from product),
c4 as (SELECT  product_category_name, product_category_name_english from prod_category)

select product_category_name_english AS 'category_name',  ROUND(AVG(review_score), 2) AS 'average_customer_rating',
    CASE
    WHEN AVG(review_score) > 2.5 THEN 'love'
        ELSE 'hate'
    END AS 'satisfaction_label'
FROM cte1
        JOIN
    cte2 ON cte1.order_id = cte2.order_id
        JOIN
    c3 ON cte2.product_id = c3.product_id
        JOIN
    c4 ON c3.product_category_name = c4.product_category_name
GROUP BY 1;

-- 3. Top Selling Products and Categories 
-- Problem: Find the top 10 best-selling product categories. 
-- Goal: Help the marketing team promote the best products.
 
WITH cte1 as (select product_id,product_category_name from product),
c2 as (select price,order_id,freight_value,product_id from order_items)
select product_category_name ,round(sum(price+freight_value),2) as total from cte1 join c2 on 
cte1.product_id=c2.product_id
group by product_category_name
order by total desc
limit 10; 

-- another method without cte 
  
  

SELECT 
    p.product_category_name,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS 'Total_sales'
FROM
    order_items oi
        JOIN
    product p ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

--  4. Payment Types and Trends 
-- Problem: Find out which payment method customers use the most (credit card, boleto, etc.). 
-- Goal: Plan for payment system improvements datasets.

select payment_type,count(payment_type) as type from payment 
group by payment_type
order by type desc
limit 1;

-- 5.Average review score per product category 

with cte1 as (select product_category_name from prod_category),
cte2 as(select product_id,product_category_name from product),
cte3 as (select order_id,product_id from order_items),
cte4 as (select order_id,review_score from review)
select cte1.product_category_name,round(avg(review_score),2) as avg_review
from cte1 join cte2 on cte1.product_category_name=cte2.product_category_name
join cte3 on cte3.product_id=cte2.product_id
join cte4 on cte4.order_id=cte3.order_id
group by 1;


-- question 6 Identify regions with most late deliveries.
with cte1 as (select customer_id,customer_city from customers),
cte2 as (select order_id,customer_id,order_delivered_customer_date,order_estimated_delivery_date from orders)
select customer_city,count(order_delivered_customer_date > order_estimated_delivery_date) as late
from cte1 join cte2 on cte1.customer_id=cte2.customer_id
group by 1
order by late desc;

with late as (Select *  from orders o where order_delivered_customer_date > order_estimated_delivery_date)

Select customer_state, count(*) as 'Total_late_deliveries' from late join customers c on late.customer_id = c.customer_id 
group by 1 
order by 2 desc;

--  quetion 7 Identify categories with most 5-star and 1-star reviews
with cte1 as (select product_id,product_category_name from product),
cte2 as (select order_id,product_id from order_items),
cte3 as (select order_id,review_score from review)

select product_category_name, count(case when review_score=5 then 1 end) as '5-star_reviews',
    count(case when review_score=1 then 1 end) as '1-star_reviews' from cte1 join cte2 on cte1.product_id=cte2.product_id
join cte3 on cte2.order_id=cte3.order_id
group by 1
order by 2 desc;

-- queston 8.Payment Behavior Analyze the average payment value per order.
select sum(payment_value)/count(distinct p.order_id) from payment p join orders o on p.order_id=o.order_id
where order_status ='Delivered'; 

--  question 9. How many orders does an average customer place? 
select customer_id,count(order_id) as avg from orders where order_status='Delivered'
group by 1;

-- question 10. Which cities have the most active customers?
select customer_city,count(customer_id) as active_customers  from customers group by 1
order by 2 desc;

-- by using state second one is more relaible as itr counts those customer who placed atleast one order 

SELECT 
    customer_state,
    COUNT(DISTINCT c.customer_id) AS 'active_customers'
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
GROUP BY 1
ORDER BY 2 DESC;

-- 11. Distribution of review scores.
select review_score,count(review_score) as distribution from review
group by 1
order by distribution desc;

-- 12. Relation between delivery time and review score.
with cte1 as (select review_score,order_id from review),
cte2 as (select order_id,order_delivered_customer_date,order_estimated_delivery_date from orders)
select case when order_delivered_customer_date>order_estimated_delivery_date then 'late' else 'on_time'
end as'delivery_status', round(avg(review_score),2) as"average_review",
count(*)  as "review_count" from cte1 join cte2 on 
cte1.order_id=cte2.order_id
group by 1;

-- -Average delay days (delivered date vs estimated date) 
with cte1 as (select order_id,order_delivered_customer_date,order_estimated_delivery_date, order_status  from orders 
where order_status="delivered")
select avg(datediff(order_delivered_customer_date,order_estimated_delivery_date)) from cte1;

-- . Categories with most orders.  doubt in this 

with cte1 as (select order_id,product_id from order_items),
cte2 as (select product_id,product_category_name from product)
select product_category_name,count(cte1.product_id) as "most_orders" from cte1 join cte2 on cte1.product_id=cte2.product_id
group by 1
order by "most_orders" desc;

select  
    product_category_name, COUNT(*) AS Total_orders
FROM
    order_items oi
        JOIN
    product p ON oi.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;


-- 15. Which 3 product categories have the best customer ratings? 

with cte1 as (select order_id,review_score from review),
cte2 as (select order_id,product_id from order_items),
cte3 as (select product_id,product_category_name from  product)
select product_category_name,avg(review_score) as "best_rating" from cte1 join cte2 on cte1.order_id=cte2.order_id
join cte3 on cte2.product_id=cte3.product_id
group by 1 
order by "best_rating" desc
limit 3;

-- question 16
-- Name 3 cities where most deliveries happen.

with cte1  as (select customer_id,customer_state from customers),
cte2 as(select order_id,customer_id,order_status from orders where order_status='delivered')
select  count(cte2.order_id) as "most_delivery",customer_state from cte1 join cte2 on cte1.customer_id=cte2.customer_id
group by 2
order by "most_delivery" desc 
limit 3;
-- doubt 
SELECT 
    customer_state, COUNT(*) AS 'Total_Deliveries'
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
WHERE
    order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;

-- 18. Find the top 5 product categories with the highest number of late deliveries. 
with cte1 as (select order_id,order_delivered_customer_date,order_estimated_delivery_date, order_status  from orders 
where order_status="delivered"),
cte2 as (select order_id,product_id from order_items),
cte3 as (select product_id,product_category_name from product)
select count(order_delivered_customer_date>order_estimated_delivery_date) as "late",product_category_name from cte1 join 
cte2 on cte1.order_id=cte2.order_id join cte3 on cte2.product_id=cte3.product_id
group by 2 
order by late desc
limit 5;

-- 19. List the top 10 cities with the highest number of unique customers. 

SELECT 
    customer_city,
    COUNT(DISTINCT customer_id) AS 'total_unique_customers'
FROM
    customers
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;













-- 21. Identify the top 5 products that received the most 1-star reviews. 
WITH CTE1 as (select review_score,order_id from review where review_id=1),
cte2 as ( select order_id, product_id from order_items),
cte3 as (select product_id,product_category_name from product)
select count(review_score),product_category_name from cte1 join cte2 on cte1.order_id=cte2.order_id
join cte3 on cte2.product_id=cte3.product_id
group by 2
order by 1 desc 
limit 5;

-- 22. Calculate the total revenue generated by each payment type. 
with cte1 as (select order_id,price,freight_value from order_items),
cte2 as (select order_id,payment_type from payment)
select payment_type,sum(price + freight_value) as "revenue generated" from cte1 
join cte2 on cte1.order_id=cte2.order_id
group by 1;

-- 23. For each product category, calculate the average review score and total number of orders.
WITH CTE1 as (select review_score,order_id from review ),
cte2 as (select order_id,product_id from order_items ),
cte3 as (select product_id,product_category_name from product)
select product_category_name,avg(review_score),count(cte2.order_id)
from cte1 join cte2 on cte1.order_id=cte2.order_id
join cte3 on cte2.product_id=cte3.product_id
group by 1;

-- 24. Find the top 5 customers who placed the most orders and their total spending
with  cte1 as (select customer_id,order_id from orders where order_status="delivered"),
 cte2 as (select order_id,product_id,freight_value,price from order_items)
select customer_id,count(distinct cte2.order_id) as "no of order",sum(price + freight_value) from cte1 join cte2 on 
cte1.order_id=cte2.order_id group by 1
order by "no of order",3 desc
limit 5 ;

SELECT 
    customer_id,
    COUNT(DISTINCT oi.order_id) AS Total_orders,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS 'Total_spending'
FROM
    orders o
        JOIN
    order_items oi ON o.order_id = oi.order_id
WHERE
    o.order_status != 'canceled'
GROUP BY 1
ORDER BY 2 DESC , 3 DESC
LIMIT 5;

--  25 Identify categories where the majority of reviews are 5-star.
with cte1 as (select order_id,review_score from review),
cte2 as (select order_id,product_id from order_items),
cte3 as (select product_id,product_category_name from product)
select product_category_name,count(CASE WHEN review_score = 5 THEN 1 ELSE 0 END)
 as "5star" from cte1 join cte2 on cte1.order_id=cte2.order_id
join cte3 on cte3.product_id=cte2.product_id
group by 1
order by 5star desc ;

select	product_category_name, count(product_category_name)
    FROM
    review r
        JOIN
    order_items oi ON r.order_id = oi.order_id
        JOIN
    product p ON p.product_id = oi.product_id
where review_score = 5
group by 1 order by 2 desc;

    






