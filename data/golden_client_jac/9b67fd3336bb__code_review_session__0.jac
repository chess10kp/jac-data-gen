node Person {}
edge Friend { has since: int = 2020; }

walker Visitor {
    can start with Root entry {
        visit [-->];
    }

    can filter with Person entry {
        # since >= 2020 to INCLUDE friendships from the default year 2020;
        # the original `since > 2020` silently dropped every default-year edge.
        visit [->:Friend:since >= 2020:->];
    }
}

with entry {
    a = Person();
    b = Person();
    root ++> a;
    a +>:Friend(since=2020):+> b;
    root spawn Visitor();
}
