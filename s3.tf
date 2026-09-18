resource "aws_s3_bucket" "main_bucket" {
  bucket_prefix = "devops-storage-bucket-"

  tags = {
    Name = "devops-storage-bucket"
  }
}