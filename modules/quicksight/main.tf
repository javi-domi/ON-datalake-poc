# QuickSight IAM Role
resource "aws_iam_role" "quicksight_role" {
  name = "quicksight_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "quicksight.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# QuickSight IAM Policy
resource "aws_iam_policy" "quicksight_policy" {
  name = "quicksight_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "quicksight:*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "redshift:*"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

# QuickSight IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "quicksight_policy_attachment" {
  role = aws_iam_role.quicksight_role.name
  policy_arn = aws_iam_policy.quicksight_policy.arn
}