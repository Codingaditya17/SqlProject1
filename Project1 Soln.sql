-- Q1-write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
with cte as ( select sum(amount) as total_spend , City from [Credit_card_transactions ] group by City)
, cte1 as (select sum(cast(amount as bigint)) as total_amount from [Credit_card_transactions ])
select top 5  cte.*,round(total_spend*1.0/total_amount*100,2) as percentage from cte inner join cte1 on 1=1
order by total_spend desc

--Q2- write a query to print highest spend month and amount spent in that month for each card type
with cte as (
select card_type,datepart(year,Date) yt
,datepart(month,Date) mt,sum(amount) as total_spend
from [Credit_card_transactions ]
group by card_type,datepart(year,Date),datepart(month,Date)
)
select * from (select *, rank() over(partition by card_type order by total_spend desc) as rn
from cte) a where rn=1

--Q3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (
select *,sum(amount) over(partition by card_type order by date,id) as total_spend
from [Credit_card_transactions ]
)
select * from (select *, rank() over(partition by card_type order by total_spend) as rn  
from cte where total_spend >= 1000000) a where rn=1

--Q4- write a query to find city which had lowest percentage spend for gold card type
with cte as (
select top 1 city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from [Credit_card_transactions ]
group by city,card_type)
select 
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having count(gold_amount) > 0 and sum(gold_amount)>0
order by gold_ratio;


--Q5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)/
with cte as (
select city,exp_type, sum(amount) as total_amount from [Credit_card_transactions ]
group by city,exp_type)
select
city , min(case when rn_desc=1 then exp_type end) as lowest_exp_type
, max(case when rn_asc=1 then exp_type end) as highest_exp_type
from
(select *
,rank() over(partition by city order by total_amount desc) rn_desc
,rank() over(partition by city order by total_amount asc) rn_asc
from cte) A
group by city;

--Q6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount)*100 as percentage_female_contribution
from [Credit_card_transactions ]
group by exp_type
order by percentage_female_contribution desc;

--Q7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type,exp_type,datepart(year,Date) yt
,datepart(month,Date) mt,sum(amount) as total_spend
from [Credit_card_transactions ]
group by card_type,exp_type,datepart(year,Date),datepart(month,Date)
)
select  top 1 *, (total_spend-prev_mont_spend) as mom_growth
from (
select *
,lag(total_spend,1) over(partition by card_type,exp_type order by yt,mt) as prev_mont_spend
from cte) A
where prev_mont_spend is not null and yt=2014 and mt=1
order by mom_growth desc;

--Q8- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city , sum(amount)*1.0/count(1) as ratio
from [Credit_card_transactions ]
where datepart(weekday,Date) in (1,7)
group by city
order by ratio desc;

--Q9- which city took least number of days to reach its
--500th transaction after the first transaction in that city;
with cte as (
select *
,row_number() over(partition by city order by Date,id) as rn
from [Credit_card_transactions ])
select top 1 city,datediff(day,min(Date),max(Date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
