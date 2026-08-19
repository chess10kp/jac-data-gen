"""RL driver (graph): social_graph.get_profile.give.

Origin: this_is_jac/littlex/social_graph.jac. `get_profile` navigates to the
caller's Profile and the `give` ability reports its profile view. The marked
body is `give`; the entry block builds a profile with a tweet and a follower,
then prints deterministic profile fields. View ids are emitted as empty strings
and timestamps are fixed literals so the auto-printed report is deterministic.
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
    has username: str = "", bio: str = "", created_at: str = "";

    def to_user_view -> UserView {
        return UserView(id="", username=self.username, bio=self.bio);
    }
    def to_profile_view -> ProfileView {
        followers = [p.to_user_view() for p in [self<-:Follow:<-[?:Profile]]];
        following = [p.to_user_view() for p in [self->:Follow:->[?:Profile]]];
        tweets = [t.to_view() for t in [self-->[?:Tweet]]];
        tweets.sort(key=lambda t: TweetView : t.created_at, reverse=True);
        return ProfileView(
            id="", username=self.username, bio=self.bio,
            followers=followers, following=following, tweets=tweets
        );
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

walker get_profile {
    has reports: list[ProfileView] = [];

    can run with Root entry {
        visit [-->[?:Profile]];
    }

    can give with Profile entry {
        # >>>HOLE id="sg_get_profile_give" instruction="Implement the give ability (walker get_profile, on Profile entry). Report here.to_profile_view()."
        report here.to_profile_view();
        # <<<HOLE
    }
}

with entry {
    me = (root ++> Profile(username="alice", bio="me"))[0];
    me ++> Tweet(content="hi", author_username="alice", created_at="2020-01-01T00:00:00Z");
    res = root spawn get_profile();
    pv = res.reports[0];
    print("username:", pv.username);
    print("bio:", pv.bio);
    print("tweet_contents:", sorted([t.content for t in pv.tweets]));
    print("tweet_count:", len(pv.tweets));
}
