
#=======================================================================
# Maintenance Page Module
# Creates an S3 static website that serves as the failover destination
# when the primary ALB is unhealthy.
#
# HOW TO USE:
# 1. Run: terraform apply (creates the S3 bucket and HTML page)
# 2. Note the output: maintenance_website_endpoint
# 3. Set in your dns-route53 module tfvars:
#      lms_failover_domain  = <maintenance_website_endpoint output>
#      lms_failover_zone_id = <maintenance_zone_id output>
#      cms_failover_domain  = <maintenance_website_endpoint output>
#      cms_failover_zone_id = <maintenance_zone_id output>
# 4. Run: terraform apply again
#    Health checks and secondary DNS records activate automatically.
#
# COST: ~$0.01/month (S3 storage for one HTML file)
#=======================================================================








#-----------------------------------------------------------------------
# S3 bucket for maintenance page
# Must be public — users hit this directly when ALB is down
#-----------------------------------------------------------------------
resource "aws_s3_bucket" "maintenance" {
  bucket        = "${local.name}-maintenance-page"
  force_destroy = true
  tags          = local.tags
}

resource "aws_s3_bucket_public_access_block" "maintenance" {
  bucket = aws_s3_bucket.maintenance.id

  # Must allow public for website hosting
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "maintenance" {
  bucket = aws_s3_bucket.maintenance.id

  index_document {
    suffix = "index.html"
  }

  # All errors also show the maintenance page
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "maintenance" {
  # depends_on needed — public access block must be removed before
  # bucket policy allowing public read can be applied
  depends_on = [aws_s3_bucket_public_access_block.maintenance]

  bucket = aws_s3_bucket.maintenance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicRead"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.maintenance.arn}/*"
    }]
  })
}

#-----------------------------------------------------------------------
# Maintenance page HTML
# Customize the content to match your brand
#-----------------------------------------------------------------------
resource "aws_s3_object" "maintenance_page" {
  bucket       = aws_s3_bucket.maintenance.id
  key          = "index.html"
  content_type = "text/html"

  # This uploads the maintenance HTML directly from Terraform.
  # Edit the HTML below to match your platform branding.
  content = <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="refresh" content="60">
      <title>Scheduled Maintenance</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
                       Roboto, Helvetica, Arial, sans-serif;
          background: #f8f9fa;
          color: #343a40;
          display: flex;
          align-items: center;
          justify-content: center;
          min-height: 100vh;
          padding: 2rem;
        }
        .card {
          background: white;
          border-radius: 8px;
          box-shadow: 0 2px 12px rgba(0,0,0,0.08);
          padding: 3rem 4rem;
          max-width: 560px;
          width: 100%;
          text-align: center;
        }
        .icon {
          font-size: 3rem;
          margin-bottom: 1.5rem;
        }
        h1 {
          font-size: 1.75rem;
          font-weight: 600;
          margin-bottom: 1rem;
          color: #212529;
        }
        p {
          font-size: 1rem;
          line-height: 1.6;
          color: #6c757d;
          margin-bottom: 0.75rem;
        }
        .refresh-note {
          font-size: 0.85rem;
          color: #adb5bd;
          margin-top: 1.5rem;
        }
      </style>
    </head>
    <body>
      <div class="card">
        <div class="icon">🔧</div>
        <h1>Scheduled Maintenance</h1>
        <p>
          We are performing scheduled maintenance to improve
          your learning experience.
        </p>
        <p>
          We will be back online shortly.
          Thank you for your patience.
        </p>
        <p class="refresh-note">
          This page refreshes automatically every 60 seconds.
        </p>
      </div>
    </body>
    </html>
  HTML

  tags = local.tags
}


