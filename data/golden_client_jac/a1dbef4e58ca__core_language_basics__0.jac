with entry {
    result = root spawn load_feed();
    tweets: list[TweetView] = result.reports[0] as list[TweetView];
}
