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