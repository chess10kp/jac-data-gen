node GraphNode { has label: str; }

walker BaseVisitor {
    can log with GraphNode entry {
        print(f"Visiting: {here.label}");
        visit [-->];
    }
}

walker DetailedVisitor(BaseVisitor) {
    override can log with GraphNode entry {
        print(f"Detailed visit to: {here.label}");
        visit [-->];
    }
}

with entry {
    root ++> GraphNode(label="A") ++> GraphNode(label="B");
    root spawn DetailedVisitor();
}
