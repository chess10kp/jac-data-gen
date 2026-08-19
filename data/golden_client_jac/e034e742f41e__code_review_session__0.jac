node Person { has name: str = ""; }

walker Searcher {
    has target: str;

    can start with Root entry {
        visit [-->];
    }

    can search with Person entry {
        if here.name == self.target {
            report here;
            disengage;
        }
        visit [-->];
    }
}
