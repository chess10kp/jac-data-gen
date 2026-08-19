"""RL driver (graph): social_graph.load_feed.run.

Origin: this_is_jac/littlex/social_graph.jac. `load_feed` starts at the caller's
root, resolves their own Profile, then queues their own tweets plus the tweets of
everyone they follow; `gather` collects each as a view and `deliver` sorts and
reports. The marked body is the `run` ability; the entry block builds a profile
that follows another profile and prints a deterministic sorted feed projection.
View ids are empty strings and timestamps are fixed literals so the report stays
stable.
"""

obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}

edge Follow {}
edge Post {}

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

walker load_feed {
    has search_query: str = "", feed: list[TweetView] = [],
        reports: list[list[TweetView]] = [];

    can run with Root entry {
        # >>>HOLE id="sg_load_feed_run" instruction="Implement the run ability (walker load_feed, on Root entry). Resolve the caller's own profile via mine = [-->[?:Profile]]. Only if mine is non-empty, bind me = mine[0], then visit me's own tweets [me-->[?:Tweet]] and also visit the tweets of everyone me follows [me->:Follow:->[?:Profile]-->[?:Tweet]]."
        mine = [-->[?:Profile]];
        if mine {
            me = mine[0];
            visit [me-->[?:Tweet]];
            visit [me->:Follow:->[?:Profile]-->[?:Tweet]];
        }
        # <<<HOLE
    }

    can gather with Tweet entry {
        self.feed.append(here.to_view());
    }

    can deliver with Root exit {
        result = self.feed;
        if self.search_query {
            q = self.search_query.lower().strip();
            result = [t for t in result if q in t.content.lower()];
        }
        result.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        report result;
    }
}

with entry {
    me = (root ++> Profile(username="alice"))[0];
    me ++> Tweet(content="my own post", author_username="alice", created_at="2020-01-01T00:00:00Z");
    bob = Profile(username="bob");
    me +>: Follow() :+> bob;
    bob ++> Tweet(content="bob post", author_username="bob", created_at="2020-02-01T00:00:00Z");
    res = root spawn load_feed();
    feed = res.reports[0];
    print("contents_desc_by_date:", [t.content for t in feed]);
    print("count:", len(feed));
}
