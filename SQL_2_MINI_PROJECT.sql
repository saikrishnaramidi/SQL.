create database SQL2MINI;

use SQL2MINI;


#1.	Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen).
create table  combined_table as
(select  *
from market_fact 
natural join cust_dimen 
natural join orders_dimen 
natural join prod_dimen 
natural join shipping_dimen 
);

#2.	#Find the top 3 customers who have the maximum number of orders

select * from
(select  Cust_id,count(Ord_id) no_of_orders
from market_fact 
group by Cust_id)t
order by no_of_orders desc
limit 3;

#3.Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
select *,datediff(str_to_date(Ship_Date,"%d-%m-%Y"),str_to_date(Order_Date,"%d-%m-%Y")) as DaysTakenForDelivery
from market_fact mf
join orders_dimen od
on mf.ord_id=od.Ord_id
join shipping_dimen sd
on sd.Ship_id=mf.Ship_id;


#4.	Find the customer whose order took the maximum time to get delivered.
select cust_id,Customer_Name,max(DaysTakenForDelivery)
from(
select cd.cust_id,Customer_Name,datediff(str_to_date(Ship_Date,"%d-%m-%Y"),str_to_date(Order_Date,"%d-%m-%Y")) as DaysTakenForDelivery
from cust_dimen cd
join market_fact mf
on cd.cust_id=mf.cust_id
join orders_dimen od
on mf.ord_id=od.Ord_id
join shipping_dimen sd
on sd.Ship_id=mf.Ship_id)t;




#5.	Retrieve total sales made by each product from the data (use Windows function)
select distinct Prod_id,round(sum(sales) over(partition by Prod_id ),2)
from market_fact;


#6.	Retrieve total profit made from each product from the data (use windows function)
select distinct Prod_id,round(sum(profit) over(partition by Prod_id ),2)
from market_fact;

#7.	Count the total number of unique customers in January and 
#how many of them came back every month over the entire year in 2011
update orders_dimen
set Order_Date=str_to_date(Order_Date,'%d-%m-%Y');
update shipping_dimen
set Ship_Date=str_to_date(Ship_Date,'%d-%m-%Y');

select order_month,count(cust_id) repeated_customers_jan_2011
 from(select distinct mf.cust_id,
month(od.order_date) as order_month, 
year(od.order_date) as order_year
from market_fact mf
join orders_dimen od
on od.ord_id = mf.ord_id
order by order_year,order_month
)t1
where cust_id in 
(select cust_id from 
(select distinct cust_id, year(od.Order_Date) order_year, month(od.Order_Date) order_month
from market_fact mf 
join orders_dimen od 
on mf.ord_id=od.ord_id
where year(od.Order_Date)=2011 and month(od.Order_Date)=1)t2 ) and order_year = 2011
group by order_month;
#8.	Retrieve month-by-month customer retention rate since the start of the business.(using views)
create view monthly_retention_rate as
select *,
case when months_gap = 1 then 'retained' 
     when months_gap > 1 then 'irregular'
     when months_gap is null then 'churned' end as category
from(
select mf.cust_id,od.order_date,year(od.order_date) order_year, month(od.order_date) order_month,
lag(Order_Date) over(Partition by Cust_id Order by Order_Date) lag_date, 
month(lag(Order_Date) over(Partition by Cust_id Order by Order_Date)) lag_month,
abs(month(od.order_date)-month(lag(Order_Date) over(Partition by Cust_id Order by Order_Date))) months_gap
from market_fact mf
join orders_dimen od
on od.ord_id = mf.ord_id)t;

select order_year, order_month , (sum(months_gap=1)/count(order_month))*100 as retention_rate
from monthly_retention_rate
group by order_year , order_month
order by order_year , order_month;


Tips: 
#1: Create a view where each user’s visits are logged by month, 
#allowing for the possibility that these will have occurred over multiple # years since whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned
# 5: calculate the retention month wise



