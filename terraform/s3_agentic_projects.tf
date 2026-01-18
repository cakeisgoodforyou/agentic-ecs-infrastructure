# Bucket for agentic projects (generated SQL, YAML files)
resource "aws_s3_bucket" "agentic_projects" {
  bucket = local.agentic_projects_bucket
  tags = merge(local.common_tags, {
    Purpose = "Store project artifacts"
  })
}

resource "aws_s3_bucket_versioning" "agentic_projects" {
  bucket = aws_s3_bucket.agentic_projects.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "agentic_projects" {
  bucket = aws_s3_bucket.agentic_projects.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "agentic_projects" {
  bucket                  = aws_s3_bucket.agentic_projects.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}