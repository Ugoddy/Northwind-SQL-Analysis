# Northwind Sales Analysis (SQL)

13 business questions answered with SQL against the Northwind sample database: a food-and-beverage wholesaler with 89 active business customers, 830 orders, and 77 products, covering July 1996 to May 1998.

The analysis covers revenue drivers, customer concentration, churn risk, sales-rep performance, discounting, and shipping performance.

## Headline numbers
- **$1,265,793** total revenue (after discounts) across 830 orders
- **Revenue is accelerating**: $208K (Jul-Dec 1996), $617K (1997), and $441K in January to early May 1998 alone, already about 71% of the full-year 1997 total
- **Three customers account for about a quarter of all revenue** (25.2%)
- **$88,666 given up to discounts**, roughly 6.5% of undiscounted sales

## Tools
SQLite, with standard SQL (CTEs and window functions). Queries port to PostgreSQL or MySQL with small syntax changes, such as `strftime` becoming `DATE_TRUNC`.

## Files
| File | Purpose |
|---|---|
| `queries.sql` | All 13 business questions as runnable SQL |
| `northwind.db` | The SQLite database, ready to query |
| `schema.sql` | Table definitions |
| `load_data.py` | Rebuilds `northwind.db` from the source CSVs (cleans NULLs, dates, and drops binary photo columns) |

## Findings

**1. Top products by revenue.** Côte de Blaye leads with $141,397, well ahead of Thüringer Rostbratwurst ($80,369). That single product is about 11% of all revenue.

**2. Top products by units sold.** Camembert Pierrot leads on volume (1,577 units), followed by Raclette Courdavault (1,496). Côte de Blaye does not appear in the top 10 by volume, so it earns its revenue through a high price rather than high volume. (Northwind has no cost column, so volume replaces profit margin here.)

**3 and 4. Revenue trend and month-over-month growth.** Monthly revenue climbed from about $27.9K in July 1996 to a peak of $123.8K in April 1998, using `LAG()` for the growth rate. *Note*: May 1998 shows a -85.2% drop, but the data ends on May 6 (14 orders), so this is a partial-month artifact and not a real decline.

**5. Churn risk.** 16 of the 89 customers who ordered (18%) had no order in the 90 days before the dataset's last order date. The most extreme case is Centro comercial Moctezuma (Mexico), whose last order was in July 1996, the first month of the data. This is the list a retention team would call first.

**6. Average order value by country.** Austria leads at $3,200 per order (40 orders), then Ireland at $2,631 (19 orders) and the USA at $2,013 (122 orders). Ireland's figure rests on a small number of orders, so treat it with care.

**7. Sales rep ranking.** Margaret Peacock leads with $232,891, then Janet Leverling ($202,813) and Nancy Davolio ($192,108). The lowest of the nine is Steven Buchanan (Sales Manager) at $68,792.

**8. Revenue by category.** Beverages (21.2%) and Dairy Products (18.5%) together make up about 40% of revenue. Grains/Cereals is the smallest at 7.6%.

**9. Customer concentration.** QUICK-Stop (Germany, $110,277), Ernst Handel (Austria, $104,875), and Save-a-lot Markets (USA, $104,362) together account for about 25% of total revenue. That is a concentration risk: losing one of them would hurt. `PERCENT_RANK()` flags the top decile as "High Value".

**10. Discount impact.** 38.9% of order lines carry a discount, costing $88,666 in total. Beverages gives up the most ($18,659), while Meat/Poultry has the highest share of discounted lines (43.9%).

**11. Repeat customers.** 98.9% of customers who ordered placed more than one order (average 9.3 orders each), which fits a wholesale customer base of businesses rather than individual shoppers. Two customers in the customers table never ordered at all (FISSA Fabrica Inter. Salchichas S.A. and Paris spécialités).

**12. Best-selling product per category.** Found in one query with `RANK() ... PARTITION BY category`. Examples: Côte de Blaye (Beverages), Thüringer Rostbratwurst (Meat/Poultry), Raclette Courdavault (Dairy Products), Vegie-spread (Condiments, $16,701).

**13. Shipper performance.** Federal Shipping is both fastest (7.5 days from order to shipment) and least often late (3.6%); United Package is slowest (9.2 days, 5.1% late). Overall, 37 of 809 shipped orders (4.6%) shipped after the required date. Northwind records shipment dates and not delivery dates, so "late" means shipped after the required date.

## SQL techniques demonstrated
- Multi-table `JOIN`s (up to 4 tables in one query)
- CTEs (`WITH`) to break complex logic into readable steps
- Window functions: `LAG`, `RANK`, `PERCENT_RANK`, `SUM() OVER ()` for share of total, and `PARTITION BY`
- `CASE WHEN` for tiering and conditional counts
- Date arithmetic (`strftime`, `julianday`)

## Data preparation
The source is the classic Northwind sample database, exported as CSVs. `load_data.py` converts the text `'NULL'` to real NULLs, converts timestamps to plain dates, keeps IDs and postal codes as text so leading zeros survive, and drops binary photo columns. Revenue is calculated as `unitPrice * quantity * (1 - discount)` using the price charged on each order line, not the current catalogue price.

## How to run
```bash
sqlite3 northwind.db < queries.sql      # runs every query
# or open northwind.db in DB Browser for SQLite and run queries one at a time
```
To rebuild the database from scratch, place the CSVs in a `data/` folder and run `python load_data.py`.
