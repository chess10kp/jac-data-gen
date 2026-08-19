node Item {}

walker Visitor {
    can traverse with Item entry {
        visit : 0 : [-->];              # Insert at FRONT of queue (DFS behavior)
        visit : -1 : [-->];             # Insert at END of queue (BFS behavior)
        visit : 2 : [-->];              # Insert at position 2 in queue
    }
}
