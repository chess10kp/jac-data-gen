"""RL driver (graph): social_graph.Tweet.to_view.

Origin: this_is_jac/littlex/social_graph.jac. The Tweet node knows how to present
itself as a TweetView, computing is_mine by comparing its author against the
caller's own Profile. The marked body is the `to_view` def; a small walker lands
on a fixed tweet and the entry block prints the deterministic projection. The
view id is emitted as an empty string so the auto-printed report stays stable.
"""

obj UserView { has id: str, username: str, bio: str = ""; }
obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}

edge Post {}

node Profile { has username: str = ""; }

node Tweet {
    has content: str = "", author_username: str = "", created_at: str = "",
        likes: list[str] = [], comments: list[dict[str, str]] = [];

    def to_view -> TweetView {
        # >>>HOLE id="sg_tweet_to_view" instruction="Implement the to_view def on Tweet. Resolve the caller's profile mine = [root-->[?:Profile]]. Compute is_mine: True only when mine is non-empty AND self.author_username equals mine[0].username. Return a TweetView with id set to the empty string, and content, author_username, created_at, likes, comments copied from self, plus the computed is_mine."
        mine = [root-->[?:Profile]];
        is_mine: bool = len(mine) > 0 and self.author_username == mine[0].username;
        return TweetView(
            id="", content=self.content, author_username=self.author_username,
            created_at=self.created_at, likes=self.likes, comments=self.comments, is_mine=is_mine
        );
        # <<<HOLE
    }
}

walker view_tweet {
    has reports: list[TweetView] = [];
    can run with Root entry { visit [-->[?:Profile]-->[?:Tweet]]; }
    can show with Tweet entry { report here.to_view(); disengage; }
}

with entry {
    p = (root ++> Profile(username="alice"))[0];
    p ++> Tweet(content="hello", author_username="alice", created_at="2020-01-01T00:00:00Z", likes=["bob", "carol"]);
    res = root spawn view_tweet();
    tv = res.reports[0];
    print("content:", tv.content);
    print("author:", tv.author_username);
    print("created_at:", tv.created_at);
    print("likes:", tv.likes);
    print("is_mine:", tv.is_mine);
}
