resource "aws_iam_role" "redshift_role" {
    name = "DatalakeRedshiftRole"
    assume_role_policy = <<-ROLE
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "redshift.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
ROLE
}

resource "aws_iam_policy" "redshift_policy" {
    name = "redshift_policy"
    policy = <<-POLICY
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Effect": "Allow",
           "Action": "s3:*",
           "Resource": "*"
       },
       {
            "Effect": "Allow",
            "Action": "glue:*",
            "Resource": "*"
       }
   ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
    role = aws_iam_role.redshift_role.name
    policy_arn = aws_iam_policy.redshift_policy.arn
}