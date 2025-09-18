import sys
from datetime import datetime, timedelta
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from awsglue.job import Job
from pyspark.context import SparkContext
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as F
from pyspark.sql.window import Window
from awsglue.data_quality import DataQuality
from pyspark.sql.types import StructType, StructField, TimestampType, DateType, IntegerType, DoubleType, StringType


args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

#variáveis do d-1
ontem = (datetime.today() - timedelta(days=1)).date()  
antiontem = (datetime.today() - timedelta(days=2)).date()
ontem_str = ontem.strftime("%Y-%m-%d")
antiontem_str = antiontem.strftime("%Y-%m-%d")

#Leitura das bases, pode ser alterado de acordo com a origem dos dados
def leitura():
    purchase_dyf = glueContext.create_dynamic_frame.from_catalog(
        database="your_db",
        table_name="purchase",
        push_down_predicate=f"transaction_date = '{ontem_str}'"
    )

    product_item_dyf = glueContext.create_dynamic_frame.from_catalog(
        database="your_db",
        table_name="product_item",
        push_down_predicate=f"transaction_date = '{ontem_str}'"
    )

    purchase_extra_dyf = glueContext.create_dynamic_frame.from_catalog(
        database="your_db",
        table_name="purchase_extra_info",
        push_down_predicate=f"transaction_date = '{ontem_str}'"
    )

    tb_spec_purchase_dyf = glueContext.create_dynamic_frame.from_catalog(
        database="your_db",
        table_name="tb_spec_purchase",
        push_down_predicate=f"transaction_date = '{antiontem_str}'"
    )
    if tb_spec_purchase_dyf.count() == 0:
        print("A tabela tb_spec_purchase está vazia. Primeira ingestão de dados.")
        empty_schema = StructType([
            StructField("transaction_datetime", TimestampType(), True),
            StructField("transaction_date", DateType(), True),
            StructField("purchase_id", IntegerType()(), True),
            StructField("buyer_id", IntegerType()(), True),
            StructField("prod_item_id", IntegerType()(), True),
            StructField("order_date", DateType(), True),
            StructField("release_date", DateType(), True),
            StructField("producer_id", IntegerType()(), True),
            StructField("product_id", IntegerType()(), True),
            StructField("item_quantity", IntegerType(), True),
            StructField("purchase_value", DoubleType(), True),
            StructField("subsidiary", StringType(), True)
        ])
        tb_spec_purchase_df = spark.createDataFrame([], empty_schema)
    else:
        tb_spec_purchase_df = tb_spec_purchase_dyf.toDF()    

    purchase_df = purchase_dyf.toDF()
    product_item_df = product_item_dyf.toDF()
    purchase_extra_df = purchase_extra_dyf.toDF()

    purchase_df = purchase_df.select(
        "transaction_datetime",
        "transaction_date",
        "purchase_id",
        "buyer_id",
        "prod_item_id",
        "order_date",
        "release_date",
        "producer_id"
    )
    
    product_item_df = product_item_df.select(
        "transaction_datetime",
        "transaction_date",
        "purchase_id",
        "product_id",
        "item_quantity",
        "purchase_value"
    )
    
    purchase_extra_df = purchase_extra_df.select(
        "transaction_datetime",
        "transaction_date",
        "purchase_id",
        "subsidiary"
    )
    return purchase_df, product_item_df, purchase_extra_df, tb_spec_purchase_df


def data_manipulation():
    purchase_df, product_item_df, purchase_extra_df, tb_spec_purchase_df = leitura()
        
    joined_df = purchase_df.alias("tb1").join(
        product_item_df.alias("tb2"), on="purchase_id", how="full_outer"
    ).join(
        purchase_extra_df.alias("tb3"), on="purchase_id", how="full_outer"
    )
    

    merged_df = tb_spec_purchase_df.alias("tbo").join(
        joined_df.alias("tbj"), on="purchase_id", how="full_outer"
    )

    final_columns = ["transaction_datetime", "transaction_date", "purchase_id", "buyer_id",
                     "prod_item_id", "order_date", "release_date", "producer_id",
                     "product_id", "item_quantity", "purchase_value", "subsidiary"]
 
    for col in final_columns:
        merged_df = merged_df.withColumn(
            col,
            F.coalesce(F.col(f"tbj.{col}"), F.col(f"tbo.{col}"))
        )

    final_df = merged_df.select(*final_columns)

    window_spec_1 = Window.partitionBy("purchase_id").orderBy(F.col("transaction_datetime"))
    merged_df = merged_df.withColumn(
        "prev_purchase_value",
        F.lag("purchase_value", 1).over(window_spec_1)
    )
    merged_df = merged_df.withColumn(
        "daily_value",
        F.when(F.col("prev_purchase_value").isNull(), F.col("purchase_value"))
         .otherwise(F.col("purchase_value") - F.col("prev_purchase_value"))
    ).drop("prev_purchase_value")


    window_spec_2 = Window.partitionBy("purchase_id").orderBy(F.col("transaction_datetime").desc())
    final_df = merged_df.withColumn("row_num", F.row_number().over(window_spec_2)) \
                        .filter(F.col("row_num") == 1) \
                        .drop("row_num")

    return final_df

def data_quality(df):
    dq = DataQuality()
    dqdl_rules = """
    isPrimaryKey purchase_id
    isComplete transaction_date
    minValue item_quantity 0
    minValue purchase_value 0
    isType transaction_datetime datetime
    """
    result = dq.evaluate(df, dqdl_rules)

    if result.result()["failedRuleCount"] > 0:
        print("Data Quality check FAILED")
        raise ValueError("Data Quality: Uma ou mais regras não passaram")
    else:
        print("Data Quality check PASSED")
        return True


def upload(final_df):
    final_dyf = DynamicFrame.fromDF(final_df, glueContext, "final_dyf")
    glueContext.write_dynamic_frame.from_options(
        frame=final_dyf,
        connection_type="s3",
        connection_options={
            "path": "s3://meu-bucket-glue-dev/tb_spec_purchases/",
            "partitionKeys": ["transaction_date"]
        },
        format="glueparquet",
        format_options={},
        transformation_ctx="append_ctx"
    )

def main():
    final_df = data_manipulation()
    data_quality(final_df)
    upload(final_df)

if __name__ == "__main__":
    main()