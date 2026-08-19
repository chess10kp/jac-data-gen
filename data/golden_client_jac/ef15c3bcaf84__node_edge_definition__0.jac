edge Family {}

walker Visitor {
    can traverse with Root entry {
        visit [-->];                      # Visit all outgoing edges
        visit [->:Family:->];             # Visit only Family edges
    }
}
