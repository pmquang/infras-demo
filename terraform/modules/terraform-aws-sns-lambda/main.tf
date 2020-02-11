#### Section for bounce

resource "aws_sns_topic" "bounce" {
  name = "${var.lambda_name}-sns-bounce"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "bounce" {
  topic_arn = "${aws_sns_topic.bounce.arn}"
  protocol = var.protocol
  endpoint = "${aws_sqs_queue.bounce.arn}"
}

resource "aws_sqs_queue" "bounce" {
  name                      = "${var.lambda_name}-sqs-bounce"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 300
  tags = var.tags
}

resource "aws_sqs_queue_policy" "bounce" {
  queue_url = "${aws_sqs_queue.bounce.id}"
  policy                    = <<EOF
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.bounce.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.bounce.arn}"
        }
      }
    }
  ]
}
EOF
}


#### Section for complaint

resource "aws_sns_topic" "complaint" {
  name = "${var.lambda_name}-sns-complaint"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "complaint" {
  topic_arn = "${aws_sns_topic.complaint.arn}"
  protocol = var.protocol
  endpoint = "${aws_sqs_queue.complaint.arn}"
}

resource "aws_sqs_queue" "complaint" {
  name                      = "${var.lambda_name}-sqs-complaint"
  delay_seconds             = 0
  max_message_size          = 2048
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = 300
  tags = var.tags
}

resource "aws_sqs_queue_policy" "complaint" {
  queue_url = "${aws_sqs_queue.complaint.id}"
  policy                    = <<EOF
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.complaint.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.complaint.arn}"
        }
      }
    }
  ]
}
EOF
}



data "archive_file" "this" {
  type = "zip"
  source_file = var.source_file
  output_path = var.output_path
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "this1" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "this2" {
  role       = "${aws_iam_role.lambda.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonCognitoPowerUser"
}


resource "aws_iam_role" "lambda" {
  name = var.lambda_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
   ]
}
EOF
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = var.lambda_name
  role          = "${aws_iam_role.lambda.arn}"
  handler       = "${var.lambda_name}.handler"
  runtime       = var.runtime
  tags          = var.tags
  source_code_hash = "${filebase64sha256("${data.archive_file.this.output_path}")}"
  environment {
    variables = var.environment_vars
  }
}

resource "aws_lambda_event_source_mapping" "bounce" {
  batch_size        = 4
  event_source_arn  = "${aws_sqs_queue.bounce.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.this.function_name}"
}

resource "aws_lambda_event_source_mapping" "complaint" {
  batch_size        = 4
  event_source_arn  = "${aws_sqs_queue.complaint.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.this.function_name}"
}
