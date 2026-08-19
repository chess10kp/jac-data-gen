node Person {
    has name: str;
}

walker Explorer {
    can explore with Person entry {
        print(f"Visiting {here.name}");

        # Different visit patterns:
        visit [-->];          # Visit all outgoing connections
        # visit [<--];        # Visit all incoming connections
        # visit [<-->];       # Visit all connections (both directions)
    }
}
