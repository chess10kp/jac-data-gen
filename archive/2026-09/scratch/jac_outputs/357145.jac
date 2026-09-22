"""create urls to use fetch nomal tweets and mention tweets."""
def create_url(user_id: Any, tweet_type: Any) -> object {
    if (tweet_type == "mention") {
        url = "https://api.twitter.com/2/users/{}/mentions".format(user_id);
    } else {
        url = "https://api.twitter.com/2/users/{}/tweets".format(user_id);
    }
    return url;
}