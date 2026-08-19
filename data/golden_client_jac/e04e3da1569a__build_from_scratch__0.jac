node Person {
    has name: str;
}

walker FindPerson {
    has target: str;
    has found: bool = False;
    can search with Person entry {
        if here.name == self.target {
            self.found = True;
            disengage;
        }
        visit [-->];
    }
}
