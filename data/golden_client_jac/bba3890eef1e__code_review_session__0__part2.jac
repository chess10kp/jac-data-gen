node User {
    has name: str;
    has email: str = "";
}

walker:pub search_users {
    has query: str;
    has limit: int = 10;
    has page: int = 1;

    can search with Root entry {
        matches = [u for u in [-->][?:User] if self.query in u.name];
        start = (self.page - 1) * self.limit;
        report matches[start:start + self.limit];
    }
}
