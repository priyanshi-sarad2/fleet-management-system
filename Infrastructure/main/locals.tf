########    Locals     ########

locals {
  # The first web app's domain from the cloudfront_s3_origins map,
  webapp_domain = try(values(var.cloudfront_s3_origins)[0].domain, null)

  # Strip the leftmost label to get the apex/root domain for the hosted zone,
  root_domain = local.webapp_domain == null ? null : join(".", slice(
    split(".", local.webapp_domain),
    1,
    length(split(".", local.webapp_domain))
  ))
}