"""concat user_id to create url."""
def create_url(user_id: Any) -> object {
    url = "https://api.twitter.com/2/users/{}/liked_tweets".format(user_id);
    return url;
}