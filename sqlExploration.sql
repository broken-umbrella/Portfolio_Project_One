select *
from sales_data -- 28 columns, 286,392 records

-- creating procedure with 10 rows so as not to run the whole command everytime
create proc topTen as (
select top 10 *
from sales_data) 


-- Deleting unnecessary columns
-- column sku is not needed
alter table sales_data
drop column sku

-- columns month and year are not needed as the dataset contains order date already
alter table sales_data
drop column [year]

alter table sales_data
drop column [month]

-- columns bi_st, SSN and ref_num are not needed as they don't play any role in the analysis
-- columns price and value have the same records, so value will be deleted
alter table sales_data
drop column bi_st

alter table sales_data
drop column ref_num

alter table sales_data
drop column ssn 

alter table sales_data
drop column [value]

-- checking datatype
select COLUMN_NAME, DATA_TYPE
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'sales_data'

alter table sales_data
alter column order_id int

alter table sales_data
alter column item_id int

alter table sales_data
alter column qty_ordered int

alter table sales_data
alter column cust_id int

alter table sales_data
alter column age int

-- Duplicates and irrelevant records
with cte_duplicates as (
select *, ROW_NUMBER () over (partition by order_id order by order_id) as rn
from sales_data)

--select *
--from cte_duplicates
--where rn > 1 
-- 84,679 duplicate records
delete from cte_duplicates
where rn > 1

-- Outliers
select *
from sales_data
order by order_id -- order_id has 1 null record

delete from sales_data
where order_id is null

select *
from sales_data
order by order_date -- Changing order_date's datatype from datetime to date

alter table sales_data
alter column order_date date

select [status], count([status])
from sales_data
group by [status]
order by count([status]) asc -- refund and order_refunded can be written together as order_refunded

update sales_data
set [status] = 'order_refunded'
where [status] = 'refund'

select *
from sales_data
order by item_id

select *
from sales_data
order by qty_ordered

select *
from sales_data
order by price

select *
from sales_data
order by discount_amount 
-- formatted differently where numbers after d3ecimal point is too long

update sales_data
set discount_amount = convert(numeric(10, 2), discount_amount)
 
-- Checking the anomalies between columns price, discount_amount and total
select *
from sales_data
where discount_amount < (price * qty_ordered) -- alright

select *
from sales_data
where qty_ordered * price <> total -- total column contains wrong amount in almost all of them

update sales_data 
set total = qty_ordered * price - discount_amount -- column total populated

select *
from sales_data
order by total -- total is 0 787 times where price is 0 as well, went something wrong probably

delete
from sales_data
where price = 0 or total = 0

select category, count(category)
from sales_data
group by category
order by count(category) -- alright

select payment_method, count(payment_method)
from sales_data
group by payment_method
order by count(payment_method) 
-- only 1 record is financesettlement, so will be deleted  
-- 6 records are cashatdoorstep which mean cod, so will be updated

delete 
from sales_data
where payment_method = 'financesettlement'

update sales_data
set payment_method = 'cod'
where payment_method = 'cashatdoorstep'

select *
from sales_data
order by cust_id

select Gender, count(Gender)
from sales_data
group by Gender
order by count(Gender)

select *
from sales_data
order by age

select [Customer Since], len([Customer Since])
from sales_data
order by len([Customer Since]) -- 78158 rows have incorrectly formatted dates, so will change unknown

update sales_data
set [Customer Since] = 'Unknown'
where len([Customer Since]) < 9 -- 9 is the smallest length of a correctly formatted date

-- column place_name contains either county or city column's record, thus is not needed
alter table sales_data
drop column [place name]

select city, count(city)
from sales_data
group by city
order by count(city)

-- naming convention checking
select *
from sales_data
where city like '%[^A-za-z ]%' -- Lincoln's new salem and naval Air Station are named wrongly

update sales_data
set city = 'Lincoln''s New Salem'
where city = 'Lincoln''S New Salem'

