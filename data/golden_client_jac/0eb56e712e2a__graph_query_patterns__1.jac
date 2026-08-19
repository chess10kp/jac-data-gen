"""RL driver (graph): social_graph.load_feed.deliver.

Origin: this_is_jac/littlex/social_graph.jac. `load_feed` gathers the caller's
and followees' tweets, then `deliver` optionally filters by search_query and
sorts by created_at. The marked body is `deliver`; the entry block builds tweets
with fixed timestamps, sets a search query, and prints the filtered contents.
View ids are empty strings so the auto-printed report stays deterministic.
"""

obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}

edge Follow {}
edge Post {}

node Profile {
    has username: str = "", bio: str = "", created_at: str = "";
}

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
    has search_query: str = "", feed: list[TweetView] = [], reports: list[list[TweetView]] = [];

    can run with Root entry {
        mine = [-->[?:Profile]];
        if mine {
            me = mine[0];
            visit [me-->[?:Tweet]];
            visit [me->:Follow:->[?:Profile]-->[?:Tweet]];
        }
    }

    can gather with Tweet entry {
        self.feed.append(here.to_view());
    }

    can deliver with Root exit {
        # >>>HOLE id="sg_load_feed_deliver" instruction="Implement the deliver ability (walker load_feed, on Root exit). Start with result = self.feed. If self.search_query is non-empty, lowercase+strip it into q and keep only tweets where q is a substring of t.content.lower(). Sort result by t.created_at descending. Report result."
        result = self.feed;
        if self.search_query {
            q = self.search_query.lower().strip();
            result = [t for t in result if q in t.content.lower()];
        }
        result.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        report result;
        # <<<HOLE
    }
}

with entry {
    me = (root ++> Profile(username="alice"))[0];
    me ++> Tweet(content="loving jac today", author_username="alice", created_at="2020-01-01T00:00:00Z");
    me ++> Tweet(content="weather is nice", author_username="alice", created_at="2020-01-02T00:00:00Z");
    me ++> Tweet(content="jac scaling well", author_username="alice", created_at="2020-01-03T00:00:00Z");
    res = root spawn load_feed(search_query="JAC");
    print("filtered_by_recency:", [t.content for t in res.reports[0]]);
    print("count:", len(res.reports[0]));
}
