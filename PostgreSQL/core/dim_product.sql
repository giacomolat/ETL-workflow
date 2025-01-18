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