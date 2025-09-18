WITH unido AS (
    SELECT
        a.purchase_id,
        a.release_date,
        a.prod_item_id,
        a.producer_id,
        b.item_quantity * b.purchase_value AS total_value
    FROM purchase AS a
    LEFT JOIN product_item AS b
           ON a.prod_item_id = b.prod_item_id
),
sumarizado AS (
    SELECT
        producer_id,
        prod_item_id,
        release_date,
        SUM(total_value) AS total_gmv
    FROM unido
    GROUP BY producer_id, prod_item_id, release_date
),

-- Quais são os 50 maiores produtores em faturamento ($) de 2021?
SELECT
    producer_id,
    SUM(total_value) AS total_gmv
FROM unido
WHERE release_date >= '2021-01-01'
  AND release_date <  '2022-01-01'
GROUP BY producer_id
ORDER BY total_gmv DESC
LIMIT 50;


-- Quais são os 2 produtos que mais faturaram ($) de cada produtor?
SELECT p1.producer_id,
       p1.prod_item_id,
       p1.total_gmv
FROM sumarizado p1
WHERE p1.prod_item_id IN (
    SELECT p2.prod_item_id
    FROM sumarizado p2
    WHERE p2.producer_id = p1.producer_id
    ORDER BY p2.total_gmv DESC
    LIMIT 2
)
ORDER BY p1.producer_id, p1.total_gmv DESC;