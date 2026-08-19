"""get_channels.gather: gather each channel once, deduping by jid via a self.seen map."""

obj UserView { has id: str, username: str, bio: str = ""; }
obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}
obj ChannelView {
    has id: str, name: str, description: str, creator_username: str,
        created_at: str, member_count: int, is_member: bool,
        posts: list[TweetView] = [];
}

edge Member {}

node Profile { has username: str = ""; }
node Tweet {
    has content: str = "", author_username: str = "", created_at: str = "",
        likes: list[str] = [], comments: list[dict[str, str]] = [];

    def to_view -> TweetView {
        mine = [root-->[?:Profile]];
        is_mine: bool = len(mine) > 0 and self.author_username == mine[0].username;
        return TweetView(
            id="", content=self.content, author_username=self.author_username,
            created_at=self.created_at, likes=self.likes, comments=self.comments, is_mine=is_mine
        );
    }
}
node Channel {
    has name: str = "", description: str = "", creator_username: str = "",
        created_at: str = "";

    def to_view(with_posts: bool) -> ChannelView {
        mine = [root-->[?:Profile]];
        is_member: bool = len(mine) > 0 and len([edge mine[0]->:Member:->self]) > 0;
        posts: list[TweetView] = [];
        if with_posts {
            posts = [t.to_view() for t in [self-->[?:Tweet]]];
            posts.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        }
        return ChannelView(
            id="", name=self.name, description=self.description,
            creator_username=self.creator_username, created_at=self.created_at,
            member_count=len([self<-:Member:<-[?:Profile]]),
            is_member=is_member, posts=posts
        );
    }
}

walker get_channels {
    has seen: dict[str, bool] = {},
        results: list[ChannelView] = [],
        reports: list[list[ChannelView]] = [];

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Profile]-->[?:Channel]];
        }
    }

    can gather with Channel entry {
        cid = jid(here);
        if cid not in self.seen {
            self.seen[cid] = True;
            self.results.append(here.to_view(False));
        }
    }

    can deliver with Root exit {
        self.results.sort(key=lambda c: ChannelView : c.created_at, reverse=True);
        report self.results;
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    p +>: Member() :+> Channel(name="zeta", creator_username="alice", created_at="2020-01-01T00:00:00Z");
    p +>: Member() :+> Channel(name="alpha", creator_username="alice", created_at="2020-02-01T00:00:00Z");
    res = root spawn get_channels();
    chans = res.reports[0];
    print("count:", len(chans));
    print("names_by_recency:", [c.name for c in chans]);
    print("creators:", sorted([c.creator_username for c in chans]));
}
