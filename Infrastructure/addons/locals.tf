# The IRSA trust policy needs the OIDC PROVIDER ARN (not the issuer URL), so look it up from the issuer URL:
# we are passing the issuer URL to the data source to get the OIDC PROVIDER ARN
data "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  url = data.aws_eks_cluster.eks_cluster_data.identity[0].oidc[0].issuer
}