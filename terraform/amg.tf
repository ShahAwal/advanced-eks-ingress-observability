resource "aws_grafana_workspace" "amg" {
  name                     = "nginx-ingress-monitoring"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]
  role_arn                 = aws_iam_role.grafana.arn

  tags = var.tags
}

resource "aws_iam_role" "grafana" {
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
  lifecycle {
    ignore_changes = [assume_role_policy]
  }
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

  tags = var.tags
}

resource "aws_iam_policy" "grafana_amp_access" {
  lifecycle {
    ignore_changes = [policy]
  }
  lifecycle {
    ignore_changes = [policy]
  }
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
}

resource "aws_iam_role_policy_attachment" "grafana_amp_access" {
  role       = aws_iam_role.grafana.name
  policy_arn = aws_iam_policy.grafana_amp_access.arn
}

# Output the Grafana workspace URL
output "grafana_workspace_url" {
  value = "https://${aws_grafana_workspace.amg.endpoint}"
}