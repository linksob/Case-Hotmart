SELECT
    transaction_date,
    subsidiary,
    SUM(daily_value) AS gmv
FROM workspace_db.tb_spec_purchases
GROUP BY transaction_date, subsidiary
ORDER BY transaction_date, subsidiary;

-- exemplo para jan/2025
SELECT
    subsidiary,
    SUM(daily_value) AS gmv
FROM workspace_db.tb_spec_purchases
WHERE transaction_date = DATE '2025-01-31'
GROUP BY subsidiary;