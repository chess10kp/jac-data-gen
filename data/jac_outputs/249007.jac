"""Return AWS region from a service ARN."""
def get_aws_region(service_arn: str) -> str {
    return service_arn.split(':')[3];
}