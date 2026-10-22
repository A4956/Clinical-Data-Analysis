# Pharma Sales & Market Analytics (MySQL)

A set of MySQL queries that analyze pharmaceutical sales performance, prescription fulfillment, and market share across territories, products, and sales representatives. The project uses a `marketdb` database with synthetic data modeled on a pharma commercial operation.

## Database Schema

The database `marketdb` contains seven tables:

| Table | Description |
|---|---|
| `products` | Product catalog, including `product_id`, `product_name`, and `therapeutic_area` |
| `territories` | Sales territories, including `territory_id`, `territory_name`, and `region` |
| `sales_reps` | Sales representatives, linked to a territory through `territory_id` |
| `doctors` | Prescribing physicians, including `doctor_id`, name, and `doctor_status` |
| `sales_transactions` | Transaction records with units sold, gross and net sales (INR), status, and dates |
| `prescriptions` | Prescriptions written by doctors for products, with `prescription_status` and `prescription_date` |
| `market_data` | Estimated total market sales by territory, therapeutic area, and report month |

## Queries

1. **Product sales performance**: Total units sold and net sales for each product in 2025.
2. **Regional sales performance**: Transactions, units, and net sales by region for January to June 2026, ranked by net sales.
3. **Prescription fulfillment rate**: Fulfilled versus total prescriptions by therapeutic area in 2025, with areas filtered to at least 30 records and rates rounded to two decimals.
4. **Monthly revenue growth**: Monthly net sales for 2025 with month-over-month change and growth percentage, using window functions (`LAG`).
5. **Top 3 products per therapeutic area**: Highest-revenue products within each therapeutic area for 2025, ranked with `DENSE_RANK()`.
6. **Sales rep performance ranking**: Completed net sales per representative from January to September 2026, ranked across all reps.
7. **Market share estimate**: Company net sales as a percentage of estimated market sales, by month, territory, and therapeutic area for 2025.
8. **Prescription-to-sales gap analysis**: Active doctors with fulfilled prescriptions in 2025 who have no completed sales transaction for the same product, using `NOT EXISTS`.

## Techniques Used

- Multi-table joins and aggregations (`GROUP BY`, `SUM`, `COUNT`)
- Common table expressions (CTEs) for readable multi-step logic
- Window functions: `LAG()` and `DENSE_RANK()` with `PARTITION BY`
- Conditional aggregation with `CASE WHEN`
- Safe division with `NULLIF()` and rounding with `ROUND()`
- Date handling with `DATE_FORMAT()` and range filters
- Anti-join pattern using `NOT EXISTS`

## How to Run

1. Load the `marketdb` schema and data into a MySQL 8.0+ instance (window functions require MySQL 8.0 or later).
2. Open the SQL script in MySQL Workbench or the MySQL CLI.
3. Run each query block independently. Lines beginning with `select * from` are quick checks on each table and can be skipped.

```bash
mysql -u <user> -p < marketdb_analysis.sql
```

## Key Business Questions

- Which products generate the most units and revenue?
- How do regions compare on sales volume and transaction count?
- Where are prescriptions going unfilled, and by therapeutic area?
- How is revenue trending month over month?
- Which products lead in each therapeutic area?
- Which sales reps are the top performers in their regions?
- What share of the estimated market does the company hold?
- Which prescribing doctors have fulfilled prescriptions with no matching sales?

## Notes

- Date ranges are hard-coded to the periods named in each business question.
- Status values are compared case-sensitively in some queries, so check the stored casing (`completed` vs `Completed`) in your data before running.
