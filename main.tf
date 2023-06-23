terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
  region = var.aws_region
  org    = var.org
  env    = var.env
}

provider "aws" {
  region     = local.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_access_secret_key
}

# S3 bucket
module "main_bucket" {
  source      = "./modules/s3"
  bucket_name = "${local.org}-datalake-${local.env}"
}

# Glue services
module "glue_services" {
  source = "./modules/glue"
}

resource "aws_s3_object" "glue_jobs" {
  bucket = module.main_bucket.s3_bucket_id
  key    = "scripts/glue_send_to_s3_job.py"
  source = "${path.module}/scripts/glue_send_to_s3_job.py"
}

# Glue connections
resource "aws_glue_connection" "ppdb_connection" {
  name = "pp_db"
  connection_properties = {
    JDBC_CONNECTION_URL = var.pp_jdbc_connection_url
    USERNAME            = var.pp_username
    PASSWORD            = var.pp_password
  }

  physical_connection_requirements {
    availability_zone = "us-east-2a"
    security_group_id_list = var.security_group_id_list
    subnet_id = var.subnet_id
  }
}

resource "aws_glue_connection" "ssdb_connection" {
  name = "ss_db"
  connection_properties = {
    JDBC_CONNECTION_URL = var.ss_jdbc_connection_url
    USERNAME            = var.ss_username
    PASSWORD            = var.ss_password
  }

  physical_connection_requirements {
    availability_zone = "us-east-2a"
    security_group_id_list = var.security_group_id_list
    subnet_id = var.subnet_id
  }
}

# Glue job
resource "aws_glue_job" "glue_etl_jobs" {
  name     = "send_data_to_s3"
  role_arn = module.glue_services.glue_iam_role
  command {
    name            = "glueetl"
    script_location = "s3://${module.main_bucket.s3_bucket_id}/scripts/glue_send_to_s3_job.py"
    python_version  = "3"
  }
  connections = [
    aws_glue_connection.ppdb_connection.name,
    aws_glue_connection.ssdb_connection.name
  ]
  default_arguments = {
    "--job-language" = "python"
    "--enable-metrics" = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--ORG" = "${local.org}"
    "--ENDPOINT" = "TODO: Add rds endpoint"    
  }
  glue_version = "3.0"
  depends_on = [
    aws_glue_connection.ppdb_connection,
    aws_glue_connection.ssdb_connection
  ]
}

resource "aws_glue_trigger" "glue_etl_trigger" {
  name     = "example"
  schedule = "cron(0 12 * * ? *)"
  type     = "SCHEDULED"

  actions {
    job_name = aws_glue_job.glue_etl_jobs.name
  }
}

# Glue Database
resource "aws_glue_catalog_database" "glue_pp_db" {
  name         = "pp_db"
  description  = "PP database"
  location_uri = "s3://${module.main_bucket.s3_bucket_id}/claims"
  parameters = {
    classification = "parquet"
    typeOfData     = "file"
  }
}

resource "aws_glue_catalog_database" "glue_ss_db" {
  name         = "ss_db"
  description  = "ss database"
  location_uri = "s3://${module.main_bucket.s3_bucket_id}/policy"
  parameters = {
    classification = "parquet"
    typeOfData     = "file"
  }
}

# Glue Crawler
resource "aws_glue_crawler" "pp_crawler" {
  name          = "pp-crawler"
  database_name = "pp_db"
  role          = module.glue_services.glue_iam_role
  schedule      = "cron(0 12 * * ? *)"

  s3_target {
    path = "s3://${module.main_bucket.s3_bucket_id}/claim"
  }

  configuration = <<EOF
{
   "Version": 1.0,
   "Grouping": {
      "TableGroupingPolicy": "CombineCompatibleSchemas" }
}
EOF
}

resource "aws_glue_crawler" "ss_crawler" {
  name          = "ss-crawler"
  database_name = "ss_db"
  role          = module.glue_services.glue_iam_role
  schedule      = "cron(0 12 * * ? *)"

  s3_target {
    path = "s3://${module.main_bucket.s3_bucket_id}/policy"
  }

  configuration = <<EOF
{
   "Version": 1.0,
   "Grouping": {
      "TableGroupingPolicy": "CombineCompatibleSchemas" }
}
EOF
}

# Redshift
module "redshift" {
  source = "./modules/redshift"
}

# Redshift VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k)]
  private_subnets = [for k, v in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 10)]

  enable_nat_gateway = true
}

# Redshift Security Group
resource "aws_security_group" "redshift_sg" {
  name        = "redshift-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "redshift_sg_inbound_rule" {
  source_security_group_id = aws_security_group.redshift_sg.id
  type              = "ingress"
  from_port         = 5439
  to_port           = 5439
  protocol          = "tcp"
  security_group_id   = aws_security_group.quicksight_sg.id
}

resource "aws_security_group_rule" "redshift_sg_outbound_rule" {
  source_security_group_id = aws_security_group.redshift_sg.id
  type              = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "tcp"
  security_group_id = aws_security_group.quicksight_sg.id
}


# Quicksight Security Group 
resource "aws_security_group" "quicksight_sg" {
  name        = "quicksight-sg"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "quicksight_sg_inbound_rule" {
  source_security_group_id = aws_security_group.quicksight_sg.id
  type              = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"
  security_group_id = aws_security_group.redshift_sg.id
}

resource "aws_security_group_rule" "quicksight_sg_outbound_rule" {
  source_security_group_id = aws_security_group.quicksight_sg.id
  type              = "egress"
  from_port   = 5439
  to_port     = 5439
  protocol    = "tcp"
  security_group_id = aws_security_group.redshift_sg.id
}


# Redshift Subnet Group
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name        = "redshift-subnet-group"
  description = "Subnet group for the datalake"
  subnet_ids  = [module.vpc.public_subnets[0]]
}

# Redshift Parameter Group
resource "aws_redshift_parameter_group" "redshift_parameter_group" {
  name        = "redshift-parameter-group"
  family      = "redshift-1.0"

    parameter {
        name  = "require_ssl"
        value = "false"
    }

    parameter {
        name  = "query_group"
        value = "${var.org}_datalake"
    }
}
  

resource "aws_redshift_cluster" "redshift_datalake" {
    cluster_identifier = "${var.org}-datalake-cluster"
    database_name = "${var.org}_datalake_db"
    master_username = var.redshift_username
    master_password = var.redshift_password
    node_type = var.redshift_node_type
    cluster_type = var.redshift_cluster_type
    number_of_nodes = 1
    encrypted = false
    port = 5439

    allow_version_upgrade = false
    automated_snapshot_retention_period = 7
    publicly_accessible = true
    skip_final_snapshot = true
    availability_zone = "us-east-2a"

    cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
    cluster_parameter_group_name = aws_redshift_parameter_group.redshift_parameter_group.name
    iam_roles = [module.redshift.redshift_role]
    vpc_security_group_ids = [aws_security_group.redshift_sg.id]

    logging {
      enable = false
    }
}

# QuickSight
module "quicksight" {
  source = "./modules/quicksight"
}

