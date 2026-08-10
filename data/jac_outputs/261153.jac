"""
    Convert all tokens into their unique ids.
    """
def tokenize_stories(stories: Any, token_to_id: Any) -> object {
    story_ids = [];
    for (story, query, answer) in stories {
        story = [[token_to_id[token] for token in sentence] for sentence in story];
        query = [token_to_id[token] for token in query];
        answer = token_to_id[answer];
        story_ids.append((story, query, answer));
    }
    return story_ids;
}