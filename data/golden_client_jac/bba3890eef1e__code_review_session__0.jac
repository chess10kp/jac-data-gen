can search with Root entry {
    matches = [u for u in [-->][?:User] if self.query in u.name];
    start = (self.page - 1) * self.limit;
    report matches[start:start + self.limit];
}
