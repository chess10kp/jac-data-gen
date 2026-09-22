""" If included, read the user from the tweet and return their self-supplied location"""
def getTweetUserLocation(tweet: Any) -> object {
    if (
        ('user' in tweet)
        and (tweet['user'] is not None)
        and ('location' in tweet['user'])
    ) {
        return tweet['user']['location'];
    } else {
        return None;
    }
}