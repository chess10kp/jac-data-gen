node Item {}

walker Visitor {
    can start with Root entry {
        visit [-->];
    }

    can go with Item entry {
        # Forward only. The original queued each neighbour up to three times
        # ([-->], [<--], and [<-->]), causing duplicate visits and back-tracking
        # into nodes we already came from -- a fast route to reprocessing/loops.
        visit [-->];
    }
}

with entry {
    root ++> Item() ++> Item();
    root spawn Visitor();
}
