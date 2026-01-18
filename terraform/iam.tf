# Orchestrator Task Role
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Orchestrator task execution role (for ECS to pull images, write logs)
resource "aws_iam_role" "orchestrator_execution" {
  name               = "${var.project_name}-${var.environment}-orchestrator-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "orchestrator_execution" {
  role       = aws_iam_role.orchestrator_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Orchestrator task role (permissions for the application itself)
resource "aws_iam_role" "orchestrator_task" {
  name               = "${var.project_name}-${var.environment}-orchestrator-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json

  tags = local.common_tags
}

# Policy for orchestrator
data "aws_iam_policy_document" "orchestrator_task" {
  # Athena permissions
  statement {
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution",
      "athena:GetWorkGroup"
    ]
    resources = [
      aws_athena_workgroup.agenitc_projects.arn
    ]
  }

  # Glue Catalog permissions
  statement {
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartitions",
      "glue:GetTableVersions"
    ]
    resources = [
      "arn:aws:glue:${local.region}:${local.account_id}:catalog",
      "arn:aws:glue:${local.region}:${local.account_id}:database/*",
      "arn:aws:glue:${local.region}:${local.account_id}:table/*/*"
    ]
  }

  # S3 permissions for Athena results
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.athena_results.arn,
      "${aws_s3_bucket.athena_results.arn}/*"
    ]
  }

  # S3 permissions for agentic projects
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.agentic_projects.arn,
      "${aws_s3_bucket.agentic_projects.arn}/*",
      "${aws_s3_bucket.agent_logs.arn}/*"
    ]
  }

  # ECS permissions to run agentic tasks
  statement {
    effect = "Allow"
    actions = [
      "ecs:RunTask",
      "ecs:DescribeTasks",
      "ecs:StopTask"
    ]
    resources = [
      "arn:aws:ecs:${local.region}:${local.account_id}:task-definition/*",
      "arn:aws:ecs:${local.region}:${local.account_id}:task/*"
    ]
  }

  # IAM pass role (for ECS to assume other agentic role)
  #statement {
  #  effect = "Allow"
  #  actions = [
  #    "iam:PassRole"
  #  ]
  #  resources = [
  #    aws_iam_role.<linktorole>.arn
  #  ]
  #}

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.orchestrator.arn}:*"
    ]
  }
}

resource "aws_iam_policy" "orchestrator_task" {
  name   = "${var.project_name}-${var.environment}--orchestrator-task-policy"
  policy = data.aws_iam_policy_document.orchestrator_task.json
}

resource "aws_iam_role_policy_attachment" "orchestrator_task" {
  role       = aws_iam_role.orchestrator_task.name
  policy_arn = aws_iam_policy.orchestrator_task.arn
}

resource "aws_iam_role_policy_attachment" "bedrock_full" {
  role       = aws_iam_role.orchestrator_task.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}