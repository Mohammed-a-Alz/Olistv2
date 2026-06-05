# Olistv2 — Analytics Engineering on Snowflake

## Overview

A production-grade analytics engineering project built on the Brazilian Olist e-commerce dataset (~100K orders, ~1,500 sellers). Raw transactional data is transformed into a clean, well-tested data warehouse on **Snowflake** using **dbt**.

This is the second version of my [AI-Ready E-commerce Analytics Pipeline](https://github.com/Mohammed-a-Alz/AI-Ready-E-commerce-Analytics-Pipeline). It rebuilds the project on Snowflake (migrated from BigQuery) and introduces a proper 3-layer dbt architecture, slowly changing dimensions, geolocation enrichment, Jinja-driven transformations, and a richer semantic layer.

---

## What's New vs V1

| Area | V1 (BigQuery) | V2 (Snowflake) |
|---|---|---|
| Warehouse | BigQuery | Snowflake |
| Architecture | 2 layers (staging → marts) | 3 layers (staging → intermediate → marts) |
| Naming convention | `stg_orders` | `stg_olist__orders` (dbt standard) |
| Customer dimension | Flat, deduplicated | SCD Type 2 via dbt snapshot |
| Geolocation | None | Lat/lng centroid per zip for customers & sellers |
| Payment logic | Inline aggregation in mart | Jinja-driven pivot in intermediate layer |
| Surrogate keys | None | `dbt_utils.generate_surrogate_key` on fact tables |
| Semantic layer metrics | 10 across 3 fact tables | 16 across 3 fact tables — adds operational KPIs (late deliveries, cancellations, review scoring) |
| Deployment | None | dbt Cloud CI/CD — dev schema for branches, isolated prod schemas on merge |
| Schema routing | None | Custom `generate_schema_name` macro for environment-aware schema isolation |
| Source documentation | Partial | Full — all sources, tables, and columns documented including known data quality issues |

---

## Architecture

```
Raw Data (Snowflake: OLIST.RAW)
    → dbt Staging       (clean, typed, renamed — one model per source table)
    → dbt Intermediate  (deduplication, aggregations, pivots — reusable logic)
    → dbt Marts         (star schema: facts + dimensions)
    → Semantic Layer    (MetricFlow: 16 governed metrics across 3 fact tables)
```

| Layer | Tool | Purpose |
|---|---|---|
| Data Warehouse | Snowflake | Storage and compute |
| Transformation | dbt | Staging, intermediate, and mart models |
| Metrics Layer | MetricFlow | Centralized, reusable metric definitions |
| Package | dbt_utils | Surrogate key generation |

---

## Data Modeling

Designed as a **star schema** — fact tables hold measurements at a specific grain, dimensions hold descriptive attributes. No fact-to-fact joins; all joins route through dimensions.

### Fact Tables

| Model | Grain | Key measures |
|---|---|---|
| `fct_orders` | One row per order | Revenue, delivery days, review score, late delivery flag |
| `fct_order_items` | One row per item per order | Price (BRL), freight, total amount |
| `fct_order_payments` | One row per payment transaction | Payment amount, type, installments |

### Dimension Tables

| Model | Description |
|---|---|
| `dim_customers` | Deduplicated by `customer_unique_id`, enriched with lat/lng from geolocation, SCD Type 2 columns from snapshot |
| `dim_products` | Physical attributes + English category name joined from translation table |
| `dim_sellers` | Seller location enriched with lat/lng centroid |
| `dim_dates` | Calendar spine used by MetricFlow for time-based aggregations |

---

## Slowly Changing Dimensions (SCD Type 2)

Customer location data changes over time. To track this historization, a **dbt snapshot** (`snap_customers`) monitors the raw customer table for changes to `zip_code`, `city`, and `state` using the `check` strategy.

When a customer's address changes, dbt inserts a new record and closes the old one — preserving the full history.

`dim_customers` surfaces these snapshot columns:

| Column | Description |
|---|---|
| `dbt_scd_id` | Unique surrogate key per snapshot record |
| `dbt_valid_from` | When this version of the record became active |
| `dbt_valid_to` | When this version expired (NULL = current record) |
| `dbt_updated_at` | When the snapshot last updated this record |

This means you can query what a customer's location was at any point in time — not just their current address.

---

## Intermediate Layer

The intermediate layer holds reusable logic that would otherwise clutter mart SQL or be duplicated across models.

| Model | Purpose |
|---|---|
| `int_payments_aggregated_to_orders` | Aggregates payment records to order grain; uses a **Jinja loop** to pivot payment methods (credit card, boleto, voucher, debit card) into separate amount columns |
| `int_order_reviews_deduped_to_orders` | Deduplicates reviews to one per order (known source data issue — multiple review IDs per order); keeps the most recent review using `ROW_NUMBER()` |
| `int_orders_aggregated_to_customers` | Aggregates order history to customer grain for use in `dim_customers` |
| `int_geolocation_deduped_to_zip` | Collapses multiple lat/lng entries per zip code to a single centroid using `AVG()` |

---

## Semantic Layer & Metrics

A **MetricFlow semantic layer** sits across the mart fact tables and defines 16 business metrics as a single source of truth. Any tool querying these metrics gets the same answer — no diverging definitions.

### Metrics Defined

**Orders** (`fct_orders`)

| Metric | Definition |
|---|---|
| `total_revenue_brl` | Total revenue from non-canceled orders |
| `total_orders` | Count of distinct orders |
| `avg_order_value` | Average revenue per non-canceled order |
| `avg_delivery_days` | Average days from purchase to customer delivery |
| `avg_review_score` | Average customer review score (1–5) |
| `avg_installments` | Average payment installments per order |
| `canceled_orders` | Count of canceled orders |
| `late_deliveries` | Count of orders delivered after estimated date |
| `delivered_orders` | Count of successfully delivered orders |

**Order Items** (`fct_order_items`)

| Metric | Definition |
|---|---|
| `total_items_sold` | Total number of order items sold |
| `total_item_revenue_brl` | Total revenue from items including freight |
| `avg_item_price_brl` | Average item price excluding freight |
| `avg_freight_brl` | Average freight charged per item |

**Payments** (`fct_order_payments`)

| Metric | Definition |
|---|---|
| `total_payments` | Count of distinct payment records |
| `total_payment_revenue_brl` | Sum of all payment amounts in BRL |
| `avg_payment_amount_brl` | Average payment amount per payment record |

---

## Data Quality

dbt tests are applied across all source, staging, and mart models.

| Test | Applied to |
|---|---|
| `unique` | All primary keys |
| `not_null` | All primary and foreign keys |
| `accepted_values` | `order_status`, `payment_type` |
| `relationships` | Foreign keys across staging models |

Known source data issues are documented in `source.yml` — including duplicate `REVIEW_ID` values per order (handled in `int_order_reviews_deduped_to_orders`) and a typo in the raw column `PRODUCT_NAME_LENGHT`.

---

## Deployment

Models are deployed via a **dbt Cloud CI/CD pipeline** with environment and schema isolation.

Development happens in a personal dev schema (`DEV_MO`) — branches are built and tested in isolation before any changes reach production. On merge to main, a production job runs and promotes models to dedicated schemas:

| Schema | Contents |
|---|---|
| `PROD_STAGING` | All staging views |
| `PROD_INTERMEDIATE` | All intermediate views |
| `PROD_MARTS` | All mart tables (materialized) |
| `SNAPSHOTS` | SCD Type 2 snapshot history |

This means a broken model or failed test on a feature branch never touches production data — the dev and prod environments are fully isolated at the schema level.

### Schema routing macro

Schema separation is enforced by a custom `generate_schema_name` macro. In production (`target.schema = PROD`), models route to `PROD_STAGING`, `PROD_INTERMEDIATE`, and `PROD_MARTS`. In development, all models land in the personal dev schema (`DEV_MO`) regardless of layer — keeping dev clean and isolated without any manual schema management.

Without this macro, dbt would append custom schema names to the target (e.g. `DEV_MO_STAGING`) instead of routing them correctly. Overriding it is a required step for proper environment isolation in Snowflake.

---

## Tech Stack

| Tool | Notes |
|---|---|
| Snowflake | Data warehouse |
| dbt | Transformation, testing, documentation |
| MetricFlow | Semantic layer & metric definitions |
| dbt_utils | Surrogate key generation |
| dbt Cloud | CI/CD pipeline, environment management |
| Git / GitHub | Version control |

---

*Author: Mohammed Alzahrani | [LinkedIn](https://linkedin.com/in/mohammedalz-)*
