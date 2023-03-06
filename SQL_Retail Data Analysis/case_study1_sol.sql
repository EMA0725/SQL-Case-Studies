use case_study1

select * from Transactions
select * from customer
select * from prod_cat_info

-- case study 1
-- DATA PREPARATION AND UNDERSTANDING

--1.Total number of rows in each table

select 'Transaction' as 'rows in',
count(*) as 'row count' 
from Transactions
union
select 'customer', count(*) from customer
union
select 'prod_cat_info', count(*) from prod_cat_info;

------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Total Transactions of return 
select count(*) 
as Total_return
from Transactions 
where Qty<0;

------------------------------------------------------------------------------------------------------------------------------------------------
-- 3. Correcting Date format

-- changing date of Transaction table
update Transactions
set tran_date=convert(date,tran_date,105)
begin tran
alter table Transactions
alter column tran_date date
--commit

-- changing date of customer table
update customer
set DOB=convert(date,DOB,105)
begin tran
alter table customer
alter column DOB date
--commit

------------------------------------------------------------------------------------------------------------------------------------------------

--4. Time range of Transactions

select 
(YEAR(max(tran_date))-YEAR(min(tran_date))) as year,
(MONTH(max(tran_date))-MONTH(min(tran_date))) as month,
(DAY(max(tran_date))-DAY(min(tran_date))) as day
from transactions;

------------------------------------------------------------------------------------------------------------------------------------------------

--5. prod categoty DIY belong to
select prod_cat
from prod_cat_info
where prod_subcat='DIY';

------------------------------------------------------------------------------------------------------------------------------------------------

-- DATA ANALYSIS

--1. Most frequently used channels
select top 1 Store_type, count(Store_type) as 'No. of Transactions'
from Transactions
group by (Store_type)
order by count(Store_type) desc

------------------------------------------------------------------------------------------------------------------------------------------------

--2. Count of male and female customers

select Gender, count(distinct(cust_id))
from Transactions t
inner join Customer c
on t.cust_id=c.customer_Id
--where datalength(Gender)<>0
WHERE Gender <> ''
group by Gender

------------------------------------------------------------------------------------------------------------------------------------------------

--3. From which city we have maximum number of customer and by how many

select top 1 city_code, count(city_code) as 'number_of_customers'
from Transactions t
inner join Customer c
on t.cust_id = c.customer_Id
where city_code <> ''		-- there are some empty data in city_code which we are ignoring
group by city_code
order by count(city_code) desc;

------------------------------------------------------------------------------------------------------------------------------------------------

--4. sub-category under book category

select count(prod_subcat)
as 'count_of_sub_category'
from prod_cat_info
where 
prod_cat='Books';

------------------------------------------------------------------------------------------------------------------------------------------------

--5. max quantity ever ordered
select max(Qty)
as 'Max_qty_ever_ordered'
from Transactions;

------------------------------------------------------------------------------------------------------------------------------------------------

--6. Net revenue of books and electronics 

with pcc
as (
select distinct(prod_cat_code) pc_code, prod_cat
from prod_cat_info )
select  prod_cat, sum(cast(total_amt as float)) 'Net_Revenue'
from Transactions t
inner join pcc p
on t.prod_cat_code = p.pc_code
where prod_cat = 'Electronics' or  prod_cat = 'Books'
group by prod_cat;

------------------------------------------------------------------------------------------------------------------------------------------------

--7. count of customers with >10 transaction excluding return

------------------- with cte -----------------------------
with tb_Transac
as
(
select count(cust_id) as customer_id
from Transactions
where convert(float,total_amt)>0
group by cust_id
having count(cust_id)>10 
)
select count(customer_id) 
from tb_Transac

------------------- with sub-query -----------------------------

select count(count_of_cust) as 'count of customers with >10 transaction excluding return'
from(
select count(cust_id) as count_of_cust
from Transactions
where convert(float,total_amt)>0
group by cust_id
having count(cust_id)>10 
) as cust_count

------------------------------------------------------------------------------------------------------------------------------------------------

--8. sum of Electronics and Clothing under Flagship store

select sum(cast(amt as float))
from(
select total_amt as amt,prod_cat 'prod_cat', Store_type 'Store_type'  from Transactions t
inner join (
select distinct(prod_cat_code) as 'prod_cat_code', prod_cat 'prod_cat' from prod_cat_info 
) as p
on t.prod_cat_code = p.prod_cat_code
) as hel
where hel.prod_cat='Electronics' or hel.prod_cat='Clothing' and  hel.Store_type='Flagship store'

--- Approach 2------

