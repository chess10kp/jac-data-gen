"""Create the facebook post URL from ID."""
def _make_post_url(row: dict[str, str]) -> str {
    return "http://facebook.com/{0}".format(row['facebook_id']);
}