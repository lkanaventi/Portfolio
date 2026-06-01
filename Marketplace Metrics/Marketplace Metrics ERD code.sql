/*-------------------------------------------------------------------------
AI USAGE CITATION (ERD & DATABASE SCHEMA DESIGN)
-------------------------------------------------------------------------
Tool: ChatGPT (OpenAI)
Usage Scope: Structural review and refinement of relational schema design
             in PostgreSQL.

Purposes:
1. Constraint Strategy Review: Evaluated primary key design decisions,
   including trade-offs between composite keys and surrogate keys in
   high-cardinality transactional tables.
2. Sequence & Data Type Scaling: Assisted in resolving integer overflow
   constraints by migrating from smallserial to bigint with controlled
   sequence management.
3. Referential Integrity Optimization: Reviewed foreign key mappings to
   ensure normalized relationships between customers, sellers, products,
   and transactional tables.
4. Import & Post-Load Adjustment Strategy: Guided safe modification of
   column defaults and constraints to support bulk CSV ingestion and
   relational backfilling.

Representative Prompts:
- "Evaluate my primary key strategy for order_items and recommend a scalable alternative."
- "What is the safest way to migrate a serial column to bigint in PostgreSQL while preserving sequence continuity?"
- "Review my schema relationships and suggest improvements for normalization and referential integrity."
- "How should I handle foreign key population when importing denormalized CSV files?"

Verification:
All structural decisions were implemented and validated directly in
PostgreSQL through constraint enforcement and successful full dataset
execution.
-------------------------------------------------------------------------
*/


CREATE TABLE product_category_name_translation (
	product_category_name varchar(200),
	product_category_name_english varchar(200),
	category_id bigserial UNIQUE
);

CREATE TABLE geolocation (
	geolocation_zip_code_prefix varchar(5),
	geolocation_lat numeric(50,14),
	geolocation_lng numeric(50,14),
	geolocation_city varchar(100),
	geolocation_state char(2),
	geolocation_id bigserial PRIMARY KEY
);

CREATE TABLE customers (
	customer_id varchar(100) PRIMARY KEY,
	customer_unique_id varchar(100),
	customer_zip_code_prefix varchar(5),
	geolocation_id bigint
		REFERENCES geolocation(geolocation_id),
	customer_city varchar(100),
	customer_state char(2)
);

UPDATE customers c
SET geolocation_id = g.geolocation_id
FROM geolocation g
WHERE c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
	AND c.customer_city = g.geolocation_city
	AND c.customer_state = g.geolocation_state
;

CREATE TABLE sellers (
	seller_id varchar(100) PRIMARY KEY,
	seller_zip_code_prefix varchar(5),
	geolocation_id bigint
		REFERENCES geolocation(geolocation_id),
	seller_city varchar(100),
	seller_state char(2)
);

UPDATE sellers s
SET geolocation_id = g.geolocation_id
FROM geolocation g
WHERE s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
	AND s.seller_city = g.geolocation_city
	AND s.seller_state = g.geolocation_state
;

CREATE TABLE products (
	product_id varchar(100) PRIMARY KEY,
	product_category_name varchar(100),
	product_name_lenght char(2),
	product_description_lenght numeric(100,0),
	product_photos_qty numeric(20,0),
	product_weight_g numeric(100,0),
	product_length_cm numeric(100,0),
	product_height_cm numeric(100,0),
	product_width_cm numeric(100,0),
	category_id bigserial
		REFERENCES product_category_name_translation(category_id)
);

ALTER TABLE products
ALTER COLUMN category_id DROP DEFAULT,
ALTER COLUMN category_id TYPE bigint;

ALTER TABLE products
ALTER COLUMN category_id DROP NOT NULL;

/* category_id is a foreign key to the category table. Initially set up as a bigserial
for simplicity, but to import CSV data and populate it correctly from the category
lookup table, we convert it to bigint and allow NULLS.
*/

UPDATE products p
SET category_id = pt.category_id
FROM product_category_name_translation pt
WHERE p.product_category_name = pt.product_category_name
;

CREATE TABLE orders (
	order_id varchar(100) PRIMARY KEY,
	customer_id varchar(100)
		REFERENCES customers(customer_id),
	order_status varchar(100),
	order_purchase_timestamp timestamptz,
	order_approved_at timestamptz,
	order_delivered_carrier_date timestamptz,
	order_delivered_customer_date timestamptz,
	order_estimated_delivery_date timestamptz
);

CREATE TABLE order_items (
	order_id varchar(100) 
		REFERENCES orders(order_id),
	order_item_id smallserial,
	product_id varchar(100)
		REFERENCES products(product_id),
	seller_id varchar(100)
		REFERENCES sellers(seller_id),
	shipping_limit_date timestamptz,
	price numeric(6,2),
	freight_value numeric(6,2),
	CONSTRAINT pk_order_items
		PRIMARY KEY (order_id, product_id, seller_id)
);

ALTER TABLE order_items
DROP CONSTRAINT pk_order_items;

ALTER TABLE order_items
ADD CONSTRAINT pk_order_items_id PRIMARY KEY (order_item_id);

ALTER TABLE order_items
ALTER COLUMN order_item_id SET NOT NULL;

/* composite key didn't work because there was at least more than one listing that had the same
order_id, product_id, and seller_id so I needed to create a different primary key that was unique*/

ALTER TABLE order_items
ALTER COLUMN order_item_id SET DATA TYPE bigint,
ALTER COLUMN order_item_id SET DEFAULT nextval('order_items_order_item_id_seq'::regclass);

/* Adjust order_item_id to support the full dataset. Originally defined as smallserial, which auto
increments only to 32,767. The table has 112,650 rows, so smallserial would overflow. Changed it 
to bigint and add the sequence manually to behave like bigserial.
*/

SELECT MAX(order_item_id) FROM order_items;
ALTER SEQUENCE order_items_order_item_id_seq RESTART WITH 112651;
CREATE SEQUENCE order_items_order_item_id_bigseq
	AS bigint
	START WITH 112651
	OWNED BY order_items.order_item_id;

ALTER TABLE order_items
ALTER COLUMN order_item_id SET DEFAULT nextval('order_items_order_item_id_bigseq'::regclass);

TRUNCATE TABLE order_items RESTART IDENTITY;

-- realized order_item_id is not unique so can't be the primary key. I'm gonna start fresh to make it cleaner.

DROP TABLE IF EXISTS order_items;

CREATE TABLE order_items (
    order_items_pk bigserial PRIMARY KEY,  -- new unique PK
    order_id varchar(100) REFERENCES orders(order_id),
    order_item_id varchar(100),            -- keep for reference
    product_id varchar(100) REFERENCES products(product_id),
    seller_id varchar(100) REFERENCES sellers(seller_id),
    shipping_limit_date timestamptz,
    price numeric(6,2),
    freight_value numeric(6,2)
	);

CREATE TABLE order_payments (
	order_id varchar(100)
		REFERENCES orders(order_id),
	payment_sequential smallint,
	payment_type varchar(100),
	payment_installations numeric(20,0),
	payment_value numeric(8,2),
	order_payments_id bigserial PRIMARY KEY
);


CREATE TABLE order_reviews (
	review_id varchar(100),
	order_id varchar(100)
		REFERENCES orders(order_id),
	review_score smallint,
	review_comment_title varchar(200),
	review_comment_message text,
	review_creation_date timestamptz,
	review_answer_timestamp timestamptz,
	order_reviews_pk bigserial PRIMARY KEY
);



	