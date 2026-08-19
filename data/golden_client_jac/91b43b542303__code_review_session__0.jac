node Person { has age: int = 0; }
edge Friend { has since: int = 2020; }

walker FilteredWalker {
    can start with Root entry {
        visit [-->];
    }

    can traverse with Person entry {
        # Friend edges to Person nodes since 2020 (inclusive)
        visit [->:Friend:since >= 2020:->][?:Person];
    }
}
