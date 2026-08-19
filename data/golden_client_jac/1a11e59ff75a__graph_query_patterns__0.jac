"""RL driver (graph): social_graph.get_all_profiles.gather.

Origin: this_is_jac/littlex/social_graph.jac. `get_all_profiles` fans out over
every root's profiles and `gather` accumulates each as a user view, delivered
once at exit. The marked body is `gather`; the entry block builds one profile so
allroots output is stable and prints the sorted usernames.
"""

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
        # >>>HOLE id="sg_get_all_profiles_gather" instruction="Implement the gather ability (walker get_all_profiles, on Profile entry). Append here.to_user_view() to self.results."
        self.results.append(here.to_user_view());
        # <<<HOLE
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
