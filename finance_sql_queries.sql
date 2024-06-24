-- Create database
create database Bank
use Bank

select * from financial_loan

-------------------------------------------------------------------------------------
----------------------------------- Data Cleaning -----------------------------------
-------------------------------------------------------------------------------------
-- Step 1 : Check for duplicate values

select id, COUNT(*)  count
from financial_loan
group by id
having COUNT(id) > 1

	-- This data doen't contain any duplicate value 


-- Step 2 : Check for null values  

SELECT COLUMN_NAME
FROM information_schema.columns
WHERE table_name = 'financial_loan' and COLUMN_NAME is null
	
	-- emp_title column contains null values


-- % of null values present 

select *, round((res.total_nulls/res.total * 100),2)  as '%_of_nulls'
from(
	select 
	cast(sum(case
			when emp_title is null then 1 
			else 0
		end) as float)total_nulls, 
	COUNT(*) total
	from financial_loan
)res

	-- So, emp_title column contains 3.71 % of null values so we can drop them
	delete from financial_loan
	where emp_title is null
     

-------------------------------------------------------------------------------------
---------------------------------------- EDA ----------------------------------------
-------------------------------------------------------------------------------------

-- 1. Total loan applications 

select COUNT(distinct id) total_loan_applications
from financial_loan


-- 2. Unique type of loan applications

select distinct application_type
from financial_loan


-- 3. Unique type of loan status

select distinct loan_status
from financial_loan


-- 4. Total loan applications based on loan_status

select loan_status, COUNT(*) total_applications
from financial_loan
group by loan_status


-- 5. Total funded loan amount

select concat((sum(loan_amount) / 1000000), ' millions') total_funded_loan_amount
from financial_loan


-- 6. Total payment received

select  sum(total_payment) total_payment_received
from financial_loan


-- 7. Average interest rate based on purpose

select purpose, round(AVG(int_rate),2) * 100 avg_int_rate
from financial_loan
group by purpose


-- 8. Average DTI based on purpose

select purpose, round(AVG(dti),2) * 100 avg_dti
from financial_loan
group by purpose


-- 9. Average DTI group by month

select month(issue_date) month, DATENAME(m,issue_date) month_name, ROUND(avg(dti),2) * 100 avg_dti
from financial_loan
group by DATENAME(m,issue_date),month(issue_date)
order by month


-- Good Loan vs Bad Loan
-- 1. Total loan applications and total good loan applications

select COUNT(id) total_applications, 
sum(
	case 
		when loan_status in ('current', 'fully paid') then 1
	end) total_good_loan_applications
from financial_loan


-- 2. Good loan applications %

select 
sum(
	case
		when loan_status in ('current','fully paid') then 1  
	end)*100 / count(id) '%_of_good_loan_applications'
from financial_loan


-- 3. Total amount received for good loan

select concat(round(SUM(total_payment) / 1000000, 2), ' millions') total_amount_recieved
from financial_loan
where loan_status in ('current', 'fully paid')


-- 4. Total loan applications and total bad loan applications

select COUNT(id) total_applications,
SUM(
	case
		when loan_status = 'charged off' then 1
	end) total_bad_loan_applications
from financial_loan


-- 5. Bad loan applications %

select 
SUM(
	case	
		when loan_status = 'charged off' then 1 
	end
) * 100 / COUNT(*) '%__of_bad_loan_applications'
from financial_loan


-- 6. Total amount received for bad loan

select concat(round(SUM(total_payment / 1000000),2), ' millions') total_amount_received
from financial_loan
where loan_status = 'charged off'

-- 7. Month over month total amount recieved


with month_over_month_payment as (
	select MONTH(issue_date) month, DATENAME(m,issue_date) month_name, SUM(total_payment) total_payment
	from financial_loan
	group by MONTH(issue_date), DATENAME(m,issue_date)
) 

select *, 
LAG(total_payment,1,0) over(order by month) prev_month_payment,
(total_payment - LAG(total_payment,1, total_payment) over(order by month)) month_over_month_pay
from month_over_month_payment


-- 8. Month to month avg interest rate and round it upto 2 decimal places

with month_over_month_avg_int_rate as (
	select MONTH(issue_date) month, DATENAME(m,issue_date) month_name, round(AVG(int_rate)*100,2) avg_int_rate
	from financial_loan
	group by MONTH(issue_date), DATENAME(m,issue_date)
)
select *, 
LAG(avg_int_rate, 1, 0) over(order by month) prev_month_avg_int_rate,
round(avg_int_rate - LAG(avg_int_rate, 1, avg_int_rate) over(order by month) , 2) month_over_month_avg_rate
from month_over_month_avg_int_rate
