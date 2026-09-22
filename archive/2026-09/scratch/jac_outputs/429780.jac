"""Helper function to make it easier to mention users on Slack."""
def mention_user(user: str) -> str {
    return "<@" + user + ">";
}