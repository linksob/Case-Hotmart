CREATE EXTERNAL TABLE IF NOT EXISTS your_database.tb_spec_purchases (
    transaction_datetime timestamp COMMENT 'Data e hora da transação de inserção na tabela',
    purchase_id bigint COMMENT 'Identificador único da compra',
    buyer_id bigint COMMENT 'Identificador do comprador',
    prod_item_id bigint COMMENT 'Identificador do item do produto',
    order_date date COMMENT 'Data do pedido',
    release_date date COMMENT 'Data de liberação',
    producer_id bigint COMMENT 'Identificador do produtor',
    product_id bigint COMMENT 'Identificador do produto',
    item_quantity int COMMENT 'Quantidade de itens comprados',
    purchase_value double COMMENT 'Valor da compra',
    subsidiary string COMMENT 'Filial responsável'
)
PARTITIONED BY (transaction_date date COMMENT 'Data da transação mais recente (partição)')
STORED AS PARQUET
LOCATION 's3://bucket/caminho/tb_spec_purchases/'
TBLPROPERTIES (
    'parquet.compress'='SNAPPY',
    'projection.enabled'='true'
);