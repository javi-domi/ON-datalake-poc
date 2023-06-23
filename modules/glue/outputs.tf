output "glue_iam_role" {
    value = aws_iam_role.iam_for_glue.arn
}

output "glue_iam_role_name" {
    value = aws_iam_role.iam_for_glue.name
}

output "glue_iam_policy" {
    value = aws_iam_policy.glue_policy.arn
}

output "glue_iam_role_policy_attachment" {
    value = aws_iam_role_policy_attachment.glue_policy_attachment
}