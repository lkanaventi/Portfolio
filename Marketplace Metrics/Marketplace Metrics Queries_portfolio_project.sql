/*-------------------------------------------------------------------------
AI USAGE CITATION (GLOBAL SCRIPT REVIEW)
-------------------------------------------------------------------------
Tool: ChatGPT (OpenAI)
Usage Scope: Applied to all queries within this script.

Purposes:
1. Architectural Support: Assisted in expanding bivariate queries into 
   multivariate analyses (e.g., linking delivery speed, satisfaction, 
   and retention).
2. Data Recovery & Efficiency: Reconstructed query logic after session 
   loss and optimized syntax for PostgreSQL-specific functions.
3. Documentation: Refined SQL comments to reflect professional 
   Data Science terminology and business funnel logic.

Representative Prompts: 
- "Review my SQL queries for the Olist dataset and suggest optimizations 
   for readability and performance."
- "Refactor this query to include customer retention counts as a 
   third variable in the satisfaction analysis."
- "What is the most efficient PostgreSQL syntax for calculating intervals 
	between two timestamps?"
- "Refine my SQL comments to use professional data science terminology 
   (e.g., 'exploratory analysis', 'data normalization', 'retention funnel')."
- "Retrieve and reconstruct the optimized SQL queries and technical commentary
	previously provided dure the code efficiency review session."

Verification: All logic was manually validated against the project ERD 
and executed in pgAdmin to ensure data accuracy and schema alignment.
-------------------------------------------------------------------------
*/

-- 1. How does delivery speed impact review scores and repeat purchases? Funnel: Fulfillment-Satisfaction-Retention
/* I began by examining order-level delivery duration (purchase to delivery)and linking it to review score to 
understand the raw relationship between fulfillment speed and customer satisfaction.
*/
SELECT 
    o.order_id, 
    (o.order_delivered_customer_date - o.order_purchase_timestamp) AS delivery_time, 
    r.review_score, 
    o.customer_id
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
ORDER BY r.review_score;


/*
After reviewing order-level data, I aggregated delivery duration by review score
to evaluate whether slower fulfillment was systematically associated with lower satisfaction.

Average delivery time increases as review scores decrease,
suggesting a directional relationship between speed and customer sentiment.
Further statistical testing is required to evaluate the strength of this relationship.
Analysis limited to completed orders with valid review scores.
*/

SELECT 
    r.review_score, 
    AVG(o.order_delivered_customer_date - o.order_purchase_timestamp) AS avg_delivery_time, 
    COUNT(*) AS order_count 
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp IS NOT NULL
  AND r.review_score IS NOT NULL
GROUP BY r.review_score
ORDER BY r.review_score;


-- Identify first order per customer using window function
-- ---------------------------------------------------------
-- First Order Identification & Retention Flag
-- AI-Assisted: Window function (ROW_NUMBER) partition logic 
--              and performance-conscious restructuring 
--              into modular temp tables.
-- ---------------------------------------------------------

/*After identifying a relationship between delivery time and satisfaction, I wanted to understand
whether fulfillment speed also impacts long-term retention. To do that, I built a customer-level 
dataset using a window function to isolate each customer’s first order. I used ROW_NUMBER() partitioned
by customer and ordered by purchase timestamp so I could accurately identify the true first transaction.
I chose the first order because first experiences tend to shape customer expectations and future purchasing
behavior. From a product or operations perspective, optimizing the first delivery may have disproportionate 
impact on retention. I then created a repeat customer flag by grouping orders at the customer level and 
checking whether total orders exceeded one. This allowed me to convert transactional data into a retention metric.
Finally, I segmented customers into “Fast First Delivery” versus “Slow First Delivery” using a 5-day threshold, 
and calculated repeat rates for each group. This allowed me to evaluate whether early fulfillment performance 
influences downstream customer loyalty. I initially had these setup as one query, but changed it to 4 queries because
running a windows function unnecessarily can be expensive.
 */
CREATE TEMP TABLE customer_orders AS (
    SELECT
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        o.order_delivered_customer_date,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_number
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id);

CREATE TEMP TABLE first_orders AS (
    SELECT *
    FROM customer_orders
    WHERE order_number = 1);

