--=========================
-- SEGMENTATION ANALYSIS
--=========================

/* From Funnel Analysis, View-to-Cart was identified as the main upstream bottleneck, while the Checkout stage also
showed an unusually high apparent drop-off. It is therefore required to investigate likely causes at these points 
through segmentation and further validation*/


--===========================================
-- CHECKOUT/PAYMENT BOTTLENECK INVESTIGATION
--===========================================


---SEGMENTING BY REFERRER

-- Identifying First Referrer per Session

/*Referrer validation showed that sessions can contain multiple referrer values.
The first recorded referrer is therefore used as the session entry referrer 
to maintain one acquisition source per session and prevent double-counting.*/

SELECT session_id, referrer_url, timestamp
FROM (
	SELECT session_id, referrer_url, timestamp,
			ROW_NUMBER () OVER (PARTITION BY session_id ORDER BY timestamp, view_id) AS row_num
	FROM product_views
	) pv
WHERE row_num = 1
ORDER BY session_id
;
GO


-- Creating Session Entry Referrer View

CREATE VIEW session_entry_referrer AS
SELECT session_id, referrer_url AS entry_referrer
FROM (
	SELECT session_id, referrer_url,
			ROW_NUMBER () OVER (PARTITION BY session_id ORDER BY timestamp, view_id) AS row_num
	FROM product_views
	) pv
WHERE row_num = 1
;
GO


-- ENTRY REFERRER GRAIN VALIDATION

-- Check if the number of rows matches the number of sessions

SELECT
	(SELECT COUNT (*) FROM user_sessions) AS UserSessions,
	(SELECT COUNT (*) FROM session_entry_referrer) AS EntryReferrerRows
;


-- Check for duplicate session_ids

SELECT session_id, COUNT (session_id) AS Duplicate_Sessions
FROM session_entry_referrer
GROUP BY session_id
HAVING COUNT (session_id) > 1
;


-- Check if any sessions are missing an entry referrer

SELECT us.session_id, ser.session_id
FROM user_sessions us
LEFT JOIN session_entry_referrer ser ON ser.session_id=us.session_id
WHERE ser.session_id IS NULL
;


-- PAYMENT BOTTLENECK BY ENTRY REFERRER

SELECT ser.entry_referrer,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS sessions_reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN session_entry_referrer ser ON ser.session_id=sf.session_id
GROUP BY ser.entry_referrer
ORDER BY payment_to_checkout_dropoff_rate DESC
;


-- PAYMENT BOTTLENECK BY DEVICE TYPE

SELECT us.device_type,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS sessions_reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN user_sessions us ON us.session_id=sf.session_id
GROUP BY us.device_type
ORDER BY payment_to_checkout_dropoff_rate DESC
;


-- PAYMENT BOTTLENECK BY REGION

SELECT r.country,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM regions r
JOIN customers c ON c.region_id = r.region_id
JOIN session_funnel sf ON sf.customer_id = c.customer_id
GROUP BY r.country
ORDER BY payment_to_checkout_dropoff_rate DESC
;


-- PAYMENT BOTTLENECK BY TIME

SELECT YEAR (us.session_start_timestamp) AS session_year,
		MONTH (us.session_start_timestamp) AS session_month,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM user_sessions us
JOIN session_funnel sf ON us.session_id = sf.session_id
GROUP BY YEAR (us.session_start_timestamp),
		 MONTH (us.session_start_timestamp)
ORDER BY YEAR (us.session_start_timestamp), MONTH (us.session_start_timestamp) ASC
;


--FINDING:

/*The initial full-period segmentation did not reveal a clear explanation for the apparent checkout drop-off.
However, the time-based analysis revealed a major change in checkout completion behaviour. While checkout 
completion rates remained between approximately 65% and 74% throughout most of 2023, the rate dropped sharply 
in January 2024 and reached 0% from February 2024 onward. This raised a data-quality concern and so there's aneed to validate this
time period*/


