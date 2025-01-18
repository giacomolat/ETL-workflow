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