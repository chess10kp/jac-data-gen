"""Retrieve container volumes details."""
def get_volumes(container: dict[str, list[dict[str, str]]]) -> list[dict[str, str]] {
    mounts = container.get('Mounts');
    return [
        dict(source=mount['Source'], destination=mount['Destination'])
        for mount in mounts
    ];
}