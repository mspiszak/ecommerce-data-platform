import sys
import logging
from datetime import datetime, timezone

from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job

from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import LongType, DecimalType, TimestampType

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("orders_etl")
logger.setLevel(logging.INFO)

# -----------------------------------------------------------------------------
# Parametry joba
# -----------------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME", "SOURCE_BUCKET", "TARGET_BUCKET"])

JOB_NAME = args["JOB_NAME"]
SOURCE_BUCKET = args["SOURCE_BUCKET"]
TARGET_BUCKET = args["TARGET_BUCKET"]

SOURCE_PATH = f"s3://{SOURCE_BUCKET}/raw/orders/"
TARGET_PATH = f"s3://{TARGET_BUCKET}/processed/orders/"

REQUIRED_COLUMNS = ["order_id", "total_amount", "ordered_at"]

logger.info("Start joba %s", JOB_NAME)
logger.info("SOURCE_PATH=%s", SOURCE_PATH)
logger.info("TARGET_PATH=%s", TARGET_PATH)

# -----------------------------------------------------------------------------
# Inicjalizacja Glue / Spark
# -----------------------------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(JOB_NAME, args)

# Nadpisuj tylko partycje (year/month) obecne w bieżącym batchu, zamiast
# kasować cały katalog processed/orders/ przy każdym uruchomieniu.
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

ETL_RUN_DATE = datetime.now(timezone.utc).strftime("%Y-%m-%d")

try:
    # -------------------------------------------------------------------
    # 1. EXTRACT - czyta parquet z raw/orders/
    # -------------------------------------------------------------------
    logger.info("Etap EXTRACT: czytanie parquet z %s", SOURCE_PATH)
    df_raw = spark.read.parquet(SOURCE_PATH)

    missing = [c for c in REQUIRED_COLUMNS if c not in df_raw.columns]
    if missing:
        raise ValueError(f"Brak wymaganych kolumn w danych źródłowych: {missing}")

    raw_count = df_raw.count()
    logger.info("Wczytano %d rekordów surowych.", raw_count)

    # -------------------------------------------------------------------
    # 2. TRANSFORM - rzutowanie typów
    # -------------------------------------------------------------------
    logger.info("Etap TRANSFORM: rzutowanie typów kolumn")
    df_cast = (
        df_raw.withColumn("order_id", F.col("order_id").cast(LongType()))
        .withColumn("total_amount", F.col("total_amount").cast(DecimalType(12, 2)))
        .withColumn("ordered_at", F.col("ordered_at").cast(TimestampType()))
    )

    # -------------------------------------------------------------------
    # 3. TRANSFORM - data quality check
    #    a) odrzuć rekordy, których kluczowe pola są NULL (np. nieudany cast)
    #    b) odrzuć rekordy z total_amount < 0
    # -------------------------------------------------------------------
    logger.info("Etap TRANSFORM: data quality check")
    df_cast = df_cast.cache()

    null_cond = F.lit(False)
    for c in REQUIRED_COLUMNS:
        null_cond = null_cond | F.col(c).isNull()

    null_count = df_cast.filter(null_cond).count()
    negative_count = df_cast.filter(F.col("total_amount") < 0).count()

    df_valid = df_cast.filter(~null_cond).filter(F.col("total_amount") >= 0)

    logger.info(
        "DQ: odrzucono %d rekordów z NULL w %s oraz %d rekordów z total_amount < 0.",
        null_count,
        REQUIRED_COLUMNS,
        negative_count,
    )

    # -------------------------------------------------------------------
    # 4. TRANSFORM - usuwanie duplikatów po order_id
    # -------------------------------------------------------------------
    logger.info("Etap TRANSFORM: deduplikacja po order_id")
    df_valid = df_valid.cache()
    before_dedup = df_valid.count()
    df_dedup = df_valid.dropDuplicates(["order_id"])
    after_dedup = df_dedup.count()
    logger.info(
        "Usunięto %d duplikatów (%d -> %d rekordów).",
        before_dedup - after_dedup,
        before_dedup,
        after_dedup,
    )

    # -------------------------------------------------------------------
    # 5. TRANSFORM - kolumny pochodne
    # -------------------------------------------------------------------
    logger.info("Etap TRANSFORM: dodawanie kolumn pochodnych")
    df_enriched = (
        df_dedup.withColumn("order_date", F.to_date(F.col("ordered_at")))
        .withColumn("order_year", F.year(F.col("ordered_at")))
        .withColumn("order_month", F.month(F.col("ordered_at")))
        .withColumn("processed_at", F.current_timestamp())
        .withColumn("etl_run_date", F.lit(ETL_RUN_DATE).cast("date"))
    )

    # -------------------------------------------------------------------
    # 6. LOAD - zapis partycjonowany year=.../month=...
    #    Kolumny order_year / order_month zostają w plikach; year / month
    #    to ich kopie użyte wyłącznie jako klucze partycji (katalogi).
    # -------------------------------------------------------------------
    logger.info("Etap LOAD: zapis parquet do %s (partycje: year, month)", TARGET_PATH)
    (
        df_enriched.withColumn("year", F.col("order_year"))
        .withColumn("month", F.col("order_month"))
        .write.mode("overwrite")
        .partitionBy("year", "month")
        .parquet(TARGET_PATH)
    )

    logger.info("Zapisano %d rekordów do %s.", after_dedup, TARGET_PATH)
    logger.info("Job %s zakończony sukcesem.", JOB_NAME)


    job.commit()

except Exception:
    logger.exception("Job %s zakończony błędem.", JOB_NAME)
    raise