CREATE TEMP TABLE customer_repeat AS (
    SELECT
        customer_unique_id,
        CASE WHEN COUNT(*) > 1 THEN 1 ELSE 0 END AS repeat_customer
    FROM customer_orders
    GROUP BY customer_unique_id);

SELECT
    CASE
        WHEN (fo.order_delivered_customer_date - fo.order_purchase_timestamp) <= INTERVAL '5 days'
            THEN 'Fast First Delivery'
        ELSE 'Slow First Delivery'
    END AS first_delivery_speed,
    COUNT(*) AS total_customers,
    SUM(cr.repeat_customer) AS repeat_customers,
    ROUND(SUM(cr.repeat_customer)::numeric / COUNT(*) * 100, 2) AS repeat_rate_percent
FROM first_orders fo
JOIN customer_repeat cr
    ON fo.customer_unique_id = cr.customer_unique_id
GROUP BY first_delivery_speed;

/* 
To connect satisfaction to retention, I maintained customer as the unit of analysis,
since repeat behavior is a customer-level outcome.

I created a customer_repeat CTE by grouping orders by customer and
flagging whether a customer placed more than one order.

In the final query, I joined orders, customers, and reviews to associate
each customer’s review score with their retention status.

This allowed me to calculate repeat rate by satisfaction level.
Repeat rates were relatively similar across most review scores,
with a modest increase among 5-star reviewers,
suggesting a potential but not dramatic association between satisfaction and retention.
*/

WITH customer_repeat AS (
    SELECT
        c.customer_unique_id,
        CASE WHEN COUNT(o.order_id) > 1 THEN 1 ELSE 0 END AS repeat_customer
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)

SELECT
    r.review_score,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    SUM(cr.repeat_customer) AS repeat_customers,
    ROUND(SUM(cr.repeat_customer)::numeric 
          / COUNT(DISTINCT c.customer_unique_id) * 100, 2) AS repeat_rate_percent
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_reviews r
    ON o.order_id = r.order_id
JOIN customer_repeat cr
    ON c.customer_unique_id = cr.customer_unique_id
GROUP BY r.review_score
ORDER BY r.review_score;

-- 2. Which specific sellers or Brazilian states experience the largest delivery delays?

-- Sellers with largest average delivery delays
-- Positive = late, Negative = early
-- ---------------------------------------------------------
-- Seller Delay Normalization (Interval → Numeric Days)
-- AI-Assisted: PostgreSQL EXTRACT(EPOCH) interval conversion 
--              and numeric day standardization for bucketing.
-- ---------------------------------------------------------

/* To identify where delivery delays originate, I shifted the unit of analysis 
from orders to sellers, since fulfillment performance is operationally tied 
to the seller fulfilling the order.

I limited the analysis to orders with both an estimated delivery date and 
an actual delivery date to ensure delay could be calculated accurately.

I joined the orders table to order_items and sellers in order to attribute 
each order to the correct seller. This allowed me to compute the average 
delivery delay per seller and rank sellers by fulfillment performance.

This helps identify which sellers contribute most to late deliveries 
and may require operational intervention.
*/
SELECT 
    s.seller_id, 
    AVG(o.order_delivered_customer_date - o.order_estimated_delivery_date) AS avg_delivery_delay
FROM orders o
JOIN order_items ot
    ON o.order_id = ot.order_id
JOIN sellers s
    ON ot.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY s.seller_id
ORDER BY avg_delivery_delay DESC;

--Brazilian states with largest delays
/* 
To examine potential environmental and logistical drivers of delay,
I shifted the unit of analysis from individual orders to seller_state.
Geographic infrastructure, remoteness, and transportation networks 
can systematically impact fulfillment speed.

Using the same delay calculation as the seller-level analysis,
I aggregated average delivery delay by state to identify whether
delays were concentrated geographically.

Results showed that AM was the only state with a positive average delay
(approximately 9 days late), while most states delivered earlier than
their estimated date.

This suggests that late delivery is not broadly systemic, but may be
driven by specific geographic constraints.
*/

SELECT 
    s.seller_state, 
    AVG(o.order_delivered_customer_date - o.order_estimated_delivery_date) AS avg_delivery_delay
