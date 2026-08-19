node Item {}

walker Visitor {
    has target: Item | None = None;

    can direct with Item entry {
        visit here;                     # Visit current node
        visit self.target;              # Visit node stored in walker field
    }
}
