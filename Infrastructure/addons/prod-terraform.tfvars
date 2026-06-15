project_name = "fleetman"
region       = "us-east-1"
env          = "prod"

create_external_secrets_operator = true

k8s_namespaces = ["fleetman-prod", "external-secrets-operator"]