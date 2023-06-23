import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame


def directJDBCSource(
    glueContext,
    connectionName,
    connectionType,
    database,
    table,
    redshiftTmpDir,
    transformation_ctx,
) -> DynamicFrame:

    connection_options = {
        "useConnectionProperties": "true",
        "dbtable": table,
        "connectionName": connectionName,
    }

    if redshiftTmpDir:
        connection_options["redshiftTmpDir"] = redshiftTmpDir

    return glueContext.create_dynamic_frame.from_options(
        connection_type=connectionType,
        connection_options=connection_options,
        transformation_ctx=transformation_ctx,
    )

args = getResolvedOptions(sys.argv, ["JOB_NAME", "ORG", "ENDPOINT"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

env = "dev"

ss_db = directJDBCSource(
    glueContext,
    connectionName="ss_db",
    connectionType="sqlserver",
    database=args["ENDPOINT"],
    table="policy",
    redshiftTmpDir="",
    transformation_ctx="ss_db",
)

pp_db = directJDBCSource(
    glueContext,
    connectionName="pp_db",
    connectionType="sqlserver",
    database="onprod",
    table="claim",
    redshiftTmpDir="",
    transformation_ctx="pp_db",
)

ss_s3 = glueContext.write_dynamic_frame.from_options(
    frame=ss_db,
    connection_type="s3",
    format="parquet",
    connection_options={"path": f"s3://{args['ORG']}-datalake-dev/policy", "partitionKeys": []},
    transformation_ctx="ss_s3",
)

pp_s3 = glueContext.write_dynamic_frame.from_options(
    frame=pp_db,
    connection_type="s3",
    format="csv",
    connection_options={"path": f"s3://{args['ORG']}-datalake-dev/claim", "partitionKeys": []},
    transformation_ctx="pp_s3",
)

job.commit()
