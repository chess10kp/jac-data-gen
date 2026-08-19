"""get_all_profiles.gather: append here.to_user_view() to self.results (delivered later on Root exit)."""

obj UserView { has id: str, username: str, bio: str = ""; }

edge Follow {}

node Profile {
    has username: str = "", bio: str = "", created_at: str = "";

    def to_user_view -> UserView {
        return UserView(id="", username=self.username, bio=self.bio);
    }
}

walker get_all_profiles {
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
    root ++> Profile(username="alice");
    res = root spawn get_all_profiles();
    print("usernames:", sorted([u.username for u in res.reports[0]]));
}
