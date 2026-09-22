"""Removes '<url>' tag from a tweet."""
def remove_url(tweet: str) -> str {
    tweet.replace('<url>', '')
}