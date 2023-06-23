# Generl
variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "The default AWS region"
}

variable "availability_zones" {
  description = "The availability zones to use for the VPC"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b"]
}

variable "aws_access_key_id" {
  type        = string
  description = "The AWS Access Key ID with permissions to S3, Glue, Redshift and Quicksight"
}

variable "aws_access_secret_key" {
  type        = string
  description = "The AWS Access Secret Key with permissions to S3, Glue, Redshift and Quicksight"
}

variable "org" {
  type        = string
  default     = "omahanational"
  description = "Organization name"
}

variable "env" {
  type        = string
  description = "The deployment environment, e.g. dev/test/staging/prod"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC for Redshift and QuickSight"
  default     = "redshift-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the Redshift VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_id" {
  description = "The subnet ID for the Redshift VPC"
}

variable "security_group_id_list" {
  description = "The security group ID for the Redshift VPC"
  type        = list(string)
}

# Glue
variable "pp_jdbc_connection_url" {
  type        = string
  description = "The JDBC URL of the database to be used by Glue"
}

variable "pp_username" {
  type        = string
  description = "The username for the database"
}

variable "pp_password" {
  type        = string
  description = "The password for the username"
}

variable "ss_jdbc_connection_url" {
  type        = string
  description = "The JDBC URL of the database to be used by Glue"
}

variable "ss_username" {
  type        = string
  description = "The username for the database"
}

variable "ss_password" {
  type        = string
  description = "The password for the username"
}

# Redshift 
variable "redshift_username" {
  description = "Username for Redshift database"
}

variable "redshift_password" {
  description = "Password for Redshift database"
}

variable "redshift_node_type" {
  description = "The node type of the Redshift cluster"
  default = "dc2.large"
}
  
variable "redshift_cluster_type" {
  description = "The cluster type of the Redshift cluster"
  default = "single-node"
}
