obj UserView { has id: str, username: str, bio: str = ""; }

node Profile {
    has username: str = "", bio: str = "";

    def to_user_view -> UserView {
        return UserView(id=jid(self), username=self.username, bio=self.bio);
    }
}