-- CHECKOUT COMPLETION TIME VALIDATION


-- Check the first and last completed checkout timestamps

SELECT
	MIN (timestamp) AS first_completed_checkout,
	MAX (timestamp) AS last_completed_checkout
FROM checkout_events
WHERE is_completed = 1
;


-- Check checkout completion directly from checkout_events by month

SELECT YEAR (timestamp) AS checkout_year,
		MONTH (timestamp) AS checkout_month,
		COUNT (checkout_event_id) AS checkout_events,
		SUM (CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) AS completed_checkouts,
		SUM (CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) * 100.00 / COUNT (checkout_event_id) AS completion_rate
FROM checkout_events
GROUP BY YEAR (timestamp),
		 MONTH (timestamp)
ORDER BY YEAR (timestamp), MONTH (timestamp)
;


-- Check if any completed checkout exists from February 2024 onward

SELECT *
FROM checkout_events
WHERE is_completed = 1
	AND timestamp >= '2024-02-01'
;


/*Since completed checkouts were no longer recorded after 12 January 2024, orders and payments were checked to
confirm whether customer transactions actually stopped or whether the issue was limited to checkout tracking*/


--CHECK FOR ORDERS AND PAYMENTS AFTER 2024-01-12

SELECT order_status,
		COUNT (*) AS orders
FROM orders
WHERE CAST (order_timestamp AS DATE) > '2024-01-12'
GROUP BY order_status
ORDER BY orders DESC
;


SELECT payment_status,
		COUNT (*) AS payments
FROM payments
WHERE CAST (payment_timestamp AS DATE) > '2024-01-12'
GROUP BY payment_status
ORDER BY payments DESC
;


/*Orders and payments continued after 12 January 2024, including 24,367 successful payments and 23,681 completed 
orders. This confirms that customer transactions continued and that the apparent checkout collapse was caused by 
a checkout tracking issue rather than a true stop in purchases. Checkout conversion analysis will therefore be 
restricted to the reliable 2023 period.*/


-- RELIABLE CHECKOUT CONVERSION


-- Payment Method to Completed Checkout Conversion for 2023

SELECT
	COUNT (sf.session_id) AS sessions,
	SUM (sf.reached_checkout) AS reached_payment_method,
	SUM (sf.checked_out) AS sessions_completed_checkouts,
	SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
	SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
	(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
WHERE YEAR (us.session_start_timestamp) = 2023
;


-- RELIABLE CHECKOUT SEGMENTATION - 2023


-- Payment Bottleneck by Device Type

SELECT us.device_type,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
WHERE YEAR (us.session_start_timestamp) = 2023
GROUP BY us.device_type
ORDER BY payment_to_checkout_dropoff_rate DESC
;


-- Payment Bottleneck by Entry Referrer

SELECT ser.entry_referrer,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
JOIN session_entry_referrer ser ON ser.session_id = sf.session_id
WHERE YEAR (us.session_start_timestamp) = 2023
GROUP BY ser.entry_referrer
ORDER BY payment_to_checkout_dropoff_rate DESC
;


-- Payment Bottleneck by Country

SELECT r.country,
		COUNT (sf.session_id) AS sessions,
		SUM (sf.reached_checkout) AS reached_payment_method,
		SUM (sf.checked_out) AS sessions_completed_checkouts,
		SUM (sf.checked_out) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_conversion,
		SUM (sf.reached_checkout) - SUM (sf.checked_out) AS payment_to_checkout_dropoff,
		(SUM (sf.reached_checkout) - SUM (sf.checked_out)) * 100.00 / SUM (sf.reached_checkout) AS payment_to_checkout_dropoff_rate
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
JOIN customers c ON c.customer_id = sf.customer_id
JOIN regions r ON r.region_id = c.region_id
WHERE YEAR (us.session_start_timestamp) = 2023
GROUP BY r.country
ORDER BY payment_to_checkout_dropoff_rate DESC
;


/*During the reliable 2023 period, Payment-to-Checkout conversion was approximately 68% overall and remained 
broadly consistent across device type, entry referrer and country. No individual segment showed a substantial 
concentration of checkout drop-off, suggesting that the remaining checkout loss was not driven by one clear 
customer or traffic segment.*/


--===========================================
-- VIEW-TO-CART BOTTLENECK INVESTIGATION
--===========================================


--View-to-Cart conversion by category

SELECT c.category_name,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT ace.session_id) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_conversion,
		COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id) AS view_to_cart_dropoff,
		(COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id)) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_dropoff_rate
