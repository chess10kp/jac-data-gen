glob visited: int = 0;

walker Example {
    can traverse with Item entry {
        global visited;
        visited += 1;
        visit [-->];
    }
}
