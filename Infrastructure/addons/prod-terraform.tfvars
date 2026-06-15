project_name = "fleetman"
region       = "us-east-1"
env          = "prod"
account_id = "176777036446"


create_external_secrets_operator = true

k8s_namespaces = ["fleetman-prod", "external-secrets-operator"]