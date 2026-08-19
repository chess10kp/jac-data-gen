can make with Profile entry {
    new = here +>: Post() :+> Tweet(
        content=self.content, author_username=here.username,
        created_at="2020-01-01T00:00:00Z"
    );
    report new[0].to_view();
}
