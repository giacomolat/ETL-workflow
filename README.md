# ETL-workflow
This project uses **Pentaho Data Integration** and **PostgreSQL** to build a data warehouse (DWH). It includes the sales fact table and two dimensional tables (dim_product and dim_payment). The ETL process implements incremental delta to optimize the extraction and loading of new data.

## Syllabus:
* Setup
* Table Structure
* ETL Job & Incremental Load: Process
* ETL Job & Incremental Load: Final Output

## Setup
* **Software**: Pentaho Data Integration v10.2
* **RDBMS**: PostgreSQL
* **pgAdmin4**: open-source Management Tool for PostgreSQL

## Table Structure
### Fact table: sales
Below is the DDL of the sales fact table, which contains sales, linked to the dim_product and dim_payment dimension tables using a star schema.
#### DDL at the Public level (or Data Sources)
```sql
-- Table: public.sales

-- DROP TABLE IF EXISTS public.sales;

CREATE TABLE IF NOT EXISTS public.sales
(
    transaction_id integer NOT NULL,
    transactional_date timestamp without time zone,
    product_id character varying COLLATE pg_catalog."default",
    customer_id integer,
    payment character varying COLLATE pg_catalog."default",
    credit_card bigint,
    loyalty_card character varying COLLATE pg_catalog."default",
    cost character varying COLLATE pg_catalog."default",
    quantity integer,
    price numeric,
    CONSTRAINT sales_pkey PRIMARY KEY (transaction_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.sales
    OWNER to postgres;
```
#### DDL at the Staging layer
```sql
-- Table: Staging.sales

-- DROP TABLE IF EXISTS "Staging".sales;

CREATE TABLE IF NOT EXISTS "Staging".sales
(
    transaction_id integer NOT NULL,
    transactional_date timestamp without time zone,
    product_id character varying COLLATE pg_catalog."default",
    customer_id integer,
    payment character varying COLLATE pg_catalog."default",
    credit_card bigint,
    loyalty_card character varying COLLATE pg_catalog."default",
    cost numeric,
    quantity integer,
    price numeric,
    CONSTRAINT sales_pkey PRIMARY KEY (transaction_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Staging".sales
    OWNER to postgres;
```
#### DDL at the Core layer
```sql
-- Table: core.sales

-- DROP TABLE IF EXISTS core.sales;

CREATE TABLE IF NOT EXISTS core.sales
(
    transaction_id integer NOT NULL,
    transactional_date timestamp without time zone,
    transactional_date_fk bigint,
    product_id character varying COLLATE pg_catalog."default",
    product_fk integer,
    customer_id integer,
    payment_fk integer,
    credit_card bigint,
    cost numeric,
    quantity integer,
    price numeric,
    total_cost numeric,
    total_price numeric,
    profit numeric,
    CONSTRAINT sales_pkey PRIMARY KEY (transaction_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS core.sales
    OWNER to postgres;
```
#### sales: Column details
* **transaction_id**: this column is a natural key, but since it has an integer as its data type, we can already define it as a surrogate key, so we do not need to add another one;
* **transactional_date**: this column, since it has timestamp (date/time) as its data type, we can interpret it as a delta column, so we can define an incremental load;
* **product_id**: this column represents the natural key of the dim_product dimension table;
* **customer_id**: this column represents an FK in this fact table, but a plausible PK in a dimension table representing customers;
* **payment**, **loyalty_card**: we can define them as flags, so we can put them in a junk dimension;
* **credit_card**: degenerate dimension, bigint type, and not linked to any dimension table, so we can leave it on the fact table;
* **cost**, **quantity**, **price**: non-aggregate measures;
* **total_price**, **total_cost**: total_price and total_cost are two fields calculated through Pentaho Data Integration, with Calculator object, given by the product between price and quantity and the product between cost and quantity, respectively;
![image](https://github.com/user-attachments/assets/6f666c0b-1f86-4644-97b0-0eb2587b4d5c)
* **profit**: profit is field calculated through Pentaho Data Integration, with Calculator object, given by the product between total_price and total_cost rispectively.
![image](https://github.com/user-attachments/assets/c74ec00b-baa1-4a9b-9172-24a378d4705c)
* **product_fk**: product_fk is the foreign key for the primary found in the dim_product dimensional table;
* **payment_fk**: payment_fk is the foreign key for the primary found in the dim_payment dimensional table.

### Dimensional table: dim_product
#### DDL at the Public level (or Data Sources)
```sql
-- Table: public.products

-- DROP TABLE IF EXISTS public.products;

CREATE TABLE IF NOT EXISTS public.products
(
    product_id character varying(5) COLLATE pg_catalog."default",
    product_name character varying(100) COLLATE pg_catalog."default",
    category character varying(50) COLLATE pg_catalog."default",
    subcategory character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.products
    OWNER to postgres;
```
#### DDL at the Staging layer
```sql
-- Table: Staging.dim_product

-- DROP TABLE IF EXISTS "Staging".dim_product;

CREATE TABLE IF NOT EXISTS "Staging".dim_product
(
    "Product_PK" integer NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    product_id character varying COLLATE pg_catalog."default",
    product_name character varying COLLATE pg_catalog."default",
    category character varying COLLATE pg_catalog."default",
    subcategory character varying COLLATE pg_catalog."default",
    CONSTRAINT dim_product_pkey PRIMARY KEY ("Product_PK")
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS "Staging".dim_product
    OWNER to postgres;
```
#### DDL at the Core layer
```sql
-- Table: core.dim_product

-- DROP TABLE IF EXISTS core.dim_product;

CREATE TABLE IF NOT EXISTS core.dim_product
(
    product_pk integer,
    product_id character varying(5) COLLATE pg_catalog."default",
    product_name character varying(100) COLLATE pg_catalog."default",
    category character varying(50) COLLATE pg_catalog."default",
    subcategory character varying(50) COLLATE pg_catalog."default",
    brand character varying(50) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS core.dim_product
    OWNER to postgres;
```
#### dim_product: Column details
* **product_pk**: product_pk is the Surrogate Key;
* **product_id**: product_id is the Primay Key;
* **product_name**, **category**, **subcategory**, **brand**: These columns are the Dimensions.

### "Junk" Dimensional table: dim_payment
#### DDL at the Core layer
```sql
-- Table: core.dim_payment

-- DROP TABLE IF EXISTS core.dim_payment;

CREATE TABLE IF NOT EXISTS core.dim_payment
(
    payment_pk integer NOT NULL GENERATED BY DEFAULT AS IDENTITY ( INCREMENT 1 START 1 MINVALUE 1 MAXVALUE 2147483647 CACHE 1 ),
    payment character varying COLLATE pg_catalog."default",
    loyalty_card character varying COLLATE pg_catalog."default",
    CONSTRAINT dim_payment_pkey PRIMARY KEY (payment_pk)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS core.dim_payment
    OWNER to postgres;
```
#### dim_payment: Column details
* **payment_pk**: These column is a natural key, but since it has an integer as its data type, we can already define it as a surrogate key;
* **payment**, **loyalty_card**: These columns are dimensions, and from the fact table we have already seen that they are flags, so put this junk in the dimension table.

## ETL Job & Incremental Load: Process
This parent-job consists of two child-jobs, called **Staging** and **Transform&Load** respectively
![image](https://github.com/user-attachments/assets/e861c1bb-15b8-4728-bfd6-20529d1fb682)

### Job: Staging
Staging Job consists of four transformations:
* Set Variable;
* Get Data and output data;
* Set variable for Sales;
* Get variable for Sales and Load.

![image](https://github.com/user-attachments/assets/388179cc-b41c-444e-afeb-a3b87362e595)

#### 1'Transformation for Staging Job: Set Variable
Starting from the first transformation, **Set Variable**, we can see that:
![image](https://github.com/user-attachments/assets/e73cdcb3-aec7-4056-9035-45ff4e01458f)

This transformation finds the last upload date and contains the following steps:
* **Table input**: Runs a query, on a table core.dim_product, to determine the last upload date
  ```sql
  SELECT MAX(product_id)
  FROM core.dim_product
  ```
  ![image](https://github.com/user-attachments/assets/eb627879-1317-4bb5-b807-ec38c08c2b14)
* **Set variable**: allowed us to set an environment variable called max, which is the maximum value returned by the query, for the incremental delta operation.
  ![image](https://github.com/user-attachments/assets/a98732e5-badf-48c9-9cf6-8d76dae68169)
  ![image](https://github.com/user-attachments/assets/46c2bf96-8567-4667-9df4-766c2b582526)

#### 2'Transformation for Staging Job: Get Data and output data
The second transformation is as follows:
![image](https://github.com/user-attachments/assets/ac15229f-9b2d-420d-ac6d-08f5adda8419)

This transformation makes it possible to identify records that have been added or modified since the last upload date and contains the following steps:
* **Get variables**: Retrieves the environment variable set on the first transformation, Set Variable
  ![image](https://github.com/user-attachments/assets/d3b52db1-582e-46d3-a7cd-f9c16bdb9dd8)
  ![image](https://github.com/user-attachments/assets/98fe8509-c444-42ce-bed2-fb916e731a25)
* **Table input**: Lets you run an SQL query that filters the source data (i.e., from the data source) by comparing product_id to the last product upload entered.
  ```sql
  SELECT * 
  FROM "public".products 
  WHERE product_id > '${LastLoad}'
  ```
* **Table output**: It allows these new or updated records to be written to the dim_product table in the data warehouse (more specifically, on the staging tier) according to the incremental load model.
  ![image](https://github.com/user-attachments/assets/cb222a6f-e3ad-4ae9-b621-882a18bc231c)

#### 3'Transformation for Staging Job: Set variable for Sales
The third transformation is as follows:
![image](https://github.com/user-attachments/assets/5c5da9bb-0f28-431a-8602-f0687ca00e29)

This transformation finds the last upload date and contains the following steps:
* **Table input**: Runs a query, on a table core.sales, to determine the last upload date, where:
    * for *Full load*, since you have no value at the beginning, you have to enter a dummy value by entering a very old date only for the first load cycle, then later we can use SELECT for Delta load:
      ```sql
      SELECT '1970-01-01 00:00:00' AS LastLoadDate
      ```
      ![image](https://github.com/user-attachments/assets/c67df3ba-4ce2-4a04-b6a3-b53c4eff3ad0)
  * for *Delta load*, through the delta column associated with timestamp type transactions, take for each workflow the new rows:
    ```sql
      SELECT MAX(transactional_date) AS LastLoadDate FROM core.sales
    ```
    ![image](https://github.com/user-attachments/assets/5f33d908-3026-422b-b5fe-6cced90552a0)
* **Set variable**: allowed us to set an environment variable called max, which is the maximum value returned by the query, for the incremental delta operation:
  ![image](https://github.com/user-attachments/assets/a6c68737-120f-470a-817d-19796a4f6560)
  ![image](https://github.com/user-attachments/assets/0705807c-2360-4566-9647-aca3c6fc862d)

#### 4'Transformation for Staging Job: Get variable for Sales and Load
The fourth transformation is as follows:
![image](https://github.com/user-attachments/assets/800651b6-ad38-4df3-bf9c-a8ef5494133a)

This transformation contains the following steps:
* **Get variables**: Retrieves the environment variable set on the third transformation, Set variable for Sales
  ![image](https://github.com/user-attachments/assets/bc266343-9509-48f5-bdd8-c476e639dd3e)
  ![image](https://github.com/user-attachments/assets/2c3b1a38-22ab-4ae4-babf-37052b3aefd4)
* **Table input**: From ```public.sales``` we go to find the rows for which the delta column ```transactional_date > '${LastLoadDate}'```
  ```sql
  SELECT * 
  FROM public.sales 
  WHERE transactional_date > '${LastLoadDate}'
  ```
  ![image](https://github.com/user-attachments/assets/1827d8be-8f36-41c2-b44c-dd260258ed40)
* **Select values**: Since between staging layer and core layer the data type of the cost column is different, through Pentaho we applied a data type transformation, from character varying to number, through the object “Select values”
  ![image](https://github.com/user-attachments/assets/e569ed3b-f37c-46ad-9c16-45af14bbb30b)
  ![image](https://github.com/user-attachments/assets/c0b52c37-8509-4f04-8dc0-a869bc21dc4a)
  ![image](https://github.com/user-attachments/assets/25412ddc-dc55-4c48-bd74-5475c5932720)
  ![image](https://github.com/user-attachments/assets/1659bdb4-7e15-4fab-bdec-43b5525d33b2)
* **Table output**: we can send what we return with that query to the “Staging” table.sales
  ![image](https://github.com/user-attachments/assets/f3ef07de-c87d-447f-a81f-207e79e8ae45)

### Job: Transform & Load
Transform & Load Job consists of two transformations:
* dim_payment;
* fact_sales.

![image](https://github.com/user-attachments/assets/acd6de8d-3b39-436c-8afc-d26a83b9c3df)

#### 1'Transformation for Transform & Load Job: dim_payment
From here we structure our core layer, starting with the dim_payment size table. First, we will manage all the information from PostgresSQL via PgAdmin; in particular, we will look at the different values of the payment and loyalty_card columns to check all possible combinations:
```sql
SELECT DISTINCT payment, loyalty_card
FROM "Staging".sales;
```
![image](https://github.com/user-attachments/assets/7f55f76a-71f9-4a3d-be8f-e8ee6b522b72)

We got in output 4 distinct values for payment and 2 distinct values for loyalty_card. So we will have to change:
* the null values with a dummy value because the null values represent the people who paid cash;
* go to remove whitespace with a trim.

On Postgres, this can be done through the COALESCE function, where null values for payments will be replaced with the string cash:
```sql
SELECT DISTINCT COALESCE(payment, 'cash') as payment, loyalty_card
FROM "Staging".sales;
```
![image](https://github.com/user-attachments/assets/f3bb1b92-66f1-4f02-a4e7-6a0dd4384538)

So we will do this through Pentaho, through the **Table input** object:
![image](https://github.com/user-attachments/assets/681a37bf-45d8-40fb-ba99-2673d4582ae0)
![image](https://github.com/user-attachments/assets/97542413-b144-40a0-8ecc-b14fd03cf88f)

Next the insert/update object, where we are going to load the data on the core.dim_payment size table, checking if the value already exists and if yes, optionally update, if not insert a new combination:
![image](https://github.com/user-attachments/assets/789257ff-125e-4fca-9e93-f0e78162d41d)

#### 2'Transformation for Transform & Load Job: fact_sales
With this transformation we will read the data from the staging table, “Staging”.sales:
```sql
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
```
![image](https://github.com/user-attachments/assets/38d1baa4-ba20-4ed1-a129-a1fa2f511d0e)

Through Pentaho we go to add the Table input object, reading the data through this query tried earlier on PostgreSQL:
![image](https://github.com/user-attachments/assets/4c592c79-8331-4d0b-9a61-948f91a38eac)

Now we are going to calculate the additional fields, such as total_price, total_cost and profit, through the Calculator object:
* ```total_price = price * quantity```
* ```total_cost = cost * quantity```
  ![image](https://github.com/user-attachments/assets/d35d184e-9ce8-4414-ac4f-3fc019161d0f)
  ![image](https://github.com/user-attachments/assets/83ea5d5b-9a45-4f66-9aa4-40f05fbbef1c)
* ```profit = total_price * total_cost```
  ![image](https://github.com/user-attachments/assets/ec4a97ef-e3d2-405a-bf1c-7ef599551a06)
  ![image](https://github.com/user-attachments/assets/cf7d4a1d-5475-4e6e-88c3-0684f9d505dd)

Then we will bring data on core.sales:
![image](https://github.com/user-attachments/assets/e272d8df-e716-4b08-a9e4-03a23b4bf9a3)

#### Output: Transform & Load job
Through PostgreSQL, with pgAdmin4, we check if there is data on the core layer, both for the sales facts table and the dim_payment size table:
![image](https://github.com/user-attachments/assets/09644bef-e150-4c57-af48-ac223343812a)
![image](https://github.com/user-attachments/assets/573e29ba-80eb-440f-a01f-4c55f5a9b7ad)

## ETL Job & Incremental Load: Final Output
Let's test Delta Load by entering data that was not entered at the start, first adding the data in our data source, then go to “DB DataWarehouseX->Public Schema->Facts Sales Table,” then “Import/Export Data...,” importing the data from the Fact_Sales_2.csv file, with expective output:
![image](https://github.com/user-attachments/assets/83af8121-d941-4199-b274-a6252812c681)

```sql
SELECT COUNT(*)
FROM public.sales;
```
![image](https://github.com/user-attachments/assets/8474213a-62b6-4963-b8a0-3143d04c80f5)

```sql
SELECT COUNT(*)
FROM core.sales;
```
![image](https://github.com/user-attachments/assets/f399067e-1d43-4dbe-8ab4-8fdc9ad1e8d1)

Now we are going to test the Delta Incremental, where we have to remember that we had set the dummy value ```‘1970-01-01 00:00:00’``` in SetLastLoadSales.ktr, and going to run the parent job CompleteETLprocess.kjb again, the output is:
![image](https://github.com/user-attachments/assets/fa2e4a92-e537-4006-9f6d-e9bf2fd007f1)
