walker load_feed {
    has feed: list = [];
    has search_query: str = "";
    can deliver with Root exit {
        result = self.feed;
        result.sort(key=with t: TweetView can t.created_at, reverse=True);
        report result;
    }
}
