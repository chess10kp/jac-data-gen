"""Create url for fetching a users groups."""
def make_users_groups_url(base_url: str, duke_unique_id: str) -> str {
    return "{}/subjects/{}/groups".format(base_url, duke_unique_id);
}