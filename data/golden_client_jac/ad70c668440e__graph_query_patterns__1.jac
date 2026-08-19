"""RL driver (graph): social_graph.Channel.to_view.

Origin: this_is_jac/littlex/social_graph.jac. The Channel node knows how to
present itself as a ChannelView: member_count from its Member edges, is_member
relative to the caller's Profile, and (optionally) its posts newest-first. The
marked body is the `to_view` def; a small walker lands on a fixed channel and
the entry block prints the deterministic projection.
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
edge ChannelPost {}

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
        # >>>HOLE id="sg_channel_to_view" instruction="Implement to_view(with_posts: bool) -> ChannelView on the Channel node. Determine is_member: the caller's Profile is [root-->[?:Profile]]; is_member is True only if such a profile exists and it has a Member edge to self. Build posts only when with_posts is True: collect to_view() of every Tweet directly out of self, then sort that list by created_at descending. Return a ChannelView with id set to the empty string, name, description, creator_username, created_at copied from self, member_count = the number of Profiles linked to self by an incoming Member edge, is_member, and posts."
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
        # <<<HOLE
    }
}

walker view_channel {
    has reports: list[ChannelView] = [];

    can run with Root entry {
        visit [-->[?:Profile]->:Member:->[?:Channel]];
    }

    can show with Channel entry {
        report here.to_view(True);
        disengage;
    }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    c = (p +>: Member() :+> Channel(name="jacdevs", description="hub", creator_username="alice", created_at="2020-01-01T00:00:00Z"))[0];
    c +>: ChannelPost() :+> Tweet(content="newer", author_username="alice", created_at="2020-03-01T00:00:00Z");
    c +>: ChannelPost() :+> Tweet(content="older", author_username="alice", created_at="2020-02-01T00:00:00Z");
    res = root spawn view_channel();
    cv = res.reports[0];
    print("name:", cv.name);
    print("description:", cv.description);
    print("creator:", cv.creator_username);
    print("member_count:", cv.member_count);
    print("is_member:", cv.is_member);
    print("post_count:", len(cv.posts));
    print("posts_by_recency:", [t.content for t in cv.posts]);
}
