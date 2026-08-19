"""RL driver (graph): social_graph.load_feed.gather.

Origin: this_is_jac/littlex/social_graph.jac. `load_feed` queues the caller's own
tweets plus those of everyone they follow; the `gather` ability appends each
visited tweet's view to self.feed and `deliver` sorts and reports. The marked
body is `gather`; the entry block builds a profile with two tweets and prints a
deterministic sorted feed projection. View ids are empty strings and timestamps
are fixed literals so the report stays stable.
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
        mine = [-->[?:Profile]];
        if mine {
            me = mine[0];
            visit [me-->[?:Tweet]];
            visit [me->:Follow:->[?:Profile]-->[?:Tweet]];
        }
    }

    can gather with Tweet entry {
        # >>>HOLE id="sg_load_feed_gather" instruction="Implement the gather ability (walker load_feed, on Tweet entry). Append here.to_view() to self.feed."
        self.feed.append(here.to_view());
        # <<<HOLE
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
    me ++> Tweet(content="first", author_username="alice", created_at="2020-01-01T00:00:00Z");
    me ++> Tweet(content="second", author_username="alice", created_at="2020-02-01T00:00:00Z");
    res = root spawn load_feed();
    feed = res.reports[0];
    print("contents_desc_by_date:", [t.content for t in feed]);
    print("count:", len(feed));
}
