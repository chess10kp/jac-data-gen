"""
Transforms a python dict {'a': 'b', 'c': 'd'} to the
aws tags format [{'Key': 'a', 'Value': 'b'}, {'Key': 'c', 'Value': 'd'}]
Only needed for boto3 api calls
"""
def dict_to_aws_tags(d: dict[str, str]) -> list[dict[str, str]] {
    return [{'Key': k, 'Value': v} for (k, v) in d.items()];
}