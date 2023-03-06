--SQL Advance Case Study
use db_SQLCaseStudies

--Q1--BEGIN 

select DISTINCT(dl.State)  from FACT_TRANSACTIONS ft
inner join DIM_LOCATION dl
on ft.idlocation = dl.idlocation
where date BETWEEN '2005-01-01' and getdate()

--Q1--END

--Q2--BEGIN
	
with cte AS(
select dm.IDModel,dmr.manufacturer_name from DIM_MODEL dm
inner join DIM_MANUFACTURER dmr
on dm.IDManufacturer = dmr.IDManufacturer
)
SELECT top 1 dl.state,COUNT(ft.Quantity) 'Count' from FACT_TRANSACTIONS ft
inner join DIM_LOCATION dl
on ft.IDLocation = dl.IDLocation
inner join cte ct
on ft.idmodel = ct.idmodel
WHERE COUNTRY = 'US' AND ct.manufacturer_name = 'Samsung'
group by dl.state
order by COUNT(ft.Quantity) desc



--Q2--END

--Q3--BEGIN      
	
select dl.ZipCode,dl.state,dm.Model_Name, count(dm.IDModel) as 'Number of Transactions'
from  FACT_TRANSACTIONS ft
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel
inner join DIM_LOCATION dl
on ft.IDLocation = dl.IDLocation
group by dl.ZipCode, dl.state, dm.Model_Name

-- Note: here by ' NUMBER OF TRANSACTIONS ' i thought how many orders were placed for each model by each zip code of each state, 
-- in case you were asking for total number of models sold then in place of dm.IDModel in count aggregate function we will put ft.Quantity



--Q3--END

--Q4--BEGIN


select top 1 ft.totalprice 'Price', dm.model_name 'Model Name' from FACT_TRANSACTIONS ft
inner join DIM_MODEL dm
on ft.idmodel = dm.IDModel
order by ft.totalprice


--Q4--END

--Q5--BEGIN

---------------****** working ****** -----------------
with cte as(
select ft.TotalPrice,ft.Quantity,dma.Manufacturer_Name,dm.Model_Name from FACT_TRANSACTIONS ft
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel
inner join DIM_MANUFACTURER dma
on dm.IDManufacturer = dma.IDManufacturer)
select Model_Name,avg(TotalPrice) as 'Average' from cte
where Manufacturer_Name in (select TOP 5 Manufacturer_Name from cte GROUP BY Manufacturer_Name ORDER BY sum(TotalPrice*Quantity) desc)
group by Model_Name
order by avg(TotalPrice) desc
------ ****************--------------------------



--Q5--END

--Q6--BEGIN
with cte as(
select dc.Customer_Name,avg(TotalPrice) 'Average' from FACT_TRANSACTIONS as ft
inner join DIM_CUSTOMER dc
on ft.IDCustomer = dc.IDCustomer
where YEAR(ft.Date) ='2009'
group by dc.Customer_name
)
select * from cte
where Average>500


--Q6--END
	
--Q7--BEGIN  
	
select * from(
select TOP 5  dm.Model_Name as 'model' from FACT_TRANSACTIONS ft
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel 
where year(Date)=2008
group by dm.Model_Name
order by sum(ft.Quantity) desc) a

INTERSECT 

select * from(
select TOP 5 dm.Model_Name as 'model' from FACT_TRANSACTIONS ft --TOP 5
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel 
where year(Date)=2009
group by dm.Model_Name
order by sum(ft.Quantity) desc) b

INTERSECT

select * from(
select TOP 5 dm.Model_Name as 'model' from FACT_TRANSACTIONS ft --TOP 5
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel 
where year(Date)=2010
group by dm.Model_Name
order by sum(ft.Quantity) desc) c


--Q7--END	

--Q8--BEGIN

-- approach 1 WORKING

with cte as(		-- cte -> for joining FACT_TRANSACTIONS(for Quantity and date), DIM_MODEL(to get IDManufacturer) and DIM_MANUFACTURER(for Manufacturer_Name) tables 
	select ft.Date, dma.Manufacturer_Name, ft.Quantity from FACT_TRANSACTIONS ft
	inner join DIM_MODEL dm
	on ft.IDModel = dm.IDModel
	inner join DIM_MANUFACTURER dma
	on dm.IDManufacturer = dma.IDManufacturer
), cte2 as(			-- cte2-> to extract 2nd top manufacturer of 2009 
select top 1 * from(	-- first we are extracting top 2 using order by desc then order by the output asc we are getting top 1, which is 2nd top manufacturer
select  top 2 Manufacturer_Name, sum(Quantity) 'Total' from cte
where year(Date)='2009'
group by Manufacturer_Name
order by sum(Quantity) desc) as tb_tmp
order by Total asc
), cte3 as(			-- cte3-> to extract 2nd top manufacturer of 2010 
select top 1 * from(  -- first we are extracting top 2 using order by desc then order by the output asc we are getting top 1, which is 2nd top manufacturer
select  top 2 Manufacturer_Name, sum(Quantity) 'Total' from cte
where year(Date)='2010'
group by Manufacturer_Name
order by sum(Quantity) desc) as tb_tmp
order by Total asc
)
select '2009' as 'year',* from cte2
union			-- union the output of cte2 and cte3 we got our final output
select '2010' as 'year',* from cte3


-------------------------------------

--Q8--END
--Q9--BEGIN WORKING


with cte as(
select ft.Date, dma.Manufacturer_Name from FACT_TRANSACTIONS ft
inner join DIM_MODEL dm
on ft.IDModel = dm.IDModel	
inner join DIM_MANUFACTURER dma
on dm.IDManufacturer = dma.IDManufacturer)

select distinct(Manufacturer_Name) from cte
where year(Date)=2010 
except			-- EXCPET means get all the values which is not common between two queries
select distinct(Manufacturer_Name) from cte
where year(Date)=2009





--Q9--END

--Q10--BEGIN

with cte as
( 
select year(ft.Date) 'Year',dc.Customer_Name,avg(ft.TotalPrice) 'AVG Spend', avg(ft.Quantity) 'AVG Quantity'
from FACT_TRANSACTIONS ft
inner join DIM_CUSTOMER dc
on ft.IDCustomer = dc.IDCustomer
group by year(ft.Date), dc.Customer_Name
)
select *,

(sum([AVG Spend]) over (partition by Customer_Name order by [year] rows between 1 preceding and 1 preceding) - 
sum([AVG Spend]) over (partition by Customer_Name order by [year] rows between current row and current row))/
sum([AVG Spend]) over (partition by Customer_Name order by [year] rows between 1 preceding and 1 preceding)*(-100) '% change of AVG Spend'
from cte




--Q10--END
	
