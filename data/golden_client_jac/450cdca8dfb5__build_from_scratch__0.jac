walker add_comment(find_tweet) {
    has content: str = "";

    can act with Tweet entry {
        if jid(here) == self.tweet_id {
            comment = {
                "username": self.actor,
                "content": self.content,
                "created_at": "2020-01-01T00:00:00Z"
            };
            here.comments.append(comment);
            report {"success": True, "comment": comment};
            disengage;
        }
    }
}
