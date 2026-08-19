can act with Channel entry {
    if jid(here) == self.channel_id {
        me = [root-->[?:Profile]][0];
        new = here +>: ChannelPost() :+> Tweet(
            content=self.content, author_username=me.username,
            created_at="2020-01-01T00:00:00Z"
        );
        grant(new[0], level=WritePerm);
        report new[0].to_view();
    }
    disengage;
}
