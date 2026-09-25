# MartRhod Digital Product Funnel & Conversion Optimisation

This project analyses MartRhod's ecommerce journey to understand where customers are dropping out of the purchase funnel and what areas should be prioritised for conversion improvement.

The analysis was carried out using SQL Server and Power BI on customer activity from January 2023 to December 2025.

## Funnel Overview

The customer journey was analysed across:

**Session → Product View → Add to Cart → Payment Method → Completed Checkout**

The main upstream funnel contained:

- 55,000 sessions
- 55,000 sessions with a product view
- 35,722 sessions with an Add to Cart
- 32,453 sessions reaching the payment stage

## Key Findings

The biggest reliable loss occurred between **Product View and Add to Cart**.

- View-to-Cart conversion: **64.95%**
- View-to-Cart drop-off: **35.05%**
- Cart-to-Payment conversion: **90.85%**
- Reliable 2023 Payment-to-Checkout conversion: **68.00%**

The View-to-Cart problem was not concentrated in one obvious segment.

Conversion was broadly similar across:

- device
- entry referrer
- country
- product category

Product price also did not show a clear relationship with View-to-Cart conversion.

Session behaviour showed a stronger difference.

Sessions that added a product to cart averaged about:

- **7.50 product views**
- **1,225 seconds**

Sessions that did not add to cart averaged about:

- **3.49 product views**
- **340 seconds**

This shows a strong relationship between engagement and cart activity, although it does not prove that higher engagement causes conversion.

Some high-exposure products also had lower View-to-Cart conversion than others, making them useful candidates for further testing.

## Data Issue Identified

During the analysis, checkout completion tracking was found to become unreliable after January 2024.

Checkout completions fell to zero even though orders and successful payments continued.

Because of this, post-2023 checkout completion data was not used for final checkout conversion comparisons.

A separate data-quality issue was also found in `registration_timestamp`, where 28,051 sessions occurred before the customer's recorded registration time. The field was therefore excluded from registration- and tenure-based analysis.

## Recommendations

The first priority is to **repair checkout completion tracking** so that full-funnel conversion can be measured reliably.

For conversion optimisation, the main focus should be the **View-to-Cart stage**, since this is where the largest reliable loss occurs.

Rather than assuming that price, device or category is responsible, product-page changes should be tested directly.

Testing should begin with **high-exposure products that currently have relatively low View-to-Cart conversion**.

## A/B Test Idea

The first test would focus on the product page.

**Problem:** A large share of product-viewing sessions do not add the product to cart.

**Test:** Compare the current product page with a version that makes the product information, value proposition and Add to Cart action clearer and easier to notice.

**Main metric:** View-to-Cart conversion rate.

**Check alongside it:** Cart-to-Payment conversion rate.

If the new version increases View-to-Cart conversion without hurting the next stage of the funnel, it would provide evidence that the change improves the purchase journey.

The analysis identifies where testing should begin. It does not claim that any individual product-page element caused the current drop-off.

## Dashboard

The Power BI dashboard presents the main funnel, conversion rates, checkout tracking trend and segmentation results.

## Project Files

- `Project_Brief.pdf` — original project scope and business questions
- `SQL/` — data quality, funnel analysis, segmentation and Power BI preparation
- `PowerBI/` — interactive Power BI report
- `Funnel_Overview_Checkout_Performance.png` — dashboard preview

## Limitations

- The dataset is synthetic and is being used to demonstrate the analytical process.
- Orders cannot be linked reliably to individual sessions because `orders` does not contain `session_id`.
- Checkout completion tracking is unreliable after January 2024.
- Product-level results are exploratory because individual products have relatively small sample sizes.
- Engagement results show association rather than causation.

## Tools

**SQL Server | Power BI | DAX | Excel**
