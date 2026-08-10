"""Returns [{'Key': 'Name', 'Value': name}] """
def create_name_tags(name: str) -> list[dict[str, str]] {
    return [
        {'Key': 'Name', 'Value': name},
        {'Key': 'ncluster', 'Value': 'ncluster'}
    ];
}