walker:priv MyWalker {
    can do_work with Root entry {
        report "first";   # reports[0]
        report "second";  # reports[1]
    }
}

with entry {
    # Spawning the walker
    response = root spawn MyWalker();
    print(response.reports);  # ["first", "second"]
}
