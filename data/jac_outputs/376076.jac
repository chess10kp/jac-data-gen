"""Builds the lambda function url based on event data"""
def get_lambda_path_from_event(event: Any) -> str {
    lambda_path = event["requestContext"]["path"];
    lambda_domain = event["requestContext"]["domainName"];
    return f"https://{lambda_domain}{lambda_path}";
}