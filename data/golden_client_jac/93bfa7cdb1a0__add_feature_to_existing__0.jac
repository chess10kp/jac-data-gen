walker Explorer {
    has visited: list = [];
    can explore with Person entry {
        self.visited.append(here.name);
        ...
    }
}
