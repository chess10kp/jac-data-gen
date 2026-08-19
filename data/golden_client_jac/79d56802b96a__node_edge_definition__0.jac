node Person {
    has name: str;
    has age: int;
}

walker DataProcessor {
    has data: str;

    # Runs when spawned at root
    can start with Root entry {
        print("Starting from root");
        visit [-->];
    }

    # Runs when visiting a Person node
    can process with Person entry {
        print(f"Processing {here.name}");
        visit [-->];
    }

    # Runs when visiting any node
    can default with entry {
        print("At unknown node type");
        visit [-->];
    }
}
