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