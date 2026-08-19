"""Social graph: a Profile node that can project itself as a compact UserView."""

obj UserView { has id: str, username: str, bio: str = ""; }

node Profile {
    has username: str = "", bio: str = "";

    def to_user_view -> UserView {
        return UserView(id="", username=self.username, bio=self.bio);
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
