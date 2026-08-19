def to_view -> TweetView {
    me = [root-->[?:Profile]][0];
    is_mine: bool = self.author_username == me.username;
    return TweetView(
        id="", content=self.content, author_username=self.author_username,
        created_at=self.created_at, likes=self.likes, comments=self.comments, is_mine=is_mine
    );
}
