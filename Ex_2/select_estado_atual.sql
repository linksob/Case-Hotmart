SELECT
    *
FROM
    tb_spec_purchases
WHERE
    transaction_date = CURRENT_DATE - INTERVAL '1' DAY

--Athena
SELECT
    *
FROM
    tb_spec_purchases
WHERE
    transaction_date = date_add('day', -1, current_date)