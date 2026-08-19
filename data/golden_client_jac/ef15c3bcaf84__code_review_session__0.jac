edge Family {}

walker Visitor {
    can traverse with `root entry {
        visit [->:Family:->];
    }
}
