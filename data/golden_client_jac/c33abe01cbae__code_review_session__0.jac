node Person { has name: str = ""; }

walker BFSWalker {
    has visited: set[str] = set();

    can start with Root entry {
        print(f"Starting at: {here}");
        visit [-->];
    }

    can traverse with Person entry {
        if jid(here) in self.visited {
            skip;
        }
        self.visited.add(jid(here));
        print(f"Visiting: {here.name}");
        visit [-->];
    }
}
