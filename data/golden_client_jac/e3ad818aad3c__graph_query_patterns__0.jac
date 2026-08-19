"""RL driver (graph): social_graph.Profile.to_user_view.

Origin: this_is_jac/littlex/social_graph.jac. The Profile node knows how to
present itself as a compact UserView carrying its id, username, and bio. The
marked body is the `to_user_view` def; a tiny walker lands on a fixed profile and
the entry block prints the deterministic projection. The view id is emitted as an
empty string so the auto-printed report stays stable.
"""

obj UserView { has id: str, username: str, bio: str = ""; }

node Profile {
    has username: str = "", bio: str = "";

    def to_user_view -> UserView {
        # >>>HOLE id="sg_profile_to_user_view" instruction="Implement the to_user_view def on Profile. Return a UserView with id set to the empty string, and username and bio copied from self."
        return UserView(id="", username=self.username, bio=self.bio);
        # <<<HOLE
    }
}

walker view_user {
    has reports: list[UserView] = [];
    can run with Root entry { visit [-->[?:Profile]]; }
    can show with Profile entry { report here.to_user_view(); disengage; }
}

with entry {
    root ++> Profile(username="alice", bio="hello there");
    res = root spawn view_user();
    uv = res.reports[0];
    print("id:", uv.id);
    print("username:", uv.username);
    print("bio:", uv.bio);
}