update sales_data
set city = 'Naval Air Station'
where city = 'Naval Air Station/ Jrb'

-- checking if same customer has been put for a different city
select a.*
from sales_data a join sales_data b
on a.cust_id = b.cust_id
where a.City <> b.City -- no

-- Upon further enquiry, it was found that most of city column's data is either incorrect or is a specific location
alter table sales_data
drop column city 


select county, count(county)
from sales_data
group by county
order by count(county)

select *
from sales_data
where county like '%[^A-za-z. -]%' 
-- Many contain city names with (city) in curly braces, will populate them with county name

select county, count(county)
from sales_data
where county like '%(city)%' 
group by county
order by count(county) desc

-- These cities are also considered county, so just removed (city) from the name
update sales_data
set county = left(County, len(county) - 7)
where county like '%(city)%'

select county, count(county)
from sales_data
where county like '%[^A-za-z. -]%' 
group by county
order by count(county) desc

select county
from sales_data
where county like '%(CA)%'

update sales_data
set county = left(County, len(county) - 5)
where county like '%(CA)%'

select county
from sales_data
where county like '%(c%'

update sales_data
set county = left(County, len(county) - 3)
where county like '%(c%'

update sales_data
set county = 'Doña Ana'
where county = 'DoÃ±a Ana'

select county, len(County)
from sales_data
order by len(County) desc

select [state], count([state])
from sales_data
group by [state]
order by count([state]) desc

-- Zip column not needed
alter table sales_data
drop column zip

select region, count(region)
from sales_data
group by Region 
order by count(region) desc -- alright

update sales_data
set Discount_Percent = convert(numeric(10, 2), Discount_Percent)

update sales_data
set Discount_Percent = convert(numeric(10, 2), discount_amount / (qty_ordered * price) * 100)


-- Data Cleaning Done (200,924 rows remain)



-- Orders in months and years
select order_date
from sales_data
order by order_date -- Ranges from 01/10/2020 to 09/30/2021

with CTE_years as (
select year(order_date) as years, convert(numeric(10, 2), count(year(order_date))) as total_orders
from sales_data
group by year(order_date))

select *, total_orders / (select count(*) from sales_data) * 100
from CTE_years
-- 2021 - 125973 - 62.70%
-- 2020 - 74951 - 37.30%

with CTE_months as (
select month(order_date) as month, convert(numeric(10, 2), count(month(order_date))) as total_orders
from sales_data
group by month(order_date))

select *, total_orders / (select count(*) from sales_data) * 100
from CTE_months
-- 2020 months
--10	6121 (3.05%), --11	12570 (6.26%), --12	56260 (28.00%)

-- 2021 months
--1	10870 (5.41%), --2	6462 (3.22%), --3	18708 (9.31%), --4	34886 (17.36%), --5	9987 (4.97%), 
--6	19227 (9.57%), --7	9886 (4.92%), --8	7762 (3.86%), --9	8185 (4.07%)

-- percentage of cancellation each year
with CTE_canceled as (
select year(order_date) as years, convert(numeric(10, 2), count([status])) as total_canceled_orders
from sales_data
where year(order_date) = '2021' and [status] = 'canceled' or [status] = 'order_refunded'
group by year(order_date))

select *, total_canceled_orders / (select count(*) from sales_data where year(order_date) = 2021) * 100
from CTE_canceled
-- 2020	37872	50.52%
-- 2021	69481	55.15%

-- cancellation rate among different age groups
alter view v_cancellation_age as (
select [status], cast(age as varchar(max)) as age
from sales_data)

with cte_age_group as (
select [status], 
	case when age between 18 and 30 then 'Between 18 and 30'
		 when age between 31 and 45 then 'Between 31 and 45'
		 when age between 46 and 60 then 'Between 46 and 60'
		 when age > 60  then '60+'
		 else age end as age_group
from v_cancellation_age)