FROM orders o
JOIN order_items ot
    ON o.order_id = ot.order_id
JOIN sellers s
    ON ot.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY s.seller_state
ORDER BY avg_delivery_delay DESC;


-- Bucket sellers by delay performance
-- Create temp table for seller average delay in numeric days
/*During my exploratory analysis, I created a temp table because I was referencing
the aggregated seller delay data across multiple queries. After refining the analysis,
I refactored it into a CTE since it was only needed within a single transformation. 
That keeps the query more modular and easier to read.
*/
CREATE TEMP TABLE seller_delay AS (
SELECT
    s.seller_id,
    AVG(EXTRACT(EPOCH FROM 
        (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400
    ) AS avg_delivery_delay_days
FROM orders o
JOIN order_items ot
    ON o.order_id = ot.order_id
JOIN sellers s
    ON ot.seller_id = s.seller_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
GROUP BY s.seller_id;


-- Bucket sellers

SELECT
    seller_id,
    avg_delivery_delay_days,
    CASE
        WHEN avg_delivery_delay_days <= 0 THEN 'Early / On Time'
        WHEN avg_delivery_delay_days <= 3 THEN 'Slight Delay (1–3 days)'
        WHEN avg_delivery_delay_days <= 7 THEN 'Moderate Delay (4–7 days)'
        ELSE 'Severe Delay (8+ days)'
    END AS delivery_delay_bucket
FROM seller_delay;


-- 3. Are customers with delayed deliveries less likely to become repeat buyers?
-- ---------------------------------------------------------
-- Customer Worst-Case Delay & Retention Analysis
-- AI-Assisted: Multi-CTE behavioral modeling structure, 
--              interval-to-day conversion, and retention 
--              rate calculation logic.
-- ---------------------------------------------------------

/* Customer-level retention analysis:
- For each customer, determined whether they were a repeat purchaser (more than one order).  
- Calculated the maximum delivery delay across all of a customer’s orders, converting timestamps
into days.  
- Categorized customers into delay buckets (Early/On-Time, Slight Delay, Moderate Delay, Severe 
Delay) based on their worst delay.  
- Computed repeat purchase rates per delay bucket to examine how extreme fulfillment delays impact
customer retention.  

This approach focuses on the worst-case delivery experience per customer as a potential driver of 
repeat purchasing behavior, providing actionable insights for operations and customer experience 
optimization.

The analysis shows the highest repeat rate among customers in the severe-delay bucket. This pattern
is likely an artifact of how delays were categorized; using a continuous measure of delivery delay 
could reveal a more nuanced relationship between fulfillment speed and repeat purchasing behavior. 
Additional modeling or statistical testing is needed to clarify this effect
*/

WITH customer_repeat AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders,
        CASE WHEN COUNT(o.order_id) > 1 THEN 1 ELSE 0 END AS is_repeat_customer
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),

customer_worst_delay AS (
    SELECT
        c.customer_unique_id,
        MAX(EXTRACT(EPOCH FROM 
            (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400
        ) AS worst_delay_days
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_unique_id
),

customer_bucket AS (
    SELECT
        cwd.customer_unique_id,
        CASE
            WHEN cwd.worst_delay_days <= 0 THEN 'Early / On Time'
            WHEN cwd.worst_delay_days <= 3 THEN 'Slight Delay'
            WHEN cwd.worst_delay_days <= 7 THEN 'Moderate Delay'
            ELSE 'Severe Delay'
        END AS delay_bucket
    FROM customer_worst_delay cwd
)

SELECT
    cb.delay_bucket,
    COUNT(*) AS total_customers,
    SUM(cr.is_repeat_customer) AS repeat_customers,
    ROUND(SUM(cr.is_repeat_customer)::numeric / COUNT(*) * 100, 2) AS repeat_rate_percent
FROM customer_bucket cb
JOIN customer_repeat cr
    ON cb.customer_unique_id = cr.customer_unique_id
GROUP BY cb.delay_bucket
ORDER BY repeat_rate_percent DESC;

-- 4.How exactly do delivery delays influence review scores? Is there a breaking point?
-- ---------------------------------------------------------
-- Delivery Delay Impact & Satisfaction Breaking Point
-- AI-Assisted: Percentile calculation using PERCENTILE_CONT, 
--              ordered-set aggregation syntax, and delay 
--              bucketing logic with interval normalization.
-- ---------------------------------------------------------

/*This query evaluates how delivery delays impact customer review scores. First, it calculates 
the delivery delay in days using EXTRACT(EPOCH) on the difference between actual and estimated 
delivery timestamps, converting seconds to days. Using a CASE WHEN statement, delays are then 
bucketed into meaningful categories: on-time/early, slight, moderate, and severe. At the bucket 
level, the query computes both the average review score and the median review score using 
PERCENTILE_CONT(0.5), providing a robust measure of central tendency less sensitive to outliers. 
This approach highlights potential “breaking points” in delivery performance where satisfaction 
may decline.
*/
WITH order_delay AS (
    SELECT
        o.order_id,
        r.review_score,
        EXTRACT(EPOCH FROM 
            (o.order_delivered_customer_date - o.order_estimated_delivery_date)
        ) / 86400 AS delay_days,
        CASE
            WHEN EXTRACT(EPOCH FROM 
                (o.order_delivered_customer_date - o.order_estimated_delivery_date)
            ) / 86400 <= 0 THEN 'On Time / Early'
            WHEN EXTRACT(EPOCH FROM 
                (o.order_delivered_customer_date - o.order_estimated_delivery_date)
            ) / 86400 <= 3 THEN 'Slight Delay (1–3 days)'
            WHEN EXTRACT(EPOCH FROM 
                (o.order_delivered_customer_date - o.order_estimated_delivery_date)
            ) / 86400 <= 7 THEN 'Moderate Delay (4–7 days)'
            ELSE 'Severe Delay (8+ days)'
        END AS delay_bucket
    FROM orders o
    JOIN order_reviews r
        ON o.order_id = r.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
      AND r.review_score IS NOT NULL
)

SELECT
    delay_bucket,
    COUNT(*) AS num_orders,
    ROUND(AVG(review_score)::numeric, 2) AS avg_review_score,
    ROUND(PERCENTILE_CONT(0.5) 
        WITHIN GROUP (ORDER BY review_score)::numeric, 2
    ) AS median_review_score
FROM order_delay
GROUP BY delay_bucket
ORDER BY MIN(delay_days);

-- ---------------------------------------------------------
-- Customer-Level Modeling Dataset Construction
-- AI-Assisted: Multi-CTE transformation pipeline design for
--              regression-ready behavioral dataset, including
--              interval normalization (EXTRACT(EPOCH)),
--              retention flag engineering, and customer-level
--              aggregation logic.
-- ---------------------------------------------------------

/* This query generates a customer-level dataset for correlation and regression analysis. 
For each customer, it calculates:
-Total orders – overall purchasing activity.
-Repeat customer flag – whether the customer placed more than one order.
-Worst delivery delay – the maximum delivery delay in days, computed from actual versus estimated
delivery timestamps.
-Average review score – the mean of all customer-provided review scores.

This dataset allows analysis of potential relationships between delivery performance, customer 
satisfaction, and repeat purchase behavior without focusing on a single business question. It 
provides a flexible foundation for downstream statistical modeling.
*/
WITH customer_repeat AS (
    SELECT
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders,
        CASE WHEN (COUNT(o.order_id)) > 1 THEN 1 ELSE 0 END AS is_repeat_customer
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
),
customer_worst_delay AS (
    SELECT
        c.customer_unique_id,
        MAX(EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date))/86400) AS worst_delay_days
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_unique_id
),
customer_avg_review AS (
    SELECT
        c.customer_unique_id,
        ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    cr.customer_unique_id,
    cr.total_orders,
    cr.is_repeat_customer,
    cwd.worst_delay_days,
    car.avg_review_score
FROM customer_repeat cr
LEFT JOIN customer_worst_delay cwd
    ON cr.customer_unique_id = cwd.customer_unique_id
LEFT JOIN customer_avg_review car
    ON cr.customer_unique_id = car.customer_unique_id;


