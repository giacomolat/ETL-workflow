SELECT 
	transaction_id ,
	transactional_date ,
	EXTRACT(year from transactional_date)*10000 + EXTRACT('month' from transactional_date)*100+EXTRACT('day' from transactional_date)as 	transactional_date_fk,
	f.product_id ,
	p.product_PK as product_FK,
	payment_PK as payment_FK,
    customer_id ,
    credit_card ,
   	cost  ,
    quantity ,
   	price
FROM "Staging".sales f
LEFT JOIN 
core.dim_payment d
ON d.payment = COALESCE(f.payment,'cash') AND d.loyalty_card=f.loyalty_card
LEFT JOIN core.dim_product p on p.product_id=f.product_id
order by transaction_id
