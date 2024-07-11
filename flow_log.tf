resource "aws_flow_log" "logs" {
  log_destination = aws_cloudwatch_log_group.flow_group.arn
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.role.arn
}

resource "aws_cloudwatch_log_group" "flow_group" {
  name = "flow-group"
}

data "aws_iam_policy_document" "flow_policy_doc" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_policies" {
  name   = "flow-logs-policies"
  role   = aws_iam_role.role.id
  policy = data.aws_iam_policy_document.flow_policy_doc.json
}

resource "aws_iam_role" "role" {
  name = "flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
