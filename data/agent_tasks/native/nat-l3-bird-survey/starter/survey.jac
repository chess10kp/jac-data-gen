"""Bird survey tallies: Site and Species nodes on root, Site -Sighted-> Species."""

node Site {
    has name: str;
}

node Species {
    has name: str;
}

edge Sighted: Site --> Species {
    has total: int = 0;
    has last_day: int = 0;
}