select age_group, count(age_group), convert(numeric(10, 2), count(age_group)) / (select count(*) from sales_data) * 100
from cte_age_group
where [status] = 'canceled'
group by age_group
-- Between 18 and 30	19515	9.71%, -- Between 46 and 60	21547	10.72%
-- 60+	22052	10.98%, -- Between 31 and 45	22518	11.21%


with CTE_category as (
select year(order_date) as years, category, convert(numeric(10, 2), count(category)) as category_orders
from sales_data
where year(order_date) = '2021'
group by year(order_date), category)

select *, category_orders / (select count(*) from sales_data where year(order_date) = '2021') * 100
from CTE_category
order by years, category_orders desc
-- 2020 highest: Mobiles & Tablets	23323orders	31.12% - Appliances	12719orders	16.97%
-- 2020 lowest: School & Education	121orders	0.16% - Books	41orders	0.05%
-- 2021 highest: Mobiles & Tablets	33115orders	26.29% - Others	23044orders	18.29%
-- 2021 lowest: School & Education	317orders	0.25% - Books	151orders	0.12%


select avg(total)
from sales_data
where [status] = 'canceled'
-- canceled avg total 2925.66 
-- not canceled avg total 1650.29


with cte_categories as (
select category, convert(numeric(10, 2), count(category)) as times_sold
from sales_data
group by category)

select *,  times_sold / (select count(*) from sales_data) * 100
from cte_categories
order by times_sold
-- Books	192	0.09, -- School & Education	438	0.21, -- Kids & Baby	2619	1.30
-- Soghaat	2625	1.30, -- Health & Sports	4231	2.10, -- Home & Living	5579.00	2.77
-- Superstore	6141	3.05, -- Computing	6681.00	3.3251378630700, -- Beauty & Grooming	8027	3.99
-- Women's Fashion	15009	7.46, -- Entertainment	16303	8.11, -- Men's Fashion	24147	12.01
-- Others	24906	12.39, -- Appliances	27588	13.73, -- Mobiles & Tablets	56438	28.08

select category, round(avg(total), 2)
from sales_data
group by category
order by avg(total) desc
-- Mobiles & Tablets	4577.63, -- Entertainment	3593.14, -- Computing	2898.44, -- Appliances	2296.46
-- Others	830.94, -- Superstore	433.48, -- Women's Fashion	414.51, -- Beauty & Grooming	317.41
-- Kids & Baby	280.65, -- Home & Living	260.27, -- Health & Sports	255.98, -- Books	233.61
-- Men's Fashion	216.96, -- School & Education	159.72, -- Soghaat	149.98

-- if discount played a role
select category, count(category) as times_sold, avg(Discount_Percent) avg_disc
from sales_data
group by category
order by avg_disc desc
-- top 3 discounted categories:
-- Superstore (8.24), -- Computing (5.25), -- Appliances (4.99)
-- bottom 3 discounted categories:
-- School & Education (1.03), -- Books (0.90), -- Others (0.12)

create view v_age_category as (
select category, cast(age as varchar(max)) as age
from sales_data)

with cte_category as (
select category, 
	case when age between 18 and 30 then 'Between 18 and 30'
		 when age between 31 and 45 then 'Between 31 and 45'
		 when age between 46 and 60 then 'Between 46 and 60'
		 when age > 60  then '60+'
		 else age end as age_group
from v_age_category
where category = 'Health & Sports')

select age_group, 
	   convert(numeric(10, 2), count(age_group)) / (select count(*) from sales_data where category = 'Health & Sports') * 100
from cte_category
group by age_group
-- 31-45 usually biggest consuner groups, 18-30 lowest

select Gender, category, count(category)
from sales_data
group by Gender, category
order by gender, count(category) desc
-- females (top 3):
--Highest --- Mobiles & Tablets	28402, --Appliances	13925, --Men's Fashion	12218
--Lowest --- Kids & Baby	1310, -- School & Education	215, -- Books	90
-- males (top 3):
--Highest --- Mobiles & Tablets	28036, -- Appliances	13663, -- Others	13064
--Lowest --- Soghaat	1188, -- School & Education	223, -- Books	102


