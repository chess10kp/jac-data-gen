"""RL driver (graph): social_graph.setup_profile.apply.

Origin: this_is_jac/littlex/social_graph.jac. `setup_profile` lands on the
caller's Profile (creating one if absent) and the `apply` ability writes the
username/bio then reports the profile view. The marked body is `apply`; the
entry block spawns it and prints the deterministic profile fields. View ids are
emitted as empty strings so the auto-printed report stays deterministic.
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

walker setup_profile {
    has username: str = "", bio: str = "", reports: list[ProfileView] = [];

    can run with Root entry {
        visit [-->[?:Profile]] else {
            fresh = here ++> Profile(created_at="2020-01-01T00:00:00Z");
            grant(fresh[0], level=ConnectPerm);
            visit fresh;
        }
    }

    can apply with Profile entry {
        # >>>HOLE id="sg_setup_profile_apply" instruction="Implement the apply ability (walker setup_profile, on Profile entry). If self.username is non-empty, set here.username to it. If self.bio is non-empty, set here.bio to it. Then report here.to_profile_view()."
        if self.username {
            here.username = self.username;
        }
        if self.bio {
            here.bio = self.bio;
        }
        report here.to_profile_view();
        # <<<HOLE
    }
}

with entry {
    res = root spawn setup_profile(username="alice", bio="hello world");
    pv = res.reports[0];
    print("username:", pv.username);
    print("bio:", pv.bio);
    print("followers:", sorted([u.username for u in pv.followers]));
    print("following:", sorted([u.username for u in pv.following]));
    print("tweet_count:", len(pv.tweets));
}
