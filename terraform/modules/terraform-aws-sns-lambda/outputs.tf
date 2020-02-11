output "bounce_topic_arn" {
  value = aws_sns_topic.bounce.arn
}

output "complaint_topic_arn" {
  value = aws_sns_topic.complaint.arn
}
