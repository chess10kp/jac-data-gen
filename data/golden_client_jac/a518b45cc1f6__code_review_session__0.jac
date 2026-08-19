node Node1 { has v: int = 0; }
node Node2 { has v: int = 0; }

walker Processor {
    can process with Node1 | Node2 entry {
        # Handles either node type; here is typed as Node1 | Node2
        print(here.v);

        # Continue on to neighbors so the whole graph is processed
        visit [-->];
    }
}
