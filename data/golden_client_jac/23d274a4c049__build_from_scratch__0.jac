walker delete_tweet(find_tweet) {
    can act with Tweet entry {
        if jid(here) == self.tweet_id {
            del here;
            report {"success": True};
            disengage;
        }
    }
}
