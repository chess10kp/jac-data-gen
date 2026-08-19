"""get_all_profiles.deliver: on Root exit, report the accumulated self.results list."""

obj UserView { has id: str, username: str, bio: str = ""; }

node Profile {
    has username: str = "", bio: str = "";

    def to_user_view -> UserView {
        return UserView(id="", username=self.username, bio=self.bio);
    }
}

walker:pub get_all_profiles {
    has results: list[UserView] = [], reports: list[list[UserView]] = [];

    can run with Root entry {
        for r in allroots() {
            visit [r-->[?:Profile]];
        }
    }

    can gather with Profile entry {
        self.results.append(here.to_user_view());
    }

    can deliver with Root exit {
        report self.results;
    }
}

with entry {
    root ++> Profile(username="alice", bio="a");
    root ++> Profile(username="bob", bio="b");
    res = root spawn get_all_profiles();
    print("usernames:", sorted([u.username for u in res.results]));
    print("count:", len(res.results));
}
