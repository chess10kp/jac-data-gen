"""RL driver (graph): social_graph.Profile.to_profile_view.

Origin: this_is_jac/littlex/social_graph.jac. The Profile node assembles a full
ProfileView straight off its edges: followers (incoming Follow), following
(outgoing Follow), and its own tweets sorted by descending created_at. The marked
body is the `to_profile_view` def; a tiny walker lands on a fixed profile and the
entry block prints only the deterministic username lists and tweet contents. View
ids are emitted as empty strings and timestamps are fixed literals so the report
stays stable.
"""

obj UserView { has id: str, username: str, bio: str = ""; }
obj TweetView {
    has id: str, content: str, author_username: str, created_at: str,
        likes: list[str], comments: list[dict[str, str]], is_mine: bool = False;
}
obj ProfileView {
    has id: str, username: str, bio: str,
        followers: list[UserView], following: list[UserView], tweets: list[TweetView];
}

edge Follow {}
edge Post {}

node Profile {
    has username: str = "", bio: str = "";

    def to_user_view -> UserView {
        return UserView(id="", username=self.username, bio=self.bio);
    }
    def to_profile_view -> ProfileView {
        # >>>HOLE id="sg_profile_to_profile_view" instruction="Implement the to_profile_view def on Profile. Build followers by calling to_user_view() on each incoming Follow profile [self<-:Follow:<-[?:Profile]], following from outgoing Follow profiles [self->:Follow:->[?:Profile]], and tweets by calling to_view() on each [self-->[?:Tweet]]; sort tweets in place by created_at descending. Return a ProfileView with id set to the empty string, username and bio from self, plus followers, following, and tweets."
        followers = [p.to_user_view() for p in [self<-:Follow:<-[?:Profile]]];
        following = [p.to_user_view() for p in [self->:Follow:->[?:Profile]]];
        tweets = [t.to_view() for t in [self-->[?:Tweet]]];
        tweets.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        return ProfileView(
            id="", username=self.username, bio=self.bio,
            followers=followers, following=following, tweets=tweets
        );
        # <<<HOLE
    }
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

walker view_profile {
    has reports: list[ProfileView] = [];
    can run with Root entry { visit [-->[?:Profile]]; }
    can show with Profile entry { report here.to_profile_view(); disengage; }
}

with entry {
    me = (root ++> Profile(username="alice", bio="me"))[0];
    me ++> Tweet(content="older", author_username="alice", created_at="2020-01-01T00:00:00Z");
    me ++> Tweet(content="newer", author_username="alice", created_at="2020-02-01T00:00:00Z");
    follower = Profile(username="bob");
    follower +>: Follow() :+> me;        # bob follows alice
    followee = Profile(username="carol");
    me +>: Follow() :+> followee;        # alice follows carol
    res = root spawn view_profile();
    pv = res.reports[0];
    print("username:", pv.username);
    print("followers:", sorted([u.username for u in pv.followers]));
    print("following:", sorted([u.username for u in pv.following]));
    print("tweets_desc_by_date:", [t.content for t in pv.tweets]);
}
