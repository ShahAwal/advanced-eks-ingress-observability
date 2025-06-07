# Handle existing IAM roles and policies with lifecycle blocks
resource "aws_iam_role" "grafana" {
  name = "grafana-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
      }
    ]
  })
  
  # Add lifecycle block to prevent recreation
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
  
  tags = var.tags
}

resource "aws_iam_policy" "grafana_amp_access" {
  name        = "GrafanaAMPAccess"
  description = "Allow Grafana to access AMP"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Effect   = "Allow"
        Resource = aws_prometheus_workspace.amp.arn
      }
    ]
  })
  
  lifecycle {
    ignore_changes = [policy]
  }
}

resource "aws_iam_policy" "prometheus_ingest" {
  name        = "AMPIngestPolicy"
  description = "Allow ingesting metrics to AMP"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Effect   = "Allow"
        Resource = aws_prometheus_workspace.amp.arn
      }
    ]
  })
  
  lifecycle {
    ignore_changes = [policy]
  }
}