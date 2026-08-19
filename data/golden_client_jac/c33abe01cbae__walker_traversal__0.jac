walker BFSWalker {
    can start with Root entry {
        print(f"Starting at: {here}");
        visit [-->];
    }

    can traverse with Person entry {
        print(f"Visiting: {here.name}");
        visit [-->];  # Queue all outgoing for later visits
    }
}
