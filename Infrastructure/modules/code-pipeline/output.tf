output "codepipeline_webhook_url" {
  description = "The URL of the AWS CodePipeline webhook"
  sensitive   = true
  value       = length(aws_codepipeline_webhook.pipeline_webhook) > 0 ? aws_codepipeline_webhook.pipeline_webhook[0].url : ""
} // to deal with cases when I don't create any webhook and it is empty