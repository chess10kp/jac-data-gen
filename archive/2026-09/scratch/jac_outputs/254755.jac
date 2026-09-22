"""
    returns the arn of an SSM parameter with specified, region, account_id and name. If the name
    starts with a '/', it does not show up in the Arn as AWS seems to store it that way.
    """
def to_arn(region: str, account_id: str, name: str) -> str {
    return (
        "arn:aws:ssm:%s:%s:parameter/%s"
        % (region, account_id, name if name[0] != "/" else name[1:])
    );
}