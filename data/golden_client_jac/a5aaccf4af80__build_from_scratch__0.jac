can deliver with Root exit {
    self.results.sort(key=lambda e: e.created_at);
    report self.results[:50];
}
