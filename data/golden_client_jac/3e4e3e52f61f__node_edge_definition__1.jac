node Item {
    has value: int = 0;
}

walker Visitor {
    can visit with Item entry {
        print(here.value);
    }
}

with entry {
    start = Item(value=1);

    # Atomic pipe forward - depth-first traversal
    start spawn :> Visitor();

    # Standard pipe with spawn - breadth-first traversal
    start spawn |> Visitor();
}
