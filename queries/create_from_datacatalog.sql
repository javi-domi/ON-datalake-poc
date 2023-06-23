create external schema if not exists db_schema_pp
from data catalog 
database 'pp_db' 
iam_role 'arn:aws:iam::{account-number}:role/DatalakeRedshiftRole'
create external database if not exists;

create external schema if not exists db_schema_ss
from data catalog 
database 'ss_db' 
iam_role 'arn:aws:iam::{account-number}:role/DatalakeRedshiftRole'
create external database if not exists;