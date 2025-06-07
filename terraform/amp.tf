resource "aws_prometheus_workspace" "amp" {
  alias = "nginx_ingress_monitoring"
  tags  = var.tags
}

resource "aws_prometheus_alert_manager_definition" "alertmanager" {
  workspace_id = aws_prometheus_workspace.amp.id
  definition   = <<EOF
alertmanager_config: |
  route:
    receiver: 'default'
    group_wait: 30s
    group_interval: 5m
    repeat_interval: 12h
    group_by: [cluster, alertname]
    routes:
      - receiver: 'critical'
        match:
          severity: critical
  receivers:
    - name: 'default'
      sns_configs:
        - topic_arn: ${aws_sns_topic.alerts.arn}
          sigv4:
            region: ${var.region}
          attributes:
            severity: warning
    - name: 'critical'
      sns_configs:
        - topic_arn: ${aws_sns_topic.alerts.arn}
          sigv4:
            region: ${var.region}
          attributes:
            severity: critical
EOF
}

resource "aws_prometheus_rule_group_namespace" "nginx_rules" {
  name         = "nginx-ingress-rules"
  workspace_id = aws_prometheus_workspace.amp.id
  data         = <<EOF
groups:
  - name: nginx.rules
    rules:
      - alert: NGINXHighHttp4xxErrorRate
        expr: sum(rate(nginx_ingress_controller_requests{status=~"4.."}[1m])) / sum(rate(nginx_ingress_controller_requests[1m])) * 100 > 5
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: NGINX high HTTP 4xx error rate (instance {{ $labels.instance }})
          description: "Too many HTTP requests with status 4xx (> 5%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      
      - alert: NGINXHighHttp5xxErrorRate
        expr: sum(rate(nginx_ingress_controller_requests{status=~"5.."}[1m])) / sum(rate(nginx_ingress_controller_requests[1m])) * 100 > 5
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: NGINX high HTTP 5xx error rate (instance {{ $labels.instance }})
          description: "Too many HTTP requests with status 5xx (> 5%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      
      - alert: NGINXLatencyHigh
        expr: histogram_quantile(0.99, sum(rate(nginx_ingress_controller_request_duration_seconds_bucket[2m])) by (host, node, le)) > 3
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: NGINX latency high (instance {{ $labels.instance }})
          description: "NGINX p99 latency is higher than 3 seconds\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
EOF
}

resource "aws_sns_topic" "alerts" {
  name = "nginx-ingress-alerts"
  tags = var.tags
}

resource "aws_iam_role" "prometheus_ingest" {
  name = "amp-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" : "system:serviceaccount:monitoring:prometheus-server"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_policy" "prometheus_ingest" {
  lifecycle {
    ignore_changes = [policy]
  }
  lifecycle {
    ignore_changes = [policy]
  }
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
}

resource "aws_iam_role_policy_attachment" "prometheus_ingest" {
  role       = aws_iam_role.prometheus_ingest.name
  policy_arn = aws_iam_policy.prometheus_ingest.arn
}

# Output the AMP workspace endpoint for use in Prometheus configuration
output "amp_endpoint" {
  value = aws_prometheus_workspace.amp.prometheus_endpoint
}

output "amp_workspace_id" {
  value = aws_prometheus_workspace.amp.id
}