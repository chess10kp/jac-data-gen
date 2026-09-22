"""remove one letter word"""
def filter_one_letter_word(tweets: list[list[str]]) -> list[list[str]] {
    for (index, tweet) in enumerate(tweets) {
        tweets[index] = [x for x in tweet if len(x) > 1];
    }
    return tweets;
}