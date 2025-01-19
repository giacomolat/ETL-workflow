# ETL-workflow
This project uses **Pentaho Data Integration** and **PostgreSQL** to build a data warehouse (DWH). It includes the sales fact table and two dimensional tables (dim_product and dim_payment). The ETL process implements incremental delta to optimize the extraction and loading of new data.

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

### Junk Dimensional table: dim_payment
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

## ETL Job & Incremental Load
This parent-job consists of two child-jobs, called **Staging** and **Transform&Load** respectively
![image](https://github.com/user-attachments/assets/e861c1bb-15b8-4728-bfd6-20529d1fb682)

### Job: Staging
Job Staging consists of four transformations:
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

#### 3'Transformation for Staging Job: Set variable for Sales;
