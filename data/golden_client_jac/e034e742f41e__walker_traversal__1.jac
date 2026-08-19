walker Searcher {
    has target: str;

    can search with Person entry {
        if here.name == self.target {
            report here;
            disengage;  # Stop traversal
        }
        visit [-->];
    }
}