FROM product_views pv
JOIN products p ON p.product_id = pv.product_id
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN add_to_cart_events ace ON ace.session_id = pv.session_id
	AND ace.product_id = pv.product_id
GROUP BY c.category_name
ORDER BY view_to_cart_dropoff_rate DESC
;


/*Same-product View-to-Cart conversion was nearly identical across the three product categories, ranging from
approximately 41.2% to 41.5%. This indicates that the drop-off was not concentrated within a particular category.*/


--View-to-Cart conversion by products

SELECT p.product_id,
		p.product_name,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT ace.session_id) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_conversion,
		COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id) AS view_to_cart_dropoff,
		(COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id)) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_dropoff_rate
FROM product_views pv
JOIN products p ON p.product_id = pv.product_id
LEFT JOIN add_to_cart_events ace ON ace.session_id = pv.session_id
	AND ace.product_id = pv.product_id
GROUP BY p.product_id, p.product_name
ORDER BY view_to_cart_dropoff_rate DESC
;


/*
Products with very few views can show very high or very low conversion rates
without representing a major business issue.

To focus on products with relatively high exposure within the catalogue,
the 75th percentile of product viewing sessions is calculated.
*/


SELECT DISTINCT
		PERCENTILE_CONT (0.75) WITHIN GROUP (ORDER BY sessions_viewed) OVER () AS Q3_sessions_viewed
FROM (
	SELECT p.product_id,
			COUNT (DISTINCT pv.session_id) AS sessions_viewed
	FROM product_views pv
	JOIN products p ON p.product_id = pv.product_id
	GROUP BY p.product_id
	) product_view_counts
;


/*
The Q3 value is 72 viewing sessions.

Products with at least 72 viewing sessions are retained for further investigation.
This focuses the analysis on relatively high-exposure products while reducing the influence
of products with very low viewing activity.
*/


SELECT p.product_id,
		p.product_name,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT ace.session_id) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_conversion,
		COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id) AS view_to_cart_dropoff,
		(COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id)) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_dropoff_rate
FROM product_views pv
JOIN products p ON p.product_id = pv.product_id
LEFT JOIN add_to_cart_events ace ON ace.session_id = pv.session_id
	AND ace.product_id = pv.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT (DISTINCT pv.session_id) >= 72
ORDER BY view_to_cart_conversion ASC
;


/*
High-exposure products show large differences in View-to-Cart conversion.
Price is therefore checked as one possible product-level factor that may explain this variation.
*/


SELECT p.product_id,
		p.product_name,
		p.price_usd,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT ace.session_id) * 100.00 / COUNT (DISTINCT pv.session_id) AS view_to_cart_conversion
FROM product_views pv
JOIN products p ON p.product_id = pv.product_id
LEFT JOIN add_to_cart_events ace ON ace.session_id = pv.session_id
	AND ace.product_id = pv.product_id
GROUP BY p.product_id, p.product_name, p.price_usd
HAVING COUNT (DISTINCT pv.session_id) >= 72
ORDER BY p.price_usd ASC
;


/*High-exposure products showed substantial differences in View-to-Cart conversion even though category-level
performance was nearly identical. Price also showed no clear relationship with conversion, as both lower-priced 
and higher-priced products displayed a wide range of conversion rates. This suggests that neither category nor 
price alone explains the observed product-level variation.*/


