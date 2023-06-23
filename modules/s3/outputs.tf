output "s3_bucket_id" {
  value       = aws_s3_bucket.bucket.id
  description = "The ID of the specific S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "The ARN of the specific S3 bucket"
}