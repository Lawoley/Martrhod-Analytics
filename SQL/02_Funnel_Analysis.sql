--=================
--FUNNEL ANALYSIS
--=================

-- Building Session-Level Funnel Table

SELECT us.session_id, 
		us.customer_id,
		COUNT (DISTINCT pv.view_id) AS no_of_views,
		COUNT (DISTINCT ace.cart_event_id) AS add_to_carts,
		CASE WHEN COUNT (DISTINCT pv.view_id) > 0 THEN 1 ELSE 0 END AS viewed,
		CASE WHEN COUNT (DISTINCT ace.cart_event_id) > 0 THEN 1 ELSE 0 END AS added_to_cart,
		CASE WHEN COUNT (DISTINCT ce.checkout_event_id) > 0 THEN 1 ELSE 0 END AS reached_checkout,
		MAX (CASE WHEN ce.is_completed = 1 THEN 1 ELSE 0 END) AS checked_out
FROM user_sessions us
	LEFT JOIN product_views pv ON pv.session_id=us.session_id
	LEFT JOIN add_to_cart_events ace ON ace.session_id=us.session_id
	LEFT JOIN checkout_events ce ON ce.session_id=us.session_id
	GROUP BY us.session_id, us.customer_id
	ORDER BY us.session_id
;
GO


-- Creating Session Funnel View

CREATE VIEW session_funnel AS
SELECT us.session_id, 
		us.customer_id,
		COUNT (DISTINCT pv.view_id) AS no_of_views,
		COUNT (DISTINCT ace.cart_event_id) AS add_to_carts,
		CASE WHEN COUNT (DISTINCT pv.view_id) > 0 THEN 1 ELSE 0 END AS viewed,
		CASE WHEN COUNT (DISTINCT ace.cart_event_id) > 0 THEN 1 ELSE 0 END AS added_to_cart,
		CASE WHEN COUNT (DISTINCT ce.checkout_event_id) > 0 THEN 1 ELSE 0 END AS reached_checkout,
		MAX (CASE WHEN ce.is_completed = 1 THEN 1 ELSE 0 END) AS checked_out
FROM user_sessions us
	LEFT JOIN product_views pv ON pv.session_id=us.session_id
	LEFT JOIN add_to_cart_events ace ON ace.session_id=us.session_id
	LEFT JOIN checkout_events ce ON ce.session_id=us.session_id
	GROUP BY us.session_id, us.customer_id
;
GO


-- FUNNEL GRAIN VALIDATION

-- Check if the number of rows in session_funnel matches the number of sessions in user_sessions

SELECT
    (SELECT COUNT (*) FROM user_sessions) AS UserSessions,
    (SELECT COUNT (*) FROM session_funnel) AS SessionFunnelRows
;


-- Check if there are no duplicate session_ids in SessionFunnel

SELECT session_id, COUNT (session_id) AS Duplicate_Sessions
FROM session_funnel
GROUP BY session_id
HAVING COUNT (session_id) > 1
;


--Check if no sessions disappeared during the joins

SELECT us.session_id, sf.session_id
FROM user_sessions us
LEFT JOIN session_funnel sf ON sf.session_id=us.session_id
WHERE sf.session_id IS NULL
;


-- Check for logical funnel progression

SELECT session_id
FROM session_funnel
	WHERE added_to_cart > viewed
			OR reached_checkout > added_to_cart
			OR checked_out > reached_checkout
;


--==============================
-- HEADLINE FUNNEL ANALYSIS
--==============================

---Session Funnel

SELECT 
		COUNT (session_id) AS sessions, 
		SUM (viewed) AS sessions_views, 
		SUM (added_to_cart) AS sessions_added_to_cart, 
		SUM (reached_checkout) AS sessions_reached_payment_method, 
		SUM (checked_out) AS sessions_completed_checkouts
FROM session_funnel
;


--CONVERSION RATES

-- Session to Views Conversion

SELECT
	SUM (viewed) * 100.00 / COUNT (*) AS session_to_view_conversion
FROM session_funnel
;


-- Views to Cart Conversion

SELECT
	SUM (added_to_cart) * 100.00 / SUM (viewed) AS view_to_cart_conversion
FROM session_funnel
;


-- Carts to Payment Method Conversion

SELECT
	SUM (reached_checkout) * 100.00 / SUM (added_to_cart) AS cart_to_payment_method_conversion
FROM session_funnel
;


-- Payment Method to Completed Checkout Conversion

SELECT
	SUM (checked_out) * 100.00 / SUM (reached_checkout) AS payment_method_to_completed_checkout_conversion
FROM session_funnel
;


-- Session to Completed Checkout Conversion

SELECT
	SUM (checked_out) * 100.00 / COUNT (*) AS overall_session_conversion
FROM session_funnel
;


-- DROP-OFF COUNTS

-- Session to Views Drop-off

SELECT
	COUNT (session_id) - SUM (viewed) AS session_to_view_dropoff
FROM session_funnel
;


-- Views to Cart Drop-off

SELECT
	SUM (viewed) - SUM (added_to_cart) AS view_to_cart_dropoff
FROM session_funnel
;


-- Carts to Payment Method Drop-off

SELECT
	SUM (added_to_cart) - SUM (reached_checkout) AS cart_to_payment_method_dropoff
FROM session_funnel
;


-- Payment Method to Completed Checkout Drop-off

/*This is the initially observed full-period checkout drop-off and is investigated further in the segmentation analysis.*/

SELECT
	SUM (reached_checkout) - SUM (checked_out) AS payment_method_to_completed_checkout_dropoff
FROM session_funnel
;


-- Session to Completed Checkout Total Drop-off

SELECT
	COUNT (session_id) - SUM (checked_out) AS session_to_completed_checkout_dropoff
FROM session_funnel
;


-- DROP-OFF RATES

-- Session to Views Drop-off Rate

SELECT
	(COUNT (session_id) - SUM (viewed)) * 100.00 / COUNT (session_id) AS session_to_view_dropoff_rate
FROM session_funnel
;


-- Views to Cart Drop-off Rate

SELECT
	(SUM (viewed) - SUM (added_to_cart)) * 100.00 / SUM (viewed) AS view_to_cart_dropoff_rate
FROM session_funnel
;


-- Carts to Payment Method Drop-off Rate

SELECT
	(SUM (added_to_cart) - SUM (reached_checkout)) * 100.00 / SUM (added_to_cart) AS cart_to_payment_method_dropoff_rate
FROM session_funnel
;


-- Payment Method to Completed Checkout Drop-off Rate

SELECT
	(SUM (reached_checkout) - SUM (checked_out)) * 100.00 / SUM (reached_checkout) AS payment_method_to_completed_checkout_dropoff_rate
FROM session_funnel
;


-- Session to Completed Checkout Overall Drop-off Rate

SELECT
	(COUNT (session_id) - SUM (checked_out)) * 100.00 / COUNT (session_id) AS session_to_completed_checkout_dropoff_rate
FROM session_funnel
;


/*
--FINDING:

The initial funnel analysis showed no loss between Session and Product View, while View-to-Cart recorded a 35.05%
drop-off and Cart-to-Payment Method recorded a much smaller 9.15% drop-off. Payment-to-Completed Checkout appeared
to show the largest loss, with a 57.71% drop-off across the full dataset.

The large checkout drop-off, together with the View-to-Cart loss, signifies a need to investigate both stages further.
*/