create view vFrequentCustomers as (
select *
from sales_data
where cust_id in (select cust_id
				  from sales_data 
				  group by cust_id 
				  having count(cust_id) >= 5))

create view vAvgSpending as (	
select cust_id, avg(total) as avgSpending
from sales_data
where cust_id in (select cust_id
				  from sales_data 
				  group by cust_id 
				  having count(cust_id) >= 5)
group by cust_id)

alter table sales_data
add avgSpending float

select a.*, b.avgSpending
from sales_data a full join vAvgSpending b
on a.cust_id = b.cust_id


-- 9034 customers at least 5 purchases (at least 5 purchases were considered sufficient to cluster)


select *
from kMeansClustering

-- Those with cluster 0
create view v_uniqueCustomerZeroes as (
select distinct cust_id, age, gender, avgSpending, customer_since_year
from kMeansClustering
where cluster = 0
) -- 6,572 customers

with cte_unique_customersZero as (
select distinct cust_id, age, gender, avgSpending, customer_since_year
from kMeansClustering
where cluster = 0)

select age, count(age)
from cte_unique_customersZero
group by age
order by count(age) 
-- top 3: 69 (130), 63 (131), , 64 (133)
-- bottom 3: 38 (89), 42 (99), , 50 and 31 (100)

select avg(avgSpending)
from v_uniqueCustomerZeroes -- 1034.72 avg spending

select gender, avg(avgSpending)
from v_uniqueCustomerZeroes
group by gender -- F	1020.51, M	1048.43

select gender, count(Gender)
from v_uniqueCustomerZeroes
group by gender -- Females (3228), Males (3344)

-- Customers with highest number of purchases
select cust_id, count(cust_id)
from kMeansClustering
where Cluster = 0
group by cust_id
order by count(cust_id) desc -- 85775 (928), 87724 (692), 96927 (591)

select customer_since_year, count(customer_since_year)
from v_uniqueCustomerZeroes
group by customer_since_year
order by count(customer_since_year) -- 2000 (1), 2015 (1), unknown (6570)


-- Cluster 1 (Special Segment)
create view v_uniqueCustomerOnes as (
select distinct cust_id, age, gender, avgSpending, customer_since_year
from kMeansClustering
where cluster = 1
) -- 190 customers 

select avg(avgSpending)
from v_uniqueCustomerOnes -- 18773.09

select customer_since_year, count(customer_since_year)
from v_uniqueCustomerOnes
group by customer_since_year
order by count(customer_since_year) -- Unknown (ALL)

-- Cluster 2 
create view v_uniqueCustomerTwos as (
select distinct cust_id, age, gender, avgSpending, customer_since_year
from kMeansClustering
where cluster = 2
) -- 2272

with cte_unique_customersTwos as (
select distinct cust_id, age, gender, avgSpending, customer_since_year
from kMeansClustering
where cluster = 2)

select age, count(age)
from cte_unique_customersTwos
group by age
order by count(age) 
--top: 41 (48), 25 (48), 37	(50), 40 (50)
-- bottom: 50 (24), 68 (27), 22	(28), 24 (28)

select avg(avgSpending)
from v_uniqueCustomerTwos -- 4909.41 avg spending

select gender, count(Gender)
from v_uniqueCustomerTwos
group by gender -- F (1148), M (1124)

select gender, avg(avgSpending)
from v_uniqueCustomerTwos
group by gender -- F	4923.98, M	4894.53

select cust_id, count(cust_id)
from kMeansClustering
where Cluster = 2
group by cust_id
order by count(cust_id) desc -- 39707 (386), 83736 (279), 59331 (205), 83364 (205), 44619 (204)

select customer_since_year, count(customer_since_year)
from v_uniqueCustomerTwos
group by customer_since_year
order by count(customer_since_year) -- Unknown (ALL)

select customer_since_year
from v_uniqueCustomerTwos
order by customer_since_year














































