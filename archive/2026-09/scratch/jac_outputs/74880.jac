"""
        - gets all the hashtags if available in the tweet
    """
def get_hashtags(hashtag_entity: list[dict[str, str]] | None) -> list[str] {
    hashtags = [];
    if hashtag_entity is not None {
        for hashtag in hashtag_entity {
            hashtags.append(hashtag['text']);
        }
    }
    return hashtags;
}