output "redshift_role" {
    value = aws_iam_role.redshift_role.arn
}

output "redshift_role_name" {
    value = aws_iam_role.redshift_role.name
}

output "redshift_policy" {
    value = aws_iam_policy.redshift_policy.arn
}

output "redshift_role_policy_attachment" {
    value = aws_iam_role_policy_attachment.redshift_policy_attachment
}