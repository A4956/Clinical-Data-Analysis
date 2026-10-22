create database marketdb;
use marketdb;

select * from doctors;
select * from market_data;
select * from prescriptions;
select * from products;
select * from sales_reps;
select * from sales_transactions;
select * from territories;
--  -------------------------------------------- PRODUCT SALES PERFORMANCE -------------------------------------------------------------------- -------------------------
-- 1. The commercial team wants to identify its best-selling products. Calculate total units sold and total net sales for each product for 2025.
select * from products;
select * from sales_transactions;

SELECT 
    p.product_id,
    p.product_name,
    SUM(st.units_sold) AS total_units_sold,
    SUM(st.net_sales_inr) AS total_net_sales
FROM
    products p
        JOIN
    sales_transactions st ON p.product_id = st.product_id
GROUP BY p.product_id , p.product_name
ORDER BY total_units_sold , total_net_sales DESC;
         
--  2.-------------------------------------------- Regional SALES PERFORMANCE -------------------------------------------------------------------- -------------------------
-- Management wants to compare sales across regions for January–June 2026.

-- Requirements:
--  Include only completed transactions.
-- Calculate total transactions, total units sold, and total net sales for each region.
-- Return region, total_transactions, total_units_sold, and total_net_sales.
-- Rank regions by total net sales, highest first.

select * from sales_transactions;
select * from territories;

select t.region, 
       count(st.transaction_id) as total_transactions, 
	   sum(st.units_sold) as total_units_sold, 
       sum(st.net_sales_inr) as total_net_sales

from territories t 
join sales_transactions st on t.territory_id= st.territory_id
group by t.region
order by total_net_sales desc;

-- 3.-------------------------------------------- Prescription fulfillment rate -------------------------------------------------------------------- -------------------------
-- The operations team needs to understand prescription completion by therapeutic area for 2025.

-- Requirements:
-- Calculate total prescriptions and fulfilled prescriptions for each therapeutic area.
-- Calculate fulfillment rate as a percentage of all prescription records.
-- Include all prescription statuses in the denominator.
-- Return only areas with at least 30 prescription records.
-- Round the rate to two decimal places.

select * from prescriptions;
select * from products;

SELECT 
    p.therapeutic_area,
    COUNT(pr.prescription_id) AS total_prescription,
    SUM(CASE
        WHEN pr.prescription_status = 'fulfilled' THEN 1
        ELSE 0
    END) AS fullfilled_prescription,
    ROUND(100 * SUM(CASE
                WHEN pr.prescription_status = 'fulfilled' THEN 1
                ELSE 0
            END) / NULLIF(COUNT(pr.prescription_id), 0),
            2) AS fullfillment_rate
FROM
    products p
        JOIN
    prescriptions pr ON pr.product_id = p.product_id
WHERE
    prescription_date >= '2025-01-01'
        AND prescription_date <= '202601-01'
GROUP BY p.therapeutic_area
ORDER BY fullfillment_rate DESC;

-- 4.-------------------------------------------- Monthly revenue growth -------------------------------------------- -------------------------------------------- 
-- Calculate monthly net sales for completed transactions throughout 2025, then compare each month with the previous month.

select * from sales_transactions;

with monthly_total_sales as (select date_format(transaction_date, "%Y-%m") as monthly,
							sum(net_sales_inr) as total_sales
					from sales_transactions
                    where transaction_date >= '2025-01-01' and transaction_date <= '2025-12-31'
                    group by date_format(transaction_date, "%Y-%m")
                    ),
revenue_comparsion as ( select  monthly,
								total_sales, 
                                lag(total_sales) over(order by monthly) as previous_month_revenue
						from monthly_total_sales)
select monthly, 
		total_sales,
         previous_month_revenue,
         round(total_sales-previous_month_revenue ,2) as revenue_cahnge,
         round(100*(total_sales-previous_month_revenue)/nullif(previous_month_revenue,0),2) as growth_percentage
from revenue_comparsion
order by growth_percentage desc;
-- 5.--------------------------------------------Top 3 products within each therapeutic area ----------------------------------------------------------------------------------------

-- The product strategy team wants the three highest-revenue products in each therapeutic area for 2025.

select * from products;
select * from sales_transactions;
with revenue_product as ( select p.product_id, 
								 p.product_name,
                                 p.therapeutic_area,
								 sum(st.gross_sales_inr) as total_revenue
						  from products p
                          join sales_transactions st on st.product_id= p.product_id
                          group by p.product_id, 
								 p.product_name,
                                 p.therapeutic_area),
product_rank as ( select product_id, 
						 product_name, 
                         therapeutic_area,
                         total_revenue, 
                         dense_rank() over(partition by therapeutic_area order by total_revenue desc) as RNK
				 from revenue_product)
