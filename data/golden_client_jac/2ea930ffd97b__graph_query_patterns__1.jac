"""RL driver (graph): social_graph.get_all_profiles.deliver.

Origin: this_is_jac/littlex/social_graph.jac. `get_all_profiles` fans out over
every root's profiles, gathers each as a UserView into self.results, and the
`deliver` ability reports that accumulated list once at root exit. The marked
body is `deliver`; the entry block builds two profiles and prints a deterministic
sorted username projection. View ids are emitted as empty strings.
"""

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
        # >>>HOLE id="sg_get_all_profiles_deliver" instruction="Implement the deliver ability (walker get_all_profiles, on Root exit). Report the accumulated self.results list."
        report self.results;
        # <<<HOLE
    }
}

with entry {
    root ++> Profile(username="alice", bio="a");
    root ++> Profile(username="bob", bio="b");
    res = root spawn get_all_profiles();
    print("usernames:", sorted([u.username for u in res.results]));
    print("count:", len(res.results));
}
