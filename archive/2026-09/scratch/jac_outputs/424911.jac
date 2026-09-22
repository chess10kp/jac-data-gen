"""
    Given a list of plugins, filter out the `acl` plugin
    and return a formatted string
    of all the acl consumer group names which are `allowed`
    to access the service.
    """
def get_consumer_groups(acls: list[dict[str, str]] | None) -> str | None {
    if acls is None {
        return;
    }
    return "`" + "`, `".join(i.get("group") for i in acls) + "`";
}