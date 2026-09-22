"""Convert a list of tweepy tweet objects to json format."""
def _convert_to_json(tweet_list: list) -> list {
    [i._json for i in tweet_list]
}