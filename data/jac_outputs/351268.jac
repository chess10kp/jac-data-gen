"""Given an ARN, return the string after the account ID, no matter the ARN format."""
def get_resource_string(arn: str) -> str {
    split_arn = arn.split(":");
    ":".join(split_arn[5:])
}