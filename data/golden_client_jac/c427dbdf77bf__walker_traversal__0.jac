walker BaseVisitor {
    can log with entry {
        print(f"Visiting: {here}");
        visit [-->];
    }
}

walker DetailedVisitor(BaseVisitor) {
    override can log with entry {
        print(f"Detailed visit to: {type(here).__name__}");
        visit [-->];
    }
}