/*
Category and price did not clearly explain the View-to-Cart drop-off.

The next step is to compare session behaviour between sessions that added to cart
and sessions that did not. This helps show whether non-carting sessions are generally
shorter and less engaged, or whether users are browsing but still not progressing.
*/


SELECT
	CASE
		WHEN sf.added_to_cart = 1 THEN 'Added to Cart'
		ELSE 'Did Not Add to Cart'
	END AS cart_status,
	COUNT (*) AS sessions,
	AVG (CAST (sf.no_of_views AS DECIMAL (10,2))) AS avg_product_views,
	AVG (CAST (us.session_duration_seconds AS DECIMAL (10,2))) AS avg_session_duration_seconds
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
GROUP BY sf.added_to_cart
ORDER BY sf.added_to_cart
;


/*
Sessions that added to cart had much higher average product views and session duration.

Because averages can be pulled upward by a small number of unusually long or active sessions,
the median is checked to confirm whether the behavioural difference is also present
for a typical session in each group.
*/


SELECT DISTINCT
		sf.added_to_cart,
		PERCENTILE_CONT (0.50) WITHIN GROUP (ORDER BY sf.no_of_views) 
			OVER (PARTITION BY sf.added_to_cart) AS median_product_views,
		PERCENTILE_CONT (0.50) WITHIN GROUP (ORDER BY us.session_duration_seconds) 
			OVER (PARTITION BY sf.added_to_cart) AS median_session_duration
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
ORDER BY sf.added_to_cart
;


/*
The engagement difference between carting and non-carting sessions is strong.

The next check tests whether this pattern is concentrated on a particular device type.
If one device shows a much larger engagement gap, it may indicate a more specific
user-experience issue. If the pattern is similar across devices, the finding can be
treated as a broader behavioural pattern rather than a device-specific problem.
*/


SELECT us.device_type,
		sf.added_to_cart,
		COUNT (*) AS sessions,
		AVG (CAST (sf.no_of_views AS DECIMAL (10,2))) AS avg_product_views,
		AVG (CAST (us.session_duration_seconds AS DECIMAL (10,2))) AS avg_session_duration_seconds
FROM session_funnel sf
JOIN user_sessions us ON us.session_id = sf.session_id
GROUP BY us.device_type, sf.added_to_cart
ORDER BY us.device_type, sf.added_to_cart
;


/*View-to-Cart progression was strongly associated with session engagement. Sessions that added to cart averaged 
7.50 product views and approximately 1,225 seconds compared with 3.49 views and 340 seconds for sessions that did 
not add to cart. Median values confirmed the same pattern, with 8 views and 1,213 seconds for carting sessions 
compared with 3 views and 327 seconds for non-carting sessions. The engagement gap was also nearly identical across 
desktop, mobile and tablet, indicating a broader behavioural pattern rather than a device-specific issue.*/


--===========================================
-- SEGMENTATION ANALYSIS - KEY FINDINGS
--===========================================

/*
1. The apparent full-period checkout collapse was caused by a tracking issue. Completed checkout records stopped 
after 12 January 2024 even though orders and successful payments continued.

2. During the reliable 2023 period, Payment-to-Checkout conversion was approximately 68% and remained broadly 
consistent across device type, entry referrer and country. No individual segment clearly explained the checkout 
drop-off.

3. Same-product View-to-Cart conversion was nearly identical across product categories, indicating that category 
was not a major driver of the View-to-Cart drop-off.

4. High-exposure products showed considerable variation in View-to-Cart conversion, but price did not show a clear 
relationship with these differences.

5. View-to-Cart progression showed a strong relationship with session engagement. Carting sessions viewed more 
products and lasted substantially longer than non-carting sessions, and this pattern remained consistent across 
all device types.
*/