--=================
-- POWER BI VIEWS
--=================


/*
This view combines the session-level funnel results with session details, entry referrer and customer location.
One row represents one session and will be used for funnel KPIs, checkout segmentation and engagement analysis.
*/

CREATE VIEW powerbi_sessions AS
SELECT sf.session_id,
		sf.customer_id,
		us.session_start_timestamp,
		CAST (us.session_start_timestamp AS DATE) AS session_date,
		us.session_duration_seconds,
		us.device_type,
		ser.entry_referrer,
		r.country,
		sf.no_of_views,
		sf.add_to_carts,
		sf.viewed,
		sf.added_to_cart,
		sf.reached_checkout,
		sf.checked_out,
		ce.timestamp AS checkout_timestamp,
		CAST (ce.timestamp AS DATE) AS checkout_date
FROM session_funnel sf
	LEFT JOIN user_sessions us ON us.session_id=sf.session_id
	LEFT JOIN session_entry_referrer ser ON ser.session_id=sf.session_id
	LEFT JOIN customers c ON c.customer_id=sf.customer_id
	LEFT JOIN regions r ON r.region_id=c.region_id
	LEFT JOIN checkout_events ce ON ce.session_id=sf.session_id
;
GO


/*
This view measures View-to-Cart performance at product level.
One row represents one product. The 72-session cutoff identifies relatively high-exposure products for further comparison.
*/

CREATE VIEW powerbi_products AS
SELECT p.product_id,
		p.product_name,
		c.category_name,
		p.price_usd,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id) AS dropoff_sessions,
		ROUND (
			100.0 * COUNT (DISTINCT ace.session_id) / COUNT (DISTINCT pv.session_id), 2
		) AS conversion_rate,
		ROUND (
			100.0 * (COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id))
			/ COUNT (DISTINCT pv.session_id), 2
		) AS dropoff_rate,
		CASE 
			WHEN COUNT (DISTINCT pv.session_id) >= 72 THEN 1 
			ELSE 0 
		END AS high_exposure
FROM product_views pv
	JOIN products p ON p.product_id=pv.product_id
	JOIN categories c ON c.category_id=p.category_id
	LEFT JOIN add_to_cart_events ace ON ace.session_id=pv.session_id
		AND ace.product_id=pv.product_id
GROUP BY p.product_id,
		p.product_name,
		c.category_name,
		p.price_usd
;
GO


/*
This view measures View-to-Cart performance at category level.
One row represents one category. Distinct sessions are calculated directly at category level so sessions interacting
with multiple products in the same category are not counted repeatedly.
*/

CREATE VIEW powerbi_categories AS
SELECT c.category_id,
		c.category_name,
		COUNT (DISTINCT pv.session_id) AS sessions_viewed,
		COUNT (DISTINCT ace.session_id) AS sessions_added_to_cart,
		COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id) AS dropoff_sessions,
		ROUND (
			100.0 * COUNT (DISTINCT ace.session_id) / COUNT (DISTINCT pv.session_id), 2
		) AS conversion_rate,
		ROUND (
			100.0 * (COUNT (DISTINCT pv.session_id) - COUNT (DISTINCT ace.session_id))
			/ COUNT (DISTINCT pv.session_id), 2
		) AS dropoff_rate
FROM product_views pv
	JOIN products p ON p.product_id=pv.product_id
	JOIN categories c ON c.category_id=p.category_id
	LEFT JOIN add_to_cart_events ace ON ace.session_id=pv.session_id
		AND ace.product_id=pv.product_id
GROUP BY c.category_id,
		c.category_name
;
GO