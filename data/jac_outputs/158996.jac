"""Create list of AWS tags from manifest."""
def _instance_tags(hostname: str, role: str) -> list[dict[str, str | list[dict[str, str]]]] {
    tags = [
        {'Key': 'Name', 'Value': hostname.lower()},
        {'Key': 'Role', 'Value': role.lower()}
    ];
    return [{'ResourceType': 'instance', 'Tags': tags}];
}