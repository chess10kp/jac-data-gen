walker find_tweet {
    has tweet_id: str = "", actor: str = "";
    can run with Root entry {
        if self.tweet_id {
            target = jobj(self.tweet_id);
            if isinstance(target, Tweet) {
                visit [target];
            }
        }
    }
}
