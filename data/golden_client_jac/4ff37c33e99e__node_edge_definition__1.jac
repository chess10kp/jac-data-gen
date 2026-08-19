"""RL driver (graph): social_graph.create_channel.make.

Origin: this_is_jac/littlex/social_graph.jac. `create_channel` navigates to the
caller's Profile, then the `make` ability attaches a new Channel via a Member
edge and reports its view. The marked body is `make`; the entry block spawns it
and prints the deterministic channel fields.
"""

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

walker create_channel {
    has name: str, description: str = "";

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can make with Profile entry {
        # >>>HOLE id="sg_create_channel_make" instruction="Implement the make ability (walker create_channel, on Profile entry). Attach a new Channel to here via a Member edge, setting name=self.name, description=self.description, creator_username=here.username, and created_at to the literal string 2020-01-01T00:00:00Z. Grant the new channel ConnectPerm, then report the channel view via to_view(False)."
        new = here +>: Member() :+> Channel(
            name=self.name,
            description=self.description,
            creator_username=here.username,
            created_at="2020-01-01T00:00:00Z"
        );
        grant(new[0], level=ConnectPerm);
        report new[0].to_view(False);
        # <<<HOLE
    }
}

with entry {
    root ++> Profile(username="alice");
    res = root spawn create_channel(name="jacdevs", description="all things jac");
    cv = res.reports[0];
    print("name:", cv.name);
    print("description:", cv.description);
    print("creator:", cv.creator_username);
    print("member_count:", cv.member_count);
    print("is_member:", cv.is_member);
    print("post_count:", len(cv.posts));
}
