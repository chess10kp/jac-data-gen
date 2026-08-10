"""Really basic sanity checking."""
def is_sane_slack_webhook(url: str | None) -> bool {
    if url is None {
        return False;
    }
    return "https://hooks.slack.com/" in url.strip();
}