select sum(convert(float,total_amt)) as 'sum of Electronics and Clothing under Flagship store '  from Transactions t
inner join (
select distinct(prod_cat_code) as 'prod_cat_code', prod_cat 'prod_cat' from prod_cat_info 
) as p
on t.prod_cat_code = p.prod_cat_code
where prod_cat='Electronics' or prod_cat='Clothing' and  Store_type='Flagship store'

------------------------------------------------------------------------------------------------------------------------------------------------

--9. Revenue by male customer through Electronics and grouped by Sub-Category

select prod_subcat 'Product sub category', sum(convert(float,total_amt)) 'Total Revenue' from Transactions t
inner join (select distinct(customer_Id) as 'customer_Id', Gender 'Gender'  from customer) c
on t.cust_id=c.customer_Id
inner join ( select * from prod_cat_info) p
on t.prod_cat_code=p.prod_cat_code and t.prod_subcat_code=p.prod_sub_cat_code
where Gender='M' and prod_cat='Electronics'
group by prod_subcat

------------------------------------------------------------------------------------------------------------------------------------------------

--10. % of sales and return of top 5 sub-cat in term of sales 

alter table Transactions
alter column total_amt float

with cte as(
select t.total_amt 'total_amt', p.prod_subcat 'prod_subcat' from Transactions t
inner join prod_cat_info p
on t.prod_cat_code=p.prod_cat_code and t.prod_subcat_code=p.prod_sub_cat_code)

select top 5 prod_subcat,(sum(case when c.total_amt<0 then c.total_amt*(-1) else 0 end)/sum(c.total_amt))*100 '% of return',
(sum(case when c.total_amt>0 then c.total_amt else 0 end)/sum(c.total_amt))*100 '% of sale'
from cte c
group by prod_subcat
order by [% of sale] desc

------------------------------------------------------------------------------------------------------------------------------------------------

--11. net revenue generated by customers between 25 and 30 in last 30 days

with cte as (
select *,case 
when   MONTH(DOB)>MONTH(GETDATE()) THEN DATEDIFF(year ,DOB ,(select GETDATE() as date))-1
when   MONTH(GETDATE())=MONTH(DOB) AND DAY(DOB)>DAY(GETDATE()) THEN DATEDIFF(year ,DOB ,(select GETDATE() as date))-1
else DATEDIFF(year ,DOB ,(select GETDATE() as date)) 
end as 'year' from Customer c
)

select sum(total_amt) from Transactions t
inner join cte c 
on t.cust_id=c.customer_Id
where c.year between 25 and 35 and  DATEDIFF(day,tran_date ,(select max(tran_date) from Transactions)) <=30 ; 

------------------------------------------------------------------------------------------------------------------------------------------------

--12. prod category with max value of return in last 3 months

select top 1 prod_cat, sum(total_amt) 'value of returns' from Transactions t
inner join (select distinct(prod_cat_code) 'prod_cat_code', prod_cat 'prod_cat' from prod_cat_info p) as p
on t.prod_cat_code=p.prod_cat_code
where total_amt<0 and DATEDIFF(month,t.tran_date,(select max(tran_date) from Transactions)) <3
group by prod_cat
order by [value of returns] 

------------------------------------------------------------------------------------------------------------------------------------------------

--13. store type that sells max products; by value and by qty

select top 1 Store_type from(
select Store_type , sum(convert(float,total_amt)) 'sales' ,count(qty) 'qty' from Transactions t
group by Store_type
) as tb_st
order by tb_st.sales desc,tb_st.qty desc 

------------------------------------------------------------------------------------------------------------------------------------------------

--14. prod categories where avg is greater than total average
select prod_cat from Transactions t
inner join (select distinct(prod_cat_code)'prod_cat_code', prod_cat 'prod_cat' from  prod_cat_info) as p
on t.prod_cat_code=p.prod_cat_code
group by prod_cat
having avg(total_amt)>(select avg(total_amt) from Transactions)

------------------------------------------------------------------------------------------------------------------------------------------------

--15. Avg. and total revenue of each sub-cat for top 5 categories in terms of quant sold

with  cte as (
select prod_cat,Qty,prod_subcat,total_amt from Transactions t
inner join prod_cat_info p
on t.prod_cat_code = p.prod_cat_code and t.prod_subcat_code = p.prod_sub_cat_code
)
select prod_subcat,avg(total_amt) 'avg' ,sum(total_amt) 'sum' from cte
where prod_cat in 
(
select top 5 prod_cat from cte
group by prod_cat
order by count(Qty) desc		-- why order by worked here

)
group by prod_subcat

------------------------------------------------------------------------------------------------------------------------------------------------