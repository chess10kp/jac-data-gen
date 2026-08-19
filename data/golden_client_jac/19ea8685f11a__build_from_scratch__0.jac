walker get_channels {
    has results: list = [];
    can gather with Channel entry {
        self.results.append(here.to_view(False));
    }
    can deliver with Root exit {
        report self.results;
    }
}
