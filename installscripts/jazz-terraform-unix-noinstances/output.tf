#
# This resource will add necessary setting needed for the user into stack_details.json
#

#General output variables
output "jazz_stack_name" {
  value = "${var.envPrefix}"
}
output "jazz_home" {
  value = "http://${aws_cloudfront_distribution.jazz.domain_name}"
}
output "jazz_username" {
  value = "${var.cognito_pool_username}"
}
output "jazz_password" {
  value = "${var.cognito_pool_password}"
}
output "region" {
  value = "${var.region}"
}
output "jazz_api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.jazz-prod.id}.execute-api.${var.region}.amazonaws.com/prod"
}

#Jenkins-related output variables
output "jenkins_elb" {
  value = "http://${lookup(var.jenkinsservermap, "jenkins_elb")}"
}

output "jenkins_username" {
  value = "${lookup(var.jenkinsservermap, "jenkinsuser")}"
}

output "jenkins_password" {
  value = "${lookup(var.jenkinsservermap, "jenkinspasswd")}"
}

#SCM (BB/Gitlab) related output variables.
output "scm_username" {
  value = "${lookup(var.scmmap, "scm_username")}"
}

output "scm_password" {
  value = "${lookup(var.scmmap, "scm_password")}"
}

output "scm_elb" {
  value = "${lookup(var.scmmap, "scm_elb")}"
}

output "scm_publicip" {
  value = "${lookup(var.scmmap, "scm_publicip")}"
}
