SHOW TABLES;

#1st request 
SELECT * from dim_customer;
select market from dim_customer where customer="Atliq Exclusive" and region="APAC";

#2nd request 
SELECT unique_products_2020,unique_products_2021,((unique_products_2021 - unique_products_2020) / unique_products_2020) * 100.0 AS percentage_chg
FROM (
SELECT COUNT(DISTINCT CASE 
            WHEN fiscal_year = 2020 
            THEN product_code 
        END) AS unique_products_2020,
        COUNT(DISTINCT CASE 
            WHEN fiscal_year = 2021 
            THEN product_code 
        END) AS unique_products_2021        
FROM fact_sales_monthly
WHERE fiscal_year IN (2020 , 2021)
) AS product_data;

select * from fact_sales_monthly;


#3rd request 
SELECT * from dim_product;
select segment, count(distinct(product_code)) as product_count 
from dim_product group by segment order by product_count desc;

#4th request
SELECT * FROM (
SELECT dim_product.segment,
	COUNT(DISTINCT CASE 
	WHEN fact_sales_monthly.fiscal_year = 2020 
	THEN fact_sales_monthly.product_code 
	END) AS product_count_2020,
        
	COUNT(DISTINCT CASE 
	WHEN fact_sales_monthly.fiscal_year = 2021 
	THEN fact_sales_monthly.product_code 
	END) AS product_count_2021
FROM fact_sales_monthly
JOIN dim_product ON fact_sales_monthly.product_code = dim_product.product_code
WHERE fiscal_year IN (2020 , 2021)
GROUP BY dim_product.segment
) AS segment_data
ORDER BY (product_count_2021 - product_count_2020) DESC
LIMIT 1;



#5th request
SELECT dim_product.product_code ,dim_product.product, fact_manufacturing_cost.manufacturing_cost from dim_product
inner join fact_manufacturing_cost on fact_manufacturing_cost.product_code =dim_product.product_code 
WHERE fact_manufacturing_cost .manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
OR fact_manufacturing_cost .manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost); 

#6th request
select avg(fact_pre_invoice_deductions.pre_invoice_discount_pct)*100 as average_discount_percentage 
,dim_customer.customer, dim_customer.customer_code from dim_customer 
inner join fact_pre_invoice_deductions on fact_pre_invoice_deductions.customer_code=dim_customer.customer_code 
where fact_pre_invoice_deductions.fiscal_year=2021 and dim_customer.market='India'
group by dim_customer.customer,dim_customer.customer_code order by average_discount_percentage desc
limit 5 ;

#7th request
select monthname(fact_sales_monthly.date) as month,fact_sales_monthly.fiscal_year as year,
sum( fact_gross_price.gross_price *fact_sales_monthly.sold_quantity) as 'Gross_sales_Amount' 
from fact_sales_monthly
join  dim_customer on fact_sales_monthly.customer_code = dim_customer.customer_code
join fact_gross_price on fact_sales_monthly.product_code = fact_gross_price.product_code
where customer="Atliq Exclusive"
group by month,year
order by year asc;


#8th request
SELECT 
case when  date between '2019-09-01' and '2019-11-01' then 'Q1'
when  date between '2019-12-01' and '2020-02-01' then 'Q2'
when  date between '2020-03-01' and '2020-05-01' then 'Q3'
when  date between '2020-06-01' and '2020-08-01' then "Q4" end as Quarter,
sum(sold_quantity) as total_sold_quantity from fact_sales_monthly where fiscal_year = 2020
group by Quarter
order by total_sold_quantity desc;

#9th request
SELECT dim_customer.channel,
    ROUND(
        SUM(fact_gross_price.gross_price * fact_sales_monthly .sold_quantity) / 1000000,2) AS gross_sales_mln,
    ROUND(
        SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) * 100 / SUM(SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity)) OVER (),
        2) AS percentage
FROM fact_sales_monthly 
JOIN fact_gross_price ON fact_sales_monthly.product_code = fact_gross_price.product_code
JOIN dim_customer ON fact_sales_monthly.customer_code = dim_customer.customer_code
WHERE fact_sales_monthly.fiscal_year = 2021
GROUP BY dim_customer.channel
ORDER BY gross_sales_mln DESC;

#10th request
select * from( select fact_sales_monthly.product_code ,dim_product.division ,dim_product.product 
, sum(fact_sales_monthly.sold_quantity) as total_sold_quantity ,
 RANK() OVER (
            PARTITION BY dim_product.division
            ORDER BY SUM(fact_sales_monthly.sold_quantity) DESC
        ) AS rank_order
from fact_sales_monthly
join dim_product on fact_sales_monthly.product_code = dim_product.product_code
where fiscal_year = 2021 
group by fact_sales_monthly.product_code ,dim_product.division ,dim_product.product 
) AS ranked_data
WHERE rank_order <= 3;











