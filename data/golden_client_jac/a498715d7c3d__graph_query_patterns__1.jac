"""RL driver (graph): social_graph.setup_profile.run.

Origin: this_is_jac/littlex/social_graph.jac. `setup_profile` lands on the
caller's root and either walks into an existing Profile or creates a fresh one
when none exists, then `apply` writes the fields and reports the profile view.
The marked body is the `run` ability; the entry block starts from a root with no
profile so the else branch fires, then prints deterministic profile fields. View
ids are empty strings and timestamps are fixed literals so the report is stable.
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
        # >>>HOLE id="sg_setup_profile_run" instruction="Implement the run ability (walker setup_profile, on Root entry). Visit any existing profile via [-->[?:Profile]]; if the visit enqueues nothing, run an else block that creates a fresh Profile attached to here with created_at set to the literal string 2020-01-01T00:00:00Z, grants it ConnectPerm, then visits that fresh node."
        visit [-->[?:Profile]] else {
            fresh = here ++> Profile(created_at="2020-01-01T00:00:00Z");
            grant(fresh[0], level=ConnectPerm);
            visit fresh;
        }
        # <<<HOLE
    }

    can apply with Profile entry {
        if self.username {
            here.username = self.username;
        }
        if self.bio {
            here.bio = self.bio;
        }
        report here.to_profile_view();
    }
}

with entry {
    res = root spawn setup_profile(username="alice", bio="hello there");
    pv = res.reports[0];
    print("username:", pv.username);
    print("bio:", pv.bio);
    print("profile_count:", len([root-->[?:Profile]]));
    print("tweet_count:", len(pv.tweets));
}