select product_id, 
	   product_name, 
	   therapeutic_area,
	   total_revenue,
       RNK
from product_rank
where RNK <=3;
-- 6.-------------------------------------------- Sales representative performance ranking  -------------------------------------------- -------------------------------------------- 

-- Rank sales representatives by completed net sales within each region from January to September 2026.

select * from sales_reps;
select * from territories;
select * from sales_transactions;

with rep_sales as ( select sr.sales_rep_id, 
						   sr.first_name,
                           sr.last_name,
                           t.region,
                           coalesce(sum(st.net_sales_inr),0) as total_sales_inr
					from sales_reps sr
                    join territories t on t.territory_id= sr.territory_id
                    join sales_transactions st on st.territory_id=sr.territory_id
                    and st.transaction_status = 'completed'
                    and transaction_date >= '2026-01-01'
                    and transaction_date <'2026-10-01'
                    group by sr.sales_rep_id, 
						   sr.first_name,
                           sr.last_name,
                           t.region),
ranked_reps as ( select  sales_rep_id, 
						 first_name,
                         last_name,
						region,
                        total_sales_inr,
                        dense_rank() over( order by total_sales_inr desc) as sales_rnk
				from  rep_sales)
select sales_rep_id, 
	   first_name,
       last_name,
       region,
	   total_sales_inr,
       sales_rnk
from ranked_reps
order by sales_rnk;

-- -------------------------------------------- Estimate pharmaceutical market share -------------------------------------------- -------------------------------------------- 
-- Management wants to compare company sales with estimated market sales by territory and therapeutic area for 2025.

select * from market_data;
select * from sales_transactions;
select * from products;


WITH company_sales AS (
    SELECT
        DATE_FORMAT(st.transaction_date, '%Y-%m') AS sales_month,
        st.territory_id,
        p.therapeutic_area,
        SUM(st.net_sales_inr) AS total_net_sales
    FROM sales_transactions st
    JOIN products p
        ON p.product_id = st.product_id
    WHERE st.transaction_date >= '2025-01-01'
      AND st.transaction_date < '2026-01-01'
      AND st.transaction_status = 'Completed'
    GROUP BY
        DATE_FORMAT(st.transaction_date, '%Y-%m'),
        st.territory_id,
        p.therapeutic_area
),
market_share AS (
    SELECT
        cs.sales_month,
        t.territory_name,
        cs.territory_id,
        cs.therapeutic_area,
        cs.total_net_sales,
        md.estimated_market_sales_inr,
        ROUND(
            100.0 * cs.total_net_sales
            / NULLIF(md.estimated_market_sales_inr, 0),
            2
        ) AS market_share_pct
    FROM company_sales cs
    JOIN territories t
        ON t.territory_id = cs.territory_id
    JOIN market_data md
        ON md.territory_id = cs.territory_id
       AND md.therapeutic_area = cs.therapeutic_area
       AND DATE_FORMAT(md.report_month, '%Y-%m') = cs.sales_month
)
SELECT
    sales_month,
    territory_id,
    territory_name,
    therapeutic_area,
    total_net_sales,
    estimated_market_sales_inr,
    market_share_pct
FROM market_share
ORDER BY sales_month, territory_name;


-- 9.Prescription-to-Sales Gap Analysis
       
WITH fulfilled_prescriptions AS (
    SELECT
        d.doctor_id,
        CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
        p.product_id,
        p.product_name,
        COUNT(pr.prescription_id) AS fulfilled_prescription_count
    FROM doctors d
    JOIN prescriptions pr
        ON d.doctor_id = pr.doctor_id
    JOIN products p
        ON pr.product_id = p.product_id
    WHERE d.doctor_status = 'Active'
      AND pr.prescription_status = 'Fulfilled'
      AND pr.prescription_date >= '2025-01-01'
      AND pr.prescription_date < '2026-01-01'
    GROUP BY
        d.doctor_id,
        d.first_name,
        d.last_name,
        p.product_id,
        p.product_name
)
SELECT
    fp.doctor_id,
    fp.doctor_name,
    fp.product_name,
    fp.fulfilled_prescription_count
FROM fulfilled_prescriptions fp
WHERE NOT EXISTS (
    SELECT 1
    FROM sales_transactions st
    WHERE st.doctor_id = fp.doctor_id
      AND st.product_id = fp.product_id
      AND st.transaction_status = 'Completed'
      AND st.transaction_date >= '2025-01-01'
      AND st.transaction_date < '2026-01-01'
)
ORDER BY
    fp.fulfilled_prescription_count DESC,
    fp.doctor_name;
                        
                               
                               
                               


                        
                    
                           

                          

