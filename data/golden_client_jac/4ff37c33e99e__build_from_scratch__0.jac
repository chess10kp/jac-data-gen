walker create_channel {
    has name: str;
    has description: str = "";

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can make with Profile entry {
        new = here +>: Member() :+> Channel(
            name=self.name, description=self.description,
            creator_username=here.username, created_at="2020-01-01T00:00:00Z"
        );
        report new[0].to_view(False);
    }
}
