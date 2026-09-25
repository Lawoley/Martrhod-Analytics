/*
PROJECT 1:
Digital Product Funnel & Conversion Optimization
Data Quality Assessment

Checks include:
- Missing values
- Duplicate records
- Invalid values
- Data entry consistency
- Referential integrity
- Funnel consistency
*/


--================================================================================
-- USER SESSION DATA QUALITY CHECKS
--================================================================================

SELECT * FROM user_sessions;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Session_IDs
FROM user_sessions 
WHERE session_id IS NULL;

SELECT COUNT (*) AS Missing_Customer_IDs
FROM user_sessions 
WHERE customer_id IS NULL;

SELECT COUNT (*) AS Missing_Session_Start_Timestamps
FROM user_sessions
WHERE session_start_timestamp IS NULL;

SELECT COUNT (*) AS Missing_Session_Durations
FROM user_sessions
WHERE session_duration_seconds IS NULL;

SELECT COUNT (*) AS Missing_Device_Types
FROM user_sessions
WHERE device_type IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate sessions

SELECT session_id, COUNT (session_id) AS Duplicate_Sessions
FROM user_sessions
GROUP BY session_id
HAVING COUNT (session_id) > 1;

-- Result: PASS 
-- No duplicate sessions found


-- Check for invalid values (e.g. negative durations, timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT session_duration_seconds 
FROM user_sessions
WHERE session_duration_seconds < 0;

SELECT session_start_timestamp
FROM user_sessions
WHERE YEAR (session_start_timestamp) < 2023
OR YEAR (session_start_timestamp) > 2025;

-- Result: PASS 
-- No invalid durations found and no sessions fell out of project scope


-- Check for referential integrity

SELECT us.customer_id
FROM user_sessions us
LEFT JOIN customers c ON c.customer_id=us.customer_id
WHERE c.customer_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found


-- Check for data entry inconsistency

SELECT DISTINCT device_type
FROM user_sessions;

-- Result: PASS 
-- Data entry is consistent



--================================================================================
-- PRODUCT VIEWS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM product_views;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_View_IDs
FROM product_views
WHERE view_id IS NULL;

SELECT COUNT (*) AS Missing_Session_IDs
FROM product_views
WHERE session_id IS NULL;

SELECT COUNT (*) AS Missing_Product_IDs
FROM product_views
WHERE product_id IS NULL;

SELECT COUNT (*) AS Missing_View_Timestamps
FROM product_views
WHERE timestamp IS NULL;

SELECT COUNT (*) AS Missing_Referrers
FROM product_views
WHERE referrer_url IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate product views

SELECT view_id, COUNT (view_id) AS Duplicate_View_IDs
FROM product_views 
GROUP BY view_id
HAVING COUNT (view_id) > 1;

-- Result: PASS 
-- No duplicate view IDs


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT timestamp
FROM product_views 
WHERE YEAR (timestamp) < 2023
OR YEAR (timestamp) > 2025;

-- Result: PASS 
-- No views fell out of scope


-- Check for data entry inconsistency

SELECT DISTINCT referrer_url
FROM product_views;

-- Result: PASS 
-- Data entry is consistent


-- Check for referential integrity

SELECT pv.session_id
FROM product_views pv
LEFT JOIN user_sessions us ON us.session_id = pv.session_id
WHERE us.session_id IS NULL;

SELECT pv.product_id
FROM product_views pv
LEFT JOIN products p ON p.product_id=pv.product_id
WHERE p.product_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- ADD-TO-CART EVENTS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM add_to_cart_events;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Cart_Event_IDs
FROM add_to_cart_events 
WHERE cart_event_id IS NULL;

SELECT COUNT (*) AS Missing_Session_IDs
FROM add_to_cart_events
WHERE session_id IS NULL;

SELECT COUNT (*) AS Missing_Product_IDs
FROM add_to_cart_events 
WHERE product_id IS NULL;

SELECT COUNT (*) AS Missing_Cart_Timestamps
FROM add_to_cart_events
WHERE timestamp IS NULL;

SELECT COUNT (*) AS Missing_Actions
FROM add_to_cart_events
WHERE action IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate cart events

SELECT cart_event_id, COUNT (cart_event_id) AS Duplicate_Cart_Events
FROM add_to_cart_events 
GROUP BY cart_event_id
HAVING COUNT (cart_event_id) > 1;

-- Result: PASS 
-- No duplicate cart events found


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT timestamp
FROM add_to_cart_events 
WHERE YEAR (timestamp) < 2023
OR YEAR (timestamp) > 2025;

-- Result: PASS 
-- No add-to-cart events fell out of scope


-- Check for data entry inconsistency

SELECT DISTINCT action
FROM add_to_cart_events;

-- Result: PASS 
-- Data entry is consistent


-- Check for referential integrity

SELECT ace.session_id
FROM add_to_cart_events ace
LEFT JOIN user_sessions us ON us.session_id = ace.session_id
WHERE us.session_id IS NULL;

SELECT ace.product_id
FROM add_to_cart_events ace
LEFT JOIN products p ON p.product_id=ace.product_id
WHERE p.product_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- CHECKOUT EVENTS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM checkout_events;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Checkout_Event_IDs
FROM checkout_events
WHERE checkout_event_id IS NULL;

SELECT COUNT (*) AS Missing_Session_IDs
FROM checkout_events
WHERE session_id IS NULL;

SELECT COUNT (*) AS Missing_Checkout_Timestamps
FROM checkout_events
WHERE timestamp IS NULL;

SELECT COUNT (*) AS Missing_Steps_Reached
FROM checkout_events
WHERE step_reached IS NULL;

SELECT COUNT (*) AS Missing_Completion_Status
FROM checkout_events
WHERE is_completed IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate checkout events

SELECT checkout_event_id, COUNT (checkout_event_id) AS Duplicate_Checkout_Events
FROM checkout_events
GROUP BY checkout_event_id
HAVING COUNT (checkout_event_id) > 1;

-- Result: PASS
-- No duplicate events found


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT timestamp
FROM checkout_events 
WHERE YEAR (timestamp) < 2023
OR YEAR (timestamp) > 2025;

-- Result: PASS 
-- No checkouts fell out of scope


-- Check for data entry inconsistency

SELECT DISTINCT step_reached 
FROM checkout_events;

SELECT DISTINCT is_completed
FROM checkout_events;

-- Result: PASS
-- Data entry is consistent


-- Check for referential integrity

SELECT ce.session_id
FROM checkout_events ce
LEFT JOIN user_sessions us ON us.session_id=ce.session_id
WHERE us.session_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- CART ABANDONMENTS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM cart_abandonments;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Abandonment_IDs
FROM cart_abandonments
WHERE abandonment_id IS NULL;

SELECT COUNT (*) AS Missing_Session_IDs
FROM cart_abandonments
WHERE session_id IS NULL;

SELECT COUNT (*) AS Missing_Checkout_Event_IDs
FROM cart_abandonments
WHERE checkout_event_id IS NULL;

SELECT COUNT (*) AS Missing_Abandonment_Timestamps
FROM cart_abandonments
WHERE timestamp IS NULL;

SELECT COUNT (*) AS Missing_Recovery_Status
FROM cart_abandonments
WHERE recovered IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate abandonment events

SELECT abandonment_id, COUNT (abandonment_id) AS Duplicate_Abandonment_Events
FROM cart_abandonments
GROUP BY abandonment_id
HAVING COUNT (abandonment_id) > 1;

-- Result: PASS
-- No duplicate abandonment events found


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT timestamp
FROM cart_abandonments
WHERE YEAR (timestamp) < 2023
OR YEAR (timestamp) > 2025;

-- Result: PASS 
-- No abandonments fell out of scope


-- Check for data entry inconsistency

SELECT DISTINCT recovered
FROM cart_abandonments;

-- Result: PASS 
-- Data entry is consistent


-- Check for referential integrity

SELECT ca.session_id
FROM cart_abandonments ca
LEFT JOIN user_sessions us ON us.session_id=ca.session_id
WHERE us.session_id IS NULL;

SELECT ca.checkout_event_id
FROM cart_abandonments ca
LEFT JOIN checkout_events ce ON ce.checkout_event_id=ca.checkout_event_id
WHERE ce.checkout_event_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- ORDERS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM orders;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Order_IDs
FROM orders
WHERE order_id IS NULL;

SELECT COUNT (*) AS Missing_Customer_IDs
FROM orders
WHERE customer_id IS NULL;

SELECT COUNT (*) AS Missing_Order_Timestamps
FROM orders
WHERE order_timestamp IS NULL;

SELECT COUNT (*) AS Missing_Order_Status
FROM orders
WHERE order_status IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate orders

SELECT order_id, COUNT (order_id) AS Duplicate_Orders
FROM orders
GROUP BY order_id
HAVING COUNT (order_id) > 1;

-- Result: PASS
-- No duplicate orders 


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT order_timestamp
FROM orders
WHERE YEAR (order_timestamp) < 2023
OR YEAR (order_timestamp) > 2025;

-- Result: PASS 
-- No orders fell out of scope


-- Check for data entry inconsistency

SELECT DISTINCT order_status
FROM orders;

-- Result: PASS
-- Data entry is consistent


-- Check for referential integrity

SELECT o.customer_id
FROM orders o
LEFT JOIN customers c ON c.customer_id=o.customer_id
WHERE c.customer_id IS NULL;

-- Result: PASS
-- No invalid foreign keys found



--================================================================================
-- PAYMENTS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM payments;


/*
Payments are used later to confirm whether transactions continued after checkout completion tracking stopped.
The table is therefore checked before it is used as supporting evidence.
*/


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Payment_IDs
FROM payments
WHERE payment_id IS NULL;

SELECT COUNT (*) AS Missing_Order_IDs
FROM payments
WHERE order_id IS NULL;

SELECT COUNT (*) AS Missing_Payment_Timestamps
FROM payments
WHERE payment_timestamp IS NULL;

SELECT COUNT (*) AS Missing_Payment_Methods
FROM payments
WHERE payment_method IS NULL;

SELECT COUNT (*) AS Missing_Payment_Status
FROM payments
WHERE payment_status IS NULL;

SELECT COUNT (*) AS Missing_Payment_Amounts
FROM payments
WHERE amount_local IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate payments

SELECT payment_id, COUNT (payment_id) AS Duplicate_Payments
FROM payments
GROUP BY payment_id
HAVING COUNT (payment_id) > 1;

-- Result: PASS
-- No duplicate payments found


-- Check for invalid values (timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT payment_timestamp
FROM payments
WHERE YEAR (payment_timestamp) < 2023
OR YEAR (payment_timestamp) > 2025;

-- Result: PASS
-- No payments fell out of scope


-- Check for invalid payment amounts

SELECT amount_local
FROM payments
WHERE amount_local < 0;

-- Result: PASS
-- No negative payment amounts found


-- Check for data entry inconsistency

SELECT DISTINCT payment_method
FROM payments;

SELECT DISTINCT payment_status
FROM payments;

-- Result: PASS
-- Data entry is consistent


-- Check for referential integrity

SELECT p.order_id
FROM payments p
LEFT JOIN orders o ON o.order_id=p.order_id
WHERE o.order_id IS NULL;

-- Result: PASS
-- No invalid foreign keys found



--================================================================================
-- CUSTOMERS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM customers;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Customer_IDs
FROM customers
WHERE customer_id IS NULL;

SELECT COUNT (*) AS Missing_Emails
FROM customers
WHERE email IS NULL;

SELECT COUNT (*) AS Missing_Registration_Timestamps
FROM customers
WHERE registration_timestamp IS NULL;

SELECT COUNT (*) AS Missing_Region_IDs
FROM customers
WHERE region_id IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate customers

SELECT customer_id, COUNT (customer_id) AS Duplicate_Customers
FROM customers
GROUP BY customer_id
HAVING COUNT (customer_id) > 1;

-- Result: PASS
-- No duplicate customers 


-- Check for invalid values (registration timestamp out of scope -- Jan 2023 to Dec 2025)

SELECT registration_timestamp
FROM customers
WHERE YEAR (registration_timestamp) < 2023
OR YEAR (registration_timestamp) > 2025;

-- Result: PASS 
-- No registrations fell out of scope


-- Check for referential integrity

SELECT c.region_id
FROM customers c
LEFT JOIN regions r ON r.region_id=c.region_id
WHERE r.region_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- PRODUCTS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM products;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Product_IDs
FROM products
WHERE product_id IS NULL;

SELECT COUNT (*) AS Missing_Category_IDs
FROM products
WHERE category_id IS NULL;

SELECT COUNT (*) AS Missing_Warehouse_IDs
FROM products
WHERE warehouse_id IS NULL;

SELECT COUNT (*) AS Missing_Prices
FROM products
WHERE price_usd IS NULL;

SELECT COUNT (*) AS Missing_Costs
FROM products
WHERE cost_usd IS NULL;

SELECT COUNT (*) AS Missing_Stock_Quantities
FROM products
WHERE stock_quantity IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate products

SELECT product_id, COUNT (product_id) AS Duplicate_Products
FROM products
GROUP BY product_id
HAVING COUNT (product_id) > 1;

-- Result: PASS
-- No duplicate products 


-- Check for invalid values (negative prices, costs or stock quantities)

SELECT price_usd
FROM products
WHERE price_usd < 0;

SELECT cost_usd
FROM products
WHERE cost_usd < 0;

SELECT stock_quantity
FROM products
WHERE stock_quantity < 0;

-- Result: PASS 
-- No prices, costs or quantities were invalid by being negative


-- Check for data entry inconsistency

SELECT DISTINCT brand
FROM products;

-- Result: PASS 
-- Data entry is consistent


-- Check for referential integrity

SELECT p.category_id
FROM products p
LEFT JOIN categories c ON c.category_id=p.category_id
WHERE c.category_id IS NULL;

SELECT p.warehouse_id
FROM products p
LEFT JOIN warehouses w ON w.warehouse_id=p.warehouse_id
WHERE w.warehouse_id IS NULL;

-- Result: PASS 
-- No invalid foreign keys found



--================================================================================
-- CATEGORIES DATA QUALITY CHECKS
--================================================================================

SELECT * FROM categories;


/*
Product category is used during View-to-Cart segmentation, so the category IDs and names
are checked before they are used to group product performance.
*/


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Category_IDs
FROM categories
WHERE category_id IS NULL;

SELECT COUNT (*) AS Missing_Category_Names
FROM categories
WHERE category_name IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate categories

SELECT category_id, COUNT (category_id) AS Duplicate_Categories
FROM categories
GROUP BY category_id
HAVING COUNT (category_id) > 1;

-- Result: PASS
-- No duplicate categories found


-- Check for data entry inconsistency

SELECT DISTINCT category_name
FROM categories;

-- Result: PASS
-- Data entry is consistent



--================================================================================
-- REGIONS DATA QUALITY CHECKS
--================================================================================

SELECT * FROM regions;


-- Check for missing critical values

SELECT COUNT (*) AS Missing_Region_IDs
FROM regions
WHERE region_id IS NULL;

SELECT COUNT (*) AS Missing_Countries
FROM regions
WHERE country IS NULL;

SELECT COUNT (*) AS Missing_Exchange_Rates
FROM regions
WHERE exchange_rate_usd IS NULL;

-- Result: PASS
-- No missing critical values found


-- Check for duplicate regions

SELECT region_id, COUNT (region_id) AS Duplicate_Regions
FROM regions
GROUP BY region_id
HAVING COUNT (region_id) > 1;

-- Result: PASS
-- No duplicate regions 


-- Check for invalid values (zero or negative exchange rates)

SELECT exchange_rate_usd
FROM regions
WHERE exchange_rate_usd <= 0;

-- Result: PASS
-- No zero or negative exchange rates found


-- Check for data entry inconsistency

SELECT DISTINCT city
FROM regions;

SELECT DISTINCT state_province
FROM regions;

SELECT DISTINCT country
FROM regions;

SELECT DISTINCT country_code
FROM regions;

SELECT DISTINCT currency
FROM regions;

-- Result: PASS 
-- Data entry is consistent



--================================================================================
-- FUNNEL CONSISTENCY CHECKS
--================================================================================

/*
The event tables are checked to confirm that later funnel events are supported by the expected earlier events.
This helps identify cases where the event sequence itself may be incomplete or logically inconsistent.
*/


-- Check for Add-to-Cart events without a previous view of the same product in the same session

SELECT DISTINCT ace.session_id, ace.product_id
FROM add_to_cart_events ace
LEFT JOIN product_views pv ON pv.session_id=ace.session_id
	AND pv.product_id=ace.product_id
	AND pv.timestamp <= ace.timestamp
WHERE pv.view_id IS NULL;

-- Result: PASS
-- No Add-to-Cart events occurred without a previous view of the same product in the same session


-- Check for checkout events without a previous Add-to-Cart event in the same session

SELECT DISTINCT ce.session_id
FROM checkout_events ce
LEFT JOIN add_to_cart_events ace ON ace.session_id=ce.session_id
	AND ace.timestamp <= ce.timestamp
WHERE ace.cart_event_id IS NULL;

-- Result: PASS
-- No checkout events occurred without a previous Add-to-Cart event in the same session



--================================================================================
-- EVENT TIMESTAMP CONSISTENCY CHECKS
--================================================================================

/*
Event timestamps are checked against the related session or transaction timestamps to confirm that events
do not occur before the activity they depend on.
*/


-- Check for product views recorded before the session started

SELECT pv.view_id, pv.session_id, pv.timestamp, us.session_start_timestamp
FROM product_views pv
JOIN user_sessions us ON us.session_id=pv.session_id
WHERE pv.timestamp < us.session_start_timestamp;

-- Result: PASS
-- No product views were recorded before their sessions started


-- Check for Add-to-Cart events recorded before the session started

SELECT ace.cart_event_id, ace.session_id, ace.timestamp, us.session_start_timestamp
FROM add_to_cart_events ace
JOIN user_sessions us ON us.session_id=ace.session_id
WHERE ace.timestamp < us.session_start_timestamp;

-- Result: PASS
-- No Add-to-Cart events were recorded before their sessions started


-- Check for checkout events recorded before the session started

SELECT ce.checkout_event_id, ce.session_id, ce.timestamp, us.session_start_timestamp
FROM checkout_events ce
JOIN user_sessions us ON us.session_id=ce.session_id
WHERE ce.timestamp < us.session_start_timestamp;

-- Result: PASS
-- No checkout events were recorded before their sessions started


-- Check for cart abandonments recorded before the related checkout event

SELECT ca.abandonment_id, ca.checkout_event_id, ca.timestamp, ce.timestamp AS checkout_timestamp
FROM cart_abandonments ca
JOIN checkout_events ce ON ce.checkout_event_id=ca.checkout_event_id
WHERE ca.timestamp < ce.timestamp;

-- Result: PASS
-- No cart abandonments were recorded before their related checkout events


-- Check for payments recorded before the related order was created

SELECT p.payment_id, p.order_id, p.payment_timestamp, o.order_timestamp
FROM payments p
JOIN orders o ON o.order_id=p.order_id
WHERE p.payment_timestamp < o.order_timestamp;

-- Result: PASS
-- No payments were recorded before their related orders were created


-- Check for sessions recorded before the customer registered

SELECT us.session_id, us.customer_id, us.session_start_timestamp, c.registration_timestamp
FROM user_sessions us
JOIN customers c ON c.customer_id=us.customer_id
WHERE us.session_start_timestamp < c.registration_timestamp;

-- Result: FLAGGED
-- 28,051 sessions were recorded before the corresponding customer's registration timestamp
-- registration_timestamp will therefore not be used for customer tenure or registration-based analysis



--================================================================================
-- DATA QUALITY ASSESSMENT FINDING
--================================================================================

/*
The data passed the main quality checks for missing critical values, duplicate primary keys, invalid values,
data entry consistency, referential integrity, funnel sequence consistency and event timestamp consistency.

One notable issue was identified in the customer registration data. A total of 28,051 sessions were recorded before
the corresponding customer's registration timestamp. Since registration_timestamp is not required for the funnel
or conversion analysis, the affected sessions were retained, while the registration timestamp was excluded from
customer tenure or registration-based analysis.
*/